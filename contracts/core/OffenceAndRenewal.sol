// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/external/IOffenceRenewal.sol";
import "../entities/structs/OffenceAndRenewal.sol";
import "../interfaces/ITrafficController.sol";
import "../libraries/LibRegistration.sol";
import "../libraries/LibStorage.sol";
import "../utils/Validator.sol";
import "../utils/DateTime.sol";
import "../utils/Loggers.sol";
import "../security/ReEntrancyGuard.sol";

contract OffenceAndRenewal is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IOffenceRenewal
{
    address public trafficController;

    bytes32 public constant GOV_AGENCY_ROLE = keccak256("GOV_AGENCY_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initializer: grant role
    function initialize(address _trafficController) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        trafficController = _trafficController;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOV_AGENCY_ROLE, msg.sender);
    }

    function addRenewRule(
        string calldata _licenseType,
        uint256 _bonusTime,
        string calldata _description
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        _validateRegistration();

        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        Validator.checkString(_licenseType);
        Validator.checkNonZero(_bonusTime);
        Validator.checkString(_description);

        require(
            !ors.licenseTypeExists[_licenseType] ||
                ors.renewRules[_licenseType].status != Enum.Status.ACTIVE,
            "Renew rule already ACTIVE"
        );

        ors.renewRules[_licenseType] = OffenceAndRenewalStruct.RenewLicense({
            licenseType: _licenseType,
            bonusTime: _bonusTime,
            description: _description,
            status: Enum.Status.ACTIVE
        });
        ors.licenseTypeExists[_licenseType] = true;

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

        Loggers.logSuccess("Renew rule added successfully");
        emit AddRenewRule(_licenseType, _bonusTime);
    }

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

    function revokeRenewRule(
        string calldata _licenseType
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        _validateRegistration();

        LibStorage.OffenseRenewalStorage storage ors = LibStorage
            .offenseRenewalStorage();

        Validator.checkString(_licenseType);
        require(
            ors.licenseTypeExists[_licenseType],
            "License type does not exist"
        );

        ors.renewRules[_licenseType].status = Enum.Status.REVOKED;
        ors.licenseTypeExists[_licenseType] = false;

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

    function deductPoint(
        string calldata _licenseNo,
        OffenceAndRenewalStruct.Offence calldata _offence
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        _validateRegistration();

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

        Loggers.logSuccess("Point deducted successfully");
        emit PointsUpdated(_licenseNo, newPoints);
    }

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

    function resetPointsToMax()
        external
        override
        nonReentrant
        onlyRole(GOV_AGENCY_ROLE)
    {
        _validateRegistration();

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

    function renewLicense(
        string calldata _licenseNo
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        _validateRegistration();

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

        uint256 oneYear = 31536000;
        uint256 newExpiryDate = license.expiryDate + (rule.bonusTime * oneYear);
        license.expiryDate = newExpiryDate;

        bool wasValid = !DateTime.isExpired(license.expiryDate);
        bool isValid = !DateTime.isExpired(newExpiryDate);
        if (!wasValid && isValid) {
            ls.validBalance[license.holderAddress]++;
        }

        Loggers.logSuccess("License renewed successfully");
        emit LicenseRenewed(_licenseNo, newExpiryDate);
    }

    function updateAllLicenseStatuses()
        external
        override
        nonReentrant
        onlyRole(GOV_AGENCY_ROLE)
    {
        _validateRegistration();

        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256 tokenCount = ls.tokenCount;
        uint256 oneYear = 31536000;
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i <= tokenCount; ) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            DriverLicenseStruct.DriverLicense storage license = ls.licenses[
                licenseNo
            ];

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
            } else if (
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

    // ------------------------------------------------------------------- //
    // --------------------------- Internal  ------------------------------//
    // ------------------------------------------------------------------- //

    /// @dev Override _authorizeUpgrade function to add authorization
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev Validate OffenceAndRenewal contract registration in TrafficController
    function _validateRegistration() internal view {
        LibRegistration.validate(
            trafficController,
            ITrafficController(trafficController).offenceAndRenewal
        );
    }
}
