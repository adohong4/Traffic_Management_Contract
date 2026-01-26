const hre = require("hardhat");

async function main() {
  const OffenceAndRenewal = await hre.ethers.getContractFactory("OffenceAndRenewal");
  const contract = await OffenceAndRenewal.deploy();
  await contract.waitForDeployment();
  console.log("OffenceAndRenewal:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});