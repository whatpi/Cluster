require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();  // <= 꼭 추가

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",

  networks: {
    hardhat: {
      // 필요하다면 chainId 고정
      chainId: 31337,
      // 메모리 블록체인 fork 옵션 예시
      // forking: {
      //   url: process.env.MAINNET_RPC_URL
      // }
    },

    /**
     * 로컬 JSON-RPC 노드를 띄우고 메타마스크로 접속하시려면
     * 1) `npx hardhat node` 실행
     * 2) metamask 네트워크에 URL http://127.0.0.1:8545, Chain ID 31337 추가
     * (계정 프라이빗키는 콘솔에 표시되는 20개 중 하나 복사)
     */
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    }
  }

};
