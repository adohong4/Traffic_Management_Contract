// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";
import "../utils/Validator.sol";

/**
 * @title AccessControl
 * @dev Role-based access control for the traffic management system
 */
contract AccessControl {
    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOV_AGENCY_ROLE = keccak256("GOV_AGENCY_ROLE");
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant INSURER_ROLE = keccak256("INSURER_ROLE");
    bytes32 public constant INSPECTOR_ROLE = keccak256("INSPECTOR_ROLE");

    mapping(address => mapping(bytes32 => bool)) private _roles;

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    modifier onlyRole(bytes32 role) {
        if (!_roles[msg.sender][role]) revert Errors.NotAuthorized(msg.sender);
        _;
    }

    // Initialize ADMIN_ROLE for the deployer
    constructor() {
        _roles[msg.sender][ADMIN_ROLE] = true;
        emit RoleGranted(ADMIN_ROLE, msg.sender, msg.sender);
    }

    /**
     * @dev Internal function to grant a role to an account
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[account][role]) {
            _roles[account][role] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Grants a role to an account
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(ADMIN_ROLE) {
        Validator.checkAddress(account);
        _roles[account][role] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes a role from an account
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(ADMIN_ROLE) {
        Validator.checkAddress(account);
        _roles[account][role] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @dev Checks if an account has a role
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _roles[account][role];
    }
}
