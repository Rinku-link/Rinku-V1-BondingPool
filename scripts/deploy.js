require('dotenv').config();
const hre = require("hardhat");
const fs = require('fs');

async function main() {
  try {
    const joyTokenAddress = process.env.LOCAL_JOYTOKEN;

    // Deploying PoolManagement
    const PoolManagement = await hre.ethers.getContractFactory("PoolManagement");
    const poolManagement = await PoolManagement.deploy(joyTokenAddress);
    await poolManagement.deployed();
    console.log("PoolManagement deployed to:", poolManagement.address);

    // Deploying UserContribution
    const UserContribution = await hre.ethers.getContractFactory("UserContribution");
    const userContribution = await UserContribution.deploy(poolManagement.address);
    await userContribution.deployed();
    console.log("UserContribution deployed to:", userContribution.address);

    // Deploying PoolContributions
    const PoolContributions = await hre.ethers.getContractFactory("PoolContributions");
    const poolContributions = await PoolContributions.deploy();
    await poolContributions.deployed();
    console.log("PoolContributions deployed to:", poolContributions.address);

    // Deploying PoolDeployer
    const PoolDeployer = await hre.ethers.getContractFactory("PoolDeployer");
    const poolDeployer = await PoolDeployer.deploy();
    await poolDeployer.deployed();
    console.log("PoolDeployer deployed to:", poolDeployer.address);

    // Deploying PoolCompletion
    const PoolCompletion = await hre.ethers.getContractFactory("PoolCompletion");
    const poolCompletion = await PoolCompletion.deploy(poolManagement.address, userContribution.address, poolContributions.address, poolDeployer.address);
    await poolCompletion.deployed();
    console.log("PoolCompletion deployed to:", poolCompletion.address);

    // Setting poolCompletionAddress in UserContribution
    await userContribution.setPoolCompletionAddress(poolCompletion.address);
    console.log("poolCompletionAddress set in UserContribution");

    // Saving deployed contract addresses
    const data = {
      PoolManagement: poolManagement.address,
      UserContribution: userContribution.address,
      PoolContributions: poolContributions.address,
      PoolDeployer: poolDeployer.address,
      PoolCompletion: poolCompletion.address,
    };

    fs.writeFileSync('deployedAddresses.json', JSON.stringify(data));
    console.log('Contract addresses saved to deployedAddresses.json');

  } catch (error) {
    console.error('An error occurred!', error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
