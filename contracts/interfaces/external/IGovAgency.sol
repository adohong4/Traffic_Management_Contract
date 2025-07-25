// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";
import "../../entities/structs/GovAgencyStruct.sol";

interface IGovAgency {
    event AgencyIssued(address indexed authority, string indexed agencyId, uint256 timestamp);
    event UpdateAgency(address indexed authority, string indexed agencyId, uint256 timestamp);
    event RevokedAgency(address indexed authority, string indexed agencyId, uint256 timestamp);

    /**
     * @notice Issues a new government agency, creating a new record and storing the agency details.
     * @param input Struct containing all necessary information to issue an agency.
     */
    function issueAgency(GovAgencyStruct.AgencyInput calldata input) external;

    /**
     * @notice Updates an existing government agency, modifying its details and status.
     * @param input Struct containing updated information for the agency.
     */
    function updateAgency(string memory _agencyId, GovAgencyStruct.AgencyUpdateInput calldata input) external;

    /**
     * @notice Retrieves agency details by agency ID.
     * @param _agencyId Agency ID to query.
     * @return A struct containing full agency information.
     */
    function getAgency(string memory _agencyId) external view returns (GovAgencyStruct.GovAgency memory);

    /**
     * @notice Revokes an existing government agency, setting its status to REVOKED.
     * @param _agencyId The ID of the agency to revoke.
     */
    function revokeAgency(string calldata _agencyId) external;

    /**
     * @notice Retrieves all government agencies.
     * @return An array of structs containing information for all agencies.
     */
    function getAllAgencies() external view returns (GovAgencyStruct.GovAgency[] memory);
}
