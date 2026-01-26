//npx hardhat run scripts/functions/govAgency.js --network localhost
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  const GOV_ADDR = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"; 

  const GovAgency = await hre.ethers.getContractFactory("GovAgency");
  const gov = await GovAgency.attach(GOV_ADDR);

  // Grant GOV_AGENCY_ROLE cho deployer
  const role = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("GOV_AGENCY_ROLE"));
  try {
    const txGrant = await gov.grantRole(role, deployer.address);
    await txGrant.wait();
    console.log("Granted GOV_AGENCY_ROLE to deployer");
  } catch (e) {
    console.log("Role already granted or error:", e.shortMessage || e.message);
  }

  const input = {
    addressGovAgency: deployer.address,      
    agencyId: "CSGT-HCM-001",
    name: "Cảnh sát Giao thông TP.HCM",
    location: "Quận 1, TP. Hồ Chí Minh"
  };

  // function issueAgency
  const tx = await gov.issueAgency(input);
  const receipt = await tx.wait();
  console.log("Issued agency successfully! Tx hash:", receipt.hash);

  // function getAgency
  const agency = await gov.getAgency("CSGT-HCM-001");
  console.log("Agency details:");
  console.log("  - Address:", agency.addressGovAgency);
  console.log("  - ID:", agency.agencyId);
  console.log("  - Name:", agency.name);
  console.log("  - Location:", agency.location);
  console.log("  - Role:", agency.role);
  console.log("  - Status:", Number(agency.status)); // 0 = ACTIVE
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });