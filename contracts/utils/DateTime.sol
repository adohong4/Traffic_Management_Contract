// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title DateTime
 * @dev Utility library for handling date and time calculations
 */
library DateTime {
    // Number of seconds in a day
    uint256 private constant SECONDS_PER_DAY = 86400;

    /**
     * @dev Checks if a timestamp is in the future
     * @param timestamp The timestamp to check
     * @return True if the timestamp is in the future
     */
    function isFuture(uint256 timestamp) internal view returns (bool) {
        return timestamp > block.timestamp;
    }

    /**
     * @dev Adds days to a timestamp
     * @param timestamp The starting timestamp
     * @param daysToAdd Number of days to add
     * @return New timestamp
     */
    function addDays(uint256 timestamp, uint256 daysToAdd) internal pure returns (uint256) {
        return timestamp + (daysToAdd * SECONDS_PER_DAY);
    }

    /**
     * @dev Checks if a timestamp is expired
     * @param expiryDate The expiry timestamp
     * @return True if expired
     */
    function isExpired(uint256 expiryDate) internal view returns (bool) {
        return expiryDate < block.timestamp;
    }

    /**
     * @dev Get year the current timestamp
     * @return Current timestamp
     */
    function getYear(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / 31556926) + 1970; // approx 1 year = 365.24 days
    }

    /**
     * @dev Get month the current timestamp
     * @return Current timestamp
     */
    function getMonth(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / 2629743) % 12 + 1; // approx month
    }
}
