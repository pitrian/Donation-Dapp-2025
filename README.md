Donation DApp (Ethereum)

A simple Blockchain Donation Decentralized Application (DApp) built on the Ethereum network, allowing users to donate ETH transparently with on-chain records.
This project is designed for learning smart contract development, Web3 interaction, and basic blockchain security concepts.

🚀 Features

Donate ETH with a custom message

Store all donation records on-chain

Secure owner-only withdrawal functionality

MetaMask wallet integration

Deployed and tested on Ethereum Sepolia Testnet

🛠 Tech Stack

Blockchain: Ethereum (EVM)

Smart Contract: Solidity ^0.8.x

Development Framework: Hardhat

Frontend Interaction: Web3.js / Ethers.js

Wallet: MetaMask

Testing Network: Sepolia Testnet

📂 Project Structure
.
├── contracts/              # Solidity smart contracts
│   └── Donation.sol
├── ignition/modules/       # Hardhat Ignition deployment scripts
├── test/                   # Smart contract tests
├── hardhat.config.js       # Hardhat configuration
├── package.json            # Project dependencies
├── index.html              # Simple Web3 frontend
└── README.md

📜 Smart Contract Overview

Donation.sol includes:

Donation struct (donor address, amount, message, timestamp)

Event logging for new donations

Access control using owner and modifiers

Secure withdrawal function restricted to the contract owner

🔐 Security Considerations

Implemented owner-only access control for withdrawal

Avoided common Solidity pitfalls using version ^0.8.x

Used events for transparency and auditability

(This project is for learning purposes and not intended for production use.)

🧪 How to Run Locally
1️⃣ Install dependencies
npm install

2️⃣ Compile smart contracts
npx hardhat compile

3️⃣ Run tests
npx hardhat test

4️⃣ Deploy to Sepolia Testnet

Configure your .env file with:

Sepolia RPC URL

Wallet private key

Then run:

npx hardhat ignition deploy ignition/modules/deploy.js --network sepolia

🌐 Demo & Interaction

Connect MetaMask to Sepolia Testnet

Use the provided index.html to interact with the deployed contract

All transactions can be verified via Etherscan (Sepolia)

📚 Learning Outcomes

Understand the workflow of Ethereum DApp development

Practice writing and deploying smart contracts

Learn Web3 wallet integration

Apply basic smart contract security principles
