// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Errors.sol";

/// @title ITrafficController
/// @notice Interface for the TrafficController contract, acting as the central registry
/// for managing addresses of core contracts in the Traffic Management system.
interface ITrafficController {
    // ============================== //
    //            Errors              //
    // ============================== //

    /// @dev Revert when trying to set an invalid (zero) address for a core contract
    error InvalidCoreContractAddress();

    /// @dev Revert when trying to access a core contract that has not been registered/set
    error CoreContractNotRegistered(string contractName);

    /// @dev Revert when caller is not authorized (not ADMIN_ROLE)
    error UnauthorizedCaller(address caller);

    // ============================== //
    //            Events              //
    // ============================== //

    /// @notice Emitted when a core contract address is updated/registered
    /// @param contractName Name of the contract (e.g., "GovAgency", "VehicleRegistration")
    /// @param oldAddress Previous address (address(0) if first time)
    /// @param newAddress New registered address
    event CoreContractUpdated(
        string indexed contractName,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice Emitted when the system is paused by admin
    /// @param admin Address of the admin who paused
    event SystemPaused(address indexed admin);

    /// @notice Emitted when the system is unpaused by admin
    /// @param admin Address of the admin who unpaused
    event SystemUnpaused(address indexed admin);

    // ============================== //
    //     External Set Functions     //
    // ============================== //

    /// @notice Sets / updates the address of GovAgency contract
    /// @param _govAgency New address of GovAgency
    function setGovAgency(address _govAgency) external;

    /// @notice Sets / updates the address of VehicleRegistration contract
    /// @param _vehicleRegistration New address of VehicleRegistration
    function setVehicleRegistration(address _vehicleRegistration) external;

    /// @notice Sets / updates the address of OffenceAndRenewal contract
    /// @param _offenceAndRenewal New address of OffenceAndRenewal
    function setOffenceAndRenewal(address _offenceAndRenewal) external;

    /// @notice Sets / updates the address of DriverLicense contract
    /// @param _driverLicense New address of DriverLicense
    function setDriverLicense(address _driverLicense) external;

    /// @notice Pauses the entire system (affects contracts that check isPaused)
    function pause() external;

    /// @notice Unpauses the system
    function unpause() external;

    // ============================== //
    //     External Get Functions     //
    // ============================== //

    /// @notice Returns the current address of GovAgency
    /// @return Address of GovAgency contract
    function govAgency() external view returns (address);

    /// @notice Returns the current address of VehicleRegistration
    /// @return Address of VehicleRegistration contract
    function vehicleRegistration() external view returns (address);

    /// @notice Returns the current address of OffenceAndRenewal
    /// @return Address of OffenceAndRenewal contract
    function offenceAndRenewal() external view returns (address);

    /// @notice Returns the current address of DriverLicense
    /// @return Address of DriverLicense contract
    function driverLicense() external view returns (address);

    /// @notice Checks if the system is currently paused
    /// @return True if paused, false otherwise
    function isPaused() external view returns (bool);

    /// @notice Checks if a given address is registered as GovAgency
    /// @param _addr Address to check
    /// @return True if _addr is the current GovAgency and not zero
    function isGovAgency(address _addr) external view returns (bool);

    /// @notice Checks if a given address is registered as VehicleRegistration
    /// @param _addr Address to check
    /// @return True if _addr is the current VehicleRegistration and not zero
    function isVehicleRegistration(address _addr) external view returns (bool);

    /// @notice Checks if a given address is registered as OffenceAndRenewal
    /// @param _addr Address to check
    /// @return True if _addr is the current OffenceAndRenewal and not zero
    function isOffenceAndRenewal(address _addr) external view returns (bool);

    /// @notice Checks if a given address is registered as DriverLicense
    /// @param _addr Address to check
    /// @return True if _addr is the current DriverLicense and not zero
    function isDriverLicense(address _addr) external view returns (bool);

    /// @notice Returns all registered core contract addresses in a struct/array format
    /// @return govAgencyAddr GovAgency address
    /// @return vehicleRegistrationAddr VehicleRegistration address
    /// @return offenceAndRenewalAddr OffenceAndRenewal address
    /// @return driverLicenseAddr DriverLicense address
    /// @return pausedStatus Current pause status
    function getAllCoreContracts()
        external
        view
        returns (
            address govAgencyAddr,
            address vehicleRegistrationAddr,
            address offenceAndRenewalAddr,
            address driverLicenseAddr,
            bool pausedStatus
        );
}
