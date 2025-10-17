# Forever Message - Deployment Guide

## Prerequisites

1. **Node.js and npm** installed
2. **Base Sepolia ETH** in your wallet
   - Get free testnet ETH: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
3. **Private key** for deployment wallet (testnet wallet recommended)

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Compile Contracts

```bash
npm run compile
```

### 3. Set Up Environment Variables

Create a `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_SEPOLIA_PRIVATE_KEY=your_private_key_here
```

**Security Notes:**
- Never commit `.env` to git (it's in `.gitignore`)
- Use a dedicated testnet wallet
- For production, use a hardware wallet or secure key management

### 4. Deploy to Base Sepolia

```bash
export BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
export BASE_SEPOLIA_PRIVATE_KEY=your_private_key_here
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

📋 Deployment Summary:
   Contract: 0x...
   Deployer: 0x...

🔍 View on BaseScan:
    https://sepolia.basescan.org/address/0x...

✨ Deployment complete!
```

## Gas Cost Testing (Optional)

To measure gas costs on a local network:

```bash
npm run gas:test
```

This will:
1. Start a local Hardhat network
2. Deploy the contract
3. Test all major operations
4. Display gas usage and cost estimates

## Deployment to Base Mainnet (Production)

⚠️ **WARNING**: This uses real ETH. Only proceed when ready for production.

### Steps:

1. Set up mainnet environment variables:

```bash
export BASE_RPC_URL=https://mainnet.base.org
export BASE_PRIVATE_KEY=your_mainnet_private_key_here
```

2. Update the deployment script to use `BASE_RPC_URL` instead of `BASE_SEPOLIA_RPC_URL`

3. Deploy:

```bash
node scripts/deploy-standalone.mjs
```

4. Verify the contract on BaseScan (recommended):

```bash
npx hardhat verify --network base <DEPLOYED_CONTRACT_ADDRESS>
```

## Expected Gas Costs

Based on contract analysis (estimates may vary with network conditions):

| Operation | Gas Usage | Cost at 1 gwei | Cost at 10 gwei |
|-----------|-----------|----------------|-----------------|
| Deploy Contract | ~2,500,000 | ~0.0025 ETH | ~0.025 ETH |
| Create Bottle | ~150,000 | ~0.00015 ETH | ~0.0015 ETH |
| Like Bottle | ~50,000 | ~0.00005 ETH | ~0.0005 ETH |
| Add Comment | ~120,000 | ~0.00012 ETH | ~0.0012 ETH |
| Unlike Bottle | ~30,000 | ~0.00003 ETH | ~0.0003 ETH |

**At current ETH price ($2000):**
- Create Bottle: ~$0.30 at 1 gwei, ~$3.00 at 10 gwei
- Add Comment: ~$0.24 at 1 gwei, ~$2.40 at 10 gwei

**Why Base?**
Base (OP Stack L2) typically has gas prices <0.01 gwei, making transactions extremely cheap compared to Ethereum mainnet.

## Troubleshooting

### Error: "Deployer has no ETH"

**Solution**: Fund your wallet with Base Sepolia ETH from the faucet:
https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

### Error: "BASE_SEPOLIA_PRIVATE_KEY environment variable not set"

**Solution**: Set the environment variable before deployment:

```bash
export BASE_SEPOLIA_PRIVATE_KEY=your_private_key_here
```

Or add it to your `.env` file.

### Error: "Cannot find module"

**Solution**: Make sure you've compiled the contracts first:

```bash
npm run compile
```

### Network Connection Issues

**Solution**: Check your RPC URL is correct. You can use:
- Public Base Sepolia: `https://sepolia.base.org`
- Alchemy: `https://base-sepolia.g.alchemy.com/v2/YOUR_KEY`
- QuickNode: Your QuickNode Base Sepolia endpoint

## Post-Deployment

After successful deployment:

1. **Save the contract address** - You'll need this for frontend integration
2. **Verify on BaseScan** - Makes the contract code public and verifiable
3. **Test contract functions** - Use Hardhat console or BaseScan interface
4. **Update frontend** - Add the contract address and ABI to your React app

## Contract Verification (Optional but Recommended)

To verify your contract on BaseScan:

1. Get a BaseScan API key: https://basescan.org/myapikey

2. Add to `.env`:
```env
BASESCAN_API_KEY=your_api_key_here
```

3. Verify:
```bash
npx hardhat verify --network baseSepolia <CONTRACT_ADDRESS>
```

## Useful Commands

```bash
# Compile contracts
npm run compile

# Clean build artifacts
npm run clean

# Start local Hardhat node
npm run node

# Run tests (when you create them)
npm test

# Deploy to Base Sepolia
npm run deploy:baseSepolia

# Test gas costs
npm run gas:test
```

## Next Steps

After deployment, you can:

1. **Interact with the contract** using ethers.js in your frontend
2. **Create a bottle**: Call `createBottle(ipfsHash)` with your IPFS content hash
3. **Query bottles**: Use `getBottle(bottleId)` to retrieve bottle data
4. **Track user bottles**: Call `getUserBottles(address)` to get all bottles by a user

## Support

For issues or questions:
- Check the main [README.md](./README.md)
- Review Base documentation: https://docs.base.org
- Check Hardhat docs: https://hardhat.org/docs

## Security Best Practices

1. **Never share your private key**
2. **Use separate wallets for testnet and mainnet**
3. **Test thoroughly on testnet before mainnet deployment**
4. **Audit your contract** (consider professional audit for production)
5. **Start with small amounts** when testing on mainnet
6. **Keep your `.env` file secure** and never commit it

---

**FM-10 Task Complete** ✅

The smart contract infrastructure is ready for Base blockchain deployment!
