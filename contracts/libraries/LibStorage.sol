// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../entities/structs/DriverLicenseStruct.sol";
import "../constants/Enum.sol";

/**
 * @title LibStorage
 * @dev Library for managing storage in the traffic management system
 */
library LibStorage {
    // Storage position for driver license data
    bytes32 constant LICENSE_STORAGE_POSITION = keccak256("diamond.storage.DriverLicense");

    // Storage struct for driver licenses
    struct LicenseStorage {
        mapping(string => DriverLicenseStruct.DriverLicense) licenses; // License data by licenseNo
        mapping(uint256 => string) tokenIdToLicenseNo; // Map tokenId to licenseNo
        mapping(address => uint256[]) holderToTokenIds; // Map holder to tokenIds
        mapping(uint256 => address) tokenToOwner; // Map tokenId to owner
        mapping(address => uint256) validBalance; // Number of valid tokens per owner
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
}
