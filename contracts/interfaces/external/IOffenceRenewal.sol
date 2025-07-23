// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../entities/structs/OffenceAndRenewal.sol";

/**
 * @title IOffenceRenewal
 * @dev Interface for managing driver license offenses and renewal rules.
 */
interface IOffenceRenewal {
    // Events
    event AddRenewRule(string indexed _licenseType, uint256 _bonusTime);
    event RevokeRenewRule(string indexed _licenseType);
    event PointsUpdated(string licenseNo, int256 newPoints);
    event LicenseRenewed(string licenseNo, uint256 newExpiryDate);
    event LicenseStatusUpdated(string indexed licenseNo, Enum.LicenseStatus newStatus);

    /**
     * @notice Adds a renewal rule for a specific license type.
     * @param _licenseType The type of driver license (e.g., A1, B2).
     * @param _bonusTime Additional time (in seconds) to be added upon renewal.
     * @param _description Description of the renewal rule.
     */
    function addRenewRule(string memory _licenseType, uint256 _bonusTime, string memory _description) external;

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
    function revokeRenewRule(string memory _licenseType) external;

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

    /**
     * @notice Resets points to 12 for all licenses with point > 0 and status == ACTIVE.
     */
    function resetPointsToMax() external;

    /**
     * @notice Renews a license by extending expiryDate based on licenseType and bonusTime.
     * @param _licenseNo The license number to renew.
     */
    function renewLicense(string memory _licenseNo) external;

    /**
     * @notice Updates status of all licenses based on expiryDate.
     */
    function updateAllLicenseStatuses() external;
}
