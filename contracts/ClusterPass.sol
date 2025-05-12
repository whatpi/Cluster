// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Non-Transferable ERC-1155 (Soul-Bound)
contract ClusterPass is ERC1155, Ownable {
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    /* ---------- 관리자용 발행·소각 ---------- */
    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        external
        onlyOwner
    {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount)
        external
        onlyOwner
    {
        _burn(from, id, amount);
    }

    /* ---------- 전송·승인 차단 ---------- */
    function setApprovalForAll(address, bool) public pure override {
        revert("Soulbound: approvals disabled");
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        // 민트·번이 아닌 일반 전송(from ≠ 0 && to ≠ 0) 차단
        if (from != address(0) && to != address(0)) {
            revert("SBT: non-transferable");
        }
        super._update(from, to, ids, values);   // 상태 갱신 유지
    }


}
