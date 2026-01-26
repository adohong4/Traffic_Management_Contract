// npx hardhat run scripts/functions/controller/read-controller-state.js --network localhost
const hre = require("hardhat");

async function main() {
  const CONTROLLER_PROXY = "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c";

  const controller = await hre.ethers.getContractAt(
    "TrafficController",
    CONTROLLER_PROXY
  );

  console.log("=== TrafficController State ===");

  // ------------------------------
  // getAllCoreContracts
  // ------------------------------
  const [
    govAgency,
    vehicleRegistration,
    offenceAndRenewal,
    driverLicense,
    paused
  ] = await controller.getAllCoreContracts();

  console.log("GovAgency:", govAgency);
  console.log("VehicleRegistration:", vehicleRegistration);
  console.log("OffenceAndRenewal:", offenceAndRenewal);
  console.log("DriverLicense:", driverLicense);
  console.log("Paused:", paused);

  console.log("\n=== isXXX checks ===");

  console.log(
    "isGovAgency:",
    await controller.isGovAgency(govAgency)
  );

  console.log(
    "isVehicleRegistration:",
    await controller.isVehicleRegistration(vehicleRegistration)
  );

  console.log(
    "isOffenceAndRenewal:",
    await controller.isOffenceAndRenewal(offenceAndRenewal)
  );

  console.log(
    "isDriverLicense:",
    await controller.isDriverLicense(driverLicense)
  );

  console.log(
    "\nPaused status (via isPaused):",
    await controller.isPaused()
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
