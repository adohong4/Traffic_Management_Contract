//npx hardhat run scripts/deploys/deploy-driver-license.js --network localhost
const hre = require("hardhat");

async function main() {
  const OffenceAndRenewal = await hre.ethers.getContractFactory("OffenceAndRenewal");
  const contract = await OffenceAndRenewal.deploy();
  await contract.waitForDeployment();
  console.log("OffenceAndRenewal deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});