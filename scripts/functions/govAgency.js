//npx hardhat run scripts/functions/govAgency.js --network localhost
// scripts/functions/govAgency.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  // Địa chỉ Proxy của TrafficController (sau khi deploy và set đầy đủ)
  const CONTROLLER_PROXY = "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c"; // thay bằng địa chỉ thật

  // Attach TrafficController để lấy địa chỉ GovAgency proxy
  const controller = await hre.ethers.getContractAt("TrafficController", CONTROLLER_PROXY);
  const GOV_PROXY = await controller.govAgency();
  console.log("GovAgency Proxy address from Controller:", GOV_PROXY);

  if (GOV_PROXY === "0x0000000000000000000000000000000000000000") {
    throw new Error("GovAgency not registered in TrafficController");
  }

  // Attach GovAgency qua Proxy address
  const GovAgency = await hre.ethers.getContractFactory("GovAgency");
  const gov = await GovAgency.attach(GOV_PROXY);

  // Grant GOV_AGENCY_ROLE nếu chưa có
  const role = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("GOV_AGENCY_ROLE"));
  try {
    const hasRole = await gov.hasRole(role, deployer.address);
    if (!hasRole) {
      const txGrant = await gov.grantRole(role, deployer.address);
      await txGrant.wait();
      console.log("Granted GOV_AGENCY_ROLE to deployer");
    } else {
      console.log("Deployer already has GOV_AGENCY_ROLE");
    }
  } catch (e) {
    console.log("Grant role skipped or error:", e.shortMessage || e.message);
  }

  // Input cho issueAgency
  const input = {
    addressGovAgency: deployer.address,
    agencyId: "CSGT-HCM-001",
    name: "Cảnh sát Giao thông TP.HCM",
    location: "Quận 1, TP. Hồ Chí Minh"
  };

  // Gọi issueAgency
  console.log("Calling issueAgency...");
  try {
    const tx = await gov.issueAgency(input);
    const receipt = await tx.wait();
    console.log("Issued agency successfully! Tx hash:", receipt.hash);
  } catch (e) {
    console.error("issueAgency failed:", e.shortMessage || e.reason || e.message);
  }

  // Gọi getAgency để kiểm tra
  console.log("\nGetting agency details...");
  try {
    const agency = await gov.getAgency("CSGT-HCM-001");
    console.log("Agency details:");
    console.log("  - Address:", agency.addressGovAgency);
    console.log("  - ID:", agency.agencyId);
    console.log("  - Name:", agency.name);
    console.log("  - Location:", agency.location);
    console.log("  - Role:", agency.role);
    console.log("  - Status:", Number(agency.status)); // 0 = ACTIVE
  } catch (e) {
    console.error("getAgency failed:", e.shortMessage || e.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });