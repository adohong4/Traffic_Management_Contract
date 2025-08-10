// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IDiamond} from "./IDiamond.sol";
/**
 * @title IDiamondCut
 * @dev Interface for the DiamondCut facet (EIP-2535)
 */

interface IDiamondCut is IDiamond {
    /**
     * @dev Add, replace, or remove facets
     * @param _diamondCut Array of facet cuts
     * @param _init Address of contract to call for initialization
     * @param _calldata Data to pass to initialization contract
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}
