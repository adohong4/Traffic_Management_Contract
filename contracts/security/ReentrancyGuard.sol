// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ReEntrancyGuard
 * @dev Prevents reentrant calls to a function
 */
contract ReEntrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Constructor initializes the guard to NOT_ENTERED
     */
    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Modifier to prevent reentrant calls
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Set the status to ENTERED
        _status = _ENTERED;

        // Execute the function
        _;

        // Reset the status to NOT_ENTERED
        _status = _NOT_ENTERED;
    }
}
