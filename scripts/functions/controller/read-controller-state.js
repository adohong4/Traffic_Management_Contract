// npx hardhat run scripts/functions/controller/read-controller-state.js --network localhost
const { ethers } = require("hardhat");

async function main() {
  const CONTROLLER_PROXY = "0xd7e05D8de832bc229BA6787E882bF83C2171774b";

  const controller = await ethers.getContractAt(
    "TrafficController",
    CONTROLLER_PROXY
  );

  console.log("=== TrafficController State ===");

  // ------------------------------
  // getAllCoreContracts
  // ------------------------------
  const result = await controller.getAllCoreContracts();

  const govAgency = result[0];
  const vehicleRegistration = result[1];
  const offenceAndRenewal = result[2];
  const driverLicense = result[3];
  const paused = result[4];

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

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
