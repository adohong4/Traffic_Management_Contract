// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/LibDiamond.sol";
import "../interfaces/internal/IDiamondCut.sol";

/**
 * @title DiamondCutFacet
 * @dev Facet for managing facet additions, replacements, and removals
 */
contract DiamondCutFacet is IDiamondCut {
    /**
     * @dev Executes a diamond cut to add, replace, or remove facets
     * @param _diamondCut Array of facet cuts to apply
     * @param _init Address of contract to call for initialization (optional)
     * @param _calldata Data to pass to the initialization contract (optional)
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
        emit DiamondCut(_diamondCut, _init, _calldata);
    }
}
