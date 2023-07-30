const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const gasPrice = ethers.utils.parseUnits("20", "gwei"); // Set gas price to 20 Gwei (or adjust as needed)
  
  const foggyBankFactory = await hre.ethers.getContractFactory("FoggyBank");
  const foggyBank = await foggyBankFactory.deploy({ gasPrice });
  
  await foggyBank.deployed();
  console.log("foggyBank deployed to:", foggyBank.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
