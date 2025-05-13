// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

enum ClaimType {OPENING, INHERIT, REBUT}
enum Side {NONE, PRO, CON}
enum CreatorType {USER, CLUSTER}
struct Claim {
    uint256 claimId;
    address creator;
    bytes32 digest;
    Side side;
    ClaimType claimType;
    uint256 parentClaimId;
    uint256 clusterId;
    bool isIssued;
}

enum Status {
    Initial,          // 0: 생성 직후
    ReadyForPromote,  // 1: 승격(프로모트) 요건 충족·타임락 대기
    Promoted,         // 2: 개시 주장(Opening) 확정
    InDiscussion,     // 3: 토론 진행 중
    Archived          // 4: 종료·보관
}
