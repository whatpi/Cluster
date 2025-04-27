// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./interfaces/IClusterPass.sol"; 
import "./Share.sol" as S;


contract ClusterSystem {
    /* ── 상수: 역할 ID ── */
    uint256 private constant ROLE_MEMBER    = 0;
    uint256 private constant ROLE_VERIFIED  = 1;
    uint256 private constant ROLE_MODERATOR = 2;

    /* ── 불변 변수 ── */
    uint256 public immutable clusterId;
    S.Side  public immutable side;
    address public immutable creator;
    uint256 public immutable parentTopicId;
    address public immutable mainSystemAddr;
    IClusterPass public immutable passContract; 

    bytes32 public policyDigest;
    bytes32 public openingClaimDigest;
    uint256 public deposit;

    constructor(
        uint256 _clusterId,
        S.Side _side,
        address _creator,
        uint256 _parentTopicId,
        address _mainSystemAddr,
        address _passContractAddr,
        bytes32 _policyDigest,
        bytes32 _openingClaimDigest,
        uint256 _deposit
    ) {
        clusterId = _clusterId;
        side = _side;
        creator = _creator;
        parentTopicId = _parentTopicId;
        policyDigest = _policyDigest;
        deposit = _deposit;
        openingClaimDigest = _openingClaimDigest;
        passContract = IClusterPass(_passContractAddr);
        mainSystemAddr = _mainSystemAddr;
    }
 

    /* ── 권한 확인 헬퍼 ── */
    function _has(address user, uint256 role) internal view returns (bool) {
        return passContract.balanceOf(user, role) > 0;
    }

    /* ── 모디파이어 ── */
    modifier onlyMember()    { require(_has(msg.sender, ROLE_MEMBER),    "Not member");    _; }
    modifier onlyVerified()  { require(_has(msg.sender, ROLE_VERIFIED),  "Not verified");  _; }
    modifier onlyModerator() { require(_has(msg.sender, ROLE_MODERATOR), "Not moderator"); _; }
    modifier onlyCreator()   { require(msg.sender == creator,           "Not creator");   _; }
    

    /* ── NFT 발급·회수 ── */
    function mintMember(address to)       external onlyModerator { passContract.mint(to, ROLE_MEMBER,    1, ""); }
    function burnMember(address from)     external onlyModerator { passContract.burn(from, ROLE_MEMBER,  1);     }

    function mintVerified(address to)     external onlyModerator { passContract.mint(to, ROLE_VERIFIED,  1, ""); }
    function burnVerified(address from)   external onlyModerator { passContract.burn(from, ROLE_VERIFIED, 1);     }

    function mintModerator(address to)    external onlyCreator  { passContract.mint(to, ROLE_MODERATOR, 1, ""); }
    function burnModerator(address from)  external onlyCreator  { passContract.burn(from, ROLE_MODERATOR, 1);    }

    // 1. 클러스터 메인 문서 편집 요청
    // require 멤버
    // 중재자거나 verified면 바로 수정 함수 실행행
    // 

    // 2. 클러스터 메인 문서 승인
    // 중재자가 증인인

    // 3. 클러스터 메인 문서 수정
    // digest 값 바꿈

    // 1. 클레임 생성 요청
    // require 멤버
    // require 같은 토픽픽 아이디 
    // 중재자거나 verified면 바로 생성 함수 실행

    // 2. 클레임 생성 승인
    // 중재만 가능

    // 3. 클레임 생성
    // 메인으로 넘기기 

    // 1. 클레임 nft화 : 클러스터당 하나씩 클레임 nft 파일을 만들기기
 
    // 2. 클레임 nft 구매

}