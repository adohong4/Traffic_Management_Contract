const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("Full System Deployment", function () {
  let deployer, controller, dl, gov, vreg, offence;

  before(async function () {
    ({ deployer, controller, dl, gov, vreg, offence } = await deployFullSystem());
  });

  it("deploys all contracts successfully", async function () {
    expect(await controller.govAgency()).to.equal(gov.address);
    expect(await controller.driverLicense()).to.equal(dl.address);
    expect(await controller.vehicleRegistration()).to.equal(vreg.address);
    expect(await controller.offenceAndRenewal()).to.equal(offence.address);
  });

  it("deployer has GOV_AGENCY_ROLE in all contracts", async function () {
    const role = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("GOV_AGENCY_ROLE"));
    expect(await gov.hasRole(role, deployer.address)).to.be.true;
    expect(await vreg.hasRole(role, deployer.address)).to.be.true;
    expect(await offence.hasRole(role, deployer.address)).to.be.true;
    expect(await dl.hasRole(role, deployer.address)).to.be.true;
  });
});