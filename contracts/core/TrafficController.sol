// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../security/AccessControl.sol";
import "../constants/Errors.sol";
import "../interfaces/external/IDriverLicense.sol";
import "../interfaces/external/IGovAgency.sol";
import "../interfaces/external/IVehicleRegistration.sol";
import "../interfaces/external/IOffenceRenewal.sol";

contract TrafficController is AccessControl {
    // Roles
    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // bytes32 public constant GOV_AGENCY_ROLE = keccak256("GOV_AGENCY_ROLE");

    // Địa chỉ các contract core
    address public govAgency;
    address public vehicleRegistration;
    address public offenceAndRenewal;
    address public driverLicense; // nếu tách riêng

    // Events
    event ContractAddressUpdated(string name, address oldAddr, address newAddr);
    event SystemPaused(address admin);
    event SystemUnpaused(address admin);

    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "System is paused");
        _;
    }

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GOV_AGENCY_ROLE, msg.sender);
    }

    // ------------------- Quản lý địa chỉ contract -------------------

    function setGovAgency(address _govAgency) external onlyRole(ADMIN_ROLE) {
        require(_govAgency != address(0), "Invalid address");
        emit ContractAddressUpdated("GovAgency", govAgency, _govAgency);
        govAgency = _govAgency;
    }

    function setVehicleRegistration(
        address _vehicleRegistration
    ) external onlyRole(ADMIN_ROLE) {
        require(_vehicleRegistration != address(0), "Invalid address");
        emit ContractAddressUpdated(
            "VehicleRegistration",
            vehicleRegistration,
            _vehicleRegistration
        );
        vehicleRegistration = _vehicleRegistration;
    }

    function setOffenceAndRenewal(
        address _offenceAndRenewal
    ) external onlyRole(ADMIN_ROLE) {
        require(_offenceAndRenewal != address(0), "Invalid address");
        emit ContractAddressUpdated(
            "OffenceAndRenewal",
            offenceAndRenewal,
            _offenceAndRenewal
        );
        offenceAndRenewal = _offenceAndRenewal;
    }

    function setDriverLicense(
        address _driverLicense
    ) external onlyRole(ADMIN_ROLE) {
        require(_driverLicense != address(0), "Invalid address");
        emit ContractAddressUpdated(
            "DriverLicense",
            driverLicense,
            _driverLicense
        );
        driverLicense = _driverLicense;
    }

    // ------------------- Pause / Unpause toàn hệ thống -------------------

    function pause() external onlyRole(ADMIN_ROLE) {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }

    // ------------------- Helper functions (gọi từ các contract khác nếu cần) -------------------

    function getGovAgency() external view returns (IGovAgency) {
        require(govAgency != address(0), "GovAgency not set");
        return IGovAgency(govAgency);
    }

    function getVehicleRegistration()
        external
        view
        returns (IVehicleRegistration)
    {
        require(
            vehicleRegistration != address(0),
            "VehicleRegistration not set"
        );
        return IVehicleRegistration(vehicleRegistration);
    }

    function getOffenceAndRenewal() external view returns (IOffenceRenewal) {
        require(offenceAndRenewal != address(0), "OffenceAndRenewal not set");
        return IOffenceRenewal(offenceAndRenewal);
    }

    function isPaused() external view returns (bool) {
        return paused;
    }
}
