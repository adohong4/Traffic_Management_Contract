// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";

library GovAgencyStruct {
    struct GovAgency {
        address addressGovAgency;
        string agencyId;
        string name;
        string location;
        string role;
        Enum.Status status;
    }

    struct AgencyInput {
        address addressGovAgency;
        string agencyId;
        string name;
        string location;
    }

    struct AgencyUpdateInput {
        address addressGovAgency;
        string name;
        string location;
        string role;
        Enum.Status status;
    }
}
