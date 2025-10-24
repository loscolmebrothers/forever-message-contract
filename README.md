# Forever Message - Smart Contract

Multi-user smart contracts for Forever Message platform on Base L2. Tracks bottle ownership, engagement (likes/comments), and automatic forever promotion using Foundry.

## Overview

The ForeverMessage contract enables:
- **Multi-user ownership**: Each bottle/comment tracks its creator address
- **Gasless for users**: Backend relayer pays all gas costs via `onlyDeployer` modifier
- **Automatic forever promotion**: Bottles meeting thresholds (100 likes + 4 comments) become permanent
- **IPFS integration**: Stores content hashes on-chain, actual content in IPFS for gas efficiency
- **Time-based expiration**: Bottles expire after 7 days unless promoted to forever status

## Architecture

### Design Principles
1. **Separation of concerns**: Contract stores references, IPFS stores content
2. **Gas optimization**: Only critical data on-chain (hashes, timestamps, engagement counts)
3. **Centralized thresholds**: Contract is single source of truth for forever promotion logic
4. **Backend relayer**: Users never pay gas; backend calls contract with user addresses

### Key Structs

```solidity
struct Bottle {
    uint256 id;
    string ipfsHash;
    uint256 createdAt;
    uint256 expiresAt;
    bool isForever;
    bool exists;
    address creator;
}

struct Comment {
    uint256 id;
    uint256 bottleId;
    string ipfsHash;
    uint256 createdAt;
    address commenter;
}
```

## Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js v18+

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install Node dependencies
yarn install
```

## Configuration

Create `.env` file:

```env
PRIVATE_KEY=your-deployer-private-key
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=your-basescan-api-key
```

## Development

### Compile

```bash
yarn compile
# or
forge build
```

### Test

```bash
# Run all tests
yarn test

# Run with gas report
yarn test:gas

# Run with coverage
yarn test:coverage

