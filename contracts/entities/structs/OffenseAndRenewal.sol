// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";

library OffenceAndRenewalStruct {
    struct RenewLicense {
        string licenseType;
        uint256 bonusTime;
        string description;
        Enum.Status status;
    }

    struct Offence {
        string errorId;
        int256 point;
    }
}
