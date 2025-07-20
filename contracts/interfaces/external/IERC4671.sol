// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC4671
 * @dev Interface for ERC-4671 (Enumerable Non-Fungible Tokens for Certificates)
 */
interface IERC4671 {
    event Issued(address indexed owner, uint256 tokenId);
    event Revoked(address indexed owner, uint256 tokenId);

    function isValid(uint256 tokenId) external view returns (bool);
    function emittedCount() external view returns (uint256);
    function holdersCount() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function hasValid(address owner) external view returns (bool);
}
