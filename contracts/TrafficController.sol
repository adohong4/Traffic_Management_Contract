// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {DefaultAccessControlEnumerable} from "./security/DefaultAccessControlEnumerable.sol";
import {ITrafficController} from "./interfaces/ITrafficController.sol";

/**
 * @title TrafficController
 * @notice Central controller for traffic management system
 * @dev Manages modules, configuration, and access control for the traffic system
 */
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

    // Router addresses - authorized to perform direct operations
    address public router;
    address public crossChainRouter;

    // Module addresses - replaces Diamond facets pattern
    mapping(bytes32 moduleKey => address moduleAddress) public modules;

    // Module configuration constants for easy management
    bytes32 public constant DRIVER_LICENSE_MODULE = keccak256("DRIVER_LICENSE_MODULE");
    bytes32 public constant VEHICLE_REGISTRATION_MODULE = keccak256("VEHICLE_REGISTRATION_MODULE");
    bytes32 public constant GOV_AGENCY_MODULE = keccak256("GOV_AGENCY_MODULE");
    bytes32 public constant OFFENCE_RENEWAL_MODULE = keccak256("OFFENCE_RENEWAL_MODULE");
    bytes32 public constant INSURANCE_MODULE = keccak256("INSURANCE_MODULE");
    bytes32 public constant INSPECTION_MODULE = keccak256("INSPECTION_MODULE");

    // Core system configuration
    address public oracle; // Chainlink oracle address (optional)
    address public treasury; // Protocol fee treasury address
    uint256 public protocolFee; // Protocol fee in basis points (10000 = 100%)
    bool public paused; // Emergency pause flag

    // Enhanced configuration mappings for detailed module management
    mapping(address moduleAddress => ModuleConfig) public moduleConfigs;
    mapping(bytes32 configKey => SystemConfig) public systemConfigs;

    /*//////////////////////////////////////////////////////////////////////////
                                DATA STRUCTURES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration for individual modules
     * @param isActive Whether the module is active
     * @param maxCapacity Maximum capacity for the module
     * @param feeRate Fee rate for module operations (basis points)
     * @param backupModule Backup module address for failover
     * @param lastUpdated Timestamp of last configuration update
     */
    struct ModuleConfig {
        bool isActive;
        uint256 maxCapacity;
        uint256 feeRate;
        address backupModule;
        uint256 lastUpdated;
    }

    /**
     * @notice System-wide configuration parameters
     * @param value Current configuration value
     * @param isActive Whether this configuration is active
     * @param minValue Minimum allowed value
     * @param maxValue Maximum allowed value
     * @param setter Address that last set this configuration
     */
    struct SystemConfig {
        uint256 value;
        bool isActive;
        uint256 minValue;
        uint256 maxValue;
        address setter;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Ensures system is not paused
     */
    modifier whenNotPaused() {
        if (paused) revert SystemPaused();
        _;
    }

    /**
     * @notice Restricts access to registered modules
     */
    modifier onlyModule(bytes32 key) {
        if (msg.sender != modules[key]) revert UnauthorizedModule(msg.sender);
        _;
    }

    /**
     * @notice Restricts access to authorized routers
     */
    modifier onlyRouter() {
        if (msg.sender != router && msg.sender != crossChainRouter) {
            revert UnauthorizedRouter();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the TrafficController contract
     * @param admin_ Address of the contract administrator
     * @param treasury_ Address of the treasury for protocol fees
     * @param protocolFee_ Initial protocol fee in basis points
     */
    function initialize(address admin_, address treasury_, uint256 protocolFee_) public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __DefaultAccessControlEnumerable_init(admin_);

        if (treasury_ == address(0)) revert ZeroAddress();

        treasury = treasury_;
        protocolFee = protocolFee_;
        paused = false;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS (DELEGATE ADMIN)
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets a module address for a given key
     * @param key Module key identifier
     * @param moduleAddr Address of the module contract
     */
    function setModule(bytes32 key, address moduleAddr) external onlyDelegateAdmin {
        _setModule(key, moduleAddr);
    }

    /**
     * @notice Internal function to set module
     * @param key Module key identifier
     * @param moduleAddr Address of the module contract
     */
    function _setModule(bytes32 key, address moduleAddr) internal {
        if (moduleAddr == address(0)) revert ZeroAddress();
        if (moduleAddr.code.length == 0) revert NotContract();

        modules[key] = moduleAddr;
        moduleConfigs[moduleAddr].lastUpdated = block.timestamp;

        emit ModuleUpdated(key, moduleAddr);
    }

    /**
     * @notice Batch sets multiple modules
     * @param keys Array of module keys
     * @param addrs Array of module addresses
     */
    function setModules(bytes32[] calldata keys, address[] calldata addrs) external onlyDelegateAdmin {
        if (keys.length != addrs.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < keys.length; i++) {
            _setModule(keys[i], addrs[i]);
        }
    }

    /**
     * @notice Updates the treasury address
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyDelegateAdmin {
        if (newTreasury == address(0)) revert ZeroAddress();
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    /**
     * @notice Updates the protocol fee
     * @param newFee New protocol fee in basis points
     */
    function setProtocolFee(uint256 newFee) external onlyDelegateAdmin {
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    /**
     * @notice Updates the oracle address
     * @param newOracle New oracle address
     */
    function setOracle(address newOracle) external onlyDelegateAdmin {
        oracle = newOracle;
        emit OracleUpdated(newOracle);
    }

    /**
     * @notice Sets the router address
     * @param _router Address of the router contract
     */
    function setRouter(address _router) external onlyDelegateAdmin {
        if (_router == address(0)) revert ZeroAddress();
        router = _router;
        emit RouterUpdated(_router);
    }

    /**
     * @notice Sets the cross-chain router address
     * @param _crossChainRouter Address of the cross-chain router contract
     */
    function setCrossChainRouter(address _crossChainRouter) external onlyDelegateAdmin {
        if (_crossChainRouter == address(0)) revert ZeroAddress();
        crossChainRouter = _crossChainRouter;
        emit CrossChainRouterUpdated(_crossChainRouter);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ROUTER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses the system (router only)
     */
    function pause() external onlyRouter {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the system (router only)
     */
    function unpause() external onlyRouter {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Emergency pause (admin only)
     */
    function emergencyPause() external onlyAdmin {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OPERATOR FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates module configuration (operator level)
     * @param moduleAddr Address of the module to configure
     * @param config New configuration parameters
     */
    function updateModuleConfig(address moduleAddr, ModuleConfig calldata config) external onlyAtLeastOperator {
        moduleConfigs[moduleAddr] = config;
        moduleConfigs[moduleAddr].lastUpdated = block.timestamp;
        emit ModuleConfigUpdated(moduleAddr, config);
    }

    /**
     * @notice Updates system configuration (operator level)
     * @param key Configuration key
     * @param config New configuration parameters
     */
    function updateSystemConfig(bytes32 key, SystemConfig calldata config) external onlyAtLeastOperator {
        systemConfigs[key] = config;
        emit SystemConfigUpdated(key, config);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MODULE GETTERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the driver license module address
     */
    function getDriverLicenseModule() external view returns (address) {
        return modules[DRIVER_LICENSE_MODULE];
    }

    /**
     * @notice Gets the vehicle registration module address
     */
    function getVehicleRegistrationModule() external view returns (address) {
        return modules[VEHICLE_REGISTRATION_MODULE];
    }

    /**
     * @notice Gets the government agency module address
     */
    function getGovAgencyModule() external view returns (address) {
        return modules[GOV_AGENCY_MODULE];
    }

    /**
     * @notice Gets the offence renewal module address
     */
    function getOffenceRenewalModule() external view returns (address) {
        return modules[OFFENCE_RENEWAL_MODULE];
    }

    /**
     * @notice Gets the insurance module address
     */
    function getInsuranceModule() external view returns (address) {
        return modules[INSURANCE_MODULE];
    }

    /**
     * @notice Gets the inspection module address
     */
    function getInspectionModule() external view returns (address) {
        return modules[INSPECTION_MODULE];
    }

    /**
     * @notice Gets module configuration
     * @param moduleAddr Address of the module
     */
    function getModuleConfig(address moduleAddr) external view returns (ModuleConfig memory) {
        return moduleConfigs[moduleAddr];
    }

    /**
     * @notice Gets system configuration
     * @param key Configuration key
     */
    function getSystemConfig(bytes32 key) external view returns (SystemConfig memory) {
        return systemConfigs[key];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a module is registered
     * @param key Module key
     */
    function isModuleRegistered(bytes32 key) external view returns (bool) {
        return modules[key] != address(0);
    }

    /**
     * @notice Gets module address by key
     * @param key Module key
     */
    function getModule(bytes32 key) external view returns (address) {
        address module = modules[key];
        if (module == address(0)) revert ModuleNotRegistered(key);
        return module;
    }

    /**
     * @notice Gets contract version
     */
    function version() external pure returns (string memory) {
        return "2.1.0-uups";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                UUPS UPGRADE AUTH
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /*//////////////////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event RouterUpdated(address indexed router);
    event CrossChainRouterUpdated(address indexed crossChainRouter);
    event EmergencyPaused(address indexed account);
    event ModuleConfigUpdated(address indexed module, ModuleConfig config);
    event SystemConfigUpdated(bytes32 indexed key, SystemConfig config);

    /*//////////////////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    error UnauthorizedRouter();
}
