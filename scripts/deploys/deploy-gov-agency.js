//npx hardhat run scripts/deploys/deploy-gov-agency.js --network localhost
const { ethers, upgrades } = require("hardhat");

async function main() {
  const GovAgency = await ethers.getContractFactory("GovAgency");

  const proxy = await upgrades.deployProxy(GovAgency, ["0xd7e05D8de832bc229BA6787E882bF83C2171774b"], { initializer: "initialize", kind: "uups" });
  await proxy.deployed();

  const proxyAddr = await proxy.address;
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("GovAgency Proxy:", proxyAddr);
  console.log("Implementation:", implAddr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});