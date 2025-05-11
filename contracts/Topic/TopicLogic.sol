// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Share.sol";
import "../MainSystem.sol";

contract TopicLogic is Initializable {

    struct Edit {
        uint256 id;
        bytes32 newDigest;
        address proposer;
        bool    approved;
    }

    uint256    public id;
    uint256    public nextEditId;
    address    public creator;
    address    public mainAddr;
    MainSystem public main;
    bool       public promoted;
    bytes32    public digest;
    uint256    public version;
    uint256    public promoteTimelock;
    uint256    public constant DELAY = 1800;
    bool       public readyforPromote;


    mapping (address => bool) public isJoined;
    mapping (address => Side) public whereSide;
    address[]                 public joinedClusters;
    mapping (Side => bool)    public sideActivated;
    mapping (uint256 => Edit) public edits;
    mapping (uint256 => mapping (address => bool)) public editId2ClusterAddr2Agreed;

    event Joined(address indexed joiner);
    event TopicPromoted();
    event EditProposed(uint256 indexed editId, address indexed proposer);
    event EditAgreed(uint256 indexed editId, address indexed approver);
    event EditApproved(uint256 indexed editId);
    event TimelockDelay(uint256 Timelock);

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
        address _mainAddr
    ) external initializer {
        id = _id;
        digest  = _digest;
        creator = _creator;
        mainAddr   = _mainAddr;
        main = MainSystem(_mainAddr);
        promoted = false;
        version = 0;
        nextEditId = 1;
        promoteTimelock = type(uint256).max;
        readyforPromote = false;
    }

    function getTopicMeta()
        external
        view
        returns (
            uint256,
            bytes32,
            address,
            bool
        )
    {
        return (id, digest, creator, promoted);
    }

    function joinTopic(Side side) onlyCluster() external {

        require(!promoted, "Already promoted");
        require(!isJoined[msg.sender], "Already joined");

        isJoined[msg.sender] = true;
        joinedClusters.push(msg.sender);
        whereSide[msg.sender] = side;
        sideActivated[side] = true;

        if (!readyforPromote ) {
            if (sideActivated[Side.CON] && sideActivated[Side.PRO]){
                readyforPromote = true;
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
    
        require(!promoted, "already promoted");
        require(readyforPromote, "Not Side Activated");
        require(block.timestamp >= promoteTimelock);

        promoted = true;
        emit TopicPromoted();
    }

    function proposeEdit(bytes32 newDigest) external onlyCluster() {

        require(!promoted, "already promoted");

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

        require(!promoted, "already promoted");
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
}
