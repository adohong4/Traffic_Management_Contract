// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITrafficRouter {
    // Events
    event RequestSubmitted(uint256 indexed requestId, address indexed requester, RequestType requestType, bytes data);
    event RequestExecuted(uint256 indexed requestId, address indexed executor);
    event RequestCancelled(uint256 indexed requestId, address indexed canceller);
    event SignerUpdated(address indexed signer);
    event SignatureRequirementUpdated(bool required);
    event CriticalOperationUpdated(RequestType operationType, bool isCritical);

    // Enums
    enum RequestType {
        SET_MODULE,
        SET_MODULES,
        SET_TREASURY,
        SET_PROTOCOL_FEE,
        SET_ORACLE,
        PAUSE_SYSTEM,
        UNPAUSE_SYSTEM,
        UPGRADE_CONTRACT
    }

    // Structs
    struct Request {
        uint256 id;
        address requester;
        RequestType requestType;
        bytes data;
        uint256 timestamp;
        bool executed;
        bool cancelled;
    }

    // Errors
    error UnauthorizedRequester();
    error RequestAlreadyExecuted();
    error RequestAlreadyCancelled();
    error RequestNotFound();
    error InvalidRequestData();
    error ExecutionFailed();
    error InvalidSigner();
    error InvalidSignature(bytes signature);
    error UnauthorizedDirectExecution();
    error UnauthorizedRouter();

    // Functions
    function submitRequest(RequestType requestType, bytes calldata data, bytes calldata signature) external returns (uint256);
    function executeRequest(uint256 requestId) external;
    function cancelRequest(uint256 requestId) external;
    function directExecute(RequestType requestType, bytes calldata data) external;
    function getRequest(uint256 requestId) external view returns (Request memory);
    function getPendingRequests() external view returns (uint256[] memory);
    function getRequestsByRequester(address requester) external view returns (uint256[] memory);
    function setSigner(address _signer) external;
    function setRequireSignatureForCriticalOps(bool _require) external;
    function setCriticalOperation(RequestType operationType, bool isCritical) external;
}
