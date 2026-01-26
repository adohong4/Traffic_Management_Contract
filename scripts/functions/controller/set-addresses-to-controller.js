// npx hardhat run scripts/functions/controller/set-addresses-to-controller.js --network localhost
const hre = require("hardhat");

async function main() {
  const CONTROLLER_PROXY = "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c";

  const controller = await hre.ethers.getContractAt("TrafficController", CONTROLLER_PROXY);

  // Thay địa chỉ proxy thực tế
  await controller.setDriverLicense("0x59b670e9fA9D0A427751Af201D676719a970857b");
  await controller.setGovAgency("0x09635F643e140090A9A8Dcd712eD6285858ceBef");
  await controller.setVehicleRegistration("0x4A679253410272dd5232B3Ff7cF5dbB88f295319");
  await controller.setOffenceAndRenewal("0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44");

  console.log("All proxies registered in TrafficController");
}

main().catch(console.error);