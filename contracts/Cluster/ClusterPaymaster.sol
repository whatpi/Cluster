// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "./ClusterSystem.sol";
import "../MainSystem.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/UserOperationLib.sol";

interface IClusterAccount {
    function execute(address target, bytes calldata innerData) external;
}


contract ClusterPaymaster is BasePaymaster {

    /// 일단 이거 왜 안되는 거?? 계속 빨간줄

    ClusterSystem public cluster;
    // address public clusterAddr;
    MainSystem public main;

    constructor (
        address entryPointAddr
    ) 
        BasePaymaster(IEntryPoint(entryPointAddr))
    {
        main = MainSystem(msg.sender);
    }

    function initialize(address _clusterAddr) external onlyOwner() {
        cluster = ClusterSystem(_clusterAddr);
    }

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32,
        uint256                      maxCost
    ) 
      internal 
      override 
      returns(bytes memory context, uint256 validationData) 
    {
        // cluster 확인
        address requestClusterAddr = abi.decode(userOp.paymasterAndData[20:], (address));
        require(requestClusterAddr == address(cluster), "your address is not for this paymaster");
        
        // 클러스터 가입자인지
        require(cluster.has(msg.sender, 0), "not member");

        // callData = selector(4) + targetAddr(32) + dataOffset(32) 
        // excute 인지
        bytes4 execSelector = bytes4(userOp.callData[:4]);
        require(execSelector == IClusterAccount.execute.selector, "invalid exec");

        // target == 클러스터 주소인지
        address target = abi.decode(userOp.callData[4:36], (address));  
        require(target == address(cluster), "target mismatch");

        // 예치금 확인
        cluster.reserveGas(maxCost);

        return (abi.encode(address(cluster), maxCost), 0);
    }

    function _postOp(
        PostOpMode, 
        bytes calldata context, // 인코딩된 데이터
        uint256 actualGasCost, // actualGasCost = gasUsed * effectiveGasPrice 프론트엔드에서 계산
        uint256
        // override 도 안되는 상황............. 왜?
    ) 
    internal override
    {
        (address clusterAddr, uint256 maxCost) = abi.decode(context, (address,uint256));

        require(clusterAddr == address(cluster), "your address is not for this paymaster");

        // 차감 및 락 풀기
        cluster.finalizeGas(maxCost, actualGasCost);

        // (환급 로직 불필요: 배포 때부터 정확하게 예치하므로 최대 한도만 잠그고, 실제만 차감)
    }
}