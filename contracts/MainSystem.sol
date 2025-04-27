// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./ClusterSystem.sol";
import "./TopicBoard.sol";
import "./ClusterPass.sol";


contract MainSystem {    

    uint256 public nextClusterId;

    mapping(uint256 => address[]) public topicId2Clusters;
    mapping(uint256 => address) public clusterIdToAddress;
    mapping(address => uint256) public addressToClusterId;

    event ClusterCreated(address clusterAddress, address indexed user, uint256 parentTopicId);

    struct Topic {
        uint256 topicId;
        address creator;
        bytes32 digest;
        bool allowNone;
    }

    TopicBoard public immutable board;

    /* -------------------- 초기화 -------------------- */
    constructor(address boardAddress) {
        require(boardAddress != address(0), "zero address");
        board = TopicBoard(boardAddress);
    }

    // 토픽 생성

    // -----------------------------------------------------------

    /* -------------------- 래핑 함수 -------------------- */

    /** 1) 초안 토픽 생성 */
    function createDraft(bytes32 digest, bool allowNone) external {
        board.createDraftTopic(digest, allowNone);
    }

    /** 2) 토픽 지지 */
    function support(uint256 topicId) external {
        board.supportTopic(topicId);
    }

    /** 3) 토픽 수정 제안 */
    function proposeEdit(
        uint256 topicId,
        bytes32 newDigest
    ) external {
        board.proposeEditTopic(topicId, newDigest);
    }

    /** 4) 수정 승인(토픽 작성자 전용) */
    function approveEdit(uint256 editId) external {
        board.approveEdit(editId);
    }

    /** 5) 메타데이터 조회 */
    function getTopic(
        uint256 topicId
    )
        external
        view
        returns (
            bytes32 digest,
            address creator,
            uint256 supporterCount,
            bool allowNone,
            TopicBoard.Status status
        )
    {
        return board.getTopicMeta(topicId);
    }



    // 클러스터 생성
    function createCluster(
        uint256 _parentTopicId,
        S.Side _side,
        uint256 _deposit,
        bytes32 _policyDigest,
        bytes32 _openingClaimDigest
    ) external payable returns (address) {
        // --------------

        // deposit require

        // ---------------
        
        // allowNone or ~isNone require

        // ---------------

        /* 2. ClusterPass(ERC-1155) 새 배포 */
        ClusterPass pass = new ClusterPass("");


        /* 3. ClusterSystem 새 배포 */
        ClusterSystem cluster = new ClusterSystem(
            nextClusterId,
            _side,
            msg.sender,
            _parentTopicId,
            address(this),  // mainSystemAddr
            address(pass), 
            _policyDigest,
            _openingClaimDigest,
            _deposit
        );

        address clusterAddr = address(cluster);

        /* 4. 소유권 이전: pass → cluster */
        pass.transferOwnership(clusterAddr);

        /* 5. 매핑·이벤트 처리 */
        topicId2Clusters[_parentTopicId].push(clusterAddr);
        clusterIdToAddress[nextClusterId] = address(cluster);
        addressToClusterId[address(cluster)] = nextClusterId;
        nextClusterId++;

        emit ClusterCreated(clusterAddr, msg.sender, _parentTopicId);

        return clusterAddr;
    }
}
