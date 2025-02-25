// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;

interface IEmailRegistery {

    struct RegisterEmailMetadata {
        address owner;
        address possibleNewOwner;
        uint256 transferWindow;
        uint256 timestampReverseTransfer;
    }

    function register(
        address _user,
        string memory _email,
        uint256 _timestampUser,
        bytes memory _signatureUser,
        uint256 _timestampAutority,
        bytes memory _signatureAutority
    ) external returns (uint256 reward);

    function reverseTransfer(
        address _user,
        string memory _email,
        uint256 _timestamp,
        bytes memory _signature
    ) external returns (uint256 reward);

    function claimTransfer(
        string memory _email
    ) external returns (uint256 reward);

    function getFullMetadata(
        string memory email
    ) external view returns (
        address owner,
        address possibleNewOwner,
        uint256 transferWindow,
        uint256 timestampReverseTransfer
    );

    function changeAutority(address _newAutority) external;
}
