// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./ClusterPass.sol"; 
import "../Share.sol";
import "../Topic/TopicLogic.sol";
import "../MainSystem.sol";
import "./ClusterPaymaster.sol";


contract ClusterSystem {
    /* ── 상수: 역할 ID ── */
    uint256 private constant ROLE_MEMBER    = 0;
    uint256 private constant ROLE_VERIFIED  = 1;
    uint256 private constant ROLE_MODERATOR = 2;

    /* ── 불변 변수 ── */
    uint256    public clusterId;
    address    public creator;
    address    public leader;
    address    public mainSystemAddr;
    MainSystem public main;
    address    public paymasterAddr;

    bytes32 public policyDigest;
    uint256 public deposit;
    uint256 public locked;

    mapping (address => bool) public isBlocked;
    

    event ClaimRequest(uint256 indexed topicId, bytes32 digest, address indexed claimCreator);
    event EditTopicRequest(uint256 indexed topicId, bytes32 digest, address indexed editor);

    // 기능별 컨트랙트
    ClusterPass public pass; 

    constructor(
        uint256 _clusterId,
        address _creator,
        address _mainSystemAddr,
        bytes32 _policyDigest,
        uint256 _deposit,
        address _paymasterAddr,
        ClusterPass _pass
    ) {
        clusterId = _clusterId;
        creator = _creator;
        leader = _creator;
        mainSystemAddr = _mainSystemAddr;
        main = MainSystem(mainSystemAddr);
        policyDigest = _policyDigest;
        deposit = _deposit;
        locked = 0;
        paymasterAddr = _paymasterAddr;
        pass = _pass;        
    }

    modifier onlyMain() {
        require(msg.sender == mainSystemAddr, "not main");
        _;
    }

    function InitializeCreator() external onlyMain() {
        _mintMember(creator);
        _mintVerified(creator);
        _mintModerator(creator);
    }
 

    /* ── 권한 확인 헬퍼 ── */
    function has(address user, uint256 role) public view returns (bool) {
        return pass.balanceOf(user, role) > 0;
    }

    function isMember(address user) public view returns (bool) {
        return has(user, ROLE_MEMBER);
    }
    
    function isVerified(address user) public view returns (bool) {
        return has(user, ROLE_VERIFIED);
    }
    
    function isModerator(address user) public view returns (bool) {
        return has(user, ROLE_MODERATOR);
    }

    function isLeader(address user) public view returns (bool) {
        return (user == leader);
    }

    /* ── 모디파이어 ── */
    modifier onlyMember()    { require(isMember(msg.sender),    "Not member");    _; }
    modifier onlyVerified()  { require(isVerified(msg.sender),  "Not verified");  _; }
    modifier onlyModerator() { require(isModerator(msg.sender), "Not moderator"); _; }
    modifier onlyLeader()   { require(isLeader(msg.sender),    "Not leader");   _; }
    

    /* ── NFT 발급·회수 ── */
    function _mintMember(address to)       internal { pass.mint(to, ROLE_MEMBER,    1, ""); }
    function _burnMember(address from)     internal { pass.burn(from, ROLE_MEMBER,  1);     }

    function _mintVerified(address to)     internal { pass.mint(to, ROLE_VERIFIED,  1, ""); }
    function _burnVerified(address from)   internal { pass.burn(from, ROLE_VERIFIED, 1);     }

    function _mintModerator(address to)    internal { pass.mint(to, ROLE_MODERATOR, 1, ""); }
    function _burnModerator(address from)  internal { pass.burn(from, ROLE_MODERATOR, 1);    }

    function join() external{

        require(!isMember(msg.sender), "Already Member");
        require(!isBlocked[msg.sender], "Blocked");

        _mintMember(msg.sender);
    }

    function mintVerified(address to) external onlyModerator() {
        require(!isBlocked[to], "Blocked");
        require(!isVerified(to), "Already Verified");
        require(isMember(to), "Not Member");

        _mintVerified(to);
    }

    function mintModerator(address to) external onlyLeader() {
        require(!isBlocked[to], "Blocked");
        require(!isModerator(to), "Already Moderator");
        require(isVerified(to), "Not Verified");

        _mintModerator(to);
    }

    function blockMemberOrVerified(address user) external onlyModerator {
        require(!isModerator(user), "not Moderator");
        require(!isBlocked[user], "Already Blocked");

        if (isMember(user)) {
            _burnMember(user);
        }

        if (isVerified(user)) {
            _burnVerified(user);
        }

        isBlocked[user] = true;
    }

    function unblock(address user) external onlyModerator {

        require(isBlocked[user], "Not Blocked");
        // 의결에 의해 추방을 만든다면 추방 취소는 다시 의결로만 가능하게 만들어야 할듯
        // 추방은 의결로는 불가능하고 권한 박탈용으로만?

        isBlocked[user] = false;
    }

    modifier onlyPaymaster() {
        require(msg.sender == paymasterAddr, "not paymaster");
        _;
    }

    // function deductGas(uint256 actualGasCost) external onlyPaymaster() {
    //     require(deposit > actualGasCost, "deposit not enough");
    //     deposit = deposit - actualGasCost;
    // }

    function reserveGas(
        uint256 amount
    ) external onlyPaymaster 
    {
        uint256 avail = deposit - locked;
        require(avail >= amount, "avail not enough");
        locked += amount;
    }

    function finalizeGas(
        uint256 reserved,
        uint256 actualGasCost
    ) external onlyPaymaster 
    {
        require(locked >= reserved, "over-release");
        locked -= reserved;
        require(deposit >= actualGasCost, "insufficient deposit");
        deposit -= actualGasCost;
    }

    
    // 의결 생성

    // 투표

    // 의결 타임럭 생성

    // 타임럭에 의존하는 함수들

    // function topicjoin

    // function tanhaek

    // paymaster

    function _editTopic(uint256 topicId, bytes32 digest) internal {
        TopicLogic proxy = TopicLogic(main.topicIdToAddrs(topicId));
        proxy.proposeEdit(digest);
    }

    function editTopic(
        uint256 topicId, 
        bytes32 digest
    ) external onlyMember {
        if(isModerator(msg.sender)) {
            _editTopic(topicId, digest);
        } else {
            emit EditTopicRequest(topicId, digest, msg.sender);
        }
    }

    function approveMemberEditingTopic(
        uint256 topicId, 
        bytes32 digest
    ) external onlyVerified {
        _editTopic(topicId, digest);
    }

    function agreedEditingTopic(
        uint256 topicId, 
        uint256 eid
    ) external onlyModerator {
        TopicLogic proxy = TopicLogic(main.topicIdToAddrs(topicId));
        proxy.agreedEdit(eid);
    }
    
    function _createClaim(
        uint256 topicId, 
        bytes32 digest, 
        address claimCreator, 
        address approver, 
        ClaimType claimType
    ) internal {
        TopicLogic proxy = TopicLogic(main.topicIdToAddrs(topicId));
        proxy.createClaim(digest, claimCreator, approver, claimType);
    }

    function createClaim(
        uint256 topicId, 
        bytes32 digest, 
        ClaimType claimType
    ) external onlyMember {
        if(isVerified(msg.sender)) {
            _createClaim(topicId, digest, msg.sender, msg.sender, claimType);
        } else {
            emit ClaimRequest(topicId, digest, msg.sender);
        }
    }

    function approveClaim(
        uint256 topicId, 
        bytes32 digest, 
        address claimCreator, 
        ClaimType claimType
    ) external onlyVerified {
        _createClaim(topicId, digest, claimCreator, msg.sender, claimType);
    }

    // _modify

    // modify  // emit modifyingrequest

    // approvemodify

    




}