// scripts/functions/driverLicense.js
// npx hardhat run scripts/functions/driverLicense.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account (deployer):", deployer.address);

  // change to your deployed contract address
  const CONTRACT_ADDR = "0x610178dA211FEF7D417bC0e6FeD39F05609AD788"; 

  const OffenceRenewal = await hre.ethers.getContractFactory("OffenceAndRenewal");
  const contract = await OffenceRenewal.attach(CONTRACT_ADDR);

  // 1. addRenewRule
  console.log("\n1. Add renew rule...");
  try {
    const tx = await contract.addRenewRule(
      "A1",               // licenseType
      2,                  // bonusTime (years)
      "Bằng A1 - Gia hạn 2 năm nếu không vi phạm"
    );
    await tx.wait();
    console.log("Add renew rule A1 success!");
  } catch (e) {
    console.error("addRenewRule failed:", e.shortMessage || e.message);
  }

  // 2. getAllRenewRules
  console.log("\n2. Get all renew rules...");
  const rules = await contract.getAllRenewRules();
  console.log("Renew rules:", rules.map(r => ({
    type: r.licenseType,
    bonus: Number(r.bonusTime),
    desc: r.description,
    status: Number(r.status)
  })));

  // 3. getRenewRule
  console.log("\n3. Get renew rule A1...");
  try {
    const rule = await contract.getRenewRule("A1");
    console.log("Rule A1:", {
      bonus: Number(rule.bonusTime),
      desc: rule.description,
      status: Number(rule.status)
    });
  } catch (e) {
    console.error("getRenewRule failed:", e.shortMessage || e.message);
  }

  // 4. renewLicense (needs a license to exist)
  // If license does not exist → will revert "License not found"
  console.log("\n4. Renew license (ví dụ licenseNo: 'DL123456')...");
  try {
    const txRenew = await contract.renewLicense("DL123456"); 
    await txRenew.wait();
    console.log("Renew success!");
  } catch (e) {
    console.error("renewLicense failed (có thể chưa có license):", e.shortMessage || e.message);
  }

  // 5. deductPoint (needs a license to exist and be active)
  console.log("\n5. Deduct point...");
  const offence = {
    errorId: "SPEED-001",
    point: 3,
    description: "Vượt tốc độ 20km/h",
    timestamp: Math.floor(Date.now() / 1000),
    location: "Quốc lộ 1A"
  };
  try {
    const txDeduct = await contract.deductPoint("DL123456", offence); 
    await txDeduct.wait();
    console.log("Deduct point success!");
  } catch (e) {
    console.error("deductPoint failed:", e.shortMessage || e.message);
  }

  // 6. resetPointsToMax
  console.log("\n6. Reset points to max...");
  try {
    const txReset = await contract.resetPointsToMax();
    await txReset.wait();
    console.log("Reset points success!");
  } catch (e) {
    console.error("resetPointsToMax failed:", e.shortMessage || e.message);
  }

  // 7. updateAllLicenseStatuses
  console.log("\n7. Update all license statuses...");
  try {
    const txUpdate = await contract.updateAllLicenseStatuses();
    await txUpdate.wait();
    console.log("Update statuses success!");
  } catch (e) {
    console.error("updateAllLicenseStatuses failed:", e.shortMessage || e.message);
  }

  // 8. revokeRenewRule
  console.log("\n8. Revoke renew rule A1...");
  try {
    const txRevoke = await contract.revokeRenewRule("A1");
    await txRevoke.wait();
    console.log("Revoke renew rule success!");
  } catch (e) {
    console.error("revokeRenewRule failed:", e.shortMessage || e.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });