// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IDiamondLoupe
 * @dev Interface for the DiamondLoupe facet (EIP-2535)
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @dev Returns all facets and their selectors
     */
    function facets() external view returns (Facet[] memory);

    /**
     * @dev Returns function selectors for a given facet
     * @param _facet Address of the facet
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory);

    /**
     * @dev Returns all facet addresses
     */
    function facetAddresses() external view returns (address[] memory);

    /**
     * @dev Returns the facet address for a given function selector
     * @param _functionSelector Function selector
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address);
}
