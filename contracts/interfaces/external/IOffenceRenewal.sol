// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../entities/structs/OffenseAndRenewal.sol";

/**
 * @title IOffenceRenewal
 * @dev Interface for managing driver license offenses and renewal rules.
 */
interface IOffenceRenewal {
    /**
     * @notice Adds a renewal rule for a specific license type.
     * @param licenseType The type of driver license (e.g., A1, B2).
     * @param bonusTime Additional time (in seconds) to be added upon renewal.
     * @param description Description of the renewal rule.
     */
    function addRenewRule(string memory licenseType, uint256 bonusTime, string memory description) external;

    /**
     * @notice Retrieves all defined renewal rules.
     * @return An array of all existing RenewLicense rules.
     */
    function getAllRenewRules() external view returns (OffenceAndRenewalStruct.RenewLicense[] memory);

    /**
     * @notice Retrieves the renewal rule for a given license type.
     * @param _licenseType The license type to query.
     * @return The renewal rule associated with the license type.
     */
    function getRenewRule(string memory _licenseType)
        external
        view
        returns (OffenceAndRenewalStruct.RenewLicense memory);

    /**
     * @notice Revokes (removes) the renewal rule for a given license type.
     * @param _licenseType The license type whose rule should be revoked.
     */
    function RevokeRenewRule(string memory _licenseType) external;

    /**
     * @notice Defines a new type of offense.
     * @param errorId The identifier/code of the offense (e.g., "ERROR001").
     * @param point The number of points to be deducted (not negative).
     */
    function addOffence(string memory errorId, int256 point) external;

    /**
     * @notice Applies a recorded offense to a specific license and deducts points accordingly.
     * @param _licenseNo The license number to apply the offense to.
     * @param _offence The offense details (errorId and point deduction).
     */
    function deductPoint(string memory _licenseNo, OffenceAndRenewalStruct.Offence memory _offence) external;

    /**
     * @notice Retrieves all offenses recorded for a specific license.
     * @param _licenseNo The license number to query.
     * @return An array of offenses associated with the license.
     */
    function getErrorIdByLicenseNo(string memory _licenseNo)
        external
        view
        returns (OffenceAndRenewalStruct.Offence[] memory);
}
