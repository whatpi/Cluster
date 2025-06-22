// hardhat.config.js  (CommonJS)
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  /* ───────── Solidity 컴파일러 ───────── */
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",   // ← 컴파일 타깃
      optimizer: { enabled: true, runs: 200 } // 필요 시
    }
  },

  /* ───────── 네트워크 ───────── */
  networks: {
    hardhat: {
      chainId: 31337,
      hardfork: "cancun",     // ← 실행 VM 규칙
      // forking: { url: process.env.MAINNET_RPC_URL }
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      chainId: 11155111,
      accounts: process.env.SEPOLIA_PK ? [process.env.SEPOLIA_PK] : []
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      chainId: 1,
      accounts: process.env.MAINNET_PK ? [process.env.MAINNET_PK] : []
    }
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  },

  mocha: { timeout: 0 },

  paths: { tests: "./tests" }
};
