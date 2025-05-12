// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ClaimTokenId.sol";
import "./MainSystem.sol";

contract ClaimNFT is ERC721URIStorage, ReentrancyGuard {

    using ClaimTokenId for uint256;
    MainSystem private main;

    // (topicId, claimId) -> 존재 여부
    mapping(uint256 => bool) private _issued;

    constructor(string memory name_, string memory symbol_, address mainAddr_)
        ERC721(name_, symbol_) {
            main = MainSystem(mainAddr_);
        }
    
    modifier onlyTopic() {
        require(main.addressToTopicId(msg.sender) != 0, "Not Topic");
        _;
    }
    


    /// @notice Topic-ID·Claim-ID 조합으로 NFT 발행
    /// @param topicId 토픽 식별자 (0 ~ 2¹²⁸-1)
    /// @param claimId 클레임 식별자 (0 ~ 2¹²⁸-1)
    /// @param tokenURI_ 메타데이터 URI
    /// @param salePriceWei 0이면 즉시 판매 미등록
    function mint(
        uint256 topicId,
        uint256 claimId,
        string calldata tokenURI_,
        uint256 salePriceWei
    ) external onlyTopic returns (uint256 tokenId) {
        tokenId = ClaimTokenId.pack(topicId, claimId);
        require(!_issued[tokenId], "already minted");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _issued[tokenId] = true;

        if (salePriceWei > 0) price[tokenId] = salePriceWei;
    }

    mapping(uint256 => uint256) public price;

    /// @notice 소유자·승인자가 토큰 가격 변경
    function setPrice(uint256 tokenId, uint256 salePriceWei) external {
        address owner = ownerOf(tokenId);               // 토큰의 실제 소유자
        _checkAuthorized(owner, msg.sender, tokenId);          // 권한 검증 (v5 방식)
        price[tokenId] = salePriceWei;
    }

    /// @notice 구매 함수
    function purchase(uint256 tokenId) external payable nonReentrant {
        uint256 salePrice = price[tokenId];
        require(salePrice > 0, "Not for sale");
        require(msg.value >= salePrice, "Underpaid");

        address seller = ownerOf(tokenId);
        _transfer(seller, msg.sender, tokenId);  // 내부에서 인증 로직 포함
        delete price[tokenId];

        (bool ok,) = payable(seller).call{value: salePrice}("");
        require(ok, "Payment failed");

        if (msg.value > salePrice) {
            (bool refund,) =
                payable(msg.sender).call{value: msg.value - salePrice}("");
            require(refund, "Refund failed");
        }
    }
}
