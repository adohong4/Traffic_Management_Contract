const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("GovAgency Functions", function () {
  let deployer, gov;

  before(async function () {
    ({ deployer, gov } = await deployFullSystem());
  });

  it("issues agency successfully", async function () {
    const input = {
      addressGovAgency: deployer.address,
      agencyId: "CSGT-HCM-001",
      name: "Cảnh sát Giao thông TP.HCM",
      location: "Quận 1, TP. Hồ Chí Minh"
    };

    await expect(gov.issueAgency(input))
      .to.emit(gov, "AgencyIssued")
      .withArgs(deployer.address, "CSGT-HCM-001", (await ethers.provider.getBlock("latest")).then(b => b.timestamp));

    const agency = await gov.getAgency("CSGT-HCM-001");
    expect(agency.name).to.equal("Cảnh sát Giao thông TP.HCM");
    expect(Number(agency.status)).to.equal(0); // ACTIVE
  });

  it("reverts when agency already exists", async function () {
    const input = {
      addressGovAgency: deployer.address,
      agencyId: "CSGT-HCM-001",
      name: "Cảnh sát Giao thông TP.HCM",
      location: "Quận 1, TP. Hồ Chí Minh"
    };

    await expect(gov.issueAgency(input)).to.be.revertedWithCustomError(gov, "AlreadyExists");
  });
});