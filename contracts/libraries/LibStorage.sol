// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../entities/structs/DriverLicenseStruct.sol";
import "../entities/structs/OffenceAndRenewal.sol";
import "../entities/structs/GovAgencyStruct.sol";
import "../entities/structs/VehicleRegistrationStruct.sol";
import "../constants/Enum.sol";

/**
 * @title LibStorage
 * @dev Library for managing storage in the traffic management system
 */
library LibStorage {
    // Storage position for government agency data
    bytes32 constant GOV_AGENCY_STORAGE_POSITION = keccak256("diamond.storage.GovAgency");
    // Storage position for driver license data
    bytes32 constant LICENSE_STORAGE_POSITION = keccak256("diamond.storage.DriverLicense");
    // Storage position for offense and renewal data
    bytes32 constant OFFENSE_RENEWAL_STORAGE_POSITION = keccak256("diamond.storage.OffenseRenewal");
    // Storage position for vehicle registration data
    bytes32 constant VEHICLE_REGISTRATION_STORAGE_POSITION = keccak256("diamond.storage.VehicleRegistration");

    // Storage struct for government agency data
    struct GovAgencyStorage {
        mapping(string => GovAgencyStruct.GovAgency) agencies; // Agency data by agencyId
        mapping(address => string[]) addressToAgencyIds; // Map address to list of agencyIds
        string[] agencyIds; // List of all agency IDs
        uint256 agencyCount; // Total number of agencies
    }

    /**
     * @dev Returns the government agency storage
     */
    function govAgencyStorage() internal pure returns (GovAgencyStorage storage gas) {
        bytes32 position = GOV_AGENCY_STORAGE_POSITION;
        assembly {
            gas.slot := position
        }
    }

    // Storage struct for driver licenses
    struct LicenseStorage {
        mapping(string => DriverLicenseStruct.DriverLicense) licenses; // License data by licenseNo
        mapping(uint256 => string) tokenIdToLicenseNo; // Map tokenId to licenseNo
        mapping(address => uint256[]) holderToTokenIds; // Map holder to tokenIds
        mapping(uint256 => address) tokenToOwner; // Map tokenId to owner
        mapping(address => uint256) validBalance; // Number of valid tokens per owner
        mapping(string => uint256) licenseNoToTokenId; // Map licenseNo to tokenId
        uint256 tokenCount; // Total number of issued tokens
        uint256 holderCount; // Number of unique holders
    }

    /**
     * @dev Returns the license storage
     */
    function licenseStorage() internal pure returns (LicenseStorage storage ls) {
        bytes32 position = LICENSE_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    // Storage struct for offense and renewal data
    struct OffenseRenewalStorage {
        mapping(string => OffenceAndRenewalStruct.Offence[]) licenseToOffences; // Map licenseNo to list of offences
        mapping(string => bool) licenseTypeExists; // Check if license type exists
        mapping(string => OffenceAndRenewalStruct.RenewLicense) renewRules; // Renewal rules by license type
        string[] licenseTypes; // List of license types
    }

    /**
     * @dev Returns the offense and renewal storage
     */
    function offenseRenewalStorage() internal pure returns (OffenseRenewalStorage storage ors) {
        bytes32 position = OFFENSE_RENEWAL_STORAGE_POSITION;
        assembly {
            ors.slot := position
        }
    }

    // Storage struct for vehicle registration data
    struct VehicleRegistrationStorage {
        mapping(string => VehicleRegistrationStruct.VehicleRegistration) registrations; // Registration data by vehiclePlateNo
        mapping(address => string[]) addressToVehiclePlateNos; // Map address to list of vehicle plate numbers
        mapping(string => bool) vehiclePlateNoExists; // Check if vehicle plate number exists
        mapping(uint256 => string) tokenIdToVehiclePlateNo; // Map address to vehicle plate number
        mapping(uint256 => address) tokenToOwner; // Map tokenId to owner
        mapping(address => uint256) validBalance; // Number of valid tokens per owner
        string[] vehiclePlateNos; // List of all vehicle plate numbers
        uint256 registrationCount; // Total number of registrations
        uint256 holderCount; // Number of unique holders
    }

    /**
     * @dev Returns the vehicle registration storage
     */
    function vehicleRegistrationStorage() internal pure returns (VehicleRegistrationStorage storage vrs) {
        bytes32 position = VEHICLE_REGISTRATION_STORAGE_POSITION;
        assembly {
            vrs.slot := position
        }
    }
}
