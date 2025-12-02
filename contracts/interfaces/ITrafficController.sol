// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITrafficController {
    event ModuleUpdated(bytes32 indexed key, address indexed module);
    event TreasuryUpdated(address indexed treasury);
    event ProtocolFeeUpdated(uint256 fee);
    event OracleUpdated(address indexed oracle);
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    error ZeroAddress();
    error NotContract();
    error ArrayLengthMismatch();
    error UnauthorizedModule(address caller);
    error SystemPaused();
    error ModuleNotRegistered(bytes32 key);
}
