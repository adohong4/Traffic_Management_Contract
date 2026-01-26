// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../constants/Constants.sol";
import "../constants/Enum.sol";
import "../constants/Success.sol";
import "../constants/NFTConstants.sol";
import "../entities/structs/VehicleRegistrationStruct.sol";
import "../utils/Validator.sol";
import "../utils/DateTime.sol";
import "../utils/Loggers.sol";
import "../utils/NFTUtils.sol";
import "../libraries/LibStorage.sol";
import "../libraries/LibAccessControl.sol";
import "../libraries/LibSharedFunctions.sol";
import "../libraries/LibNFT.sol";
import "../interfaces/external/IERC4671.sol";
import "../interfaces/external/IVehicleRegistration.sol";
import "../security/ReEntrancyGuard.sol";
import "../security/AccessControl.sol";

abstract contract VehicleRegistration is
    IVehicleRegistration,
    IERC4671,
    ReEntrancyGuard,
    AccessControl
{
    // Constructor: grant role
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GOV_AGENCY_ROLE, msg.sender);
    }

    /**
     * @dev Create a new Vehicle license as an ERC-4671 NFT
     */
    function registerVehicleRegistration(
        VehicleRegistrationStruct.RegistrationInput calldata input
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        // LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));

        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();

        Validator.checkAddress(input.addressUser);
        Validator.checkString(input.identityNo);
        Validator.checkString(input.vehicleModel);
        Validator.checkString(input.chassisNo);
        Validator.checkString(input.vehiclePlateNo);

        if (
            bytes(vrs.registrations[input.vehiclePlateNo].vehiclePlateNo)
                .length != 0
        ) revert Errors.AlreadyExists();

        uint256 vehicleTokenId = vrs.registrationCount + 1;
        vrs.registrationCount = vehicleTokenId;

        vrs.registrations[input.vehiclePlateNo] = VehicleRegistrationStruct
            .VehicleRegistration({
                addressUser: input.addressUser,
                identityNo: input.identityNo,
                vehicleModel: input.vehicleModel,
                chassisNo: input.chassisNo,
                vehiclePlateNo: input.vehiclePlateNo,
                colorPlate: uint256(input.colorPlate),
                status: Enum.Status.ACTIVE
            });

        vrs.addressToVehiclePlateNos[input.addressUser].push(
            input.vehiclePlateNo
        );
        vrs.vehiclePlateNoExists[input.vehiclePlateNo] = true;
        vrs.vehiclePlateNos.push(input.vehiclePlateNo);

        // save infomation to NFT
        vrs.tokenIdToVehiclePlateNo[vehicleTokenId] = input.vehiclePlateNo;
        vrs.tokenToOwner[vehicleTokenId] = input.addressUser;
        vrs.validBalance[input.addressUser]++;

        // check and update the number of unique holders
        if (vrs.validBalance[input.addressUser] == 1) {
            vrs.holderCount++;
        }

        // log the event
        Loggers.logSuccess("Vehicle registration issued successfully");
        emit Registration(
            input.addressUser,
            input.vehiclePlateNo,
            block.timestamp
        );
        emit VehicleRegistrationIssued(
            input.vehiclePlateNo,
            input.addressUser,
            vehicleTokenId
        );
        emit IERC4671.Issued(input.addressUser, vehicleTokenId);
    }

    /**
     * @dev Updates an existing vehicle registration
     */
    function updateVehicleRegistration(
        string calldata __vehiclePlateNo,
        VehicleRegistrationStruct.RegistrationUpdateInput calldata input
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        // LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();

        Validator.checkString(__vehiclePlateNo);
        Validator.checkString(input.identityNo);
        Validator.checkAddress(input.addressUser);

        // Check if the vehicle plate number exists
        if (
            bytes(vrs.registrations[__vehiclePlateNo].vehiclePlateNo).length ==
            0
        ) revert Errors.NotFound();

        VehicleRegistrationStruct.VehicleRegistration storage registration = vrs
            .registrations[__vehiclePlateNo];
        bool wasValid = registration.status == Enum.Status.ACTIVE;

        // Update the registration details
        if (registration.addressUser != input.addressUser) {
            uint256 oldtokenId = _findTokenIdByVehiclePlateNo(__vehiclePlateNo);
            _updateHolderMapping(
                oldtokenId,
                registration.addressUser,
                input.addressUser,
                wasValid
            );
        }

        // upadte the registration details
        registration.identityNo = input.identityNo;
        registration.colorPlate = input.colorPlate;

        // Update the status to ACTIVE
        bool isValid = registration.status == Enum.Status.ACTIVE;
        if (wasValid && !isValid) {
            vrs.validBalance[input.addressUser]--;
        } else if (!wasValid && isValid) {
            vrs.validBalance[input.addressUser]++;
        }

        Loggers.logSuccess("Vehicle registration updated successfully");
        emit Update(input.addressUser, __vehiclePlateNo, block.timestamp);
        emit VehicleRegistrationUpdated(
            __vehiclePlateNo,
            input.addressUser,
            block.timestamp
        );
    }

    /**
     * @dev Internal function to find tokenId by vehiclePlateNo
     */
    function _findTokenIdByVehiclePlateNo(
        string memory vehiclePlateNo
    ) private view returns (uint256) {
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        for (uint256 i = 1; i <= vrs.registrationCount; i++) {
            if (
                keccak256(bytes(vrs.tokenIdToVehiclePlateNo[i])) ==
                keccak256(bytes(vehiclePlateNo))
            ) {
                return i;
            }
        }
        revert Errors.NotFound();
    }

    /**
     * @dev Internal function to update holder mappings when owner changes
     */
    function _updateHolderMapping(
        uint256 tokenId,
        address oldHolder,
        address newHolder,
        bool wasValid
    ) private {
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        string[] storage oldHolderPlates = vrs.addressToVehiclePlateNos[
            oldHolder
        ];
        string memory plateNo = vrs.tokenIdToVehiclePlateNo[tokenId];
        uint256 index = LibSharedFunctions.findIndexString(
            oldHolderPlates,
            plateNo
        );
        LibSharedFunctions.removeStringByIndex(oldHolderPlates, index);

        if (oldHolderPlates.length == 0 && vrs.validBalance[oldHolder] == 0) {
            vrs.holderCount--;
        }

        vrs.addressToVehiclePlateNos[newHolder].push(plateNo);
        vrs.tokenToOwner[tokenId] = newHolder;

        if (vrs.addressToVehiclePlateNos[newHolder].length == 1) {
            vrs.holderCount++;
        }

        if (wasValid) {
            vrs.validBalance[oldHolder]--;
            vrs.validBalance[newHolder]++;
        }
    }

    /**
     * @dev Revokes a vehicle registration
     */
    function RevokeVehicleRegistration(
        string memory vehiclePlateNo
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        // LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();

        // Validate input
        Validator.checkString(vehiclePlateNo);
        if (
            bytes(vrs.registrations[vehiclePlateNo].vehiclePlateNo).length == 0
        ) {
            revert Errors.NotFound();
        }

        VehicleRegistrationStruct.VehicleRegistration storage registration = vrs
            .registrations[vehiclePlateNo];
        bool wasValid = registration.status == Enum.Status.ACTIVE;

        // Cập nhật trạng thái
        registration.status = Enum.Status.REVOKED;
        if (wasValid) {
            vrs.validBalance[registration.addressUser]--;
        }

        uint256 tokenId = _findTokenIdByVehiclePlateNo(vehiclePlateNo);

        // Ghi log và phát sự kiện
        Loggers.logSuccess("Vehicle registration revoked successfully");
        emit Revoke(registration.addressUser, vehiclePlateNo, block.timestamp);
        emit VehicleRegistrationRevoked(
            vehiclePlateNo,
            registration.addressUser,
            block.timestamp
        );
        emit IERC4671.Revoked(registration.addressUser, tokenId);
    }

    /**
     * @dev Retrieves vehicle registration by user address
     */
    function getVehicleByAddressUser(
        address _addressUser
    )
        external
        view
        override
        returns (VehicleRegistrationStruct.VehicleRegistration[] memory)
    {
        Validator.checkAddress(_addressUser);
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        string[] memory plateNos = vrs.addressToVehiclePlateNos[_addressUser];
        VehicleRegistrationStruct.VehicleRegistration[]
            memory registrations = new VehicleRegistrationStruct.VehicleRegistration[](
                plateNos.length
            );

        for (uint256 i = 0; i < plateNos.length; i++) {
            registrations[i] = vrs.registrations[plateNos[i]];
        }
        return registrations;
    }

    /**
     * @dev Get all vehicle registrations
     */
    function getAllVehicleRegistrations()
        external
        view
        override
        returns (VehicleRegistrationStruct.VehicleRegistration[] memory)
    {
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        VehicleRegistrationStruct.VehicleRegistration[]
            memory registrations = new VehicleRegistrationStruct.VehicleRegistration[](
                vrs.vehiclePlateNos.length
            );

        for (uint256 i = 0; i < vrs.vehiclePlateNos.length; i++) {
            registrations[i] = vrs.registrations[vrs.vehiclePlateNos[i]];
        }
        return registrations;
    }

    /**
     * IERC4671 override
     */

    /**
     * @dev Checks if a token is valid
     */
    function isValid(uint256 tokenId) external view override returns (bool) {
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        string memory plateNo = vrs.tokenIdToVehiclePlateNo[tokenId];
        if (bytes(plateNo).length == 0) revert Errors.NotFound();
        return vrs.registrations[plateNo].status == Enum.Status.ACTIVE;
    }

    /**
     * @dev Returns the total number of issued tokens
     */
    function emittedCount() external view override returns (uint256) {
        return LibStorage.vehicleRegistrationStorage().registrationCount;
    }

    /**
     * @dev Returns the number of unique holders
     */
    function holdersCount() external view override returns (uint256) {
        return LibStorage.vehicleRegistrationStorage().holderCount;
    }

    /**
     * @dev Returns the owner of a token
     */
    function ownerOf(uint256 tokenId) external view override returns (address) {
        LibStorage.VehicleRegistrationStorage storage vrs = LibStorage
            .vehicleRegistrationStorage();
        address owner = vrs.tokenToOwner[tokenId];
        if (owner == address(0)) revert Errors.NotFound();
        return owner;
    }

    /**
     * @dev Returns the number of valid tokens for an owner
     */
    function balanceOf(address owner) external view override returns (uint256) {
        Validator.checkAddress(owner);
        return LibStorage.vehicleRegistrationStorage().validBalance[owner];
    }

    /**
     * @dev Checks if an owner has at least one valid token
     */
    function hasValid(address owner) external view override returns (bool) {
        Validator.checkAddress(owner);
        return LibStorage.vehicleRegistrationStorage().validBalance[owner] > 0;
    }
}
