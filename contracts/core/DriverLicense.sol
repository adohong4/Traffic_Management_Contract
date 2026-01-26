// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../constants/Constants.sol";
import "../constants/Enum.sol";
import "../constants/Success.sol";
import "../constants/NFTConstants.sol";
import "../entities/structs/DriverLicenseStruct.sol";
import "../utils/Validator.sol";
import "../utils/DateTime.sol";
import "../utils/Loggers.sol";
import "../utils/NFTUtils.sol";
import "../libraries/LibStorage.sol";
import "../libraries/LibAccessControl.sol";
import "../libraries/LibSharedFunctions.sol";
import "../libraries/LibNFT.sol";
import "../interfaces/external/IERC4671.sol";
import "../interfaces/external/IDriverLicense.sol";
import "../security/ReEntrancyGuard.sol";
import "../libraries/LibRegistration.sol";
import "../interfaces/ITrafficController.sol";

/**
 * @title DriverLicenseFacet
 * @dev Manages driver licenses as ERC-4671 NFTs in the traffic management system
 */
contract DriverLicense is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IDriverLicense,
    IERC4671
{
    address public trafficController;

    bytes32 public constant GOV_AGENCY_ROLE = keccak256("GOV_AGENCY_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // initialize
    function initialize(address _trafficController) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        trafficController = _trafficController;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOV_AGENCY_ROLE, msg.sender);
    }

    /**
     * @dev Issues a new driver license as an ERC-4671 NFT
     */
    function issueLicense(
        DriverLicenseStruct.LicenseInput calldata input
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        _validateRegistration();
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        Validator.checkString(input.licenseNo);
        Validator.checkAddress(input.holderAddress);
        Validator.checkString(input.holderId);
        Validator.checkString(input.licenseType);
        Validator.checkString(input.authorityId);
        Validator.checkPoints(input.point);

        if (bytes(ls.licenses[input.licenseNo].licenseNo).length != 0)
            revert Errors.AlreadyExists();
        if (input.issueDate > input.expiryDate) revert Errors.InvalidInput();

        uint256 tokenId = ls.tokenCount + 1;
        ls.tokenCount = tokenId;

        ls.licenses[input.licenseNo] = DriverLicenseStruct.DriverLicense(
            tokenId,
            input.licenseNo,
            input.holderAddress,
            input.holderId,
            input.name,
            input.licenseType,
            input.issueDate,
            input.expiryDate,
            Enum.LicenseStatus.ACTIVE,
            input.authorityId,
            input.point
        );

        uint256[] storage holderTokens = ls.holderToTokenIds[
            input.holderAddress
        ];
        if (holderTokens.length >= 12) revert Errors.InvalidInput();

        holderTokens.push(tokenId);
        if (holderTokens.length == 1) {
            ls.holderCount++;
        }
        ls.validBalance[input.holderAddress]++;
        ls.tokenIdToLicenseNo[tokenId] = input.licenseNo;
        ls.tokenToOwner[tokenId] = input.holderAddress;

        Loggers.logSuccess("License issued successfully");

        emit LicenseIssued(
            input.licenseNo,
            input.holderAddress,
            input.issueDate
        );
        emit IERC4671.Issued(input.holderAddress, tokenId);
    }

    /**
     * @dev Updates an existing license
     */
    function updateLicense(
        DriverLicenseStruct.LicenseUpdateInput calldata input
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        // Validations
        Validator.checkString(input.licenseNo);
        Validator.checkAddress(input.holderAddress);
        Validator.checkPoints(input.point);
        if (bytes(ls.licenses[input.licenseNo].licenseNo).length == 0)
            revert Errors.NotFound();

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[
            input.licenseNo
        ];
        bool wasValid = license.status == Enum.LicenseStatus.ACTIVE &&
            !DateTime.isExpired(license.expiryDate);
        if (input.expiryDate < license.issueDate) revert Errors.InvalidInput();

        // Update holder mappings if holder changes
        if (license.holderAddress != input.holderAddress) {
            uint256 tokenId = license.tokenId;
            _updateHolderMapping(
                tokenId,
                license.holderAddress,
                input.holderAddress,
                wasValid
            );
            license.holderAddress = input.holderAddress;
        }

        // Update license data
        license.name = input.name;
        license.licenseType = input.licenseType;
        license.expiryDate = input.expiryDate;
        license.status = input.status;
        license.point = input.point;

        // Update valid balance
        bool isValid = input.status == Enum.LicenseStatus.ACTIVE &&
            !DateTime.isExpired(input.expiryDate);
        if (wasValid && !isValid) {
            ls.validBalance[input.holderAddress]--;
        } else if (!wasValid && isValid) {
            ls.validBalance[input.holderAddress]++;
        }

        // Log success
        Loggers.logSuccess("License updated successfully");

        emit LicenseUpdated(input.licenseNo, input.expiryDate, input.status);
    }

    /**
     * @dev Internal function to update holder mappings when holder changes
     */
    function _updateHolderMapping(
        uint256 tokenId,
        address oldHolder,
        address newHolder,
        bool wasValid
    ) private {
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
    function revokeLicense(
        string calldata _licenseNo
    ) external override nonReentrant onlyRole(GOV_AGENCY_ROLE) {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();

        // Validation
        Validator.checkString(_licenseNo);
        if (bytes(ls.licenses[_licenseNo].licenseNo).length == 0)
            revert Errors.NotFound();

        DriverLicenseStruct.DriverLicense storage license = ls.licenses[
            _licenseNo
        ];
        bool wasValid = license.status == Enum.LicenseStatus.ACTIVE &&
            !DateTime.isExpired(license.expiryDate);

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
    function getAllLicenses()
        external
        view
        override
        returns (DriverLicenseStruct.DriverLicense[] memory)
    {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256 tokenCount = ls.tokenCount;
        uint256 validCount = 0;

        // Đếm số giấy phép hợp lệ
        for (uint256 i = 1; i <= tokenCount; i++) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            if (
                bytes(licenseNo).length > 0 &&
                bytes(ls.licenses[licenseNo].licenseNo).length > 0
            ) {
                validCount++;
            }
        }

        // Tạo mảng kết quả với kích thước chính xác
        DriverLicenseStruct.DriverLicense[]
            memory allLicenses = new DriverLicenseStruct.DriverLicense[](
                validCount
            );
        uint256 index = 0;

        // Lấy các giấy phép hợp lệ
        for (uint256 i = 1; i <= tokenCount; i++) {
            string memory licenseNo = ls.tokenIdToLicenseNo[i];
            if (
                bytes(licenseNo).length > 0 &&
                bytes(ls.licenses[licenseNo].licenseNo).length > 0
            ) {
                allLicenses[index] = ls.licenses[licenseNo];
                index++;
            }
        }
        return allLicenses;
    }

    /**
     * @dev Retrieves licenses by holder address
     */
    function getLicensesByHolder(
        address _holderAddress
    )
        external
        view
        override
        returns (DriverLicenseStruct.DriverLicense[] memory)
    {
        Validator.checkAddress(_holderAddress);
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        uint256[] memory tokenIds = ls.holderToTokenIds[_holderAddress];
        uint256 len = tokenIds.length;
        DriverLicenseStruct.DriverLicense[]
            memory holderLicenses = new DriverLicenseStruct.DriverLicense[](
                len
            );

        for (uint256 i = 0; i < len; ) {
            holderLicenses[i] = ls.licenses[ls.tokenIdToLicenseNo[tokenIds[i]]];
            unchecked {
                ++i;
            }
        }
        return holderLicenses;
    }

    /**
     * @dev Retrieves a license by licenseNo
     */
    function getLicense(
        string calldata _licenseNo
    )
        external
        view
        override
        returns (DriverLicenseStruct.DriverLicense memory)
    {
        LibStorage.LicenseStorage storage ls = LibStorage.licenseStorage();
        if (bytes(ls.licenses[_licenseNo].licenseNo).length == 0)
            revert Errors.NotFound();
        return ls.licenses[_licenseNo];
    }

    /**
     * @dev Returns the total number of licenses
     */
    function getLicenseCount() external view override returns (uint256) {
        return LibStorage.licenseStorage().tokenCount;
    }

    /**
     * IERC4671 override
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
        DriverLicenseStruct.DriverLicense memory license = ls.licenses[
            licenseNo
        ];
        return
            license.status == Enum.LicenseStatus.ACTIVE &&
            !DateTime.isExpired(license.expiryDate);
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

    // ------------------------------------------------------------------- //
    // --------------------------- Internal  ------------------------------//
    // ------------------------------------------------------------------- //

    /// @dev Override _authorizeUpgrade function to add authorization
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev Validate
    function _validateRegistration() internal view {
        LibRegistration.validate(
            trafficController,
            ITrafficController(trafficController).driverLicense
        );
    }
}
