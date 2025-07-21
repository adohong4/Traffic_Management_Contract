// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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
abstract contract DriverLicenseFacet is IDriverLicense, IERC4671 {
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
}
