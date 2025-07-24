// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Enum.sol";

library DriverLicenseStruct {
    struct DriverLicense {
        uint256 tokenId; // ID token cho NFT
        string licenseNo; // Mã bằng lái xe
        address holderAddress; // Địa chỉ ví của người sở hữu
        string holderId; // CCCD
        string name; // họ tên
        string licenseType; // Mã bằng lái
        uint256 issueDate; // Ngày bắt đầu
        uint256 expiryDate; // Ngày kết thúc
        Enum.LicenseStatus status; // Trạng thái bằng
        string authorityId; // ID cơ quan chức năng
        uint256 point; // 0 <= point <= 12
    }

    struct LicenseInput {
        string licenseNo;
        address holderAddress;
        string holderId;
        string name;
        string licenseType;
        uint256 issueDate;
        uint256 expiryDate;
        string authorityId;
        uint256 point;
    }

    struct LicenseUpdateInput {
        string licenseNo;
        address holderAddress;
        string name;
        string licenseType;
        uint256 expiryDate;
        Enum.LicenseStatus status;
        uint256 point;
    }
}
