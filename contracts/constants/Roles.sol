// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * Roles
 * Defines roles for access control in the traffic management system
 */
contract Roles {
    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOV_AGENCY_ROLE = keccak256("GOV_AGENCY_ROLE");
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant INSURER_ROLE = keccak256("INSURER_ROLE");
    bytes32 public constant INSPECTOR_ROLE = keccak256("INSPECTOR_ROLE");
}
