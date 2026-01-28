//npx hardhat run scripts/deploys/deploy-traffic-controller.js --network localhost
//npx hardhat run scripts/deploys/deploy-traffic-controller.js --network sepolia
const { ethers, upgrades } = require("hardhat");

async function main() {
  const TrafficController = await ethers.getContractFactory("TrafficController");

  const proxy = await upgrades.deployProxy(TrafficController, [], { initializer: "initialize", kind: "uups" });
  await proxy.deployed();

  const proxyAddr = await proxy.address;
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("TrafficController Proxy:", proxyAddr);
  console.log("Implementation:", implAddr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});