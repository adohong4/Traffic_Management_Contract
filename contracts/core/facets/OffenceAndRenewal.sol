// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./DriverLicenseFacet.sol";
import "../../interfaces/external/IOffenceRenewal.sol";
import "../../entities/structs/OffenceAndRenewal.sol";

abstract contract PenaltyAndRenewal is DriverLicenseFacet, IOffenceRenewal {
    mapping(string => bool) public licenseTypeExists;
    mapping(string => OffenceAndRenewalStruct.RenewLicense) public renewRules;
    string[] public licenseTypes;

    event AddRenewRule(string indexed _licenseType, uint256 _bonusTime);
    event RevokeRenewRule(string indexed _licenseType);
    event PointsUpdated(string licenseNo, int256 newPoints);

    function addRenewRule(string memory _licenseType, uint256 _bonusTime, string memory _description)
        external
        override
    {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));

        // Validate inputs
        Validator.checkString(_licenseType);
        Validator.checkNonZero(_bonusTime);
        Validator.checkString(_description);

        require(!licenseTypeExists[_licenseType], "License type already exists");

        // Create and store the renewal rule
        OffenceAndRenewalStruct.RenewLicense memory newRule = OffenceAndRenewalStruct.RenewLicense({
            licenseType: _licenseType,
            bonusTime: _bonusTime,
            description: _description,
            status: Enum.Status.ACTIVE
        });
        licenseTypeExists[_licenseType] = true;
        licenseTypes.push(_licenseType);

        // Log success
        Loggers.logSuccess("License issued successfully");

        // Emit event
        emit AddRenewRule(_licenseType, _bonusTime);
    }

    /**
     * @dev Retrieves all defined renewal rules
     */
    function getAllRenewRules() external view override returns (OffenceAndRenewalStruct.RenewLicense[] memory) {
        uint256 count = 0;
        uint256 len = licenseTypes.length;

        for (uint256 i = 0; i < len;) {
            if (renewRules[licenseTypes[i]].status == Enum.Status.ACTIVE) {
                count++;
            }
            unchecked {
                ++i;
            }
        }

        OffenceAndRenewalStruct.RenewLicense[] memory activeRules = new OffenceAndRenewalStruct.RenewLicense[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < len;) {
            string memory licenseType = licenseTypes[i];
            if (renewRules[licenseType].status == Enum.Status.ACTIVE) {
                activeRules[index] = renewRules[licenseType];
                index++;
            }
            unchecked {
                ++i;
            }
        }
        return activeRules;
    }

    /**
     * @dev Retrieves the renewal rule for a given license type
     */
    function getRenewRule(string calldata _licenseType)
        external
        view
        override
        returns (OffenceAndRenewalStruct.RenewLicense memory)
    {
        Validator.checkString(_licenseType);
        require(licenseTypeExists[_licenseType], "License type does not exist");
        return renewRules[_licenseType];
    }

    /**
     * @dev Revokes the renewal rule for a given license type
     */
    function revokeRenewRule(string calldata _licenseType) external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));

        Validator.checkString(_licenseType);
        require(licenseTypeExists[_licenseType], "License type does not exist");

        renewRules[_licenseType].status = Enum.Status.REVOKED;
        licenseTypeExists[_licenseType] = false;

        emit RevokeRenewRule(_licenseType);
    }

    /**
     * @dev Deducts points from a license based on an offense
     */
    function deductPoint(string calldata _licenseNo, OffenceAndRenewalStruct.Offence calldata _offence)
        external
        override
    {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(_licenseNo);
        Validator.checkString(_offence.errorId);
        Validator.checkPoints(uint256(_offence.point));

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[_licenseNo];
        require(license.status == Enum.LicenseStatus.ACTIVE, "License is not active");

        int256 newPoints = int256(license.point) - int256(_offence.point);
        license.point = newPoints > 0 ? uint256(newPoints) : 0;

        if (license.point == 0) {
            license.status = Enum.LicenseStatus.REVOKED;
        }

        // Log the offense
        Loggers.logSuccess("Point deducted successfully");

        emit PointsUpdated(_licenseNo, newPoints);
    }
}
