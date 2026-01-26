// scripts/functions/vehicleRegistration.js
// npx hardhat run scripts/functions/vehicleRegistration.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account (deployer):", deployer.address);

  // address contract
  const VEHICLE_ADDR = "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853";

  const VehicleReg = await hre.ethers.getContractFactory("VehicleRegistration");
  const vehicle = await VehicleReg.attach(VEHICLE_ADDR);

  // 1. registerVehicleRegistration 
  console.log("\n1. Register a vehicle...");
  const regInput = {
    addressUser: deployer.address,                // chủ xe
    identityNo: "079123456789",
    vehicleModel: "Honda Wave RSX 110",
    chassisNo: "CHAS1234567890ABC",
    vehiclePlateNo: "51A-999.99",
    colorPlate: 1  // ví dụ: 1 = trắng, tùy enum của bạn
  };

  try {
    const txReg = await vehicle.registerVehicleRegistration(regInput);
    const receiptReg = await txReg.wait();
    console.log("Register success! Tx:", receiptReg.hash);
  } catch (e) {
    console.error("Register failed:", e.shortMessage || e.message);
  }

  // 2. getVehicleByAddressUser
  console.log("\n2. Get vehicles of deployer...");
  const vehicles = await vehicle.getVehicleByAddressUser(deployer.address);
  console.log("Vehicles found:", vehicles.length);
  if (vehicles.length > 0) {
    console.log("First vehicle:", {
      plate: vehicles[0].vehiclePlateNo,
      model: vehicles[0].vehicleModel,
      status: Number(vehicles[0].status),
      owner: vehicles[0].addressUser
    });
  }

  // 3. getAllVehicleRegistrations
  console.log("\n3. Get all registrations...");
  const allRegs = await vehicle.getAllVehicleRegistrations();
  console.log("Total registrations:", allRegs.length);

  // 4. updateVehicleRegistration (example: change owner)
  console.log("\n4. Update vehicle (change owner)...");
  const updateInput = {
    identityNo: "079123456789-UPDATED",
    addressUser: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"  // account #1 
  };

  try {
    const txUpdate = await vehicle.updateVehicleRegistration("51A-999.99", updateInput);
    await txUpdate.wait();
    console.log("Update success!");
  } catch (e) {
    console.error("Update failed:", e.shortMessage || e.message);
  }

  // 5. RevokeVehicleRegistration
  console.log("\n5. Revoke vehicle...");
  try {
    const txRevoke = await vehicle.RevokeVehicleRegistration("51A-999.99");
    await txRevoke.wait();
    console.log("Revoke success!");
  } catch (e) {
    console.error("Revoke failed:", e.shortMessage || e.message);
  }

  // 6. Check IERC4671 functions
  console.log("\n6. Check IERC4671...");
  const emitted = await vehicle.emittedCount();
  console.log("Emitted count:", Number(emitted));

  const holders = await vehicle.holdersCount();
  console.log("Holders count:", Number(holders));

  const isValid = await vehicle.isValid(1); // tokenId 1 nếu đã issue
  console.log("Token 1 valid?", isValid);

  const balance = await vehicle.balanceOf(deployer.address);
  console.log("Balance of deployer:", Number(balance));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });