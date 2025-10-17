import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  console.log("⛽ Testing ForeverMessage Gas Costs\n");

  const artifactPath = path.join(__dirname, "../artifacts/contracts/ForeverMessage.sol/ForeverMessage.json");
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // Use local hardhat network
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  const wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);

  console.log("📡 Network: Local Hardhat");
  console.log("👤 Test account:", wallet.address);
  console.log();

  console.log("📝 Deploying ForeverMessage for testing...");
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy();
  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();
  console.log("✅ Contract deployed to:", contractAddress, "\n");

  const gasResults = [];

  async function recordGas(operation, tx) {
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed;
    const cost = gasUsed * receipt.gasPrice;
    gasResults.push({ operation, gasUsed, cost });
    console.log("   Gas used:", gasUsed.toString());
    console.log("   Cost:", ethers.formatEther(cost), "ETH\n");
  }

  console.log("🧪 Test 1: Creating a bottle");
  const createTx = await contract.createBottle("QmTest1234567890abcdefghijklmnopqrstuvwxyz123456");
  await recordGas("Create Bottle", createTx);

  console.log("🧪 Test 2: Liking a bottle");
  const likeTx = await contract.likeBottle(1);
  await recordGas("Like Bottle", likeTx);

  console.log("🧪 Test 3: Adding a comment");
  const commentTx = await contract.addComment(1, "QmComment1234567890abcdefghijklmnopqrstuv123456");
  await recordGas("Add Comment", commentTx);

  console.log("🧪 Test 4: Unliking a bottle");
  const unlikeTx = await contract.unlikeBottle(1);
  await recordGas("Unlike Bottle", unlikeTx);

  console.log("🧪 Test 5: Creating 5 bottles (batch test)");
  let totalBatchGas = 0n;
  for (let i = 0; i < 5; i++) {
    const tx = await contract.createBottle("QmBatch" + i + "234567890abcdefghijklmnopqrstuv123456");
    const receipt = await tx.wait();
    totalBatchGas += receipt.gasUsed;
  }
  console.log("   Total gas for 5 bottles:", totalBatchGas.toString());
  console.log("   Average per bottle:", (totalBatchGas / 5n).toString(), "\n");

  console.log("📊 Gas Cost Summary:");
  console.log("═══════════════════════════════════════════════");

  gasResults.forEach(({ operation, gasUsed, cost }) => {
    console.log(operation.padEnd(20), gasUsed.toString().padStart(10), "gas |", ethers.formatEther(cost), "ETH");
  });

  console.log("═══════════════════════════════════════════════");

  const totalGas = gasResults.reduce((sum, r) => sum + r.gasUsed, 0n);
  const totalCost = gasResults.reduce((sum, r) => sum + r.cost, 0n);

  console.log("TOTAL".padEnd(20), totalGas.toString().padStart(10), "gas |", ethers.formatEther(totalCost), "ETH");

  console.log("\n💡 Estimated costs at different gas prices:");
  const avgBottleGas = gasResults.find(r => r.operation === "Create Bottle")?.gasUsed || 0n;
  const avgCommentGas = gasResults.find(r => r.operation === "Add Comment")?.gasUsed || 0n;

  [1n, 5n, 10n, 25n].forEach(gweiPrice => {
    const gasPrice = gweiPrice * 1000000000n;
    const bottleCost = avgBottleGas * gasPrice;
    const commentCost = avgCommentGas * gasPrice;
    console.log("   At", gweiPrice.toString(), "gwei:");
    console.log("      Create bottle: $" + (parseFloat(ethers.formatEther(bottleCost)) * 2000).toFixed(4), "(assuming ETH = $2000)");
    console.log("      Add comment:   $" + (parseFloat(ethers.formatEther(commentCost)) * 2000).toFixed(4));
  });

  console.log("\n✨ Gas testing complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });
