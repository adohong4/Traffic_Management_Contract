// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../entities/structs/VehicleRegistrationStruct.sol";

interface IVehicleRegistration {
    //events
    event Registration(address indexed _addressAgent, string _vehiclePlateNo, uint256 _timestamp);
    event Update(address indexed _addressAgent, string _vehiclePlateNo, uint256 _timestamp);
    event Revoke(address indexed _addressAgent, string _vehiclePlateNo, uint256 _timestamp);

    /**
     * @dev Registers a new vehicle
     * @param input The registration input data
     */
    function registerVehicleRegistration(VehicleRegistrationStruct.RegistrationInput calldata input) external;

    /**
     * @dev Updates an existing vehicle registration
     * @param __vehiclePlateNo The vehicle plate number to update
     * @param input The updated registration data
     */
    function updateVehicleRegistration(
        string calldata __vehiclePlateNo,
        VehicleRegistrationStruct.RegistrationUpdateInput calldata input
    ) external;

    /**
     * @dev Retrieves vehicle registration details by address user
     * @param _addressUser The address user to query
     * @return The vehicle registration details
     */
    function getVehicleByAddressUser(address _addressUser)
        external
        view
        returns (VehicleRegistrationStruct.VehicleRegistration[] memory);

    /**
     * @dev Get all vehicle registrations
     * @return An array of all vehicle registrations
     */
    function getAllVehicleRegistrations()
        external
        view
        returns (VehicleRegistrationStruct.VehicleRegistration[] memory);

    /**
     * @dev Retrieves vehicle registration details by vehicle plate number
     */
    function RevokeVehicleRegistration(string memory _vehiclePlateNo) external;
}
