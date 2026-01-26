const hre = require("hardhat");

async function main() {
  const DriverLicense = await hre.ethers.getContractFactory("DriverLicense");
  const dl = await DriverLicense.deploy();
  await dl.waitForDeployment();
  console.log("DriverLicense:", await dl.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});