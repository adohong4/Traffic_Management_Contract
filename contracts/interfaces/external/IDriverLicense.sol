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
     * @notice Issues a new driver license, creating a new NFT and storing the license details.
     * @param input Struct containing all necessary information to issue a license.
     */
    function issueLicense(DriverLicenseStruct.LicenseInput calldata input) external;

    /**
     * @notice Updates an existing driver license, modifying its details and status.
     * @param input Struct containing updated information for the license.
     */
    function updateLicense(DriverLicenseStruct.LicenseUpdateInput calldata input) external;

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
