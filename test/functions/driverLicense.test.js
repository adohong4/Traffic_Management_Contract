const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("DriverLicense Functions", function () {
  let deployer, dl;

  before(async function () {
    ({ deployer, dl } = await deployFullSystem());
  });

  it("issues license successfully", async function () {
    const input = {
      licenseNo: "DL123456",
      holderAddress: deployer.address,
      holderId: "079123456789",
      name: "Nguyen Van A",
      licenseType: "A1",
      issueDate: Math.floor(Date.now() / 1000),
      expiryDate: Math.floor(Date.now() / 1000) + 31536000 * 5,
      authorityId: "CSGT-HCM-001",
      point: 12
    };

    await expect(dl.issueLicense(input))
      .to.emit(dl, "LicenseIssued")
      .withArgs("DL123456", deployer.address, input.issueDate);

    const license = await dl.getLicense("DL123456");
    expect(license.licenseNo).to.equal("DL123456");
    expect(license.point.toNumber()).to.equal(12); // ethers v5 trả về BigNumber
  });

  it("reverts when license already exists", async function () {
    const input = {
      licenseNo: "DL123456",
      holderAddress: deployer.address,
      holderId: "079123456789",
      name: "Nguyen Van A",
      licenseType: "A1",
      issueDate: Math.floor(Date.now() / 1000),
      expiryDate: Math.floor(Date.now() / 1000) + 31536000 * 5,
      authorityId: "CSGT-HCM-001",
      point: 12
    };

    await expect(dl.issueLicense(input)).to.be.revertedWithCustomError(dl, "AlreadyExists");
  });
});