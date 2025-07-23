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
    event LicenseRenewed(string licenseNo, uint256 newExpiryDate);
    event LicenseStatusUpdated(string indexed licenseNo, Enum.LicenseStatus newStatus);

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

    /**
     * @dev Updates all licenses with point > 0 and status == ACTIVE to point = 12
     */
    function resetPointsToMax() external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        uint256 tokenCount = ls.tokenCount;

        for (uint256 i = 0; i < tokenCount;) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            DriverLicenseStruct.DriverLicense storage license = ls.licenses[licenseNo];
            if (license.point > 0 && license.status == Enum.LicenseStatus.ACTIVE) {
                license.point = 12;
                emit PointsUpdated(licenseNo, 12);
            }
            unchecked {
                ++i;
            }
        }

        Loggers.logSuccess("All eligible licenses updated to 12 points");
    }

    /**
     * @dev Renews a license by extending expiryDate based on licenseType and bonusTime
     */
    function renewLicense(string calldata _licenseNo) external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(_licenseNo);
        require(bytes(ls.licenses[_licenseNo].licenseNo).length != 0, "License not found");

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[_licenseNo];
        require(license.status == Enum.LicenseStatus.ACTIVE, "License is not active");
        require(licenseTypeExists[license.licenseType], "No renewal rule for this license type");

        OffenceAndRenewalStruct.RenewLicense memory rule = renewRules[license.licenseType];
        require(rule.status == Enum.Status.ACTIVE, "Renewal rule is not active");

        // Renewal expiryDate: bonusTime * 1 year (1 year = 365 days = 31536000 seconds)
        uint256 oneYear = 31536000;
        uint256 newExpiryDate = license.expiryDate + (rule.bonusTime * oneYear);
        license.expiryDate = newExpiryDate;

        // Update validBalance
        bool wasValid = !DateTime.isExpired(license.expiryDate);
        bool isValid = !DateTime.isExpired(newExpiryDate);
        if (!wasValid && isValid) {
            ls.validBalance[license.holderAddress]++;
        }

        Loggers.logSuccess("License renewed successfully");
        emit LicenseRenewed(_licenseNo, newExpiryDate);
    }

    /**
     * @dev Updates status of all licenses based on expiryDate
     */
    function updateAllLicenseStatuses() external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256 tokenCount = ls.tokenCount;
        uint256 oneYear = 31536000;
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i < tokenCount;) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            DriverLicenseStruct.DriverLicense storage license = ls.licenses[licenseNo];

            // checked if expiryDate < today => SUSPENDED
            if (DateTime.isExpired(license.expiryDate) && license.status != Enum.LicenseStatus.REVOKED) {
                if (license.status == Enum.LicenseStatus.ACTIVE) {
                    ls.validBalance[license.holderAddress]--;
                }
                license.status = Enum.LicenseStatus.SUSPENDED;
                emit LicenseStatusUpdated(licenseNo, Enum.LicenseStatus.SUSPENDED);
            }
            // checked if expiryDate > 1 year && status == SUSPENDED => REVOKED
            else if (license.status == Enum.LicenseStatus.SUSPENDED && license.expiryDate + oneYear < currentTime) {
                license.status = Enum.LicenseStatus.REVOKED;
                emit LicenseStatusUpdated(licenseNo, Enum.LicenseStatus.REVOKED);
            }

            unchecked {
                ++i;
            }
        }

        Loggers.logSuccess("All license statuses updated");
    }

    /**
     * @dev Retrieves all offenses for a license (not implemented as no offense storage is provided)
     */
    function getErrorIdByLicenseNo(string calldata _licenseNo)
        external
        view
        override
        returns (OffenceAndRenewalStruct.Offence[] memory)
    {
        Validator.checkString(_licenseNo);
        LibStorage.OffenseRenewalStorage storage ors = LibStorage.offenseRenewalStorage();
        return ors.licenseToOffences[_licenseNo];
    }
}
