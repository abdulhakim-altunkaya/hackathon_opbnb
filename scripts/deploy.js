
const hre = require("hardhat");

async function main() {
  const foggyBank = await hre.ethers.deployContract("FoggyBank", [], {});
  await foggyBank.waitForDeployment();
  console.log(`foggyBank deployed to ${foggyBank.target}`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
