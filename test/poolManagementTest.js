require('dotenv').config();
const hre = require("hardhat");
const fs = require("fs");
const ethers = hre.ethers;

async function main() {
    const [deployer] = await ethers.getSigners();
    const deployedAddresses = JSON.parse(fs.readFileSync("deployedAddresses.json"));
    const PoolManagement = await ethers.getContractAt("PoolManagement", deployedAddresses.PoolManagement);
    const UserContribution = await ethers.getContractAt("UserContribution", deployedAddresses.UserContribution);

    // Create new pool
    const poolName = "TestPool";
    const minContribution = ethers.utils.parseEther("0.1"); // 0.1 JOY
    const maxContribution = ethers.utils.parseEther("10"); // 10 JOY
    // Convert deployer address to bytes32
    let addressBytes = ethers.utils.zeroPad(deployer.address, 32);

    // Generate Merkle root from deployer's address
    let merkleRoot = ethers.utils.keccak256(addressBytes);

    await PoolManagement.connect(deployer).createPool(poolName, minContribution, maxContribution, merkleRoot);

    // Get pool count
    const poolCount = await PoolManagement.connect(deployer).poolsCount();
    console.log(`Pool count is ${poolCount.toString()}`);
    if (poolCount < 1) {
        throw new Error("Pool count should be 1");
    }

    // Contribute to pool
    const contributionAmount = ethers.utils.parseEther("1"); // 1 JOY

    // Use the same addressBytes as a placeholder for the Merkle proof
    const merkleProof = [addressBytes];

    await UserContribution.connect(deployer).contributeToPool(0, contributionAmount, merkleProof);

    // Check contribution
    const contribution = await UserContribution.connect(deployer).getPoolContribution(0, deployer.address);
    console.log(`Contribution is ${ethers.utils.formatEther(contribution)}`);
    if (!contribution.eq(contributionAmount)) {
        throw new Error("Contribution amount does not match");
    }

    console.log("All tests passed");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
