import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, "../.env") });

async function main() {
  console.log("🚀 Starting ForeverMessage deployment...\n");

  // Load contract artifact (Foundry output)
  const artifactPath = path.join(
    __dirname,
    "../out/ForeverMessage.sol/ForeverMessage.json"
  );
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // Foundry's JSON structure has abi and bytecode in different format
  const abi = artifact.abi;
  const bytecode = artifact.bytecode.object;

  // Get RPC URL and private key from environment
  const rpcUrl = process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org";
  const privateKey = process.env.BASE_SEPOLIA_PRIVATE_KEY;

  if (!privateKey) {
    console.error(
      "❌ Error: BASE_SEPOLIA_PRIVATE_KEY environment variable not set"
    );
    console.log(
      "\nSet it with: export BASE_SEPOLIA_PRIVATE_KEY=your_private_key"
    );
    process.exit(1);
  }

  // Connect to network
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log(
    "📡 Network:",
    await provider.getNetwork().then((network) => network.name)
  );
  console.log("👤 Deployer address:", wallet.address);

  // Check balance
  const balance = await provider.getBalance(wallet.address);
  console.log("💰 Deployer balance:", ethers.formatEther(balance), "ETH\n");

  if (balance === 0n) {
    console.error("❌ Error: Deployer has no ETH");
    process.exit(1);
  }

  // Deploy contract
  console.log("📝 Deploying ForeverMessage contract...");
  const factory = new ethers.ContractFactory(abi, bytecode, wallet);
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
    console.log(
      "   Gas price:",
      ethers.formatUnits(receipt.gasPrice, "gwei"),
      "gwei"
    );
    console.log(
      "   Total cost:",
      ethers.formatEther(receipt.gasUsed * receipt.gasPrice),
      "ETH"
    );
    console.log("   Block number:", receipt.blockNumber);
  }

  // Verify contract constants
  console.log("\n🔧 Contract Configuration:");
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
