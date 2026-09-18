# Token Vesting Platform

A professional full-stack token vesting platform built with Solidity, Foundry, Next.js, and modern Ethereum tooling.

**Live Site:** [Token Vesting](https://token-vesting.0xs.to/)

The platform allows a contract owner to create time-based vesting schedules for beneficiaries. Beneficiaries can connect their wallets, view their schedules, and claim tokens as they vest. The owner can manage schedules, pause protected operations, reclaim unvested allocations from revoked schedules, and withdraw genuinely excess tokens.

> **Network:** Sepolia testnet  
> **Token:** Vesting Token (`VST`)

---

## Overview

TokenVesting is an ERC20 vesting application that supports multiple beneficiaries and configurable schedules. Each schedule defines:

- The total token allocation
- The vesting start timestamp
- A cliff duration
- The total vesting duration
- The amount already claimed
- Whether the schedule has been revoked

The contract tracks the total outstanding allocation so beneficiary funds remain protected from accidental owner withdrawals. Only tokens exceeding the outstanding allocation can be withdrawn as excess.

---

## Features

- **Create Vesting Schedules:** The owner can assign a custom allocation, start time, cliff, and vesting duration to each beneficiary
- **Linear Vesting:** Tokens vest progressively over the configured vesting period after the cliff has expired
- **Claim Vested Tokens:** Beneficiaries can claim available tokens without waiting for the full schedule to complete
- **Schedule Revocation:** The owner can stop future vesting while preserving tokens vested up to the revocation time
- **Reclaim Unvested Tokens:** The owner can recover the unvested portion of a revoked schedule
- **Excess Token Withdrawal:** The owner can only withdraw tokens above the total outstanding allocation
- **Pause Controls:** The owner can pause and unpause operations protected by the pause mechanism
- **Owner Dashboard:** Displays contract balance, outstanding allocation, and available excess
- **Wallet-Aware Interface:** Handles wallet connection, account switching, wrong-network states, and missing schedules
- **Readable Transaction Errors:** Contract custom errors are decoded into user-facing messages
- **Transaction Feedback:** Pending, confirmation, success, and failure states are displayed through notifications
- **Verified Contracts:** Deployed Sepolia contracts are available through Etherscan

---

## How to Use

### 1. Connect Your Wallet

- Open the application on the Sepolia testnet
- Click **Connect Wallet**
- Approve the connection in MetaMask or another supported wallet
- Make sure the wallet is connected to **Sepolia**

RainbowKit displays a wrong-network state when the wallet is connected to another chain.

### 2. Beneficiary Workflow

Connect the wallet that was assigned a vesting schedule.

- View the assigned allocation and schedule details
- Check the start time, cliff duration, vesting duration, and claimable amount
- Wait until the cliff has expired
- Click **Claim Vested Tokens** when tokens are available
- Confirm the transaction in the wallet
- Refreshing the dashboard updates the schedule and token balances

Claimed tokens are transferred directly to the beneficiary address. A different wallet cannot redirect the claim to itself.

### 3. Owner Workflow

Connect the wallet that deployed the `TokenVesting` contract. The owner dashboard provides access to administrative functions.

#### Add a Beneficiary

- Enter the beneficiary wallet address
- Enter the total allocation in the token's smallest unit or the format supported by the interface
- Enter the start time as a Unix timestamp in seconds
- Enter the cliff duration in seconds
- Enter the total vesting duration in seconds
- Submit the transaction and confirm it in the wallet

The contract must already hold enough `VST` tokens to cover the new allocation and all existing outstanding allocations.

#### Revoke a Schedule

- Select an existing beneficiary
- Click **Revoke Schedule**
- Confirm the transaction

Revocation stops future vesting. The amount vested at the exact time of revocation remains claimable by the beneficiary.

#### Reclaim Unvested Tokens

After revoking a schedule:

- Select the revoked beneficiary
- Click **Reclaim Unvested Tokens**
- Confirm the transaction

Only the unvested portion is transferred back to the contract owner. The beneficiary remains in the contract's historical beneficiary array and cannot be re-added under the current contract design.

#### Withdraw Excess Tokens

The owner can withdraw tokens only when:

```text
Contract balance > total outstanding allocation
```

This protects tokens reserved for active and revoked beneficiary schedules. The dashboard displays the available excess before the transaction is submitted.

#### Pause and Unpause

The owner can pause and unpause the contract. Pausing blocks functions protected by `whenNotPaused`, including adding beneficiaries, revoking schedules, claiming tokens, and reclaiming unvested tokens.

---

## Vesting Behaviour

### Linear Vesting

After the cliff has expired, the claimable amount is calculated linearly from the schedule start time until the vesting period ends.

The underlying calculation is equivalent to:

\[
\text{vested amount} = \frac{\text{total allocation} \times (\text{current time} - \text{start time})}{\text{vesting duration}}
\]

The amount available to claim is:

\[
\text{claimable amount} = \text{vested amount} - \text{amount already claimed}
\]

Once the vesting duration has elapsed, the full allocation is considered vested. A beneficiary cannot claim more than the schedule allocation.

### Cliff and Timestamps

- `startTime` is a Unix timestamp measured in seconds
- `cliffDuration` is measured in seconds
- `vestingDuration` is measured in seconds
- The cliff must be shorter than the total vesting duration
- Claims are unavailable before the cliff expires
- Transactions and timestamps are evaluated by the blockchain, not the user's local clock

### One Schedule Per Address

Each beneficiary address can have only one vesting schedule.

A revoked schedule is not deleted. Because its allocation remains stored, the same beneficiary cannot be added again under the current contract implementation. Revocation is therefore a permanent state transition for that address.

The beneficiary count includes addresses retained in the contract's beneficiary array, including revoked schedules.

---

## Smart Contracts

The contracts are deployed on **Sepolia testnet** and can be inspected on Etherscan.

| Contract               | Address                                      | Verified Source                                                                                   |
| ---------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **TokenVesting**       | `0x1Ed38eDf4C2d862065fcdD2F55Ed2646b6E68d96` | [View Code](https://sepolia.etherscan.io/address/0x1Ed38eDf4C2d862065fcdD2F55Ed2646b6E68d96#code) |
| **VestingToken (VST)** | `0xC86720dCB5d5377D7882C41f74F9D6CFF2DA03Bf` | [View Code](https://sepolia.etherscan.io/address/0xC86720dCB5d5377D7882C41f74F9D6CFF2DA03Bf#code) |

`VestingToken` is a test ERC20 token. Its constructor mints the initial supply to the deployer, who can then transfer tokens to the `TokenVesting` contract for testing.

---

## Accounting and Fund Safety

The `TokenVesting` contract tracks `totalOutstandingAllocation`.

This value decreases when:

- A beneficiary claims vested tokens
- The owner reclaims unvested tokens from a revoked schedule

The available excess is calculated as:

```text
Available excess = contract token balance - total outstanding allocation
```

The contract rejects excess withdrawals when:

- The contract is underfunded
- There is no excess balance

This ensures the owner cannot withdraw tokens reserved for beneficiaries.

---

## Technology Stack

### Smart Contracts

- **Solidity** 0.8.26
- **Foundry** for compilation, testing, scripting, and deployment
- **OpenZeppelin Contracts** v5.x
- **ERC20** token standard
- **Ownable** for owner-only administration
- **Pausable** for emergency controls
- **SafeERC20** for safe token transfers
- **Custom Errors** for gas-efficient validation and frontend decoding

### Frontend

- **Next.js** 16.3.4 with the App Router
- **React** 19.2.8
- **TypeScript**
- **Tailwind CSS** v4
- **Wagmi** v2.19.5
- **Viem** v2.56.3
- **RainbowKit** v2.2.11
- **TanStack Query** for query and cache management
- **Sonner** for transaction notifications

---

## Repository Structure

```text
.
├── contracts/
│   ├── src/
│   │   ├── TokenVesting.sol
│   │   └── VestingToken.sol
│   ├── script/
│   │   └── DeployTokenVesting.s.sol
│   ├── test/
│   └── foundry.toml
├── frontend/
│   ├── app/
│   ├── components/
│   ├── hooks/
│   ├── lib/
│   ├── public/
│   └── package.json
└── README.md
```

Blockchain hooks are kept separate from presentational frontend components so transaction and read logic can be tested and maintained independently from the user interface.

---

## Development

### Prerequisites

Install the following before starting:

- Node.js 18 or later
- npm
- Foundry
- Git
- MetaMask or another Ethereum wallet
- Sepolia ETH for transaction gas

### Clone and Install

```bash
git clone <repository-url>
cd token-vesting

cd contracts
forge install
forge build
forge test

cd ../frontend
npm install
```

Do not commit private keys, API keys, wallet seed phrases, or local environment files.

### Frontend Environment Variables

Create `frontend/.env.local` with the Alchemy key used by the frontend configuration:

```env
NEXT_PUBLIC_ALCHEMY_API_KEY=your_alchemy_api_key
```

The `.env.local` file is local configuration and must remain untracked.

### Start the Frontend

```bash
cd frontend
npm run dev
```

Open the local URL shown by Next.js in your browser.

### Production Frontend Commands

```bash
cd frontend
npm run lint
npm run build
npm run start
```

---

## Smart Contract Commands

Run these commands from the `contracts` directory.

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Run Tests with Verbose Output

```bash
forge test -vvv
```

### Format Solidity

```bash
forge fmt
```

### Deploy to Sepolia

The deployment script deploys `VestingToken` first and then deploys `TokenVesting` using the newly deployed token address. Configure your RPC endpoint and signing method securely before broadcasting.

```bash
cd contracts
forge script script/DeployTokenVesting.s.sol:DeployTokenVesting \
  --rpc-url <sepolia-rpc-url> \
  --broadcast
```

Use a secure Foundry wallet configuration rather than placing a private key directly in shell history. After deployment, verify the printed addresses and update the frontend contract configuration if deploying a new instance.

---

## Testing Coverage

The project has been tested across the main beneficiary and owner workflows, including:

- Wallet connection and Sepolia network validation
- Owner and non-owner access states
- Beneficiaries with and without schedules
- Schedule creation and duplicate beneficiary rejection
- Cliff and linear vesting calculations
- Claiming vested tokens
- Schedule revocation
- Reclaiming unvested tokens
- Repeated reclaim prevention
- Contract pause and unpause behaviour
- Contract balance and outstanding allocation accounting
- Excess-token withdrawal validation
- Transaction confirmation and cache refresh
- Custom contract error decoding
- Read failures and transaction failures in the frontend
- Explicit gas-limit handling for Sepolia RPC estimation issues

---

## Known Limitations

- The application currently targets Sepolia testnet rather than mainnet.
- `VST` is a test token and has no intended monetary value.
- A beneficiary address can have only one schedule.
- Revoked beneficiaries remain in the historical beneficiary array.
- A revoked beneficiary cannot be assigned a new schedule under the current contract design.
- Blockchain timestamps and transaction confirmations depend on network conditions.
- Users need Sepolia ETH to pay transaction fees.
- Token transfers into the vesting contract must be performed before allocations can be created.

---

## Risk Disclaimer

Before using this platform, understand the following:

- **Smart Contract Risk:** Smart contracts can contain bugs or vulnerabilities despite testing and source-code verification.
- **Testnet Only:** This deployment is intended for Sepolia testing and demonstration.
- **Token Risk:** `VST` is a test token and should not be treated as having real-world value.
- **Transaction Risk:** Incorrect addresses, timestamps, durations, or token transfers may produce unexpected results.
- **Network Risk:** RPC failures, congestion, wallet errors, and gas-estimation problems can affect transactions.
- **Administrative Risk:** The contract owner has privileged abilities to add beneficiaries, revoke schedules, pause protected operations, reclaim unvested tokens, and withdraw excess tokens.

Use the application only with testnet assets and only amounts you can afford to lose.

---

## Portfolio

This project demonstrates:

- Solidity smart contract development
- Foundry testing and deployment workflows
- ERC20 vesting mechanics
- OpenZeppelin security patterns
- Owner-controlled administrative functions
- Full-stack Web3 application development
- Next.js App Router architecture
- Wagmi and Viem Ethereum integration
- Wallet and transaction-state handling
- Frontend custom-error decoding
- Professional documentation and risk communication

[View Portfolio](https://www.0xs.to/)

---

## Support

For issues:

1. Confirm that the wallet is connected to Sepolia
2. Confirm that the connected wallet is the intended beneficiary or contract owner
3. Check the transaction details in the wallet and on Etherscan
4. Confirm that the vesting contract has sufficient `VST` funding
5. Review the relevant contract error displayed by the application
6. Verify that the schedule has not already been claimed, revoked, or reclaimed
