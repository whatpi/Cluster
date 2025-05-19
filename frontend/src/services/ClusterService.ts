// import { ethers } from "ethers";
// import {
//   keccak256,
//   defaultAbiCoder,
//   arrayify,
//   hexConcat
// } from "ethers/lib/utils";
// import { EntryPoint__factory } from "@account-abstraction/contracts";
// import ClusterAccountAbi from "../../../artifacts/contracts/ClusterSystem.sol/ClusterSystem.json";
// import BundlerClient from "./bundlerClient"; // fetch wrapper

// export default class ClusterService {
//   provider: ethers.providers.Web3Provider;
//   signer: ethers.Signer;
//   entryPoint: ethers.Contract;
//   bundlerUrl: string;
//   paymaster: string;
//   clusterAddr: string;
//   accountAddr: string;

//   constructor(config: {
//     entryPoint: string;
//     bundlerUrl: string;
//     paymaster: string;
//     clusterAddr: string;
//     accountAddr: string;
//   }) {
//     this.provider = new ethers.providers.Web3Provider(window.ethereum);
//     this.signer   = this.provider.getSigner();
//     this.entryPoint = EntryPoint__factory
//       .connect(config.entryPoint, this.provider);
//     this.bundlerUrl  = config.bundlerUrl;
//     this.paymaster   = config.paymaster;
//     this.clusterAddr = config.clusterAddr;
//     this.accountAddr = config.accountAddr;
//   }

//   /** 1) callData 자동 생성 */
//   async makeCallData(
//     method: string,
//     args: any[]
//   ): Promise<string> {
//     const accountIface = new ethers.Interface(ClusterAccountAbi.abi);
//     // 멀티콜이 아닌 단일 execute(target,data) 구조라면:
//     const innerData = accountIface.encodeFunctionData(method, args);
//     // 만약 Account 컨트랙트에 execute(target,data)가 있다면:
//     const executeIface = new ethers.Interface([
//       "function execute(address,bytes)"
//     ]);
//     return executeIface.encodeFunctionData("execute", [
//       this.clusterAddr,
//       innerData
//     ]);
//   }

//   /** 2) UserOperation 빌드 */
//   async buildUserOp(callData: string) {
//     // 2.1) 논스 조회
//     const nonce = await this.entryPoint.getNonce(
//       this.accountAddr, 0
//     );
//     // 2.2) 가스 파라미터 (환경에 맞게 튜닝)
//     const feeData = await this.provider.getFeeData();
//     const userOp = {
//       sender:               this.accountAddr,
//       nonce,
//       initCode:             "0x",
//       callData,
//       callGasLimit:         200_000,
//       verificationGasLimit: 100_000,
//       preVerificationGas:   50_000,
//       maxPriorityFeePerGas: feeData.maxPriorityFeePerGas!,
//       maxFeePerGas:         feeData.maxFeePerGas!,
//       // 2.3) paymasterAndData 자동 생성
//       paymasterAndData: hexConcat([
//         this.paymaster,
//         defaultAbiCoder.encode(["address"], [this.clusterAddr])
//       ]),
//       signature:            "0x"
//     };
//     // 2.4) 해시 및 서명
//     const userOpHash = await this.entryPoint.getUserOpHash(userOp);
//     const sig        = await this.signer.signMessage(
//       arrayify(userOpHash)
//     );
//     userOp.signature = sig;
//     return userOp;
//   }

//   /** 3) Bundler에 전송 */
//   async sendUserOp(userOp: any) {
//     const payload = {
//       jsonrpc: "2.0",
//       id: 1,
//       method: "eth_sendUserOperation",
//       params: [userOp, this.entryPoint.address]
//     };
//     return BundlerClient.post(this.bundlerUrl, payload);
//   }

//   /** 사용자가 호출할 메인 함수 */
//   async execute(
//     method: string,
//     args: any[]
//   ): Promise<string> {
//     // A. callData 생성
//     const callData = await this.makeCallData(method, args);
//     // B. UserOp 생성
//     const userOp   = await this.buildUserOp(callData);
//     // C. 전송
//     const taskId   = await this.sendUserOp(userOp);
//     return taskId;  // Bundler가 반환한 Task ID
//   }
// }
