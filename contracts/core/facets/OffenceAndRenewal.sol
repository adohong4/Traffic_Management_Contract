// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./DriverLicenseFacet.sol";
import "../../interfaces/external/IOffenceRenewal.sol";

abstract contract PenaltyAndRenewal is DriverLicenseFacet, IOffenceRenewal {}
