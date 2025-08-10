example:
issue Driver License: tuple ["ABC123460", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "HOLDER003", "Juwngkog", "B", 1672531200, 1704067200, "AUTH001", 12]
// expiryDate < 1753290000 (đã hết hạn)
  ["ABC100001", 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "HOLDER001", "Nguyen Van A", "B", 1672531200, 1700000000, "AUTH001", 12]
  
  // expiryDate > 1753290000 (còn hiệu lực)
  ["ABC100002", 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "HOLDER002", "Le Thi B", "B", 1680000000, 1760000000, "AUTH002", 12]
  
  // expiryDate = hôm nay (có thể coi là hết hạn nếu kiểm tra `expiryDate < block.timestamp`)
  ["ABC100003", 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "HOLDER003", "Tran Van C", "C1", 1688888888, 1753290000, "AUTH003", 12]
  
  // expiryDate > hôm nay
  ["ABC100004", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "HOLDER004", "Pham Thi D", "D2", 1690000000, 1800000000, "AUTH004", 12]

  // expiryDate < hôm nay
  ["ABC100005", 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, "HOLDER005", "Dang Van E", "E1", 1672531200, 1740000000, "AUTH005", 12]

Deduct Point: License_No: ABC123456, tuple ["Ma123", 1]

Update Driver License: tuple: ["ABC123460", 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Juwngkog", "A1", 1837443600, 2, 12]


issue Gov Agency: ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "CA123", "Cong an ha noi", "Ha noi"]


function main.test.sol:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../security/AccessControl.sol";
import "../libraries/LibStorage.sol";
import "../libraries/LibAccessControl.sol";
import "./facets/OffenceAndRenewal.sol";
import "./facets/GovAgencyFacet.sol";
import "./facets/LicenseAndOffenceFacet.sol";
import "./facets/VehicleRegistration.sol";

contract MainContract is AccessControl, GovAgencyFacet, LicenseAndOffenceFacet {
    constructor(address admin) {
        // Cấp quyền cho admin khởi tạo
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(GOV_AGENCY_ROLE, admin);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(GOV_AGENCY_ROLE, msg.sender);
    }
}
```

[
  ["0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99", 0, ["0xd8e30e70"]],
  ["0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005", 0, ["0x585582fb", "0xe6ff763a", "0x567a3f7c", "0x7a0ed627"]],
  ["0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d", 0, ["0x880ad0af", "0x8da5cb5b"]],
  ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", 0, ["0x19e3b533", "0x0716c2ae", "0x11046047", "0xcf3bbe18", "0x24c1d5a7"]],
  ["0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c", 0, ["0xea36b558", "0xe7de23a4", "0x0e4cd7fc", "0xc670641d"]]
]