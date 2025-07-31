// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IDiamondCut
 * @dev Interface for the DiamondCut facet (EIP-2535)
 */
interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @dev Emitted when a diamond cut is performed
     */
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @dev Add, replace, or remove facets
     * @param _diamondCut Array of facet cuts
     * @param _init Address of contract to call for initialization
     * @param _calldata Data to pass to initialization contract
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}
