const { expect } = require("chai");
const { deployFullSystem } = require("../fixtures/setup");

describe("VehicleRegistration Functions", function () {
  let deployer, vreg;

  before(async function () {
    ({ deployer, vreg } = await deployFullSystem());
  });

  it("registers vehicle successfully", async function () {
    const input = {
      addressUser: deployer.address,
      identityNo: "079123456789",
      vehicleModel: "Honda Wave RSX 110",
      chassisNo: "CHAS1234567890ABC",
      vehiclePlateNo: "51A-999.99",
      colorPlate: 1
    };

    await expect(vreg.registerVehicleRegistration(input))
      .to.emit(vreg, "VehicleRegistrationIssued")
      .withArgs("51A-999.99", deployer.address, 1);

    const vehicles = await vreg.getVehicleByAddressUser(deployer.address);
    expect(vehicles.length).to.equal(1);
  });

  it("reverts when plate already exists", async function () {
    const input = {
      addressUser: deployer.address,
      identityNo: "079123456789",
      vehicleModel: "Honda Wave RSX 110",
      chassisNo: "CHAS1234567890ABC",
      vehiclePlateNo: "51A-999.99",
      colorPlate: 1
    };

    await expect(vreg.registerVehicleRegistration(input)).to.be.revertedWithCustomError(vreg, "AlreadyExists");
  });
});