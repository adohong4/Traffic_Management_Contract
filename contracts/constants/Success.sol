// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title Success
 * @dev Defines success messages emitted as events in the traffic management system
 */
contract Success {
    // Success messages for events
    string public constant LICENSE_ISSUED = "License issued successfully";
    string public constant LICENSE_UPDATED = "License updated successfully";
    string public constant LICENSE_RENEWED = "License renewed successfully";
    string public constant LICENSE_REVOKED = "License revoked successfully";
    string public constant AUTHORITY_ADDED = "Authority added successfully";
}
