const { ethers, upgrades } = require("hardhat");

async function deployFullSystem() {
  const [deployer] = await ethers.getSigners();

  // Deploy TrafficController proxy
  const TrafficController = await ethers.getContractFactory("TrafficController");
  const controllerProxy = await upgrades.deployProxy(
    TrafficController,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await controllerProxy.deployed(); // ethers v5 dùng .deployed()

  // Deploy DriverLicense proxy
  const DriverLicense = await ethers.getContractFactory("DriverLicense");
  const dlProxy = await upgrades.deployProxy(
    DriverLicense,
    [controllerProxy.address], // ethers v5 dùng .address thay vì getAddress()
    { initializer: "initialize", kind: "uups" }
  );
  await dlProxy.deployed();

  await controllerProxy.setDriverLicense(dlProxy.address);

  // Deploy GovAgency proxy
  const GovAgency = await ethers.getContractFactory("GovAgency");
  const govProxy = await upgrades.deployProxy(
    GovAgency,
    [controllerProxy.address],
    { initializer: "initialize", kind: "uups" }
  );
  await govProxy.deployed();

  await controllerProxy.setGovAgency(govProxy.address);

  // Deploy VehicleRegistration proxy
  const VehicleRegistration = await ethers.getContractFactory("VehicleRegistration");
  const vregProxy = await upgrades.deployProxy(
    VehicleRegistration,
    [controllerProxy.address],
    { initializer: "initialize", kind: "uups" }
  );
  await vregProxy.deployed();

  await controllerProxy.setVehicleRegistration(vregProxy.address);

  // Deploy OffenceAndRenewal proxy
  const OffenceAndRenewal = await ethers.getContractFactory("OffenceAndRenewal");
  const offenceProxy = await upgrades.deployProxy(
    OffenceAndRenewal,
    [controllerProxy.address],
    { initializer: "initialize", kind: "uups" }
  );
  await offenceProxy.deployed();

  await controllerProxy.setOffenceAndRenewal(offenceProxy.address);

  // Grant GOV_AGENCY_ROLE cho deployer ở tất cả proxy
  const govRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("GOV_AGENCY_ROLE"));
  await govProxy.grantRole(govRole, deployer.address);
  await vregProxy.grantRole(govRole, deployer.address);
  await offenceProxy.grantRole(govRole, deployer.address);
  await dlProxy.grantRole(govRole, deployer.address);

  return {
    deployer,
    controller: controllerProxy,   // đổi tên cho dễ đọc trong test
    dl: dlProxy,
    gov: govProxy,
    vreg: vregProxy,
    offence: offenceProxy,
  };
}

module.exports = { deployFullSystem };