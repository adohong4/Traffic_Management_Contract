// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITrafficController {
    event ModuleUpdated(bytes32 indexed key, address indexed module);
    event TreasuryUpdated(address indexed treasury);
    event ProtocolFeeUpdated(uint256 fee);
    event OracleUpdated(address indexed oracle);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event FacetRegistered(bytes32 indexed facetKey, address indexed facetAddress);
    event FacetUnregistered(bytes32 indexed facetKey, address indexed facetAddress);
    event FacetPaused(bytes32 indexed facetKey, address indexed facetAddress);
    event FacetUnpaused(bytes32 indexed facetKey, address indexed facetAddress);

    error ZeroAddress();
    error NotContract();
    error ArrayLengthMismatch();
    error UnauthorizedModule(address caller);
    error SystemPaused();
    error ModuleNotRegistered(bytes32 key);
    error FacetNotRegistered(bytes32 facetKey);

    // Router function
    function router() external view returns (address);

    // Access control functions
    function isAdmin(address user) external view returns (bool);
    function isDelegateAdmin(address user) external view returns (bool);
    function isOperator(address user) external view returns (bool);

    // Facet management functions
    function getFacet(bytes32 facetKey) external view returns (address);
    function isFacetRegistered(bytes32 facetKey) external view returns (bool);
    function registerFacet(bytes32 facetKey, address facetAddr) external;
    function unregisterFacet(bytes32 facetKey) external;
    function pauseFacet(bytes32 facetKey) external;
    function unpauseFacet(bytes32 facetKey) external;

    // Module management functions
    function setModule(bytes32 key, address moduleAddr) external;
    function setModules(bytes32[] calldata keys, address[] calldata addrs) external;
    function getModule(bytes32 key) external view returns (address);
    function isModuleRegistered(bytes32 key) external view returns (bool);

    // System configuration functions
    function setTreasury(address newTreasury) external;
    function setProtocolFee(uint256 newFee) external;
    function setOracle(address newOracle) external;
    function pause() external;
    function unpause() external;
}
