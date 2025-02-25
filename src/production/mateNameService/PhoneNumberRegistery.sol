// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract PhoneNumberRegistery {
    struct RegisterPhoneNumberMetadata {
        address owner;
        address possibleNewOwner;
        uint256 transferWindow;
        uint256 timestampReverseTransfer;
    }

    mapping(string phoneNumber => RegisterPhoneNumberMetadata) private phoneNumberMetadata;

    address public immutable MNS_ADDRESS;

    address autority;

    modifier onlyMNS() {
        if (msg.sender != MNS_ADDRESS) {
            revert();
        }
        _;
    }

    constructor(address _MNS_ADDRESS, address _autority) {
        MNS_ADDRESS = _MNS_ADDRESS;
        autority = _autority;
    }

    function register(
        address _user,
        string memory _phoneNumber,
        uint256 _timestampUser,
        bytes memory _signatureUser,
        uint256 _timestampAutority,
        bytes memory _signatureAutority
    ) external onlyMNS returns (uint256 reward) {
        if (
            !verifyMessageSignedForRegister_User(
                _user,
                _phoneNumber,
                _timestampUser,
                _signatureUser
            )
        ) {
            revert();
        }
        if (
            !verifyMessageSignedForRegister_Autority(
                _user,
                _signatureUser,
                _phoneNumber,
                _timestampAutority,
                _signatureAutority
            )
        ) {
            revert();
        }

        if (
            _timestampUser + 1 hours < block.timestamp ||
            _timestampAutority + 1 hours < block.timestamp
        ) {
            revert();
        }

        if (phoneNumberMetadata[_phoneNumber].owner == address(0)) {
            phoneNumberMetadata[_phoneNumber].owner = _user;
            return 50;
        } else {
            phoneNumberMetadata[_phoneNumber].possibleNewOwner = _user;
            phoneNumberMetadata[_phoneNumber].transferWindow =
                block.timestamp +
                1 days;
            return 25;
        }
    }

    function reverseTransfer(
        address _user,
        string memory _phoneNumber,
        uint256 _timestamp,
        bytes memory _signature
    ) external onlyMNS returns (uint256 reward) {
        if (
            !verifyMessageSignedForReverseTransfer(
                _user,
                _phoneNumber,
                _timestamp,
                _signature
            )
        ) {
            revert();
        }

        if (
            phoneNumberMetadata[_phoneNumber].owner == address(0) ||
            phoneNumberMetadata[_phoneNumber].possibleNewOwner == address(0) ||
            phoneNumberMetadata[_phoneNumber].owner != _user ||
            phoneNumberMetadata[_phoneNumber].transferWindow < block.timestamp
        ) {
            revert();
        }

        phoneNumberMetadata[_phoneNumber].timestampReverseTransfer = block
            .timestamp;
        phoneNumberMetadata[_phoneNumber].possibleNewOwner = address(0);
        phoneNumberMetadata[_phoneNumber].transferWindow = 0;

        return 25;
    }

    function claimTransfer(
        string memory _phoneNumber
    ) external onlyMNS returns (uint256 reward) {
        if (
            phoneNumberMetadata[_phoneNumber].owner == address(0) ||
            phoneNumberMetadata[_phoneNumber].timestampReverseTransfer == 0 ||
            phoneNumberMetadata[_phoneNumber].timestampReverseTransfer +
                1 days <
            block.timestamp
        ) {
            revert();
        }

        phoneNumberMetadata[_phoneNumber].owner = phoneNumberMetadata[
            _phoneNumber
        ].possibleNewOwner;
        phoneNumberMetadata[_phoneNumber].possibleNewOwner = address(0);
        phoneNumberMetadata[_phoneNumber].transferWindow = 0;

        return 25;
    }

    function getFullMetadata(
        string memory phoneNumber
    ) external view onlyMNS returns (address, address, uint256, uint256) {
        return (
            phoneNumberMetadata[phoneNumber].owner,
            phoneNumberMetadata[phoneNumber].possibleNewOwner,
            phoneNumberMetadata[phoneNumber].transferWindow,
            phoneNumberMetadata[phoneNumber].timestampReverseTransfer
        );
    }

    //█Signature functions█████████████████████████████████████████████████████████████████████████

    function verifyMessageSignedForRegister_User(
        address signer,
        string memory _phoneNumber,
        uint256 _timeStamp,
        bytes memory signature
    ) internal pure returns (bool) {
        string memory messageToSign = string.concat(
            "bd91a162",
            ",",
            _phoneNumber,
            ",",
            Strings.toString(_timeStamp)
        );
        address whoSign = recoverSigner(
            messageToSign,
            bytes(messageToSign).length,
            signature
        );
        return signer == whoSign;
    }

    function verifyMessageSignedForRegister_Autority(
        address signer,
        bytes memory _signatureUser,
        string memory _phoneNumber,
        uint256 _timeStamp,
        bytes memory signature
    ) internal pure returns (bool) {
        string memory messageToSign = string.concat(
            "bd91a162",
            ",",
            string(_signatureUser),
            ",",
            _phoneNumber,
            ",",
            Strings.toString(_timeStamp)
        );
        address whoSign = recoverSigner(
            messageToSign,
            bytes(messageToSign).length,
            signature
        );
        return signer == whoSign;
    }

    function verifyMessageSignedForReverseTransfer(
        address signer,
        string memory _phoneNumber,
        uint256 _timeStamp,
        bytes memory signature
    ) internal pure returns (bool) {
        string memory messageToSign = string.concat(
            "f106fe1d",
            ",",
            _phoneNumber,
            ",",
            Strings.toString(_timeStamp)
        );
        address whoSign = recoverSigner(
            messageToSign,
            bytes(messageToSign).length,
            signature
        );
        return signer == whoSign;
    }

    //█ERC-191 signature functions█████████████████████████████████████████████████████████████████

    function recoverSigner(
        string memory message,
        uint256 lengthOfMessage,
        bytes memory signature
    ) internal pure returns (address) {
        //bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", bytes(message).length, message));
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(lengthOfMessage),
                message
            )
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Ensure signature is valid
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature value");
    }

    //█Tools for admin█████████████████████████████████████████████████████████████████████████████

    function changeAutority(address _newAutority) public onlyMNS {
        autority = _newAutority;
    }
}
