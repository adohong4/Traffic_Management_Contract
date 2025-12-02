// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ITrafficFacet
 * @notice Base interface for all traffic management facets
 * @dev Provides common functionality and access control for facets
 */
interface ITrafficFacet {
    // Events
    event FacetInitialized(address indexed facetAddress);
    event FacetPaused(address indexed facetAddress);
    event FacetUnpaused(address indexed facetAddress);

    // Core functions that all facets must implement
    function initializeFacet(address controller) external;
    function getFacetName() external pure returns (string memory);
    function getFacetVersion() external pure returns (string memory);
    function isFacetActive() external view returns (bool);
    function pauseFacet() external;
    function unpauseFacet() external;

    // Access control - facets should check permissions through controller
    function hasPermission(address user, string calldata permission) external view returns (bool);

    // Emergency functions
    function emergencyStop() external;
    function emergencyResume() external;
}
