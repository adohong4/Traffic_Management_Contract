// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../security/AccessControl.sol";
import "../constants/Errors.sol";
import "../interfaces/ITrafficController.sol";

/// @title TrafficController
/// @notice Central registry and configuration contract for the Traffic Management system.
/// Manages addresses of core contracts (GovAgency, VehicleRegistration, OffenceAndRenewal, ...).
/// Only ADMIN_ROLE can update addresses or pause/unpause the system.
contract TrafficController is AccessControl, ITrafficController {
    // ============================== //
    //          State Variables       //
    // ============================== //

    address public override govAgency;
    address public override vehicleRegistration;
    address public override offenceAndRenewal;
    address public override driverLicense;

    bool public paused;

    // ============================== //
    //          Constructor           //
    // ============================== //

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // ============================== //
    //     External Set Functions     //
    // ============================== //

    /// @inheritdoc ITrafficController
    function setGovAgency(
        address _govAgency
    ) external override onlyRole(ADMIN_ROLE) {
        if (_govAgency == address(0)) revert InvalidCoreContractAddress();
        emit CoreContractUpdated("GovAgency", govAgency, _govAgency);
        govAgency = _govAgency;
    }

    /// @inheritdoc ITrafficController
    function setVehicleRegistration(
        address _vehicleRegistration
    ) external override onlyRole(ADMIN_ROLE) {
        if (_vehicleRegistration == address(0))
            revert InvalidCoreContractAddress();
        emit CoreContractUpdated(
            "VehicleRegistration",
            vehicleRegistration,
            _vehicleRegistration
        );
        vehicleRegistration = _vehicleRegistration;
    }

    /// @inheritdoc ITrafficController
    function setOffenceAndRenewal(
        address _offenceAndRenewal
    ) external override onlyRole(ADMIN_ROLE) {
        if (_offenceAndRenewal == address(0))
            revert InvalidCoreContractAddress();
        emit CoreContractUpdated(
            "OffenceAndRenewal",
            offenceAndRenewal,
            _offenceAndRenewal
        );
        offenceAndRenewal = _offenceAndRenewal;
    }

    /// @inheritdoc ITrafficController
    function setDriverLicense(
        address _driverLicense
    ) external override onlyRole(ADMIN_ROLE) {
        if (_driverLicense == address(0)) revert InvalidCoreContractAddress();
        emit CoreContractUpdated(
            "DriverLicense",
            driverLicense,
            _driverLicense
        );
        driverLicense = _driverLicense;
    }

    /// @inheritdoc ITrafficController
    function pause() external override onlyRole(ADMIN_ROLE) {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /// @inheritdoc ITrafficController
    function unpause() external override onlyRole(ADMIN_ROLE) {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }

    // ============================== //
    //     External View Functions    //
    // ============================== //

    /// @inheritdoc ITrafficController
    function isPaused() external view override returns (bool) {
        return paused;
    }

    /// @inheritdoc ITrafficController
    function isGovAgency(address _addr) external view override returns (bool) {
        return _addr == govAgency && govAgency != address(0);
    }

    /// @inheritdoc ITrafficController
    function isVehicleRegistration(
        address _addr
    ) external view override returns (bool) {
        return
            _addr == vehicleRegistration && vehicleRegistration != address(0);
    }

    /// @inheritdoc ITrafficController
    function isOffenceAndRenewal(
        address _addr
    ) external view override returns (bool) {
        return _addr == offenceAndRenewal && offenceAndRenewal != address(0);
    }
}
