const hre = require("hardhat");

async function main() {
  const GovAgency = await hre.ethers.getContractFactory("GovAgency");
  const gov = await GovAgency.deploy();
  await gov.waitForDeployment();
  console.log("GovAgency:", await gov.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});