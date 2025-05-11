// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./ClusterPass.sol"; 
import "./Share.sol";


contract ClusterSystem {
    /* ── 상수: 역할 ID ── */
    uint256 private constant ROLE_MEMBER    = 0;
    uint256 private constant ROLE_VERIFIED  = 1;
    uint256 private constant ROLE_MODERATOR = 2;

    /* ── 불변 변수 ── */
    uint256 public immutable clusterId;
    address public immutable creator;
    address public immutable mainSystemAddr;

    bytes32 public policyDigest;
    bytes32 public openingClaimDigest;
    uint256 public deposit;

    // 기능별 컨트랙트
    ClusterPass public immutable passContract; 

    constructor(
        uint256 _clusterId,
        address _creator,
        address _mainSystemAddr,
        bytes32 _policyDigest,
        uint256 _deposit
    ) {
        clusterId = _clusterId;
        creator = _creator;
        mainSystemAddr = _mainSystemAddr;
        policyDigest = _policyDigest;
        deposit = _deposit;

        ClusterPass passContract = new ClusterPass("");
        /* 4. 소유권 이전: pass → cluster */
        passContract.transferOwnership(address(this));

    }
 

    /* ── 권한 확인 헬퍼 ── */
    function has(address user, uint256 role) external view returns (bool) {
        return passContract.balanceOf(user, role) > 0;
    }

    /* ── 모디파이어 ── */
    modifier onlyMember()    { require(this.has(msg.sender, ROLE_MEMBER),    "Not member");    _; }
    modifier onlyVerified()  { require(this.has(msg.sender, ROLE_VERIFIED),  "Not verified");  _; }
    modifier onlyModerator() { require(this.has(msg.sender, ROLE_MODERATOR), "Not moderator"); _; }
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