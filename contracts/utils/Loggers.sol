// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Success.sol";
import "../constants/Errors.sol";

/**
 * @title Loggers
 * @dev Utility library for emitting log events
 */
library Loggers {
    /**
     * @dev Emits a success event with a message
     * @param message The success message
     */
    function logSuccess(string memory message) internal {
        emit SuccessEvent(message, block.timestamp);
    }

    /**
     * @dev Emits an error event with a reason
     * @param reason The error reason
     */
    function logError(string memory reason) internal {
        emit ErrorEvent(reason, block.timestamp);
    }

    // Events
    event SuccessEvent(string message, uint256 timestamp);
    event ErrorEvent(string reason, uint256 timestamp);
}
