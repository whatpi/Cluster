// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TopicBoard {
    uint256 public constant SUPPORT_THRESHOLD = 10;

    enum Status { DRAFT, FINAL }

    struct Topic {
        uint256 id;
        bytes32 digest;
        address creator;
        uint256 supporterCount;
        bool    allowNone;
        Status  status;
        mapping(address => bool) supporters;
    }

    struct EditProposal {
        uint256 id;
        uint256 topicId;
        bytes32 newDigest;
        address proposer;
        bool    approved;
    }

    uint256 private _nextTopicId;
    uint256 private _nextEditId;

    mapping(uint256 => Topic)        private _topics;
    mapping(uint256 => EditProposal) private _edits;

    event DraftCreated(uint256 indexed id, address indexed creator);
    event TopicSupported(uint256 indexed id, address indexed supporter);
    event EditProposed(uint256 indexed editId, uint256 indexed topicId, address proposer);
    event TopicPromoted(uint256 indexed id);

    /* 조회 헬퍼 */
    function getTopicMeta(uint256 id)
        external
        view
        returns (
            bytes32 digest,
            address creator,
            uint256 supporterCount,
            bool allowNone,
            Status status
        )
    {
        Topic storage t = _topics[id];
        return (t.digest, t.creator, t.supporterCount, t.allowNone, t.status);
    }
    /* ─────────── 1. 초안 생성 ─────────── */
    function createDraftTopic(bytes32 digest, bool allowNone) external {
        uint256 id = _nextTopicId++;
        Topic storage t = _topics[id];
        t.id = id;
        t.digest   = digest;
        t.creator  = msg.sender;
        t.allowNone = allowNone;
        t.status   = Status.DRAFT;

        emit DraftCreated(id, msg.sender);
    }

    /* 내부 헬퍼: 주소를 인자로 받아 지지 + 이벤트 */
    function _addSupport(
        Topic storage t,
        uint256 topicId,
        address supporter
    ) internal {
        require(!t.supporters[supporter], "already supported");

        t.supporters[supporter] = true;
        t.supporterCount += 1;
        emit TopicSupported(topicId, supporter);

        _promoteIfReady(t);   // 지지 직후 승격 검사
    }


    /* 2. 토픽 지지 */
    function supportTopic(uint256 id) external {
        Topic storage t = _topics[id];
        require(t.status == Status.DRAFT, "final");
        _addSupport(t, id, msg.sender);
    }


    /* ─────────── 3. 수정 제안 ─────────── */
    function proposeEditTopic(uint256 id, bytes32 newDigest) external {
        Topic storage t = _topics[id];
        require(t.status == Status.DRAFT, "final");

        uint256 eid = _nextEditId++;
        _edits[eid] = EditProposal({
            id:        eid,
            topicId:   id,
            newDigest: newDigest,
            proposer:  msg.sender,
            approved:  false
        });

        emit EditProposed(eid, id, msg.sender);
    }

    /* ─────────── 4~6. 수정 승인 및 자동 지지 ─────────── */
    function approveEdit(uint256 editId) external {
        EditProposal storage e = _edits[editId];
        Topic storage t = _topics[e.topicId];

        require(msg.sender == t.creator, "not creator");
        require(!e.approved, "done");
        require(t.status == Status.DRAFT, "final");

        t.digest = e.newDigest;
        e.approved = true;

        // 수정 제안자 자동 지지
        _addSupport(t, e.topicId, e.proposer);
    }

    /* ─────────── 내부 함수 ─────────── */
    function _promoteIfReady(Topic storage t) private {
        if (t.supporterCount >= SUPPORT_THRESHOLD) {
            t.status = Status.FINAL;
            // TopicPromoted 이벤트 등을 원하면면 추가

            emit TopicPromoted(t.id);
        }
    }
}
