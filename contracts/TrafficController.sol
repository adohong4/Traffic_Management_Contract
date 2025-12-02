// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {DefaultAccessControlEnumerable} from "./security/DefaultAccessControlEnumerable.sol";
import {ITrafficController} from "./interfaces/ITrafficController.sol";

contract TrafficController is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultAccessControlEnumerable,
    ITrafficController
{
    /*//////////////////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // Module addresses - thay thế cho Facet trong Diamond
    mapping(bytes32 moduleKey => address moduleAddress) public modules;

    // Các hằng role key để dễ quản lý
    bytes32 public constant DRIVER_LICENSE_MODULE = keccak256("DRIVER_LICENSE_MODULE");
    bytes32 public constant VEHICLE_REGISTRATION_MODULE = keccak256("VEHICLE_REGISTRATION_MODULE");
    bytes32 public constant GOV_AGENCY_MODULE = keccak256("GOV_AGENCY_MODULE");
    bytes32 public constant OFFENCE_RENEWAL_MODULE = keccak256("OFFENCE_RENEWAL_MODULE");
    bytes32 public constant INSURANCE_MODULE = keccak256("INSURANCE_MODULE");
    bytes32 public constant INSPECTION_MODULE = keccak256("INSPECTION_MODULE");

    // Config chung
    address public oracle; // Chainlink oracle (nếu cần)
    address public treasury; // Ví thu phí (nếu có)
    uint256 public protocolFee; // Phí hệ thống (basis points: 10000 = 100%)
    bool public paused; // Emergency pause

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        if (paused) revert SystemPaused();
        _;
    }

    modifier onlyModule(bytes32 key) {
        if (msg.sender != modules[key]) revert UnauthorizedModule(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(address admin_, address treasury_, uint256 protocolFee_) public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __DefaultAccessControlEnumerable_init(admin_);

        treasury = treasury_;
        protocolFee = protocolFee_;
        paused = false;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setModule(bytes32 key, address moduleAddr) external onlyAdmin {
        if (moduleAddr == address(0)) revert ZeroAddress();
        if (moduleAddr.code.length == 0) revert NotContract();

        modules[key] = moduleAddr;
        emit ModuleUpdated(key, moduleAddr);
    }

    function setModules(bytes32[] calldata keys, address[] calldata addrs) external onlyAdmin {
        if (keys.length != addrs.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < keys.length; i++) {
            setModule(keys[i], addrs[i]);
        }
    }

    function setTreasury(address newTreasury) external onlyAdmin {
        if (newTreasury == address(0)) revert ZeroAddress();
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function setProtocolFee(uint256 newFee) external onlyAdmin {
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    function setOracle(address newOracle) external onlyAdmin {
        oracle = newOracle;
        emit OracleUpdated(newOracle);
    }

    function pause() external onlyAdmin {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyAdmin {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MODULE GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function getDriverLicenseModule() external view returns (address) {
        return modules[DRIVER_LICENSE_MODULE];
    }

    function getVehicleRegistrationModule() external view returns (address) {
        return modules[VEHICLE_REGISTRATION_MODULE];
    }

    function getGovAgencyModule() external view returns (address) {
        return modules[GOV_AGENCY_MODULE];
    }

    function getOffenceRenewalModule() external view returns (address) {
        return modules[OFFENCE_RENEWAL_MODULE];
    }

    function getInsuranceModule() external view returns (address) {
        return modules[INSURANCE_MODULE];
    }

    function getInspectionModule() external view returns (address) {
        return modules[INSPECTION_MODULE];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                UUPS UPGRADE AUTH
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /*//////////////////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function isModuleRegistered(bytes32 key) external view returns (bool) {
        return modules[key] != address(0);
    }

    function getModule(bytes32 key) external view returns (address) {
        address module = modules[key];
        if (module == address(0)) revert ModuleNotRegistered(key);
        return module;
    }

    function version() external pure returns (string memory) {
        return "2.0.0-uups";
    }
}
