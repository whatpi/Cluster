// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../Mainsystem.sol";
import "./ClusterPass.sol";
import "./ClusterPaymaster.sol";
import "@account-abstraction/contracts/core/EntryPoint.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";



contract ClusterFactory is Ownable{

    MainSystem public main;
    EntryPoint public entryPoint;
    UpgradeableBeacon public beacon;

    event ImplementationUpgraded(uint256 indexed implementation);


    constructor(
        address mainAddr,
        address entryPointAddr,
        address beaconAddr
    ) 
    {
        main = MainSystem(mainAddr);
        entryPoint = EntryPoint(entryPointAddr);
        beacon = UpgradeableBeacon(beaconAddr);
    }

    function createCluster(
        uint256 _id,
        address _creator,
        // address _paymasterAddr,
        // address _passAddr,
        bytes32 _policyDigest
        // uint256 _deposit
    ) 
    external payable returns (address proxyAddr) 
    {
        ClusterPass pass = new ClusterPass("");
        ClusterPaymaster paymaster = new ClusterPaymaster(address(entryPoint), address(main));

        uint256 _deposit = msg.value;

        bytes memory initData = abi.encodeWithSelector(
            ClusterSystem.initialize.selector,
            _id, // clusterId는 1부터
            _creator,
            address(main),  // mainSystemAddr
            _policyDigest,
            _deposit,
            address(paymaster),
            address(pass)
        );

        proxyAddr = address(new BeaconProxy(
            address(beacon),
            initData
        ));

        // // ClusterSystem 배포
        // ClusterSystem cluster = new ClusterSystem(
        //     _id, // clusterId는 1부터
        //     _creator,
        //     address(main),  // mainSystemAddr
        //     _policyDigest,
        //     _deposit,
        //     address(paymaster),
        //     address(pass)
        // );

        ClusterSystem cluster = ClusterSystem(proxyAddr);

        pass.transferOwnership(proxyAddr);

        cluster.InitializeCreator();

        paymaster.initialize(proxyAddr);
        entryPoint.depositTo{value: msg.value}(address(paymaster));

        return proxyAddr;
    }

    function upgradeImplementation(address newImplementation) external onlyOwner() {
        beacon.upgradeTo(newImplementation);
        emit ImplementationUpgraded(newImplementation);
    }

}