// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";
import "../../entities/structs/DriverLicenseStruct.sol";

/**
 * @title IDriverLicense
 * @dev Interface for driver license management
 */
interface IDriverLicense {
    function issueLicense(
        string memory licenseNo,
        address holderAddress,
        string memory holderId,
        string memory name,
        string memory licenseType,
        uint256 issueDate,
        uint256 expiryDate,
        string memory authorityId,
        uint256 point
    ) external;

    function updateLicense(
        string memory licenseNo,
        address holderAddress,
        string memory name,
        string memory licenseType,
        uint256 expiryDate,
        Enum.LicenseStatus status
    ) external;

    function renewLicense(string memory licenseNo, uint256 newExpiryDate) external;

    function revokeLicense(string memory licenseNo) external;

    function getLicense(string memory licenseNo) external view returns (DriverLicenseStruct.DriverLicense memory);

    function getAllLicenses() external view returns (DriverLicenseStruct.DriverLicense[] memory);

    function getLicensesByHolder(address holderAddress)
        external
        view
        returns (DriverLicenseStruct.DriverLicense[] memory);

    function getLicenseCount() external view returns (uint256);
}
