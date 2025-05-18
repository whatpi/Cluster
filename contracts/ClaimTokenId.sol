// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library ClaimTokenId {
    uint256 private constant OFFSET = 128;

    function pack(uint256 topicId, uint256 claimId)
        internal
        pure
        returns (uint256 tokenId)
    {
        require(topicId < (1 << OFFSET), "topicId overflow");
        require(claimId < (1 << OFFSET), "claimId overflow");
        return (topicId << OFFSET) | claimId;
    }

    function unpack(uint256 tokenId)
        internal
        pure
        returns (uint256 topicId, uint256 claimId)
    {
        topicId = tokenId >> OFFSET;
        claimId = tokenId & ((1 << OFFSET) - 1);
    }
}


