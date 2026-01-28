// npx hardhat run scripts/functions/controller/set-addresses-to-controller.js --network localhost
const hre = require("hardhat");

async function main() {
  const CONTROLLER_PROXY = "0xd7e05D8de832bc229BA6787E882bF83C2171774b";

  const controller = await hre.ethers.getContractAt("TrafficController", CONTROLLER_PROXY);

  // Thay địa chỉ proxy thực tế
  const tx1 = await controller.setDriverLicense("0xFFB4B88f5881c911973bd8bEbBa58d54ADAe330a");
  await tx1.wait();
  const tx2 = await controller.setGovAgency("0x2853573Cf826D5488B6Da07F661A251D6F413DEb");
  await tx2.wait();
  const tx3 = await controller.setVehicleRegistration("0x34430483Ed96E3475E130d7E3e198E6d65458DEA");
  await tx3.wait();
  const tx4 = await controller.setOffenceAndRenewal("0xcf54c1Ca03fB2666E3fBACF969651CEC5C5125cF");
  await tx4.wait();
  console.log("All proxies registered in TrafficController");
}

main().catch(console.error);