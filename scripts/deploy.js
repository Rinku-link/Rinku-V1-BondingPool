// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  // Deploy BLPToken contract
  const BlpTokenFactory = await hre.ethers.getContractFactory("BlpToken");
  const blpToken = await BlpTokenFactory.deploy();
  await blpToken.deployed();
  console.log("BLPToken contract deployed to:", blpToken.address);

  // Deploy MetaFactory contract
  const MetaFactoryFactory = await hre.ethers.getContractFactory("MetaFactory");
  const metaFactory = await MetaFactoryFactory.deploy(blpToken.address);
  await metaFactory.deployed();
  console.log("MetaFactory contract deployed to:", metaFactory.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
