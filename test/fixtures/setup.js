const { ethers, upgrades } = require("hardhat");

async function deployFullSystem() {
  const [deployer] = await ethers.getSigners();

  // Deploy TrafficController proxy
  const TrafficController = await ethers.getContractFactory("TrafficController");
  const controllerProxy = await upgrades.deployProxy(TrafficController, [], { initializer: "initialize", kind: "uups" });
  await controllerProxy.waitForDeployment();

  // Deploy DriverLicense proxy
  const DriverLicense = await ethers.getContractFactory("DriverLicense");
  const dlProxy = await upgrades.deployProxy(DriverLicense, [await controllerProxy.getAddress()], { initializer: "initialize", kind: "uups" });
  await dlProxy.waitForDeployment();
  await controllerProxy.setDriverLicense(await dlProxy.getAddress());

  // Deploy GovAgency proxy
  const GovAgency = await ethers.getContractFactory("GovAgency");
  const govProxy = await upgrades.deployProxy(GovAgency, [await controllerProxy.getAddress()], { initializer: "initialize", kind: "uups" });
  await govProxy.waitForDeployment();
  await controllerProxy.setGovAgency(await govProxy.getAddress());

  // Deploy VehicleRegistration proxy
  const VehicleRegistration = await ethers.getContractFactory("VehicleRegistration");
  const vregProxy = await upgrades.deployProxy(VehicleRegistration, [await controllerProxy.getAddress()], { initializer: "initialize", kind: "uups" });
  await vregProxy.waitForDeployment();
  await controllerProxy.setVehicleRegistration(await vregProxy.getAddress());

  // Deploy OffenceAndRenewal proxy
  const OffenceAndRenewal = await ethers.getContractFactory("OffenceAndRenewal");
  const offenceProxy = await upgrades.deployProxy(OffenceAndRenewal, [await controllerProxy.getAddress()], { initializer: "initialize", kind: "uups" });
  await offenceProxy.waitForDeployment();
  await controllerProxy.setOffenceAndRenewal(await offenceProxy.getAddress());

  // Grant GOV_AGENCY_ROLE cho deployer ở tất cả proxy
  const govRole = ethers.keccak256(ethers.toUtf8Bytes("GOV_AGENCY_ROLE"));
  await govProxy.grantRole(govRole, deployer.address);
  await vregProxy.grantRole(govRole, deployer.address);
  await offenceProxy.grantRole(govRole, deployer.address);
  await dlProxy.grantRole(govRole, deployer.address);

  return { deployer, controllerProxy, dlProxy, govProxy, vregProxy, offenceProxy };
}

module.exports = { deployFullSystem };