// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Constants.sol";
import "../constants/Errors.sol";
import "../constants/NFTConstants.sol";

/**
 * @title Validator
 * @dev Utility library for input validation
 */
library Validator {
    /**
     * @dev Validates that an address is not zero
     * @param addr The address to validate
     */
    function checkAddress(address addr) internal pure {
        if (addr == address(0)) revert Errors.ZeroAddressNotAllowed();
    }

    /**
     * @dev Validates that a string is not empty
     * @param str The string to validate
     */
    function checkString(string memory str) internal pure {
        if (bytes(str).length == 0) revert Errors.InvalidInput();
    }

    /**
     * @dev Validates that a uint256 is not zero
     * @param value The value to validate
     */
    function checkNonZero(uint256 value) internal pure {
        if (value == 0) revert Errors.InvalidInput();
    }

    /**
     * @dev Validates driver license points
     */
    function checkPoints(uint256 point) internal pure {
        if (point > 12) revert Errors.InvalidPointValue(point);
    }
}
