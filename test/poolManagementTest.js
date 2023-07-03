require('dotenv').config();
const hre = require("hardhat");
const fs = require("fs");
const ethers = hre.ethers;
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

async function main() {
    const [deployer] = await ethers.getSigners();
    const deployedAddresses = JSON.parse(fs.readFileSync("deployedAddresses.json"));
    const PoolManagement = await ethers.getContractAt("PoolManagement", deployedAddresses.PoolManagement);
    const UserContribution = await ethers.getContractAt("UserContribution", deployedAddresses.UserContribution);

    // Create new pool
    const poolName = "TestPool";
    const minContribution = ethers.utils.parseEther("0.1"); // 0.1 JOY
    const maxContribution = ethers.utils.parseEther("10"); // 10 JOY
    
    let deployerAddress = deployer.address; // Assuming 'deployer' object exists
    let additionalAddress = '0x17F6AD8Ef982297579C203069C1DbfFE4348c372';

    // Generate leaves from the two addresses
    let addresses = [deployerAddress, additionalAddress];
    let leaves = addresses.map(address => Buffer.from(keccak256(address), 'hex'));

    // Create the Merkle Tree
    let merkleTree = new MerkleTree(leaves, keccak256, { sort: true });

    // Get the Merkle root
    let merkleRoot = merkleTree.getHexRoot();

    // Generate the Merkle proof for the deployer's address
    let deployerLeaf = Buffer.from(keccak256(deployerAddress), 'hex');
    let merkleProof = merkleTree.getHexProof(deployerLeaf);

    await PoolManagement.connect(deployer).createPool(poolName, minContribution, maxContribution, merkleRoot);

    // Get pool co  unt
    const poolCount = await PoolManagement.connect(deployer).poolsCount();
    console.log(`Pool count is ${poolCount.toString()}`);
    if (poolCount < 1) {
        throw new Error("Pool count should be 1");
    }

    // Contribute to pool
    const contributionAmount = ethers.utils.parseEther("1"); // 1 JOY

    await UserContribution.connect(deployer).contributeToPool(poolCount-1, contributionAmount, merkleProof);

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
