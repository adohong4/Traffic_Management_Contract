//npx hardhat run scripts/deploys/deploy-offence-and-renewal.js --network localhost
const { ethers, upgrades } = require("hardhat");

async function main() {
  const OffenceAndRenewal = await ethers.getContractFactory("OffenceAndRenewal");

  const proxy = await upgrades.deployProxy(OffenceAndRenewal, ["0xd7e05D8de832bc229BA6787E882bF83C2171774b"], { initializer: "initialize", kind: "uups" });
  await proxy.deployed();

  const proxyAddr = await proxy.address;
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("OffenceAndRenewal Proxy:", proxyAddr);
  console.log("Implementation:", implAddr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});