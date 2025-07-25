// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Errors.sol";
import "../../constants/Enum.sol";
import "../../entities/structs/GovAgencyStruct.sol";
import "../../interfaces/external/IGovAgency.sol";
import "../../libraries/LibStorage.sol";
import "../../libraries/LibAccessControl.sol";
import "../../utils/Validator.sol";
import "../../utils/Loggers.sol";

/**
 * @title GovAgencyFacet
 * @dev Manages government agencies in the traffic management system
 */
contract GovAgencyFacet is IGovAgency {
    // AccessControl contract instance
    AccessControl private immutable accessControl;

    constructor(address _accessControl) {
        accessControl = AccessControl(_accessControl);
    }

    /**
     * @notice Issues a new government agency, creating a new record and storing the agency details.
     * @param input Struct containing all necessary information to issue an agency.
     */
    function issueAgency(GovAgencyStruct.AgencyInput calldata input) external override {
        LibAccessControl.enforceAdminOrGovAgency(accessControl);

        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.agencyId);
        Validator.checkString(input.name);
        Validator.checkString(input.location);

        if (bytes(gas.agencies[input.agencyId].agencyId).length != 0) revert Errors.AlreadyExists();

        // Store agency data
        gas.agencies[input.agencyId] = GovAgencyStruct.GovAgency({
            addressGovAgency: input.addressGovAgency,
            agencyId: input.agencyId,
            name: input.name,
            location: input.location,
            role: "GOV_AGENCY_ROLE",
            status: Enum.Status.ACTIVE
        });

        // Update mappings
        gas.addressToAgencyIds[input.addressGovAgency].push(input.agencyId);
        gas.agencyIds.push(input.agencyId);
        gas.agencyCount++;

        // Grant GOV_AGENCY_ROLE to the address
        accessControl.grantRole(accessControl.GOV_AGENCY_ROLE(), input.addressGovAgency);

        Loggers.logSuccess("Agency issued successfully");

        emit AgencyIssued(msg.sender, input.agencyId, block.timestamp);
    }

    /**
     * @notice Updates an existing government agency, modifying its details and status.
     * @param _agencyId Agency ID to query.
     * @param input Struct containing updated information for the agency.
     */
    function updateAgency(string calldata _agencyId, GovAgencyStruct.AgencyUpdateInput calldata input)
        external
        override
    {
        LibAccessControl.enforceAdminOrGovAgency(accessControl);

        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkString(_agencyId);
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.name);
        Validator.checkString(input.location);
        Validator.checkString(input.role);

        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];

        // Update agency data
        if (agency.addressGovAgency != input.addressGovAgency) {
            // Update address mapping
            _updateAddressMapping(_agencyId, agency.addressGovAgency, input.addressGovAgency);
            // Revoke old address's role and grant to new address
            accessControl.revokeRole(accessControl.GOV_AGENCY_ROLE(), agency.addressGovAgency);
            accessControl.grantRole(accessControl.GOV_AGENCY_ROLE(), input.addressGovAgency);
            agency.addressGovAgency = input.addressGovAgency;
        }

        agency.name = input.name;
        agency.location = input.location;
        agency.status = input.status;
        agency.role = input.role;

        Loggers.logSuccess("Agency updated successfully");

        emit UpdateAgency(msg.sender, _agencyId, block.timestamp);
    }

    /**
     * @notice Retrieves agency details by agency ID.
     * @param _agencyId Agency ID to query.
     * @return A struct containing full agency information.
     */
    function getAgency(string memory _agencyId) external view override returns (GovAgencyStruct.GovAgency memory) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();
        return gas.agencies[_agencyId];
    }

    /**
     * @notice Revokes an existing government agency, setting its status to REVOKED.
     * @param _agencyId The ID of the agency to revoke.
     */
    function revokeAgency(string calldata _agencyId) external override {
        LibAccessControl.enforceAdminOrGovAgency(accessControl);

        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validation
        Validator.checkString(_agencyId);
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];
        if (agency.status == Enum.Status.REVOKED) revert Errors.InvalidInput();

        // Update status
        agency.status = Enum.Status.REVOKED;

        // Revoke GOV_AGENCY_ROLE
        accessControl.revokeRole(accessControl.GOV_AGENCY_ROLE(), agency.addressGovAgency);

        Loggers.logSuccess("Agency revoked successfully");

        emit RevokedAgency(msg.sender, _agencyId, block.timestamp);
    }

    /**
     * @notice Retrieves all government agencies.
     * @return An array of all government agency structs.
     */
    function getAllAgencies() external view returns (GovAgencyStruct.GovAgency[] memory) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        uint256 agencyCount = gas.agencyCount;
        GovAgencyStruct.GovAgency[] memory allAgencies = new GovAgencyStruct.GovAgency[](agencyCount);

        for (uint256 i = 0; i < agencyCount; i++) {
            allAgencies[i] = gas.agencies[gas.agencyIds[i]];
        }

        return allAgencies;
    }

    /**
     * @dev Internal function to update address-to-agency mapping when address changes
     */
    function _updateAddressMapping(string memory agencyId, address oldAddress, address newAddress) private {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        string[] storage oldAgencyIds = gas.addressToAgencyIds[oldAddress];
        uint256 index = _findIndex(oldAgencyIds, agencyId);
        _removeByIndex(oldAgencyIds, index);
        gas.addressToAgencyIds[newAddress].push(agencyId);
    }

    /**
     * @dev Internal function to find index of agencyId in array
     */
    function _findIndex(string[] storage array, string memory agencyId) private view returns (uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == keccak256(bytes(agencyId))) {
                return i;
            }
        }
        revert Errors.NotFound();
    }

    /**
     * @dev Internal function to remove element from array by index
     */
    function _removeByIndex(string[] storage array, uint256 index) private {
        if (index >= array.length) revert Errors.InvalidInput();
        array[index] = array[array.length - 1];
        array.pop();
    }
}
