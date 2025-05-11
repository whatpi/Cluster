// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./ClusterSystem.sol";
import "./Topic/TopicFactory.sol";
import "./ClusterPass.sol";


contract MainSystem {    

    uint256 public nextClusterId;
    uint256 public nextTopicId;

    TopicFactory public immutable topicFactory;
    address public immutable topicFactoryAddress;

    // mapping(uint256 => address[]) public topicId2Clusters;
    mapping(uint256 => address) public clusterIdToAddrs;
    mapping(address => uint256) public addressToClusterId;
    mapping(uint256 => address) public topicIdToAddrs;

    event TopicCreated(uint256 id, address proxyAddr);
    event ClusterCreated(uint256 id, address clusterAddress, address indexed user);

    constructor() {
        topicFactory = new TopicFactory(address(this));        
        nextClusterId = 1; // 클러스터 아이디는 1부터 시작합니다
        nextTopicId = 0;
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

        // event
        emit TopicCreated(nextTopicId, proxyAddr);

        nextTopicId++;

        return proxyAddr;
    }






}
