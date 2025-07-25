// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./TopicLogic.sol";
import "../Share.sol";

contract TopicFactory is Ownable{
    address public impl;            // TopicLogic 구현 주소
    address public mainAddr;           // main 주소
    address public claimAddr;
    UpgradeableBeacon public beacon;

    mapping(uint256 => address) public topicAddr;  // id → proxyAddr

    event TopicCreated(uint256 indexed id, address proxyAddr);
    event ImplementationUpgraded(address newImpl);

    constructor(address _mainAddr, address _claimAddr) {
        impl  = address(new TopicLogic());    // 1회 배포
        beacon = new UpgradeableBeacon(impl, address(this));

        mainAddr = _mainAddr;
        claimAddr = _claimAddr;
    }

    // 의존성 주입구 열어놓기

    function setMainSystem(address _mainAddr) external onlyOwner() {
        require(msg.sender == mainAddr, "only main");
        mainAddr = _mainAddr;
    }

    function setClaimNFT(address _claimAddr) external onlyOwner() {
        require(msg.sender == mainAddr, "only main");
        claimAddr = _claimAddr;
    }

    function createTopic(
        uint256 id,
        bytes32 digest,
        address creator
    ) external returns (address proxyAddr) {
        require(topicAddr[id] == address(0), "id used");

        // 이니셜라이즈 명령의 인코딩 데이터
        bytes memory initData = abi.encodeWithSelector(
            TopicLogic.initialize.selector,
            id,
            digest,
            creator,
            mainAddr,
            claimAddr
        );


        proxyAddr = address(new BeaconProxy(
            address(beacon),
            initData
        ));
                
        emit TopicCreated(id, proxyAddr);
    }

    function upgradeImplementation(address newImplementation) external onlyOwner() {
        beacon.upgradeTo(newImplementation);
        emit ImplementationUpgraded(newImplementation);
    }

    

}
