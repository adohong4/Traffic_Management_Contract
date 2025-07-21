// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title NFTConstants
 * @dev Defines constants related to NFTs in the traffic management system
 */
contract NFTConstants {
    // Base URI for NFT metadata (can be overridden)
    string public constant BASE_URI = "ipfs://";

    // Default token name and symbol for ERC-4671
    string public constant TOKEN_NAME = "DriverLicenseNFT";
    string public constant TOKEN_SYMBOL = "DLNFT";

    // Maximum number of licenses per holder
    uint256 public constant MAX_LICENSES_PER_HOLDER = 5;

    // Maximum points for a driver license
    uint256 public constant MAX_LICENSE_POINTS = 12;
}
