// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";
import "../security/AccessControl.sol";

/**
 * @title LibAccessControl
 * @dev Library for role-based access control
 */
library LibAccessControl {
    /**
     * @dev Enforces role-based access control
     * @param role The required role
     */
    function enforceRole(bytes32 role) internal view {
        if (!AccessControl(address(this)).hasRole(role, msg.sender)) {
            revert Errors.NotAuthorized(msg.sender);
        }
    }
}
