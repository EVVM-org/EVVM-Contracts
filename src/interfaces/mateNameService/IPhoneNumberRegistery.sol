// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPhoneNumberRegistery {

    struct RegisterPhoneNumberMetadata {
        address owner;
        address possibleNewOwner;
        uint256 transferWindow;
        uint256 timestampReverseTransfer;
    }

    function register(
        address _user,
        string memory _phoneNumber,
        uint256 _timestampUser,
        bytes memory _signatureUser,
        uint256 _timestampAutority,
        bytes memory _signatureAutority
    ) external returns (uint256 reward);

    function reverseTransfer(
        address _user,
        string memory _phoneNumber,
        uint256 _timestamp,
        bytes memory _signature
    ) external returns (uint256 reward);

    function claimTransfer(
        string memory _phoneNumber
    ) external returns (uint256 reward);

    function getFullMetadata(
        string memory phoneNumber
    ) external view returns (
        address owner,
        address possibleNewOwner,
        uint256 transferWindow,
        uint256 timestampReverseTransfer
    );

    function changeAutority(address _newAutority) external;
}
