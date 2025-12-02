// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IDefaultAccessControlEnumerable} from "../interfaces/internal/IDefaultAccessControlEnumerable.sol";
/// @notice This is a default access control with 3 roles:
// Todo: write test to check allow permission
/// - ADMIN: allowed to do anything
/// - ADMIN_DELEGATE: allowed to do anything except assigning ADMIN and ADMIN_DELEGATE roles
/// - OPERATOR: low-privileged role, generally keeper or some other bot

contract DefaultAccessControlEnumerable is
    Initializable,
    AccessControlEnumerableUpgradeable,
    IDefaultAccessControlEnumerable
{
    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
    bytes32 public constant SIGNER = keccak256("signer");

    /// @param admin_ Admin of the contract
    function __DefaultAccessControlEnumerable_init(address admin_) internal onlyInitializing {
        __AccessControlEnumerable_init();
        _grantRole(OPERATOR, admin_);
        _grantRole(ADMIN_ROLE, admin_);
        _grantRole(ADMIN_DELEGATE_ROLE, admin_);
        _grantRole(SIGNER, admin_);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN_DELEGATE_ROLE);
        _setRoleAdmin(SIGNER, ADMIN_DELEGATE_ROLE);
    }

    // -------------------------  EXTERNAL, VIEW  ------------------------------

    function isAdmin(address _sender) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, _sender);
    }

    function isDelegateAdmin(address _sender) public view virtual returns (bool) {
        return hasRole(ADMIN_DELEGATE_ROLE, _sender);
    }

    function isOperator(address _sender) public view virtual returns (bool) {
        return hasRole(OPERATOR, _sender);
    }

    function isSigner(address _sender) public view virtual returns (bool) {
        return hasRole(SIGNER, _sender);
    }
    // ------------------------------------------------------------------- //
    // --------------------------- Modifier ------------------------------ //
    // ------------------------------------------------------------------- //

    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) {
            revert InvalidAdminRole();
        }
        _;
    }

    modifier onlyDelegateAdmin() {
        if (!isDelegateAdmin(msg.sender)) {
            revert InvalidDelegateRole();
        }
        _;
    }

    modifier onlyAtLeastOperator() {
        if (!isOperator(msg.sender)) {
            revert InvalidAtLeastOperatorRole();
        }
        _;
    }

    modifier onlySigner() {
        if (!isSigner(msg.sender)) {
            revert InvalidSignerRole();
        }
        _;
    }
}
