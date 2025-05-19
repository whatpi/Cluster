// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./Cluster/ClusterSystem.sol";
import "./Topic/TopicFactory.sol";
import "./ClaimNFT.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "./Cluster/ClusterPass.sol";
import "./Cluster/ClusterPaymaster.sol";


// claimNFT, 토픽 팩토리 adress(0)로 배포
// 메인 시스템 컨스턱터에 주소 넣기
// claimNft, 토픽팩토리에 메인 시스템 주소 넣기

contract MainSystem {    

    uint256 public nextClusterId;
    uint256 public nextTopicId;

    TopicFactory public topicFactory;
    address      public topicFactoryAddr;
    IEntryPoint  public entryPoint;
    address      public entryPointAddr;

    // mapping(uint256 => address[]) public topicId2Clusters;
    mapping(uint256 => address) public clusterIdToAddrs;
    mapping(address => uint256) public addressToClusterId;
    mapping(uint256 => address) public topicIdToAddrs;
    mapping(address => uint256) public addressToTopicId;

    event TopicCreated(uint256 id, address proxyAddr);
    event ClusterCreated(uint256 id, address clusterAddress, address indexed user);

    constructor(
        address _topicFactoryAddr,
        address _entryPointAddr
    ) 
    {
        // claimNFT = new ClaimNFT("","",address(this));
        // topicFactory = new TopicFactory(address(this), claimNFTAddr);
        topicFactory = TopicFactory(_topicFactoryAddr);
        nextClusterId = 1; // 클러스터 아이디는 1부터 시작합니다
        nextTopicId = 1; // 1부터 하는 이유는 그게 토픽이 아니면 0을 뱉어낼 거기 떄문에..
        entryPoint = IEntryPoint(_entryPointAddr);
        entryPointAddr = _entryPointAddr;
    }

    // 클러스터 생성
    function createCluster(
        bytes32 _policyDigest
    ) external payable returns (address clusterAddr) {
        // --------------

        // deposit require
        require(msg.value >= 0.0027 ether, "Minimum is 0.0027 ETH");

        uint256 _deposit = msg.value;
        
        ClusterPass _pass = new ClusterPass("");
        ClusterPaymaster paymaster = new ClusterPaymaster(entryPointAddr);


        /* 3. ClusterSystem 새 배포 */
        ClusterSystem cluster = new ClusterSystem(
            nextClusterId, // clusterId는 1부터
            msg.sender,
            address(this),  // mainSystemAddr
            _policyDigest,
            _deposit,
            address(paymaster),
            _pass
        );

        clusterAddr = address(cluster);

        _pass.transferOwnership(clusterAddr);

        cluster.InitializeCreator();

        paymaster.initialize(clusterAddr);
        entryPoint.depositTo{value: msg.value}(address(paymaster));

        clusterIdToAddrs[nextClusterId] = address(cluster);
        addressToClusterId[address(cluster)] = nextClusterId;

        emit ClusterCreated(nextClusterId, clusterAddr, msg.sender);

        nextClusterId++;

        return clusterAddr;
    }

    function createTopic(bytes32 digest) external returns (address proxyAddr)  {

        // only timelock

        proxyAddr = topicFactory.createTopic(nextTopicId, digest, msg.sender);
        topicIdToAddrs[nextTopicId] = proxyAddr;
        addressToTopicId[proxyAddr] = nextTopicId;

        // event
        emit TopicCreated(nextTopicId, proxyAddr);

        nextTopicId++;

        return proxyAddr;
    }






}
