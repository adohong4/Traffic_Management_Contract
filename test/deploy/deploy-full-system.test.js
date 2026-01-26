const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("Full System Deployment", function () {
  let deployer, controller, dl, gov, vreg, offence;

  before(async function () {
    ({ deployer, controller, dl, gov, vreg, offence } = await deployFullSystem());
  });

  it("deploys all contracts successfully", async function () {
    expect(await controller.govAgency()).to.equal(await gov.getAddress());
    expect(await controller.driverLicense()).to.equal(await dl.getAddress());
    expect(await controller.vehicleRegistration()).to.equal(await vreg.getAddress());
    expect(await controller.offenceAndRenewal()).to.equal(await offence.getAddress());
  });

  it("deployer has GOV_AGENCY_ROLE in all contracts", async function () {
    const role = ethers.keccak256(ethers.toUtf8Bytes("GOV_AGENCY_ROLE"));
    expect(await gov.hasRole(role, deployer.address)).to.be.true;
    expect(await vreg.hasRole(role, deployer.address)).to.be.true;
    expect(await offence.hasRole(role, deployer.address)).to.be.true;
    expect(await dl.hasRole(role, deployer.address)).to.be.true;
  });
});