# AirClar: Clarity Airdrop Distribution System

A robust and secure smart contract system built with Clarity for managing token airdrops on the Stacks blockchain. This project provides a flexible and gas-efficient solution for conducting token distributions with features like claim periods, distribution caps, and batch operations.

## Features

- **Secure Token Distribution**: Implements SIP-010 compliant token distribution with proper ownership checks
- **Claiming System**: Time-based claiming period with configurable start and end blocks
- **Batch Operations**: Efficient batch processing for adding multiple eligible addresses
- **Distribution Controls**: Configurable distribution cap and monitoring
- **Emergency Functions**: Admin controls for emergency situations
- **Gas Optimized**: Efficient implementation to minimize transaction costs

## Contract Architecture

The project consists of two main Clarity contracts:

1. `sip-010-trait.clar`: Defines the standard interface for fungible tokens
2. `airdrop-distributor-v1.clar`: Main airdrop distribution logic

### Directory Structure

```
clarity-airdrop-distribution/
├── contracts/
│   ├── traits/
│   │   └── sip-010-trait.clar
│   └── airdrop-distributor-v1.clar
├── README.md
└── LICENSE
```

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): Clarity development environment
- A compatible SIP-010 token contract

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/clarity-airdrop-distribution.git
cd clarity-airdrop-distribution
```

2. Initialize Clarinet project (if not already done):
```bash
clarinet new
```

### Deployment Steps

1. Deploy the trait contract:
```bash
clarinet contract:deploy traits/sip-010-trait
```

2. Deploy your token contract that implements the SIP-010 trait

3. Deploy the airdrop contract:
```bash
clarinet contract:deploy airdrop-distributor-v1
```

4. Initialize the airdrop contract:
```bash
clarinet contract:call set-token-contract <token-contract-address>
clarinet contract:call set-claim-period <start-block> <end-block>
```

## Usage

### Setting Up an Airdrop

1. Set the token contract:
```clarity
(contract-call? .airdrop-distributor-v1 set-token-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-contract)
```

2. Set the claim period:
```clarity
(contract-call? .airdrop-distributor-v1 set-claim-period u100 u1000)
```

3. Add eligible addresses:
```clarity
;; Single address
(contract-call? .airdrop-distributor-v1 add-eligible-address 'ST1... u1000)

;; Batch addresses
(contract-call? .airdrop-distributor-v1 batch-add-eligible-addresses (list 'ST1... 'ST2...) (list u1000 u2000))
```

### Claiming Tokens

Users can claim their tokens by calling:
```clarity
(contract-call? .airdrop-distributor-v1 claim-tokens .token-contract)
```

### Administrative Functions

- Update distribution cap:
```clarity
(contract-call? .airdrop-distributor-v1 update-distribution-cap u2000000)
```

- Emergency withdraw:
```clarity
(contract-call? .airdrop-distributor-v1 emergency-withdraw .token-contract u1000)
```

## Security Considerations

1. **Ownership Controls**: Only the contract owner can perform administrative functions
2. **Double-Claim Prevention**: Users cannot claim tokens multiple times
3. **Distribution Cap**: Total distribution cannot exceed the configured cap
4. **Time-Bound**: Claims are only valid within the specified claim period
5. **Emergency Controls**: Admin can halt distribution and withdraw tokens if needed

## Testing

To run the test suite:
```bash
clarinet test
```