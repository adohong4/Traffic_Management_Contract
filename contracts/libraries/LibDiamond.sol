// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../interfaces/internal/IDiamondCut.sol";
import "../constants/Errors.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 position;
    }

    struct DiamondStorage {
        // Maps function selectors to facet addresses and positions
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // Maps facets to their function selectors
        mapping(address => bytes4[]) facetFunctionSelectors;
        // List of facet addresses
        address[] facetAddresses;
        // Maps interface IDs to whether they are supported
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.contractOwner = _newOwner;
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != contractOwner()) revert Errors.NotAuthorized(msg.sender);
    }

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;

            require(functionSelectors.length > 0, "LibDiamond: No selectors in facet");
            require(
                action == IDiamondCut.FacetCutAction.Add || action == IDiamondCut.FacetCutAction.Replace
                    || action == IDiamondCut.FacetCutAction.Remove,
                "LibDiamond: Invalid action"
            );

            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            }
        }

        // Call initialization function if provided
        if (_init != address(0)) {
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    assembly {
                        revert(add(32, error), mload(error))
                    }
                } else {
                    revert("LibDiamond: Initialization failed");
                }
            }
        }
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_facetAddress != address(0), "LibDiamond: Invalid facet address");
        DiamondStorage storage ds = diamondStorage();
        uint16 position = uint16(ds.facetAddresses.length);

        // Add facet address if it doesn't exist
        bool facetExists = false;
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            if (ds.facetAddresses[i] == _facetAddress) {
                facetExists = true;
                break;
            }
        }
        if (!facetExists) {
            ds.facetAddresses.push(_facetAddress);
        }

        // Add function selectors
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamond: Selector already exists");
            ds.selectorToFacetAndPosition[selector] =
                FacetAddressAndPosition({facetAddress: _facetAddress, position: position});
            ds.facetFunctionSelectors[_facetAddress].push(selector);
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_facetAddress != address(0), "LibDiamond: Invalid facet address");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamond: Same facet");
            removeFunction(oldFacetAddress, selector);
            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                position: ds.selectorToFacetAndPosition[selector].position
            });
            ds.facetFunctionSelectors[_facetAddress].push(selector);
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_facetAddress == address(0), "LibDiamond: Non-zero facet address for remove");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != address(0), "LibDiamond: Selector does not exist");
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        bytes4[] storage selectors = ds.facetFunctionSelectors[_facetAddress];
        for (uint256 i; i < selectors.length; i++) {
            if (selectors[i] == _selector) {
                selectors[i] = selectors[selectors.length - 1];
                selectors.pop();
                break;
            }
        }
        delete ds.selectorToFacetAndPosition[_selector];

        // Remove facet address if it has no selectors
        if (selectors.length == 0) {
            for (uint256 i; i < ds.facetAddresses.length; i++) {
                if (ds.facetAddresses[i] == _facetAddress) {
                    ds.facetAddresses[i] = ds.facetAddresses[ds.facetAddresses.length - 1];
                    ds.facetAddresses.pop();
                    break;
                }
            }
        }
    }
}
