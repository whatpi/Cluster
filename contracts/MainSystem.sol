// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./ClusterSystem.sol";
import "./Topic/TopicFactory.sol";
import "./ClusterPass.sol";
import "./ClaimNFT.sol";


contract MainSystem {    

    uint256 public nextClusterId;
    uint256 public nextTopicId;

    TopicFactory public immutable topicFactory;
    address public immutable topicFactoryAddr;
    ClaimNFT public immutable claimNFT;
    address public immutable claimNFTAddr;

    // mapping(uint256 => address[]) public topicId2Clusters;
    mapping(uint256 => address) public clusterIdToAddrs;
    mapping(address => uint256) public addressToClusterId;
    mapping(uint256 => address) public topicIdToAddrs;
    mapping(address => uint256) public addressToTopicId;

    event TopicCreated(uint256 id, address proxyAddr);
    event ClusterCreated(uint256 id, address clusterAddress, address indexed user);

    constructor() {
        claimNFT = new ClaimNFT("","",address(this));
        claimNFTAddr = address(claimNFT);
        topicFactory = new TopicFactory(address(this), claimNFTAddr);        
        nextClusterId = 1; // 클러스터 아이디는 1부터 시작합니다
        nextTopicId = 1; // 1부터 하는 이유는 그게 토픽이 아니면 0을 뱉어낼 거기 떄문에..
    }

    // 클러스터 생성
    function createCluster(
        uint256 _deposit,
        bytes32 _policyDigest
    ) external payable returns (address clusterAddr) {
        // --------------

        // deposit require
        require(msg.value >= 0.1 ether, "Minimum is 0.1 ETH");


        /* 3. ClusterSystem 새 배포 */
        ClusterSystem cluster = new ClusterSystem(
            nextClusterId, // clusterId는 1부터
            msg.sender,
            address(this),  // mainSystemAddr
            _policyDigest,
            _deposit
        );

        clusterAddr = address(cluster);


        /* 5. 매핑·이벤트 처리 */
        // topicId2Clusters[_parentTopicId].push(clusterAddr);
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
