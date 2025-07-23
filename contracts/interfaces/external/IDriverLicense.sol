// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";
import "../../entities/structs/DriverLicenseStruct.sol";

/**
 * @title IDriverLicense
 * @dev Interface for managing driver licenses, including issuance, updates, revocation, and retrieval.
 */
interface IDriverLicense {
    /**
     * @notice Issues a new driver license to a holder.
     * @param licenseNo Unique license number.
     * @param holderAddress Address of the license holder (owner).
     * @param holderId National ID or citizen ID of the holder.
     * @param name Full name of the license holder.
     * @param licenseType Type/category of the license (e.g., A1, B2).
     * @param issueDate Unix timestamp of license issuance.
     * @param expiryDate Unix timestamp of license expiration.
     * @param authorityId ID of the issuing government authority.
     * @param point Initial point value assigned to the license.
     */
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

    /**
     * @notice Updates license information such as type, name, status, expiry, and point.
     * @param licenseNo License number to update.
     * @param holderAddress New holder address (if changed).
     * @param name Updated full name of the holder.
     * @param licenseType Updated license type/category.
     * @param expiryDate New expiry date of the license.
     * @param status Updated status of the license (ACTIVE, REVOKED, etc.).
     * @param point Updated point balance.
     */
    function updateLicense(
        string memory licenseNo,
        address holderAddress,
        string memory name,
        string memory licenseType,
        uint256 expiryDate,
        Enum.LicenseStatus status,
        uint256 point
    ) external;

    /**
     * @notice Revokes an active driver license, changing its status to REVOKED.
     * @param licenseNo License number to revoke.
     */
    function revokeLicense(string memory licenseNo) external;

    //function renewLicense(string memory licenseNo, uint256 newExpiryDate) external;

    /**
     * @notice Retrieves license details by license number.
     * @param licenseNo License number to query.
     * @return A struct containing full license information.
     */
    function getLicense(string memory licenseNo) external view returns (DriverLicenseStruct.DriverLicense memory);

    /**
     * @notice Returns all issued licenses stored on-chain.
     * @return An array of all DriverLicense structs.
     */
    function getAllLicenses() external view returns (DriverLicenseStruct.DriverLicense[] memory);

    /**
     * @notice Retrieves all licenses issued to a specific wallet address.
     * @param holderAddress Address of the license holder.
     * @return An array of licenses associated with the address.
     */
    function getLicensesByHolder(address holderAddress)
        external
        view
        returns (DriverLicenseStruct.DriverLicense[] memory);

    /**
     * @notice Returns the total number of licenses issued.
     * @return Total license count.
     */
    function getLicenseCount() external view returns (uint256);
}