# Run with detailed gas price estimation
yarn test:gas:price
```

### Test Coverage

45 comprehensive tests covering:
- Deployment (2 tests)
- Bottle creation (6 tests) 
- Likes/unlikes (7 tests)
- Comments (6 tests)
- Forever promotion (7 tests)
- Manual forever marking (2 tests)
- Expiration (4 tests)
- IPFS updates (2 tests)
- View functions (4 tests)
- Edge cases (2 tests)
- Fuzz tests (3 tests)

## Deployment

### Deploy to Base Sepolia

```bash
yarn deploy:baseSepolia
```

This will:
1. Compile contracts
2. Deploy to Base Sepolia testnet
3. Save deployment info to `deployment-info.json`
4. Output contract address and transaction hash

## Contract API

### Core Functions

#### `createBottle(string memory _ipfsHash, address _creator)`
Creates a new bottle owned by `_creator`.
- **Access**: `onlyDeployer`
- **Emits**: `BottleCreated(bottleId, creator, ipfsHash, createdAt, expiresAt)`
- **Returns**: `bottleId`

#### `likeBottle(uint256 _bottleId, address _liker)`
Records a like from `_liker`.
- **Access**: `onlyDeployer`
- **Emits**: `BottleLiked(bottleId, liker)`

#### `unlikeBottle(uint256 _bottleId, address _unliker)`
Removes a like from `_unliker`.
- **Access**: `onlyDeployer`
- **Emits**: `BottleUnliked(bottleId, unliker)`

#### `addComment(uint256 _bottleId, string memory _ipfsHash, address _commenter)`
Adds comment to bottle from `_commenter`.
- **Access**: `onlyDeployer`
- **Emits**: `CommentAdded(commentId, bottleId, commenter, ipfsHash)`
- **Returns**: `commentId`

#### `checkIsForever(uint256 _bottleId, uint256 _likeCount, uint256 _commentCount)`
Checks if bottle meets thresholds and promotes to forever if eligible.
- **Access**: `onlyDeployer`
- **Emits**: `BottleMarkedForever(bottleId)` (if promoted)
- **Thresholds**: 100 likes AND 4 comments

#### `updateBottleIPFS(uint256 _bottleId, string memory _newIpfsHash)`
Updates bottle IPFS hash (for count synchronization).
- **Access**: `onlyDeployer`
- **Emits**: `BottleIPFSUpdated(bottleId, oldHash, newHash)`

### View Functions

#### `getBottle(uint256 _bottleId)`
Returns bottle data.
- **Returns**: `(id, ipfsHash, createdAt, expiresAt, creator, isForever, exists)`

#### `getComment(uint256 _commentId)`
Returns comment data.
- **Returns**: `(id, bottleId, ipfsHash, createdAt, commenter)`

#### `getBottleComments(uint256 _bottleId)`
Returns array of comment IDs for a bottle.

#### `isBottleExpired(uint256 _bottleId)`
Checks if bottle has expired (not forever and past expiration).

#### `hasUserLikedBottle(uint256 _bottleId, address _user)`
Checks if user has liked a bottle.

## Constants

```solidity
uint256 public constant BOTTLE_EXPIRATION_TIME = 7 days;
uint256 public constant FOREVER_LIKES_THRESHOLD = 100;
uint256 public constant FOREVER_COMMENTS_THRESHOLD = 4;
```

## Events

```solidity
event BottleCreated(uint256 indexed bottleId, address indexed creator, string ipfsHash, uint256 createdAt, uint256 expiresAt);
event BottleLiked(uint256 indexed bottleId, address indexed liker);
event BottleUnliked(uint256 indexed bottleId, address indexed unliker);
event CommentAdded(uint256 indexed commentId, uint256 indexed bottleId, address indexed commenter, string ipfsHash);
event BottleMarkedForever(uint256 indexed bottleId);
event BottleIPFSUpdated(uint256 indexed bottleId, string oldIpfsHash, string newIpfsHash);
```

## Architecture Flow

### Creating a Bottle
1. User interacts with frontend
2. Backend uploads content to IPFS → gets CID
3. Backend calls `createBottle(CID, userAddress)` with deployer wallet
4. Contract stores reference and emits event with user as creator
5. User owns bottle on-chain (verifiable via creator address)

### Forever Promotion
1. User likes/comments on bottle
2. Backend increments counts in IPFS
3. Backend calls `checkIsForever(bottleId, likeCount, commentCount)`
4. Contract checks if thresholds met (≥100 likes AND ≥4 comments)
5. If yes, contract promotes to forever automatically
6. Backend is ignorant of thresholds (contract is source of truth)

## Gas Costs (Base Sepolia)

Typical costs with Base gas prices (~0.001-0.01 gwei):

| Operation | Gas Used | Cost (@ 0.005 gwei) | Cost USD (ETH @ $2500) |
|-----------|----------|---------------------|------------------------|
| Deploy | ~2.5M | 0.0125 ETH | ~$31.25 |
| Create Bottle | ~120k | 0.0006 ETH | ~$1.50 |
| Like Bottle | ~65k | 0.000325 ETH | ~$0.81 |
| Add Comment | ~95k | 0.000475 ETH | ~$1.19 |
| Check Forever | ~45k | 0.000225 ETH | ~$0.56 |

**10k bottles scenario**: ~$15k-30k total gas costs depending on engagement.

## Security

### Access Control
- `onlyDeployer` modifier protects all write functions
- Backend relayer holds deployer private key (never exposed to users)
- User addresses passed as parameters, ownership tracked on-chain

### Validations
- Bottle existence checks
- Expiration checks for likes/comments
- Duplicate like prevention
- Comment association validation

## File Structure

```
forever-message-contract/
├── contracts/
│   └── ForeverMessage.sol      # Main contract
├── test/
│   └── ForeverMessage.t.sol    # Foundry test suite (45 tests)
├── scripts/
│   ├── deploy-standalone.mjs   # Deployment script
│   └── gas-price-report.sh     # Gas estimation tool
├── out/                        # Compiled artifacts (gitignored)
├── cache_forge/                # Build cache (gitignored)
├── lib/                        # Foundry dependencies
├── foundry.toml               # Foundry configuration
├── remappings.txt             # Import mappings
└── package.json
```

## Foundry Commands Reference

```bash
# Build
forge build

# Test
forge test                      # Run all tests
forge test -vv                  # Verbose output
forge test -vvv                 # Very verbose (including traces)
forge test --gas-report         # With gas report
forge test --match-test testName  # Run specific test

# Coverage
forge coverage

# Clean
forge clean

# Snapshot (gas)
forge snapshot
```

## License

MIT

## Links

- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
- [Foundry Book](https://book.getfoundry.sh/)
