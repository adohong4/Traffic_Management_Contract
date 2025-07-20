// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LibDiamond
 * @dev Library for Diamond Pattern storage and management
 */
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) facets; // Mapping of function selectors to facet addresses
        address owner; // Diamond contract owner
    }

    /**
     * @dev Returns the diamond storage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Sets the contract owner
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.owner = _newOwner;
    }

    /**
     * @dev Returns the contract owner
     */
    function contractOwner() internal view returns (address) {
        return diamondStorage().owner;
    }
}
