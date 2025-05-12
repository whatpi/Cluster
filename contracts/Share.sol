// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

enum ClaimType {INHERIT, REBUT}
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