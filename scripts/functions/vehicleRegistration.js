// scripts/functions/vehicleRegistration.js
// npx hardhat run scripts/functions/vehicleRegistration.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  const VEHICLE_ADDR = "0x4A679253410272dd5232B3Ff7cF5dbB88f295319"; 

  const VehicleReg = await hre.ethers.getContractFactory("VehicleRegistration");
  const vehicle = await VehicleReg.attach(VEHICLE_ADDR);

  // 1. registerVehicleRegistration
  console.log("\n1. Register vehicle...");
  const regInput = {
    addressUser: deployer.address,
    identityNo: "079123456789",
    vehicleModel: "Honda Wave RSX 110",
    chassisNo: "CHAS1234567890ABC",
    vehiclePlateNo: "51A-999.99",
    colorPlate: 1
  };

  try {
    const tx = await vehicle.registerVehicleRegistration(regInput);
    await tx.wait();
    console.log("Register success! Plate:", regInput.vehiclePlateNo);
  } catch (e) {
    console.error("registerVehicleRegistration failed:", e.shortMessage || e.message);
  }

  // 2. getVehicleByAddressUser
  console.log("\n2. Get vehicles of deployer...");
  const vehicles = await vehicle.getVehicleByAddressUser(deployer.address);
  console.log("Vehicles count:", vehicles.length);
  if (vehicles.length > 0) {
    console.log("First:", vehicles[0].vehiclePlateNo, Number(vehicles[0].status));
  }

  // 3. getAllVehicleRegistrations
  console.log("\n3. Get all registrations...");
  const all = await vehicle.getAllVehicleRegistrations();
  console.log("Total:", all.length);

  // 4. updateVehicleRegistration
  console.log("\n4. Update vehicle...");
  const updateInput = {
    identityNo: "079123456789-UPDATED",
    addressUser: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" // account khác
  };
  try {
    const tx = await vehicle.updateVehicleRegistration("51A-999.99", updateInput);
    await tx.wait();
    console.log("Update success!");
  } catch (e) {
    console.error("updateVehicleRegistration failed:", e.shortMessage || e.message);
  }

  // 5. RevokeVehicleRegistration
  console.log("\n5. Revoke vehicle...");
  try {
    const tx = await vehicle.RevokeVehicleRegistration("51A-999.99");
    await tx.wait();
    console.log("Revoke success!");
  } catch (e) {
    console.error("Revoke failed:", e.shortMessage || e.message);
  }

  // 6. IERC4671 checks
  console.log("\n6. IERC4671...");
  console.log("Emitted count:", Number(await vehicle.emittedCount()));
  console.log("Holders count:", Number(await vehicle.holdersCount()));
  console.log("Balance of deployer:", Number(await vehicle.balanceOf(deployer.address)));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });