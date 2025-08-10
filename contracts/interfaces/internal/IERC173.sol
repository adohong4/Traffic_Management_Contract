// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IERC173
 * @dev ERC-173 Contract Ownership Standard
 * @notice This interface defines the ownership management functions for a contract.
 */

/* is ERC165 */
interface IERC173 {
    /**
     * @notice Emitted when ownership of the contract is transferred.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Gets the address of the current owner.
     * @return owner_ The address of the current owner.
     */
    function owner() external view returns (address owner_);

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Can only be called by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external;
}
