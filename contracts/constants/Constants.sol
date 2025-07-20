// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title Constants
 * @dev Defines common constants used across the traffic management system
 */
contract Constants {
    // Maximum duration for a driver license (in seconds, equivalent to 5 years)
    uint256 public constant DRIVER_LICENSE_DURATION = 5 * 365 days;

    // Maximum duration for vehicle insurance (in seconds, equivalent to 1 year)
    uint256 public constant INSURANCE_DURATION = 365 days;

    // Maximum duration for vehicle inspection (in seconds, equivalent to 2 years)
    uint256 public constant INSPECTION_DURATION = 2 * 365 days;

    // Minimum age requirement for driver license (in years)
    uint256 public constant MINIMUM_DRIVER_AGE = 18;

    // Maximum number of vehicles per owner
    uint256 public constant MAX_VEHICLES_PER_OWNER = 10;

    // Gas optimization: Store frequently used values as constants
    uint256 public constant ZERO = 0;
    address public constant ZERO_ADDRESS = address(0);
}
