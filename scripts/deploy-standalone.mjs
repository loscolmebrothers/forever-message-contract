import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  console.log("🚀 Starting ForeverMessage deployment...\n");

  // Load contract artifact
  const artifactPath = path.join(__dirname, "../artifacts/contracts/ForeverMessage.sol/ForeverMessage.json");
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // Get RPC URL and private key from environment
  const rpcUrl = process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org";
  const privateKey = process.env.BASE_SEPOLIA_PRIVATE_KEY;

  if (!privateKey) {
    console.error("❌ Error: BASE_SEPOLIA_PRIVATE_KEY environment variable not set");
    console.log("\nSet it with: export BASE_SEPOLIA_PRIVATE_KEY=your_private_key");
    process.exit(1);
  }

  // Connect to network
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log("📡 Network:", await provider.getNetwork().then(n => n.name));
  console.log("👤 Deployer address:", wallet.address);

  // Check balance
  const balance = await provider.getBalance(wallet.address);
  console.log("💰 Deployer balance:", ethers.formatEther(balance), "ETH\n");

  if (balance === 0n) {
    console.error("❌ Error: Deployer has no ETH");
    console.log("Get Base Sepolia ETH from: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet");
    process.exit(1);
  }

  // Deploy contract
  console.log("📝 Deploying ForeverMessage contract...");
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy();

  console.log("⏳ Waiting for deployment transaction...");
  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log("✅ ForeverMessage deployed to:", contractAddress);

  // Get deployment details
  const deployTx = contract.deploymentTransaction();
  if (deployTx) {
    const receipt = await deployTx.wait();
    console.log("\n📊 Gas Usage Analysis:");
    console.log("   Gas used:", receipt.gasUsed.toString());
    console.log("   Gas price:", ethers.formatUnits(receipt.gasPrice, "gwei"), "gwei");
    console.log("   Total cost:", ethers.formatEther(receipt.gasUsed * receipt.gasPrice), "ETH");
    console.log("   Block number:", receipt.blockNumber);
  }

  // Verify contract constants
  console.log("\n🔧 Contract Configuration:");
  console.log("   Comments threshold:", await contract.COMMENTS_THRESHOLD());
  console.log("   Likes threshold:", await contract.LIKES_THRESHOLD());
  console.log("   Expiration days:", await contract.EXPIRATION_DAYS());

  console.log("\n📋 Deployment Summary:");
  console.log("   Contract:", contractAddress);
  console.log("   Deployer:", wallet.address);
  console.log("\n🔍 View on BaseScan:");
  console.log("   ", "https://sepolia.basescan.org/address/" + contractAddress);

  console.log("\n✨ Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
