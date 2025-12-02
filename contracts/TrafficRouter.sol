// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {DefaultAccessControlEnumerable} from "./security/DefaultAccessControlEnumerable.sol";
import {ITrafficRouter} from "./interfaces/ITrafficRouter.sol";
import {ITrafficController} from "./interfaces/ITrafficController.sol";
import {ITrafficFacet} from "./interfaces/ITrafficFacet.sol";

/**
 * @title TrafficRouter
 * @notice Router for traffic management system operations
 * @dev Handles request queuing, execution, and signature verification
 */
contract TrafficRouter is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultAccessControlEnumerable,
    ITrafficRouter
{
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // TrafficController contract reference
    ITrafficController public trafficController;

    // Signature verification parameters
    address public signer;
    uint256 public nonce;

    // Request management
    uint256 private _nextRequestId;
    mapping(uint256 => Request) public requests;
    uint256[] private _pendingRequests;
    mapping(address => uint256[]) private _requesterRequests;

    // Security configuration
    bool public requireSignatureForCriticalOps;
    mapping(RequestType => bool) public isCriticalOperation;

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Ensures request is pending and valid
     */
    modifier onlyPendingRequest(uint256 requestId) {
        if (requestId >= _nextRequestId || requests[requestId].executed || requests[requestId].cancelled) {
            revert RequestNotFound();
        }
        _;
    }

    /**
     * @notice Restricts access to request owner or admin
     */
    modifier onlyRequestOwnerOrAdmin(uint256 requestId) {
        Request storage request = requests[requestId];
        if (msg.sender != request.requester && !isAdmin(msg.sender)) {
            revert UnauthorizedRequester();
        }
        _;
    }

    /**
     * @notice Restricts access to router role
     */
    modifier onlyRouter() {
        if (msg.sender != trafficController.router()) {
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
     * @notice Initializes the TrafficRouter contract
     * @param admin_ Address of the contract administrator
     * @param trafficController_ Address of the TrafficController contract
     * @param signer_ Address authorized to sign requests
     * @param requireSignature_ Whether to require signatures for critical operations
     */
    function initialize(address admin_, address trafficController_, address signer_, bool requireSignature_)
        public
        initializer
    {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __DefaultAccessControlEnumerable_init(admin_);

        if (trafficController_ == address(0)) revert InvalidRequestData();
        if (signer_ == address(0)) revert InvalidSigner();

        trafficController = ITrafficController(trafficController_);
        signer = signer_;
        requireSignatureForCriticalOps = requireSignature_;
        _nextRequestId = 1;

        // Define critical operations requiring signature verification
        isCriticalOperation[RequestType.PAUSE_SYSTEM] = true;
        isCriticalOperation[RequestType.UPGRADE_CONTRACT] = true;
        isCriticalOperation[RequestType.SET_TREASURY] = true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONFIGURATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the signer address
     * @param _signer New signer address
     */
    function setSigner(address _signer) external override onlyDelegateAdmin {
        if (_signer == address(0)) revert InvalidSigner();
        signer = _signer;
        emit SignerUpdated(_signer);
    }

    /**
     * @notice Updates signature requirement for critical operations
     * @param _require Whether to require signatures
     */
    function setRequireSignatureForCriticalOps(bool _require) external override onlyDelegateAdmin {
        requireSignatureForCriticalOps = _require;
        emit SignatureRequirementUpdated(_require);
    }

    /**
     * @notice Sets whether an operation type requires signature verification
     * @param operationType Type of operation
     * @param isCritical Whether the operation is critical
     */
    function setCriticalOperation(RequestType operationType, bool isCritical) external override onlyDelegateAdmin {
        isCriticalOperation[operationType] = isCritical;
        emit CriticalOperationUpdated(operationType, isCritical);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                REQUEST MANAGEMENT
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Submits a new request for execution
     * @param requestType Type of request to submit
     * @param data Encoded request data
     * @param signature Signature for verification (if required)
     * @return requestId Unique identifier for the submitted request
     */
    function submitRequest(RequestType requestType, bytes calldata data, bytes calldata signature)
        external
        override
        onlyDelegateAdmin
        nonReentrant
        returns (uint256)
    {
        // Verify signature for critical operations
        if (requireSignatureForCriticalOps && isCriticalOperation[requestType]) {
            _verifySignature(msg.sender, requestType, data, signature);
        }

        uint256 requestId = _nextRequestId++;

        Request storage newRequest = requests[requestId];
        newRequest.id = requestId;
        newRequest.requester = msg.sender;
        newRequest.requestType = requestType;
        newRequest.data = data;
        newRequest.timestamp = block.timestamp;
        newRequest.executed = false;
        newRequest.cancelled = false;

        _pendingRequests.push(requestId);
        _requesterRequests[msg.sender].push(requestId);

        emit RequestSubmitted(requestId, msg.sender, requestType, data);

        return requestId;
    }

    /**
     * @notice Executes a pending request
     * @param requestId Identifier of the request to execute
     */
    function executeRequest(uint256 requestId)
        external
        override
        onlyAtLeastOperator
        nonReentrant
        onlyPendingRequest(requestId)
    {
        Request storage request = requests[requestId];

        // Execute the request on TrafficController
        bool success = _executeRequestLogic(request.requestType, request.data);

        if (!success) {
            revert ExecutionFailed();
        }

        request.executed = true;

        // Remove from pending requests array
        _removePendingRequest(requestId);

        emit RequestExecuted(requestId, msg.sender);
    }

    /**
     * @notice Cancels a pending request
     * @param requestId Identifier of the request to cancel
     */
    function cancelRequest(uint256 requestId)
        external
        override
        onlyRequestOwnerOrAdmin(requestId)
        nonReentrant
        onlyPendingRequest(requestId)
    {
        Request storage request = requests[requestId];
        request.cancelled = true;

        // Remove from pending requests array
        _removePendingRequest(requestId);

        emit RequestCancelled(requestId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                DIRECT EXECUTION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows router to execute certain operations directly
     * @param requestType Type of operation to execute
     * @param data Encoded operation data
     */
    function directExecute(RequestType requestType, bytes calldata data) external override onlyRouter nonReentrant {
        // Only allow non-critical operations for direct execution
        if (requestType == RequestType.SET_PROTOCOL_FEE || requestType == RequestType.SET_ORACLE) {
            bool success = _executeRequestLogic(requestType, data);
            if (!success) revert ExecutionFailed();
        } else {
            revert UnauthorizedDirectExecution();
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                FACET EXECUTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes a function on a registered facet
     * @param facetKey Key of the facet to execute on
     * @param data Encoded function call data
     */
    function executeOnFacet(bytes32 facetKey, bytes calldata data)
        external
        onlyDelegateAdmin
        nonReentrant
        returns (bytes memory)
    {
        address facetAddr = trafficController.getFacet(facetKey);

        // Execute function call on facet
        (bool success, bytes memory result) = facetAddr.call(data);

        if (!success) {
            // If call failed, try to decode the revert reason
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert ExecutionFailed();
            }
        }

        return result;
    }

    /**
     * @notice Batch executes functions on multiple facets
     * @param facetKeys Array of facet keys
     * @param dataArray Array of encoded function call data
     */
    function batchExecuteOnFacets(bytes32[] calldata facetKeys, bytes[] calldata dataArray)
        external
        onlyDelegateAdmin
        nonReentrant
    {
        if (facetKeys.length != dataArray.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < facetKeys.length; i++) {
            this.executeOnFacet(facetKeys[i], dataArray[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies signature for critical operations
     * @param requester Address that submitted the request
     * @param requestType Type of request
     * @param data Request data
     * @param signature Signature to verify
     */
    function _verifySignature(address requester, RequestType requestType, bytes memory data, bytes memory signature)
        internal
    {
        bytes32 message =
            keccak256(abi.encodePacked(signer, nonce++, requester, uint256(requestType), data)).toEthSignedMessageHash();

        if (!SignatureChecker.isValidSignatureNow(signer, message, signature)) {
            revert InvalidSignature(signature);
        }
    }

    /**
     * @notice Executes request logic on TrafficController
     * @param requestType Type of request to execute
     * @param data Encoded request data
     * @return success Whether execution was successful
     */
    function _executeRequestLogic(RequestType requestType, bytes memory data) internal returns (bool) {
        bytes4 selector = _getFunctionSelector(requestType);
        bytes memory callData = abi.encodePacked(selector, data);

        (bool success,) = address(trafficController).call(callData);
        return success;
    }

    /**
     * @notice Gets function selector for request type
     * @param requestType Type of request
     * @return selector Function selector
     */
    function _getFunctionSelector(RequestType requestType) internal pure returns (bytes4) {
        if (requestType == RequestType.SET_MODULE) {
            return ITrafficController.setModule.selector;
        } else if (requestType == RequestType.SET_MODULES) {
            return ITrafficController.setModules.selector;
        } else if (requestType == RequestType.SET_TREASURY) {
            return ITrafficController.setTreasury.selector;
        } else if (requestType == RequestType.SET_PROTOCOL_FEE) {
            return ITrafficController.setProtocolFee.selector;
        } else if (requestType == RequestType.SET_ORACLE) {
            return ITrafficController.setOracle.selector;
        } else if (requestType == RequestType.PAUSE_SYSTEM) {
            return ITrafficController.pause.selector;
        } else if (requestType == RequestType.UNPAUSE_SYSTEM) {
            return ITrafficController.unpause.selector;
        }

        revert InvalidRequestData();
    }

    /**
     * @notice Removes request from pending requests array
     * @param requestId Identifier of request to remove
     */
    function _removePendingRequest(uint256 requestId) internal {
        uint256 length = _pendingRequests.length;
        for (uint256 i = 0; i < length; i++) {
            if (_pendingRequests[i] == requestId) {
                _pendingRequests[i] = _pendingRequests[length - 1];
                _pendingRequests.pop();
                break;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets request details by ID
     * @param requestId Request identifier
     * @return Request details
     */
    function getRequest(uint256 requestId) external view override returns (Request memory) {
        if (requestId >= _nextRequestId) revert RequestNotFound();
        return requests[requestId];
    }

    /**
     * @notice Gets all pending request IDs
     * @return Array of pending request IDs
     */
    function getPendingRequests() external view override returns (uint256[] memory) {
        return _pendingRequests;
    }

    /**
     * @notice Gets all request IDs by requester
     * @param requester Address of the requester
     * @return Array of request IDs
     */
    function getRequestsByRequester(address requester) external view override returns (uint256[] memory) {
        return _requesterRequests[requester];
    }

    /**
     * @notice Gets the next request ID that will be assigned
     * @return Next request ID
     */
    function getNextRequestId() external view returns (uint256) {
        return _nextRequestId;
    }

    /**
     * @notice Gets contract version
     */
    function version() external pure returns (string memory) {
        return "1.1.0-uups";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                UUPS UPGRADE AUTH
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
