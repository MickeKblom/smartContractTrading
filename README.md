# Launchpad Smart Contract

This project implements a launchpad for ERC20 tokens with bonding curve functionality. It allows users to create new tokens, buy/sell tokens via the bonding curve, and interact with virtual tokens using ETH.

## Overview

This smart contract ecosystem consists of the following components:
1. **MockVirtuals:** The core contract managing token creation, buying/selling, and virtual token transactions.
2. **BondingCurve:** A separate contract deployed per token that handles pricing and liquidity.
3. **CustomToken:** ERC20 token implementation for created tokens and virtuals.

---

## Prerequisites

Ensure you have the following before interacting with the contracts:
- **Remix IDE** or a similar Solidity development environment.
- **OpenZeppelin contracts** for ERC20 and ownership functionalities.

---

## Deployment & Setup

### 1. Deploy MockVirtuals
   - Compile and deploy the `MockVirtuals.sol` contract.
   - Copy the deployed contract address.

### 2. Create Virtuals Token
   - Call `createVirtualsToken` from the `MockVirtuals` contract.
   - This mints 1 billion virtual tokens and assigns them to the MockVirtuals contract.

### 3. Buy Virtuals Token with ETH
   - Call `buyVirtuals` on the `MockVirtuals` contract, sending ETH.
   - You will receive virtual tokens based on the ETH sent.

### 4. Approve Spending of Virtuals
   - In the virtuals token ERC20 contract, approve MockVirtuals to spend your tokens.
   - Example: `approve(MockVirtualsAddress, amount)`.

---

## Creating a New Token

### 1. Create New Token
   - Call `createToken` on the `MockVirtuals` contract.
   - Parameters:
     - `name`: Name of the new token (e.g., "AgentToken").
     - `symbol`: Token symbol (e.g., "AGT").
     - `creatorAmount`: Number of tokens the creator wants to purchase initially.
   - If `creatorAmount` > 0, ensure you have enough virtuals and have approved MockVirtuals.

### 2. Locate New Token and Bonding Curve
   - Check transaction logs for the `TokenCreated` and `BondingCurveDeployed` events.
   - Copy the addresses of the newly created token and its corresponding bonding curve.

---

## Buying and Selling Tokens

### 1. Approve Virtuals for Bonding Curve (Required for Buying)
   - In the virtuals ERC20 contract, approve the bonding curve contract to spend your virtual tokens.
   - Example: `approve(BondingCurveAddress, amount)`.

### 2. Approve Token for Bonding Curve (Required for Selling)
   - In the new token's ERC20 contract, approve the bonding curve contract to spend your agent tokens.
   - Example: `approve(BondingCurveAddress, amount)`.

### 3. Buy Tokens
   - Call `buy` on the BondingCurve contract.
   - Parameters:
     - `amount`: The number of tokens you wish to buy.
   - Ensure you have enough virtuals and approval set up.

### 4. Sell Tokens
   - Call `sell` on the BondingCurve contract.
   - Parameters:
     - `amount`: The number of tokens you wish to sell.
   - Ensure you have enough tokens and approval set up.


## Important Notes

- Ensure all approvals are correctly set for smooth transactions.
- BondingCurve contract holds all token liquidity.
- Buying and selling prices are based on a linear bonding curve.
- Virtuals token is the primary currency for all transactions.

---

## License

This project is licensed under the MIT License.
