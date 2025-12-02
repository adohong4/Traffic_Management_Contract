// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";
import "../constants/Enum.sol";
import "../entities/structs/GovAgencyStruct.sol";
import "../utils/Validator.sol";
import "../utils/Loggers.sol";
import "../libraries/LibStorage.sol";
import "../interfaces/external/IGovAgency.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ITrafficFacet.sol";
import "../interfaces/ITrafficController.sol";

/**
 * @title GovAgencyFacet
 * @dev Manages government agency accounts with controller integration
 */
contract GovAgencyFacet is IGovAgency, ITrafficFacet, ReentrancyGuard {
    // Controller reference for access control
    ITrafficController public trafficController;

    // Facet state
    bool public facetActive;
    bool public facetPaused;
    string public constant FACET_NAME = "GovAgencyFacet";
    string public constant FACET_VERSION = "1.0.0";

    /**
     * @notice Initializes the facet with controller reference
     * @param controller Address of the traffic controller
     */
    function initializeFacet(address controller) external override {
        require(controller != address(0), "Invalid controller");
        trafficController = ITrafficController(controller);
        facetActive = true;
        facetPaused = false;

        emit FacetInitialized(address(this));
    }

    /**
     * @notice Gets facet name
     */
    function getFacetName() external pure override returns (string memory) {
        return FACET_NAME;
    }

    /**
     * @notice Gets facet version
     */
    function getFacetVersion() external pure override returns (string memory) {
        return FACET_VERSION;
    }

    /**
     * @notice Checks if facet is active
     */
    function isFacetActive() external view override returns (bool) {
        return facetActive && !facetPaused;
    }

    /**
     * @notice Pauses the facet
     */
    function pauseFacet() external override {
        require(msg.sender == address(trafficController) || trafficController.isAdmin(msg.sender), "Unauthorized");
        facetPaused = true;
        emit FacetPaused(address(this));
    }

    /**
     * @notice Unpauses the facet
     */
    function unpauseFacet() external override {
        require(msg.sender == address(trafficController) || trafficController.isAdmin(msg.sender), "Unauthorized");
        facetPaused = false;
        emit FacetUnpaused(address(this));
    }

    /**
     * @notice Checks if user has specific permission
     * @param user User address
     * @param permission Permission name
     */
    function hasPermission(address user, string calldata permission) external view override returns (bool) {
        // Check permissions through controller
        if (keccak256(bytes(permission)) == keccak256("ISSUE_AGENCY")) {
            return trafficController.isDelegateAdmin(user) || trafficController.isOperator(user);
        }
        if (keccak256(bytes(permission)) == keccak256("UPDATE_AGENCY")) {
            return trafficController.isDelegateAdmin(user);
        }
        return false;
    }

    /**
     * @notice Emergency stop
     */
    function emergencyStop() external override {
        require(trafficController.isAdmin(msg.sender), "Admin only");
        facetPaused = true;
        facetActive = false;
    }

    /**
     * @notice Emergency resume
     */
    function emergencyResume() external override {
        require(trafficController.isAdmin(msg.sender), "Admin only");
        facetActive = true;
        facetPaused = false;
    }

    /**
     * @dev Issues a new government agency with access control
     */
    function issueAgency(GovAgencyStruct.AgencyInput calldata input) external override nonReentrant {
        require(this.isFacetActive(), "Facet not active");
        require(this.hasPermission(msg.sender, "ISSUE_AGENCY"), "Insufficient permission");

        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.agencyId);
        Validator.checkString(input.name);
        Validator.checkString(input.location);

        if (bytes(gas.agencies[input.agencyId].agencyId).length != 0) revert Errors.AlreadyExists();

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

        emit AgencyIssued(input.addressGovAgency, input.agencyId, block.timestamp);
    }

    /**
     * @dev Updates an existing government agency with access control
     */
    function updateAgency(string memory _agencyId, GovAgencyStruct.AgencyUpdateInput calldata input)
        external
        override
        nonReentrant
    {
        require(this.isFacetActive(), "Facet not active");
        require(this.hasPermission(msg.sender, "UPDATE_AGENCY"), "Insufficient permission");

        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validations
        Validator.checkString(_agencyId);
        Validator.checkAddress(input.addressGovAgency);
        Validator.checkString(input.name);
        Validator.checkString(input.location);
        Validator.checkString(input.role);
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];

        // Update address mappings if address changes
        if (agency.addressGovAgency != input.addressGovAgency) {
            _updateAddressMapping(_agencyId, agency.addressGovAgency, input.addressGovAgency);
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
    function _updateAddressMapping(string memory agencyId, address oldAddress, address newAddress) private {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        string[] storage oldAgencyIds = gas.addressToAgencyIds[oldAddress];

        // Find and remove agencyId from old address
        for (uint256 i = 0; i < oldAgencyIds.length;) {
            if (keccak256(bytes(oldAgencyIds[i])) == keccak256(bytes(agencyId))) {
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
    function revokeAgency(string calldata _agencyId) external override nonReentrant {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();

        // Validation
        Validator.checkString(_agencyId);
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();

        GovAgencyStruct.GovAgency storage agency = gas.agencies[_agencyId];
        agency.status = Enum.Status.REVOKED;

        // Log success
        Loggers.logSuccess("Agency revoked successfully");

        emit RevokedAgency(agency.addressGovAgency, _agencyId, block.timestamp);
    }

    /**
     * @dev Retrieves agency details by agency ID
     */
    function getAgency(string memory _agencyId) external view override returns (GovAgencyStruct.GovAgency memory) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        if (bytes(gas.agencies[_agencyId].agencyId).length == 0) revert Errors.NotFound();
        return gas.agencies[_agencyId];
    }

    /**
     * @dev Retrieves all government agencies
     */
    function getAllAgencies() external view override returns (GovAgencyStruct.GovAgency[] memory) {
        LibStorage.GovAgencyStorage storage gas = LibStorage.govAgencyStorage();
        uint256 agencyCount = gas.agencyCount;
        GovAgencyStruct.GovAgency[] memory allAgencies = new GovAgencyStruct.GovAgency[](agencyCount);

        for (uint256 i = 0; i < gas.agencyIds.length;) {
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
