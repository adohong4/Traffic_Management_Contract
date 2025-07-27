// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";

library VehicleRegistrationStruct {
    /**
     * @dev Struct to hold vehicle registration details
     */
    struct VehicleRegistration {
        address addressUser;
        string identityNo;
        string vehicleModel;
        string chassisNo;
        string vehiclePlateNo;
        uint256 colorPlate;
        Enum.Status status;
    }

    /**
     * @dev Struct for input data when registering a vehicle
     */
    struct RegistrationInput {
        address addressUser;
        string identityNo;
        string vehicleModel;
        string chassisNo;
        string vehiclePlateNo;
        Enum.ColorPlate colorPlate; // 0: White, 1: Green, 2: Blue, 3: Red
    }

    /**
     * @dev Struct for updating vehicle registration details
     */
    struct RegistrationUpdateInput {
        address addressUser;
        string identityNo;
        uint256 colorPlate;
    }
}
