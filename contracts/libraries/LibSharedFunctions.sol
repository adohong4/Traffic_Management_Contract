// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";
import "../utils/Validator.sol";

/**
 * @title LibSharedFunctions
 * @dev Library for shared utility functions across the traffic management system
 */
library LibSharedFunctions {
    /**
     * @dev Finds the index of a value in an array
     * @param array The array to search
     * @param value The value to find
     * @return The index of the value, or reverts if not found
     */
    function findIndex(uint256[] storage array, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        revert Errors.NotFound();
    }

    /**
     * @dev Removes an element from an array by swapping with the last element
     * @param array The array to modify
     * @param index The index to remove
     */
    function removeByIndex(uint256[] storage array, uint256 index) internal {
        if (index >= array.length) revert Errors.InvalidInput();
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @dev Checks if an address is in an array
     * @param arr The array of addresses
     * @param value The address to check
     * @return True if the address is found, false otherwise
     */
    function findIndexString(string[] memory arr, string memory value) internal pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(bytes(arr[i])) == keccak256(bytes(value))) {
                return i;
            }
        }
        revert("Value not found");
    }

    /**
     * @dev Removes a string from an array by index
     * @param arr The array of strings
     * @param index The index to remove
     */
    function removeStringByIndex(string[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}
