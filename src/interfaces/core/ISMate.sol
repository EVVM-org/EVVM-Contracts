// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**

        8 8                                                                              
88   ad88888ba    ad88888ba   88b           d88         db    888888888888  88888888888  
88  d8" 8 8 "8b  d8"     "8b  888b         d888        d88b        88       88           
88  Y8, 8 8      Y8,          88`8b       d8'88       d8'`8b       88       88           
88  `Y8a8a8a,    `Y8aaaaa,    88 `8b     d8' 88      d8'  `8b      88       88aaaaa      
88    `"8"8"8b,    `"""""8b,  88  `8b   d8'  88     d8YaaaaY8b     88       88"""""      
88      8 8 `8b          `8b  88   `8b d8'   88    d8""""""""8b    88       88           
88  Y8a 8 8 a8P  Y8a     a8P  88    `888'    88   d8'        `8b   88       88           
88   "Y88888P"    "Y88888P"   88     `8'     88  d8'          `8b  88       88888888888  
        8 8                                                                                                                                                         

 * @title Staking Mate contract for Roll A Mate Protocol 
 * @author TBD
 */

interface ISMate {

    function goldenStaking(
        address _token,
        uint256 _amountOfSMate,
        uint256 _nonce_AccountBook,
        bytes memory _signature_AccountBook
    ) external;

    function presaleStake(
        address _token,
        address _user,
        uint256 _nonce,
        bytes memory _signature,
        uint256 _priorityFee_AccountBook,
        bool _priority_AccountBook,
        uint256 _nonce_AccountBook,
        bytes memory _signature_AccountBook,
        uint256 _nonce_priorityFee_AccountBook,
        bytes memory _signature_priorityFee_AccountBook
    ) external;

    function externalStaking(
        address _token,
        address _user,
        uint256 _nonce,
        uint256 _amountOfSMate,
        bytes memory _signature,
        uint256 _priorityFee_AccountBook,
        bool _priority_AccountBook,
        uint256 _nonce_AccountBook,
        bytes memory _signature_AccountBook,
        uint256 _nonce_priorityFee_AccountBook,
        bytes memory _signature_priorityFee_AccountBook
    ) external;

    function checkIfStakeNonceUsed(
        address _account, 
        uint256 _nonce
    ) external view returns (bool);

    function getTimeAllowExternalStaking() external view returns (uint256);

    function getTimeAllowInternalStaking() external view returns (uint256);

    function getGoldenFisher() external view returns (address);

    function getGoldenFisherFuture() external view returns (address);

    function getPresaleStaker(
        address _account
    ) external view returns (bool, uint256);

    function getPresaleStakerCount() external view returns (uint256);

    function getAllowExternalStaking() external view returns (bool);

    function getAllowInternalStaking() external view returns (bool);

    function getAccountBookAddress() external view returns (address);

    function getSMateAddress() external pure returns (address);

    function getMateAddress() external pure returns (address);

    function getOwner() external view returns (address);


}