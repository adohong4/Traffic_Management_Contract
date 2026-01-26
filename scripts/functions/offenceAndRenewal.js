// npx hardhat run scripts/functions/offenceAndRenewal.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  const OFFENCE_ADDR = "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44"; 

  const OffenceRenewal = await hre.ethers.getContractFactory("OffenceAndRenewal");
  const contract = await OffenceRenewal.attach(OFFENCE_ADDR);

  // 1. addRenewRule
  console.log("\n1. Add renew rule...");
  try {
    const tx = await contract.addRenewRule("A1", 2, "Bằng A1 - Gia hạn 2 năm nếu không vi phạm");
    await tx.wait();
    console.log("Add renew rule success!");
  } catch (e) {
    console.error("addRenewRule failed:", e.shortMessage || e.message);
  }

  // 2. getAllRenewRules
  console.log("\n2. Get all renew rules...");
  const rules = await contract.getAllRenewRules();
  console.log("Renew rules:", rules.map(r => ({
    type: r.licenseType,
    bonus: Number(r.bonusTime),
    status: Number(r.status)
  })));

  // 3. getRenewRule
  console.log("\n3. Get renew rule A1...");
  try {
    const rule = await contract.getRenewRule("A1");
    console.log("Rule A1:", { bonus: Number(rule.bonusTime), status: Number(rule.status) });
  } catch (e) {
    console.error("getRenewRule failed:", e.shortMessage || e.message);
  }

  // 4. deductPoint (cần license tồn tại trước)
  console.log("\n4. Deduct point...");
  const offence = {
    errorId: "SPEED-001",
    point: 3,
    description: "Vượt tốc độ",
    timestamp: Math.floor(Date.now() / 1000),
    location: "QL1A"
  };
  try {
    const tx = await contract.deductPoint("DL123456", offence); // thay licenseNo thật
    await tx.wait();
    console.log("Deduct point success!");
  } catch (e) {
    console.error("deductPoint failed:", e.shortMessage || e.message);
  }

  // 5. renewLicense (cần license tồn tại)
  console.log("\n5. Renew license...");
  try {
    const tx = await contract.renewLicense("DL123456"); // thay licenseNo thật
    await tx.wait();
    console.log("Renew success!");
  } catch (e) {
    console.error("renewLicense failed:", e.shortMessage || e.message);
  }

  // 6. resetPointsToMax
  console.log("\n6. Reset points to max...");
  try {
    const tx = await contract.resetPointsToMax();
    await tx.wait();
    console.log("Reset success!");
  } catch (e) {
    console.error("resetPointsToMax failed:", e.shortMessage || e.message);
  }

  // 7. updateAllLicenseStatuses
  console.log("\n7. Update all license statuses...");
  try {
    const tx = await contract.updateAllLicenseStatuses();
    await tx.wait();
    console.log("Update statuses success!");
  } catch (e) {
    console.error("updateAllLicenseStatuses failed:", e.shortMessage || e.message);
  }

  // 8. revokeRenewRule
  console.log("\n8. Revoke renew rule A1...");
  try {
    const tx = await contract.revokeRenewRule("A1");
    await tx.wait();
    console.log("Revoke success!");
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