# Forever Message - Smart Contract

A social experiment platform where users post daily messages in bottles that float in a digital ocean. Messages expire in 30 days unless engaged with. Popular messages (4 comments + 100 likes) become permanent "forever messages".

## Tech Stack

- **Blockchain**: Base (OP Stack L2) for cheap gas fees
- **Storage**: IPFS for content storage
- **Framework**: Hardhat v3.0.7 with TypeScript
- **Language**: Solidity 0.8.28

## Project Structure

```
forever-message-contract/
├── contracts/
│   └── ForeverMessage.sol           # Main contract (222 lines)
├── scripts/
│   ├── deploy-standalone.mjs        # Production deployment script
│   └── test-gas-standalone.mjs      # Gas cost testing script
├── test/                            # Test files (ready for your tests)
├── ignition/
│   └── modules/
│       └── ForeverMessage.ts        # Hardhat Ignition deployment module
├── hardhat.config.ts                # Hardhat configuration with Base networks
├── .env.example                     # Environment variables template
├── DEPLOYMENT.md                    # Comprehensive deployment guide
└── package.json                     # NPM scripts for easy deployment
```

## Smart Contract Features

The `ForeverMessage.sol` contract implements:

- **Bottle Creation**: Post messages with IPFS hash references
- **30-Day Expiration**: Messages expire unless they become "forever"
- **Engagement Tracking**: Likes and comments tracked on-chain
- **Forever Status**: Bottles with 100+ likes AND 4+ comments become permanent
- **Gas Efficiency**: Only IPFS hashes stored on-chain, content on IPFS

### Key Functions

- `createBottle(ipfsHash)` - Post a new message bottle
- `likeBottle(bottleId)` / `unlikeBottle(bottleId)` - Engagement actions
- `addComment(bottleId, ipfsHash)` - Add comments (IPFS stored)
- `getBottle(bottleId)` - Retrieve bottle data
- `getUserBottles(address)` - Get all bottles by user
- `isBottleExpired(bottleId)` - Check expiration status

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Required variables:
```env
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_SEPOLIA_PRIVATE_KEY=your_testnet_private_key_here
```

**Important**: 
- Never commit your `.env` file to git
- Use a dedicated wallet for testnet
- Get Base Sepolia ETH from: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

### 3. Set Private Key (Secure Method)

Using Hardhat Keystore (recommended):

```bash
npx hardhat keystore set BASE_SEPOLIA_PRIVATE_KEY
```

Or set as environment variable:

```bash
export BASE_SEPOLIA_PRIVATE_KEY=your_private_key
```

## Compilation

Compile the smart contracts:

```bash
npx hardhat compile
```

## Deployment

### Deploy to Base Sepolia (Testnet)

```bash
# Set environment variables
export BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
export BASE_SEPOLIA_PRIVATE_KEY=your_testnet_private_key

# Deploy using npm script
npm run deploy:baseSepolia
```

Expected output:
```
🚀 Starting ForeverMessage deployment...
📡 Network: base-sepolia
👤 Deployer address: 0x...
💰 Deployer balance: 0.1 ETH

📝 Deploying ForeverMessage contract...
⏳ Waiting for deployment transaction...
✅ ForeverMessage deployed to: 0x...

📊 Gas Usage Analysis:
   Gas used: ~2500000
   Gas price: 0.001 gwei
   Total cost: ~0.0025 ETH
   Block number: 12345

🔧 Contract Configuration:
   Comments threshold: 4
   Likes threshold: 100
   Expiration days: 30

🔍 View on BaseScan:
    https://sepolia.basescan.org/address/0x...

✨ Deployment complete!
```

**Note**: See [DEPLOYMENT.md](./DEPLOYMENT.md) for comprehensive deployment instructions.

### Deploy to Base Mainnet (Production)

**⚠️ WARNING**: This uses real ETH. Only deploy when ready for production.

See [DEPLOYMENT.md](./DEPLOYMENT.md) for mainnet deployment instructions.

## Gas Cost Testing

Test gas costs on a local network:

```bash
npm run gas:test
```

This will:
1. Deploy the contract
2. Test all major operations (create bottle, like, comment, etc.)
3. Provide detailed gas analysis
4. Show estimated costs at different gas prices

Expected operations gas costs (approximate):
- Create Bottle: ~150,000 gas
- Like Bottle: ~50,000 gas
- Add Comment: ~120,000 gas
- Unlike Bottle: ~30,000 gas

## Testing

Run tests (when you create them):

```bash
npx hardhat test
```

Run specific test file:

```bash
npx hardhat test test/ForeverMessage.test.ts
```

## Network Configuration

Configured networks in `hardhat.config.ts`:

- **hardhatMainnet**: Local L1 simulation
- **hardhatOp**: Local OP Stack simulation
- **sepolia**: Ethereum Sepolia testnet
- **baseSepolia**: Base Sepolia testnet (recommended for testing)
- **base**: Base mainnet (production)

## Contract Verification

After deployment, verify your contract on BaseScan:

```bash
npx hardhat verify --network baseSepolia DEPLOYED_CONTRACT_ADDRESS
```

## Development Notes

### Why Base?
- **Low gas costs**: OP Stack L2 provides significantly cheaper transactions
- **EVM compatible**: Full Solidity support
- **Fast finality**: Quick block times for better UX
- **Growing ecosystem**: Strong community and tooling

### IPFS Integration
The contract stores only IPFS hashes. Your frontend should:
1. Upload message content to IPFS
2. Get the IPFS hash (CID)
3. Call `createBottle(ipfsHash)` with the hash
4. Retrieve content from IPFS using the stored hash

### Forever Message Logic
A bottle becomes permanent when:
```solidity
likeCount >= 100 AND commentCount >= 4
```

This is checked automatically in `_checkForeverStatus()` after likes/comments.

## Useful Commands

```bash
# Compile contracts
npm run compile

# Clean build artifacts
npm run clean

# Start local Hardhat node
npm run node

# Deploy to Base Sepolia
npm run deploy:baseSepolia

# Test gas costs
npm run gas:test

# Run tests (when you create them)
npm test

# Hardhat console
npx hardhat console --network baseSepolia

# Get help
npx hardhat help
```

## Resources

- [Hardhat 3 Documentation](https://hardhat.org/docs/getting-started)
- [Base Documentation](https://docs.base.org)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
- [BaseScan](https://basescan.org)
- [IPFS Documentation](https://docs.ipfs.tech)

## License

MIT

## Contributing

This is part of the Forever Message social experiment. For questions or contributions, please open an issue.
