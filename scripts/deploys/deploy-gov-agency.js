//npx hardhat run scripts/deploys/deploy-gov-agency.js --network localhost
const { ethers, upgrades } = require("hardhat");

async function main() {
  const GovAgency = await ethers.getContractFactory("GovAgency");

  const proxy = await upgrades.deployProxy(GovAgency, ["0x3Aa5ebB10DC797CAC828524e59A333d0A371443c"], { initializer: "initialize", kind: "uups" });
  await proxy.waitForDeployment();

  const proxyAddr = await proxy.getAddress();
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("GovAgency Proxy:", proxyAddr);
  console.log("Implementation:", implAddr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});