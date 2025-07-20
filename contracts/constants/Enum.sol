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
}
