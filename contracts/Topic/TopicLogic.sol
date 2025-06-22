// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Share.sol";
import "../MainSystem.sol";
import "../ClaimNFT.sol";


contract TopicLogic is Initializable {

    // struct Claim {
    //     uint256 claimId;
    //     address creator;
    //     bytes32 digest;
    //     Side side;
    //     ClaimType claimType;
    //     uint256 parentClaimId;
    //     uint256 clusterId;
    //     bool isIssued;
    // }

    struct Edit {
        uint256 id;
        bytes32 newDigest;
        address proposer;
        bool    approved;
    }

    uint256    public id;
    uint256    public nextEditId;
    uint256    public nextClaimId;
    address    public creator;
    address    public mainAddr;
    address    public claimAddr;
    MainSystem public main;
    ClaimNFT   public claimNFT;
    bytes32    public digest;
    uint256    public version;
    uint256    public promoteTimelock;
    uint256    public constant DELAY = 1800;
    uint256    public restAgreeToArchiveCount;
    // bool       public readyforPromote;
    // bool       public promoted;
    // bool       public archived;

    Status     public status;

    mapping (address => bool) public isJoined;
    // 클러스터 + 유저
    mapping (address => Side) public whereSide;
    address[]                 public joinedClusters;
    mapping (Side => bool)    public sideActivated;
    mapping (uint256 => Edit) public edits;
    mapping (uint256 => mapping (address => bool)) public editId2ClusterAddr2Agreed;
    mapping (uint256 => Claim) cliams;
    mapping (address => bool) public addr2archiveAgeed;
    mapping (Side => bytes32) public side2digest;

    event Joined(address indexed joiner);
    event TopicPromoted();
    event EditProposed(uint256 indexed editId, address indexed proposer);
    event EditAgreed(uint256 indexed editId, address indexed approver);
    event EditApproved(uint256 indexed editId);
    event TimelockDelay(uint256 Timelock);
    event ClaimCreated(uint256 indexed claimId);
    event OpeningClaimModified(uint256 indexed claimId);
    event AgreeArchive(address indexed clusterAddr);
    event Archived();

    modifier onlyMainSys() {
        require(msg.sender == mainAddr, "only mainSystem");
        _;
    }

    modifier onlyCluster() {
        require(main.addressToClusterId(msg.sender) != 0, "only ClusterSystem");
        _;
    }

    function initialize(
        uint256 _id,
        bytes32 _digest,
        address _creator,
        address _mainAddr,
        address _claimAddr
    ) external initializer {
        id = _id;
        digest  = _digest;
        creator = _creator;
        mainAddr   = _mainAddr;
        claimAddr  = _claimAddr;
        main = MainSystem(_mainAddr);
        claimNFT = ClaimNFT(_claimAddr);
        // promoted = false;
        version = 0;
        nextEditId = 1;
        nextClaimId = 1;
        promoteTimelock = type(uint256).max;
        // readyforPromote = false;
        // archived = false;
        status = Status.Initial;
    }

    function getTopicMeta()
        external
        view
        returns (
            uint256,
            bytes32,
            address,
            Status
        )
    {
        return (id, digest, creator, status);
    }

    function joinTopic(Side side) onlyCluster() external {

        require(uint(status) < uint(Status.Promoted), "Already promoted");
        require(!isJoined[msg.sender], "Already joined");

        isJoined[msg.sender] = true;
        joinedClusters.push(msg.sender);
        whereSide[msg.sender] = side;
        sideActivated[side] = true;

        if (status == Status.ReadyForPromote ) {
            if (sideActivated[Side.CON] && sideActivated[Side.PRO]){
                status = Status.Promoted;
                _resetTimelock();
            }
            // readyforpromote = false 인데 activated가 모두 안되어있을 경우만 reset 안함
        } else {
            _resetTimelock();
        }         

        emit Joined(msg.sender);
    }


    function _resetTimelock() internal {

        promoteTimelock = block.timestamp + DELAY;

        emit TimelockDelay(promoteTimelock);

    }


    // 이 함수를 백엔드에서 계속 돌려줘야함
    function promoteTopic() external {
    
        require(status == Status.ReadyForPromote, "ReadyforPromote require");
        require(block.timestamp >= promoteTimelock);

        status = Status.Promoted;
        restAgreeToArchiveCount = JoinedCluster.length;
        emit TopicPromoted();
    }

    function proposeEdit(bytes32 newDigest) external onlyCluster() {

        require(uint(status) < uint(Status.Promoted), "Already promoted");

        uint256 eid = nextEditId++;

        edits[eid] = Edit({
            id:        eid,
            newDigest: newDigest,
            proposer:  msg.sender,
            approved:  false
        });

        editId2ClusterAddr2Agreed[eid][msg.sender] = true;

        emit EditProposed(eid, msg.sender);
    }

    function agreedEdit(uint256 eid) external onlyCluster() {

        require(uint(status) < uint(Status.Promoted), "Already promoted");
        require(!edits[eid].approved, "already approved");

        editId2ClusterAddr2Agreed[eid][msg.sender] = true;

        emit EditAgreed(eid, msg.sender);

        _approveEdit(eid);
    }

    function _approveEdit(uint256 eid) internal {

        for (uint256 i=0; i < joinedClusters.length; i++) {
            address cl = joinedClusters[i];
            if (editId2ClusterAddr2Agreed[eid][cl] == false) {
                return;
            }
        }

        // 모두 approved

        Edit storage e = edits[eid];
        e.approved = true;
        digest = e.newDigest;
        version = eid;

        _resetTimelock();

        emit EditApproved(eid);
    }

    function createClaim(
        uint256 parentClaimId, 
        bytes32 claimDigest, 
        address claimCreator, 
        address claimApprover, 
        ClaimType claimType
    ) external onlyCluster() {

        Side clusterSide = whereSide[msg.sender];

        //claimCreator가 다른 진영에 클레임을 생성한 적 있는지 검토
        if (whereSide[claimCreator] == Side.NONE) {
            whereSide[claimCreator] = clusterSide;
        } else {
            require(whereSide[claimCreator] == clusterSide, "creater's side is already locked");
        }

        // if type = opening : require promoted
        if (claimType == ClaimType.OPENING) {
            require (status == Status.Promoted, "only promoted status");
            require (parentClaimId == 0, "parent is 0 required");

        } else if (claimType == ClaimType.REBUT || claimType == ClaimType.INHERIT) {
            require (status == Status.InDiscussion, "only in discussion");

            // parent와 관계
            Claim memory c = claims[parentClaimId];
            if (claimType == ClaimType.INHERIT) {
                require(c.side == clusterSide);
            } else {
                // claimType == ClaimType.REBUT
                if (c.side == Side.PRO) {
                    require(clusterSide == Side.CON, "oposite side is required");
                } else if (c.side == Side.CON) {
                    require(clusterSide == Side.PRO, "oposite side is required");
                } else {
                  // c.side = side.none  
                }
            }

        } else {
            revert ("invalid claim type");
        }

        // id: 넥스트 클레임 아이디++
        // 클레임 스트럭트 생성
        // 아이디 -> 클레임 매핑에 집어넣기 (매핑 직접 만드시면 됩니다)
        // 이벤트 뱉어냄

        uint256 _claimId = nextClaimId++;

        // ai 아님

        claims[_cliamId] = Claim({
            claimId:       _claimId,
            creator:       claimCreator,
            digest:        claimDigest,
            side:          whereSide[msg.sender],
            claimType:     claimType,
            parentClaimId: parentClaimId,
            clusterId:     main.addressToClusterId(msg.sender),
            isIssued:      false
        });

        emit ClaimCreated(_claimId);
    }

    // 김지민님
    function modifyOpeningClaim(uint256 claimId, bytes32 newDigest) external onlyCluster() {

        require(status == Status.Promoted, "promoted required");
        Claim storage c = cliams[claimId];
        require(c.claimType == ClaimType.OPENING, "opening required");

        c.digest = newDigest;

        emit OpeningClaimModified(claimId);
    }

    // 김윤태님
    function agreeToArchive() external onlyCluster {
        // require InDiscussion
        require(status == Status.InDiscussion, "in discussion required");
        require(addr2archiveAgeed[msg.sender] == false, "already agreed");

        // restAgreeToArchiveCount = JoinedCluster.length로 constructor에 선언하기
        // restAgreeToArchiveCount를 1씩 감소시키기

        restAgreeToArchiveCount -= 1;

        if (restAgreeToArchiveCount == 0) {
            _archive();
        }

        emit AgreeArchive(msg.sender);
    }

    // 김윤태님
    function _archvie() internal {
        // staus = archived
        status = Status.Archived;
        side2digest[Side.PRO] = bytes32(0);
        side2digest[side.CON] = bytes32(0);

        // archive struct 생성
        // digest = bytes32(0)
        // side 값별로 매핑에 저장 
        // 이벤트 뱉어냄

        emit Archived();
    }

    // 김윤태님
    function EditArchive(bytes32 archiveDigest) external onlyCluster {
        // require archived true
        require(status == Status.Archived);

        side2digest[whereSide[msg.sender]] = archiveDigest;
    }

    // 이재민님
    function mintClaimNFT(
        uint256 claimId, 
        string calldata tokenURI_, 
        uint256 salePriceWei
    ) external {
        // claims에서 claim 꺼내기
        Claim storage c = claims[claimId];
        require(c.claimType != claimType.OPENING, "not opening required");
        // require isIssued false
        require(!c.isIssued, "already issuded");
        // require msg.sender = 크레이터
        require(c.creator == msg.sender);
        
        // claimNFT 포인터에서 mint 함수 꺼내서 인자 넣기
        claimNFT.mintClaimNFT(c.claimId, tokenURI_, salePriceWei);
        c.isIssued = true;
    }






    

    

    


}
