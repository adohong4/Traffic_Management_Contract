// scripts/functions/driverLicense.js
// npx hardhat run scripts/functions/driverLicense.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  const DL_ADDR = "0x59b670e9fA9D0A427751Af201D676719a970857b";

  const DriverLicense = await hre.ethers.getContractFactory("DriverLicense");
  const dl = await DriverLicense.attach(DL_ADDR);

  // 1. issueLicense
  console.log("\n1. Issue a new license...");
  const input = {
    licenseNo: "DL123456",
    holderAddress: deployer.address,
    holderId: "079123456789",
    name: "Nguyen Van A",
    licenseType: "A1",
    issueDate: Math.floor(Date.now() / 1000),
    expiryDate: Math.floor(Date.now() / 1000) + 31536000 * 5, // 5 năm
    authorityId: "CSGT-HCM-001",
    point: 12
  };

  try {
    const tx = await dl.issueLicense(input);
    await tx.wait();
    console.log("Issue license success! LicenseNo:", input.licenseNo);
  } catch (e) {
    console.error("issueLicense failed:", e.shortMessage || e.message);
  }

  // 2. getLicense
  console.log("\n2. Get license DL123456...");
  try {
    const license = await dl.getLicense("DL123456");
    console.log("License:", {
      tokenId: Number(license.tokenId),
      holder: license.holderAddress,
      type: license.licenseType,
      point: Number(license.point),
      status: Number(license.status),
      expiry: Number(license.expiryDate)
    });
  } catch (e) {
    console.error("getLicense failed:", e.shortMessage || e.message);
  }

  // 3. getLicensesByHolder
  console.log("\n3. Get licenses of deployer...");
  const licenses = await dl.getLicensesByHolder(deployer.address);
  console.log("Licenses count:", licenses.length);
  if (licenses.length > 0) {
    console.log("First license:", licenses[0].licenseNo);
  }

  // 4. updateLicense (example)
  console.log("\n4. Update license...");
  const updateInput = {
    licenseNo: "DL123456",
    holderAddress: deployer.address,
    name: "Nguyen Van A Updated",
    licenseType: "A1",
    expiryDate: Math.floor(Date.now() / 1000) + 31536000 * 10, // +10 năm
    status: 0, // ACTIVE
    point: 10
  };

  try {
    const tx = await dl.updateLicense(updateInput);
    await tx.wait();
    console.log("Update success!");
  } catch (e) {
    console.error("updateLicense failed:", e.shortMessage || e.message);
  }

  // 5. revokeLicense
  console.log("\n5. Revoke license...");
  try {
    const tx = await dl.revokeLicense("DL123456");
    await tx.wait();
    console.log("Revoke success!");
  } catch (e) {
    console.error("revokeLicense failed:", e.shortMessage || e.message);
  }

  // 6. Check IERC4671
  console.log("\n6. IERC4671 checks...");
  console.log("Emitted count:", Number(await dl.emittedCount()));
  console.log("Holders count:", Number(await dl.holdersCount()));
  console.log("Balance of deployer:", Number(await dl.balanceOf(deployer.address)));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });