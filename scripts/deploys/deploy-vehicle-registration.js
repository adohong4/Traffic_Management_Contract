// scripts/deploys/deploy-vehicle-registration.js
const hre = require("hardhat");

async function main() {
  const VehicleRegistration = await hre.ethers.getContractFactory("VehicleRegistration");
  const vreg = await VehicleRegistration.deploy();
  await vreg.waitForDeployment();
  console.log("VehicleRegistration deployed to:", await vreg.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});