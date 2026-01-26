const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("OffenceAndRenewal Functions", function () {
  let deployer, offence;

  before(async function () {
    ({ deployer, offence } = await deployFullSystem());
  });

  it("adds renew rule successfully", async function () {
    await expect(offence.addRenewRule("A1", 2, "Gia hạn 2 năm"))
      .to.emit(offence, "AddRenewRule")
      .withArgs("A1", 2);

    const rules = await offence.getAllRenewRules();
    expect(rules.length).to.equal(1);
  });

  it("reverts when renew rule already active", async function () {
    await expect(offence.addRenewRule("A1", 3, "Gia hạn 3 năm"))
      .to.be.revertedWith("Renew rule already ACTIVE");
  });
});