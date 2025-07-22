// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../constants/Constants.sol";
import "../../constants/Enum.sol";
import "../../constants/Success.sol";
import "../../constants/NFTConstants.sol";
import "../../entities/structs/DriverLicenseStruct.sol";
import "../../utils/Validator.sol";
import "../../utils/DateTime.sol";
import "../../utils/Loggers.sol";
import "../../utils/NFTUtils.sol";
import "../../libraries/LibStorage.sol";
import "../../libraries/LibAccessControl.sol";
import "../../libraries/LibSharedFunctions.sol";
import "../../libraries/LibNFT.sol";
import "../../interfaces/external/IERC4671.sol";
import "../../interfaces/external/IDriverLicense.sol";

/**
 * @title DriverLicenseFacet
 * @dev Manages driver licenses as ERC-4671 NFTs in the traffic management system
 */
contract DriverLicenseFacet is IDriverLicense, IERC4671 {
    // Events for ERC-4671
    event LicenseIssued(string indexed licenseNo, address indexed holder, uint256 issueDate);
    event LicenseUpdated(string indexed licenseNo, uint256 newExpiryDate, Enum.LicenseStatus newStatus);
    event LicenseRevoked(string indexed licenseNo, uint256 timestamp);

    /**
     * @dev Issues a new driver license as an ERC-4671 NFT
     */
    function issueLicense(
        string memory _licenseNo,
        address _holderAddress,
        string memory _holderId,
        string memory _name,
        string memory _licenseType,
        uint256 _issueDate,
        uint256 _expiryDate,
        string memory _authorityId,
        uint256 _point
    ) external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(_licenseNo);
        Validator.checkAddress(_holderAddress);
        Validator.checkString(_holderId);
        Validator.checkString(_licenseType);
        Validator.checkString(_authorityId);
        Validator.checkPoints(_point);
        if (bytes(ls.licenses[_licenseNo].licenseNo).length != 0) revert Errors.AlreadyExists();
        if (_issueDate > _expiryDate) revert Errors.InvalidInput();

        if (ls.holderToTokenIds[_holderAddress].length >= 12) {
            revert Errors.InvalidInput();
        }

        // Generate token ID
        uint256 tokenId = ls.tokenCount;
        ls.tokenCount++;

        // Store license data
        ls.licenses[_licenseNo] = DriverLicenseStruct.DriverLicense(
            tokenId,
            _licenseNo,
            _holderAddress,
            _holderId,
            _name,
            _licenseType,
            _issueDate,
            _expiryDate,
            Enum.LicenseStatus.ACTIVE,
            _authorityId,
            _point
        );

        // Update ERC-4671 mappings
        ls.tokenIdToLicenseNo[tokenId] = _licenseNo;
        ls.tokenToOwner[tokenId] = _holderAddress;
        ls.holderToTokenIds[_holderAddress].push(tokenId);
        if (ls.holderToTokenIds[_holderAddress].length == 1) {
            ls.holderCount++;
        }
        ls.validBalance[_holderAddress]++;

        // Log success
        Loggers.logSuccess("License issued successfully");

        // Emit events
        emit LicenseIssued(_licenseNo, _holderAddress, _issueDate);
        emit IERC4671.Issued(_holderAddress, tokenId);
    }

    /**
     * @dev Updates an existing license
     */
    function updateLicense(
        string memory _licenseNo,
        address _holderAddress,
        string memory _name,
        string memory _licenseType,
        uint256 _expiryDate,
        Enum.LicenseStatus _status,
        uint256 _point
    ) external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(_licenseNo);
        Validator.checkAddress(_holderAddress);
        Validator.checkPoints(_point);
        if (bytes(ls.licenses[_licenseNo].licenseNo).length == 0) revert Errors.NotFound();
        if (_expiryDate < ls.licenses[_licenseNo].issueDate) revert Errors.InvalidInput();

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[_licenseNo];
        bool wasValid = license.status == Enum.LicenseStatus.ACTIVE && !DateTime.isExpired(license.expiryDate);

        // Update holder mappings if holder changes
        if (license.holderAddress != _holderAddress) {
            uint256 tokenId = license.tokenId;
            _updateHolderMapping(tokenId, license.holderAddress, _holderAddress, wasValid);
            license.holderAddress = _holderAddress;
        }

        // Update license data
        license.name = _name;
        license.licenseType = _licenseType;
        license.expiryDate = _expiryDate;
        license.status = _status;
        license.point = _point;

        // Update valid balance
        bool isValid = _status == Enum.LicenseStatus.ACTIVE && !DateTime.isExpired(_expiryDate);
        if (wasValid && !isValid) {
            ls.validBalance[_holderAddress]--;
        } else if (!wasValid && isValid) {
            ls.validBalance[_holderAddress]++;
        }

        // Log success
        Loggers.logSuccess("License updated successfully");

        emit LicenseUpdated(_licenseNo, _expiryDate, _status);
    }

    /**
     * @dev Internal function to update holder mappings when holder changes
     */
    function _updateHolderMapping(uint256 tokenId, address oldHolder, address newHolder, bool wasValid) private {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256[] storage oldHolderTokens = ls.holderToTokenIds[oldHolder];
        uint256 index = LibSharedFunctions.findIndex(oldHolderTokens, tokenId);
        LibSharedFunctions.removeByIndex(oldHolderTokens, index);
        if (oldHolderTokens.length == 0 && ls.validBalance[oldHolder] == 0) {
            ls.holderCount--;
        }
        ls.holderToTokenIds[newHolder].push(tokenId);
        ls.tokenToOwner[tokenId] = newHolder;
        if (ls.holderToTokenIds[newHolder].length == 1) {
            ls.holderCount++;
        }
        if (wasValid) {
            ls.validBalance[oldHolder]--;
            ls.validBalance[newHolder]++;
        }
    }

    /**
     * @dev Revokes a License
     */
    function revokeLicense(string memory _licenseNo) external override {
        LibAccessControl.enforceRole(keccak256("GOV_AGENCY_ROLE"));
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(_licenseNo);
        if (bytes(ls.licenses[_licenseNo].licenseNo).length == 0) revert Errors.NotFound();

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[_licenseNo];
        bool wasValid = license.status == Enum.LicenseStatus.ACTIVE && !DateTime.isExpired(license.expiryDate);

        license.status = Enum.LicenseStatus.REVOKED;
        if (wasValid) {
            ls.validBalance[license.holderAddress]--;
        }

        uint256 tokenId = license.tokenId;

        // Log success
        Loggers.logSuccess("License revoked successfully");

        emit LicenseRevoked(_licenseNo, block.timestamp);
        emit Revoked(license.holderAddress, tokenId);
    }

    /**
     * @dev Get all licenses
     */
    function getAllLicenses() external view override returns (DriverLicenseStruct.DriverLicense[] memory) {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        DriverLicenseStruct.DriverLicense[] memory allLicenses = new DriverLicenseStruct.DriverLicense[](ls.tokenCount);
        for (uint256 i = 0; i < ls.tokenCount; i++) {
            allLicenses[i] = ls.licenses[ls.tokenIdToLicenseNo[i]];
        }
        return allLicenses;
    }

    /**
     * @dev Retrieves licenses by holder address
     */
    function getLicensesByHolder(address _holderAddress)
        external
        view
        override
        returns (DriverLicenseStruct.DriverLicense[] memory)
    {
        Validator.checkAddress(_holderAddress);
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256[] memory tokenIds = ls.holderToTokenIds[_holderAddress];
        DriverLicenseStruct.DriverLicense[] memory holderLicenses =
            new DriverLicenseStruct.DriverLicense[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            holderLicenses[i] = ls.licenses[ls.tokenIdToLicenseNo[tokenIds[i]]];
        }
        return holderLicenses;
    }

    /**
     * @dev Retrieves a license by licenseNO
     */
    function getLicense(string memory _licenseNo)
        external
        view
        override
        returns (DriverLicenseStruct.DriverLicense memory)
    {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        if (bytes(ls.licenses[_licenseNo].licenseNo).length == 0) revert Errors.NotFound();
        return ls.licenses[_licenseNo];
    }

    /**
     * @dev Returns the total number of licenses
     */
    function getLicenseCount() external view override returns (uint256) {
        return LibStorage.licenseStorage().tokenCount;
    }

    /**
     * IERC24 override
     */

    /**
     * @dev Returns the number of unique holders
     */
    function holdersCount() external view override returns (uint256) {
        return LibStorage.licenseStorage().holderCount;
    }

    /**
     * @dev Returns the total number of issued tokens
     */
    function emittedCount() external view override returns (uint256) {
        return LibStorage.licenseStorage().tokenCount;
    }

    /**
     * @dev Checks if a token is valid
     */
    function isValid(uint256 tokenId) external view override returns (bool) {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        string memory licenseNo = ls.tokenIdToLicenseNo[tokenId];
        if (bytes(licenseNo).length == 0) revert Errors.NotFound();
        DriverLicenseStruct.DriverLicense memory license = ls.licenses[licenseNo];
        return license.status == Enum.LicenseStatus.ACTIVE && !DateTime.isExpired(license.expiryDate);
    }

    /**
     * @dev Returns the owner of a token
     */
    function ownerOf(uint256 tokenId) external view override returns (address) {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        address owner = ls.tokenToOwner[tokenId];
        if (owner == address(0)) revert Errors.NotFound();
        return owner;
    }

    /**
     * @dev Returns the number of valid tokens for an owner
     */
    function balanceOf(address owner) external view override returns (uint256) {
        Validator.checkAddress(owner);
        return LibStorage.licenseStorage().validBalance[owner];
    }

    /**
     * @dev Checks if an owner has at least one valid token
     */
    function hasValid(address owner) external view override returns (bool) {
        Validator.checkAddress(owner);
        return LibStorage.licenseStorage().validBalance[owner] > 0;
    }
}
