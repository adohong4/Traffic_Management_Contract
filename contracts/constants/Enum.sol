// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Enum {
    // License status enum
    enum LicenseStatus {
        ACTIVE,
        SUSPENDED,
        REVOKED,
        EXPIRED
    }

    enum Status {
        PENDING,
        APPROVED,
        REJECTED,
        ACTIVE,
        PAUSED,
        REVOKED,
        COMPLETED
    }

    enum ColorPlate {
        WHITE,
        YELLOW,
        BLUE,
        RED
    }
}
