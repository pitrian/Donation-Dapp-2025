import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";

// Nạp biến môi trường từ file .env
dotenv.config();

const config = {
  solidity: "0.8.28", // Đảm bảo phiên bản này khớp hoặc cao hơn trong file .sol
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "", 
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
};

export default config;