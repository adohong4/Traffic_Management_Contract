// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library DriverLicenseStruct {
    enum LicenseStatus {
        ACTIVE, // hoạt động
        SUSPENDED, // tạm hoãn
        REVOKED, // thu hồi
        EXPIRED // hết hạn

    }

    struct License {
        uint256 tokenId; // ID token cho NFT
        string licenseId; // Mã bằng lái xe
        address holderAddress; // Địa chỉ ví của người sở hữu
        string holderId; // CCCD
        string name; // họ tên
        string dob; // ngày tháng năm sinh
        string licenseType; // Mã bằng lái
        uint256 issueDate; // Ngày bắt đầu
        uint256 expiryDate; // Ngày kết thúc
        LicenseStatus status; // Trạng thái bằng
        string ipfsHash; // Mã IPFS cho ảnh đại diện
        string authorityId; // ID cơ quan chức năng
    }
}
