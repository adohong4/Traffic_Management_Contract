// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//* Implementation of a diamond.
import {LibDiamond} from "../libraries/LibDiamond.sol";

error AddressAndCalldataLengthDoNotMatch(uint256 _addressesLength, uint256 _calldataLength);

contract DiamondMultiInit {
    /*     
     * @dev Initializes multiple facets in a diamond.
     * @param _addresses Array of facet addresses to initialize.
     * @param _calldata Array of calldata for each facet's initialization.
     */
    function multiInit(address[] calldata _addresses, bytes[] calldata _calldata) external {
        if (_addresses.length != _calldata.length) {
            revert AddressAndCalldataLengthDoNotMatch(_addresses.length, _calldata.length);
        }
        for (uint256 i; i < _addresses.length; i++) {
            LibDiamond.initializeDiamondCut(_addresses[i], _calldata[i]);
        }
    }
}
