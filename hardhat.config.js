require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-chai-matchers");
require("dotenv").config(); 

const { PRIVATE_KEY, ETH_SEPOLIA_RPC_URL, ETHERSCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },

  networks: {
    hardhat: {
      // Local node default configuration
      chainId: 31337,
    },

    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },

    sepolia: {
      url: ETH_SEPOLIA_RPC_URL || "https://rpc.sepolia.org",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
    },

  },

  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY || "",
    },
    customChains: [],
  },

  mocha: {
    timeout: 40000,
  },
};