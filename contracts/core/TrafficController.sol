// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../constants/Errors.sol";
import "../interfaces/ITrafficController.sol";

/// @title TrafficController
/// @notice Central registry and configuration contract for the Traffic Management system.
/// Manages addresses of core contracts (GovAgency, VehicleRegistration, OffenceAndRenewal, DriverLicense).
/// Only ADMIN_ROLE can update addresses or pause/unpause the system.
contract TrafficController is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ITrafficController
{
    // ============================== //
    //          State Variables       //
    // ============================== //

    address public override govAgency;
    address public override vehicleRegistration;
    address public override offenceAndRenewal;
    address public override driverLicense;

    bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============================== //
    //          Initialize           //
    // ============================== //

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ============================== //
    //     External Set Functions     //
    // ============================== //

    /// @inheritdoc ITrafficController
    function setGovAgency(
        address _govAgency
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_govAgency == address(0)) revert InvalidCoreContractAddress();
        emit CoreContractUpdated("GovAgency", govAgency, _govAgency);
        govAgency = _govAgency;
    }

    /// @inheritdoc ITrafficController
    function setVehicleRegistration(
        address _vehicleRegistration
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_driverLicense == address(0)) revert InvalidCoreContractAddress();
        emit CoreContractUpdated(
            "DriverLicense",
            driverLicense,
            _driverLicense
        );
        driverLicense = _driverLicense;
    }

    /// @inheritdoc ITrafficController
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /// @inheritdoc ITrafficController
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
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

    /// @inheritdoc ITrafficController
    function isDriverLicense(
        address _addr
    ) external view override returns (bool) {
        return _addr == driverLicense && driverLicense != address(0);
    }

    /// @inheritdoc ITrafficController
    function getAllCoreContracts()
        external
        view
        override
        returns (
            address govAgencyAddr,
            address vehicleRegistrationAddr,
            address offenceAndRenewalAddr,
            address driverLicenseAddr,
            bool pausedStatus
        )
    {
        return (
            govAgency,
            vehicleRegistration,
            offenceAndRenewal,
            driverLicense,
            paused
        );
    }
}
