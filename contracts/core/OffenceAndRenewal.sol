// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./DriverLicense.sol";
import "../interfaces/external/IOffenceRenewal.sol";
import "../entities/structs/OffenceAndRenewal.sol";

contract OffenceAndRenewal is DriverLicense, IOffenceRenewal {
    /**
     * @dev Adds a renewal rule for a specific license type
     */
    function addRenewRule(
        string calldata _licenseType,
        uint256 _bonusTime,
        string calldata _description
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        // Validate inputs
        Validator.checkString(_licenseType);
        Validator.checkNonZero(_bonusTime);
        Validator.checkString(_description);

        require(
            !ors.licenseTypeExists[_licenseType] ||
                ors.renewRules[_licenseType].status != Enum.Status.ACTIVE,
            "Renew rule for this license type is already ACTIVE"
        );

        ors.renewRules[_licenseType] = OffenceAndRenewalStruct.RenewLicense({
            licenseType: _licenseType,
            bonusTime: _bonusTime,
            description: _description,
            status: Enum.Status.ACTIVE
        });
        ors.licenseTypeExists[_licenseType] = true;

        // just add into licenseTypes if it does not exist
        bool exists = false;
        for (uint256 i = 0; i < ors.licenseTypes.length; ) {
            if (
                keccak256(bytes(ors.licenseTypes[i])) ==
                keccak256(bytes(_licenseType))
            ) {
                exists = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!exists) {
            ors.licenseTypes.push(_licenseType);
        }

        // Log success
        Loggers.logSuccess("Renew rule added successfully");

        // Emit event
        emit AddRenewRule(_licenseType, _bonusTime);
    }

    /**
     * @dev Retrieves all defined renewal rules
     */
    function getAllRenewRules()
        external
        view
        override
        returns (OffenceAndRenewalStruct.RenewLicense[] memory)
    {
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();
        uint256 len = ors.licenseTypes.length;
        uint256 count = 0;

        // Count rule active
        for (uint256 i = 0; i < len; ) {
            if (
                ors.renewRules[ors.licenseTypes[i]].status == Enum.Status.ACTIVE
            ) {
                count++;
            }
            unchecked {
                ++i;
            }
        }

        OffenceAndRenewalStruct.RenewLicense[]
            memory activeRules = new OffenceAndRenewalStruct.RenewLicense[](
                count
            );
        uint256 index = 0;
        for (uint256 i = 0; i < len; ) {
            string memory licenseType = ors.licenseTypes[i];
            if (ors.renewRules[licenseType].status == Enum.Status.ACTIVE) {
                activeRules[index] = ors.renewRules[licenseType];
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
    function getRenewRule(
        string calldata _licenseType
    )
        external
        view
        override
        returns (OffenceAndRenewalStruct.RenewLicense memory)
    {
        Validator.checkString(_licenseType);
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();
        require(
            ors.licenseTypeExists[_licenseType],
            "License type does not exist"
        );
        return ors.renewRules[_licenseType];
    }

    /**
     * @dev Revokes the renewal rule for a given license type
     */
    function revokeRenewRule(
        string calldata _licenseType
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        Validator.checkString(_licenseType);
        require(
            ors.licenseTypeExists[_licenseType],
            "License type does not exist"
        );

        ors.renewRules[_licenseType].status = Enum.Status.REVOKED;
        ors.licenseTypeExists[_licenseType] = false;

        // delete licenseType from ors.licenseTypes
        for (uint256 i = 0; i < ors.licenseTypes.length; ) {
            if (
                keccak256(bytes(ors.licenseTypes[i])) ==
                keccak256(bytes(_licenseType))
            ) {
                ors.licenseTypes[i] = ors.licenseTypes[
                    ors.licenseTypes.length - 1
                ];
                ors.licenseTypes.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        emit RevokeRenewRule(_licenseType);
    }

    /**
     * @dev Deducts points from a license based on an offense and stores the offense
     */
    function deductPoint(
        string calldata _licenseNo,
        OffenceAndRenewalStruct.Offence calldata _offence
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        Validator.checkString(_licenseNo);
        Validator.checkString(_offence.errorId);
        Validator.checkPoints(uint256(_offence.point));

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[
            _licenseNo
        ];
        require(
            license.status == Enum.LicenseStatus.ACTIVE,
            "License is not active"
        );

        ors.licenseToOffences[_licenseNo].push(_offence);

        int256 newPoints = int256(license.point) - int256(_offence.point);
        license.point = newPoints > 0 ? uint256(newPoints) : 0;

        if (license.point == 0) {
            license.status = Enum.LicenseStatus.SUSPENDED;
        }

        // Log success
        Loggers.logSuccess("Point deducted successfully");

        emit PointsUpdated(_licenseNo, newPoints);
    }

    /**
     * @dev Retrieves all offenses recorded for a specific license
     */
    function getErrorIdByLicenseNo(
        string calldata _licenseNo
    )
        external
        view
        override
        returns (OffenceAndRenewalStruct.Offence[] memory)
    {
        Validator.checkString(_licenseNo);
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();
        return ors.licenseToOffences[_licenseNo];
    }

    /**
     * @dev Updates all licenses with point > 0 and status == ACTIVE to point = 12
     */
    function resetPointsToMax()
        external
        override
        nonReentrant
        onlyRole(GOV_AGENCY_ROLE)
    {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256 tokenCount = ls.tokenCount;

        for (uint256 i = 0; i <= tokenCount; ) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            DriverLicenseStruct.DriverLicense storage license = ls.licenses[
                licenseNo
            ];
            if (
                license.point > 0 &&
                license.point < 12 &&
                license.status == Enum.LicenseStatus.ACTIVE
            ) {
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
    function renewLicense(
        string calldata _licenseNo
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        Validator.checkString(_licenseNo);
        require(
            bytes(ls.licenses[_licenseNo].licenseNo).length != 0,
            "License not found"
        );

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[
            _licenseNo
        ];
        require(
            license.status == Enum.LicenseStatus.ACTIVE,
            "License is not active"
        );
        require(
            ors.licenseTypeExists[license.licenseType],
            "No renewal rule for this license type"
        );

        OffenceAndRenewalStruct.RenewLicense memory rule = ors.renewRules[
            license.licenseType
        ];
        require(
            rule.status == Enum.Status.ACTIVE,
            "Renewal rule is not active"
        );

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
    function updateAllLicenseStatuses()
        external
        override
        nonReentrant
        onlyRole(GOV_AGENCY_ROLE)
    {
        //LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256 tokenCount = ls.tokenCount;
        uint256 oneYear = 31536000;
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i <= tokenCount; ) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            DriverLicenseStruct.DriverLicense storage license = ls.licenses[
                licenseNo
            ];

            // if expiryDate < today => SUSPENDED
            if (
                DateTime.isExpired(license.expiryDate) &&
                license.status != Enum.LicenseStatus.REVOKED
            ) {
                if (license.status == Enum.LicenseStatus.ACTIVE) {
                    ls.validBalance[license.holderAddress]--;
                }
                license.status = Enum.LicenseStatus.SUSPENDED;
                emit LicenseStatusUpdated(
                    licenseNo,
                    Enum.LicenseStatus.SUSPENDED
                );
            }
            // If expiryDate + 1 year < today and status == SUSPENDED => REVOKED
            else if (
                license.status == Enum.LicenseStatus.SUSPENDED &&
                license.expiryDate + oneYear < currentTime
            ) {
                license.status = Enum.LicenseStatus.REVOKED;
                emit LicenseStatusUpdated(
                    licenseNo,
                    Enum.LicenseStatus.REVOKED
                );
            }

            unchecked {
                ++i;
            }
        }

        Loggers.logSuccess("All license statuses updated");
    }
}
