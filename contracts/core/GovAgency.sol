// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";
import "../constants/Enum.sol";
import "../entities/structs/GovAgencyStruct.sol";
import "../utils/Validator.sol";
import "../utils/Loggers.sol";
import "../libraries/LibStorage.sol";
import "../libraries/LibAccessControl.sol";
import "../interfaces/external/IGovAgency.sol";
import "../security/ReEntrancyGuard.sol";
import "../security/AccessControl.sol";
import "../libraries/LibRegistration.sol";
import "../interfaces/ITrafficController.sol";

/**
 * @title GovAgencyFacet
 * @dev Manages government agency accounts in the traffic management system
 */
contract GovAgency is IGovAgency, ReEntrancyGuard, AccessControl {
    address public immutable trafficController;

    // Constructor: grant role
    constructor(address _trafficController) {
        trafficController = _trafficController;
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GOV_AGENCY_ROLE, msg.sender);
    }

    function _validateRegistration() internal view {
        LibRegistration.validate(
            trafficController,
            ITrafficController(trafficController).govAgency
        );
    }

    /**
     * @dev Issues a new government agency
     */
    function issueAgency(
        GovAgencyStruct.AgencyInput calldata input
    ) external override nonReentrant onlyRole(ADMIN_ROLE) {
        _validateRegistration();
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.agencyId);
        Validator.checkString(input.name);
        Validator.checkString(input.location);

        if (bytes(gas.agencies[input.agencyId].agencyId).length != 0)
            revert Errors.AlreadyExists();

        // Store agency data
        gas.agencies[input.agencyId] = GovAgencyStruct.GovAgency(
            input.addressGovAgency,
            input.agencyId,
            input.name,
            input.location,
            "GOVERNMENT_AGENCY", // Default role
            Enum.Status.ACTIVE
        );

        // Update mappings
        gas.addressToAgencyIds[input.addressGovAgency].push(input.agencyId);
        gas.agencyIds.push(input.agencyId);
        gas.agencyCount++;

        // Log success
        Loggers.logSuccess("Agency issued successfully");

        emit AgencyIssued(
            input.addressGovAgency,
            input.agencyId,
            block.timestamp
        );
    }

    /**
     * @dev Updates an existing government agency
     */
    function updateAgency(
        string memory _agencyId,
        GovAgencyStruct.AgencyUpdateInput calldata input
    ) external override nonReentrant onlyRole(ADMIN_ROLE) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkString(_agencyId);
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.name);
        Validator.checkString(input.location);
        Validator.checkString(input.role);
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0)
            revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];

        // Update address mappings if address changes
        if (agency.addressGovAgency != input.addressGovAgency) {
            _updateAddressMapping(
                _agencyId,
                agency.addressGovAgency,
                input.addressGovAgency
            );
            agency.addressGovAgency = input.addressGovAgency;
        }

        // Update agency data
        agency.name = input.name;
        agency.location = input.location;
        agency.role = input.role;
        agency.status = input.status;

        // Log success
        Loggers.logSuccess("Agency updated successfully");

        emit UpdateAgency(input.addressGovAgency, _agencyId, block.timestamp);
    }

    /**
     * @dev Internal function to update address mappings when agency address changes
     */
    function _updateAddressMapping(
        string memory agencyId,
        address oldAddress,
        address newAddress
    ) private {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        string[] storage oldAgencyIds = gas.addressToAgencyIds[oldAddress];

        // Find and remove agencyId from old address
        for (uint256 i = 0; i < oldAgencyIds.length; ) {
            if (
                keccak256(bytes(oldAgencyIds[i])) == keccak256(bytes(agencyId))
            ) {
                oldAgencyIds[i] = oldAgencyIds[oldAgencyIds.length - 1];
                oldAgencyIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        // Add agencyId to new address
        gas.addressToAgencyIds[newAddress].push(agencyId);
    }

    /**
     * @dev Revokes an existing government agency
     */
    function revokeAgency(
        string calldata _agencyId
    ) external override nonReentrant onlyRole(ADMIN_ROLE) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validation
        Validator.checkString(_agencyId);
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0)
            revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];
        agency.status = Enum.Status.REVOKED;

        // Log success
        Loggers.logSuccess("Agency revoked successfully");

        emit RevokedAgency(agency.addressGovAgency, _agencyId, block.timestamp);
    }

    /**
     * @dev Retrieves agency details by agency ID
     */
    function getAgency(
        string memory _agencyId
    ) external view override returns (GovAgencyStruct.GovAgency memory) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0)
            revert Errors.NotFound();
        return gas.agencies[_agencyId];
    }

    /**
     * @dev Retrieves all government agencies
     */
    function getAllAgencies()
        external
        view
        override
        returns (GovAgencyStruct.GovAgency[] memory)
    {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        uint256 agencyCount = gas.agencyCount;
        GovAgencyStruct.GovAgency[]
            memory allAgencies = new GovAgencyStruct.GovAgency[](agencyCount);

        for (uint256 i = 0; i < gas.agencyIds.length; ) {
            string memory agencyId = gas.agencyIds[i];
            if (bytes(gas.agencies[agencyId].agencyId).length > 0) {
                allAgencies[i] = gas.agencies[agencyId];
            }
            unchecked {
                ++i;
            }
        }
        return allAgencies;
    }
}
