// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * Errors
 * Custom errors for the traffic management system to optimize gas
 */
contract Errors {
    // General errors
    error ZeroAddressNotAllowed();
    error InvalidInput();
    error NotAuthorized(address caller);
    error AlreadyExists();
    error NotFound();

    // Driver license errors
    error DriverLicenseExpired(uint256 tokenId);
    error DriverLicenseNotValid(uint256 tokenId);
    error DriverAgeNotEligible(uint256 age);
    error InvalidPointValue(uint256 point);

    // Vehicle errors
    error VehicleLimitReached(address owner);
    error VehicleNotRegistered(uint256 vehicleId);

    // Insurance errors
    error InsuranceExpired(uint256 insuranceId);
    error InsuranceNotValid(uint256 insuranceId);

    // Inspection errors
    error InspectionExpired(uint256 inspectionId);
    error InspectionNotValid(uint256 inspectionId);

    // Governance errors
    error GovAgencyNotRegistered(address agency);

    error NoSelectorsGivenToAdd();
    error NotContractOwner(address _user, address _contractOwner);
    error NoSelectorsProvidedForFacetForCut(address _facetAddress);
    error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
    error NoBytecodeAtAddress(address _contractAddress, string _message);
    error IncorrectFacetCutAction(uint8 _action);
    error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
    error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
    error CannotReplaceImmutableFunction(bytes4 _selector);
    error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
    error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
    error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
    error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
    error CannotRemoveImmutableFunction(bytes4 _selector);
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
}
