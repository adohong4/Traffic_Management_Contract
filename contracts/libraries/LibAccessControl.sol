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

    /**
     * @dev Enforces access for ADMIN_ROLE or GOV_AGENCY_ROLE
     * @param accessControl The AccessControl contract instance
     */
    function enforceAdminOrGovAgency(AccessControl accessControl) internal view {
        if (
            !accessControl.hasRole(accessControl.ADMIN_ROLE(), msg.sender)
                && !accessControl.hasRole(accessControl.GOV_AGENCY_ROLE(), msg.sender)
        ) {
            revert Errors.NotAuthorized(msg.sender);
        }
    }

    /**
     * @dev Modifier to restrict access to ADMIN_ROLE or GOV_AGENCY_ROLE
     */
    modifier onlyAdminOrGovAgency(AccessControl accessControl) {
        enforceAdminOrGovAgency(accessControl);
        _;
    }
}
