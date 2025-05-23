// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      // 실제 배포 시에는 아래 주석을 해제하고 개인 키를 입력해야 합니다
      // accounts: ["0xYOUR_PRIVATE_KEY_HERE"]
      // 테스트 목적으로는 아래 더미 계정을 사용합니다
      accounts: ["0x0000000000000000000000000000000000000000000000000000000000000001"]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
