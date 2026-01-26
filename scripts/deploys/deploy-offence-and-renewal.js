//npx hardhat run scripts/deploys/deploy-offence-and-renewal.js --network localhost
const { ethers, upgrades } = require("hardhat");

async function main() {
  const OffenceAndRenewal = await ethers.getContractFactory("OffenceAndRenewal");

  const proxy = await upgrades.deployProxy(OffenceAndRenewal, ["0x3Aa5ebB10DC797CAC828524e59A333d0A371443c"], { initializer: "initialize", kind: "uups" });
  await proxy.waitForDeployment();

  const proxyAddr = await proxy.getAddress();
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("OffenceAndRenewal Proxy:", proxyAddr);
  console.log("Implementation:", implAddr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});