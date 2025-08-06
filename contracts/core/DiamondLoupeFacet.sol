// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/LibDiamond.sol";
import "../interfaces/internal/IDiamondLoupe.sol";

/**
 * @title DiamondLoupeFacet
 * @dev Facet for inspecting facet information (EIP-2535)
 */
contract DiamondLoupeFacet is IDiamondLoupe {
    /**
     * @dev Returns all facets and their selectors
     */
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.facetAddresses.length);
        for (uint256 i = 0; i < ds.facetAddresses.length; i++) {
            facets_[i].facetAddress = ds.facetAddresses[i];
            facets_[i].functionSelectors = ds.facetFunctionSelectors[ds.facetAddresses[i]];
        }
    }

    /**
     * @dev Returns function selectors for a given facet
     * @param _facet Address of the facet
     */
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory) {
        return LibDiamond.diamondStorage().facetFunctionSelectors[_facet];
    }

    /**
     * @dev Returns all facet addresses
     */
    function facetAddresses() external view override returns (address[] memory) {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    /**
     * @dev Returns the facet address for a given function selector
     * @param _functionSelector Function selector
     */
    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return LibDiamond.diamondStorage().selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}
