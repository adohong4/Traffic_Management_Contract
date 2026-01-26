// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../interfaces/ITrafficController.sol";

library LibRegistration {
    function validate(
        address controller,
        function() external view returns (address) getter
    ) internal view {
        require(controller != address(0), "Controller not set");
        require(getter() == address(this), "Contract not registered");
    }
}
