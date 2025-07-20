// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../entities/structs/DriverLicenseStruct.sol";
import "../constants/Constants.sol";

/**
 * @title LibStorage
 * @dev Library for managing storage in the traffic management system
 */
library LibStorage {
    // Storage position for driver license data
    bytes32 constant LICENSE_STORAGE_POSITION = keccak256("diamond.storage.DriverLicense");

    // Storage struct for driver licenses
    struct LicenseStorage {
        mapping(string => DriverLicenseStruct.DriverLicense) licenses;
        mapping(uint256 => string) tokenIdToLicenseId;
        mapping(address => uint256[]) holderToTokenIds;
        mapping(uint256 => address) tokenToOwner;
        mapping(address => uint256) validBalance;
        uint256 tokenCount;
        uint256 holderCount;
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
