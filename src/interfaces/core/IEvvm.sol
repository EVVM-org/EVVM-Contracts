// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;
/**

░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  
░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
 
 * @title AccountBook contract for Roll A Mate Protocol
 * @author 
 * @notice 
 */

interface IEvvm {

    struct PayData {
        address from;
        address to_address;
        string to_username;
        address token; 
        uint256 amount;
        uint256 priorityFee;
        uint256 nonce;
        bool priority;
        address executor;
        bytes signature;
    }

    struct SplitPayMetadata {
        uint256 amount;
        address to_address;
        string to_username;
    }
    
    //░▒▓█Withdrawal functions██████████████████████████████████████████████████▓▒░

    function withdrawalNoMateStaking_sync(
        address user,
        address addressToReceive,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable;

    function withdrawalNoMateStaking_async(
        address user,
        address addressToReceive,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable;

    function withdrawalMateStaking_sync(
        address user,
        address addressToReceive,
        address token,
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable;

    function withdrawalMateStaking_async(
        address user,
        address addressToReceive,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable;

    //░▒▓█Pay functions█████████████████████████████████████████████████████████▓▒░

    function payNoMateStaking_sync(
        address from,
        address to_address,
        string memory to_username,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external;

    function payNoMateStaking_async(
        address from,
        address to_address,
        string memory to_username,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external;

    function payMateStaking_sync(
        address from,
        address to_address,
        string memory to_username,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external;

    function payMateStaking_async(
        address from,
        address to_address,
        string memory to_username,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external;

    //░▒▓█Multiple pay transactions function████████████████████████████████████▓▒░

    function payMultiple(
        PayData[] memory payData
    ) external returns(
        uint256 successfulTransactions, 
        uint256 failedTransactions, 
        bytes[] memory signaturesFailed
    );

    //░▒▓█Disperse pay function█████████████████████████████████████████████████▓▒░

    function dispersePay(
        address from,
        SplitPayMetadata[] memory toData,
        address token, 
        uint256 amount,
        uint256 priorityFee,
        bool priority,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external;

    //░▒▓█Pay for contract account functions████████████████████████████████████▓▒░

    function caPay(
        address to,
        address token, 
        uint256 amount
    ) external;

    function disperseCaPay(
        SplitPayMetadata[] memory toData,
        address token, 
        uint256 amount
    ) external;

    //░▒▓█fisher bridge functions███████████████████████████████████████████████▓▒░

    function fisherWithdrawal(
        address user,
        address addressToReceive,
        address token,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external;

    //░▒▓█Getter functions██████████████████████████████████████████████████████▓▒░

    function getMaxAmountToWithdraw() external view returns (uint256);

    function getNextCurrentSyncNonce(address user) external view returns (uint256);

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool);

    function getNextFisherWithdrawalNonce( address user ) external view returns (uint256);

    function getNextFisherDepositNonce( address user ) external view returns (uint256);

    function seeBalance(address user, address token) external view returns (uint256);

    function seeMinimumMateStakeForFishing() external view returns (uint256);

    function isMateStaker(address user) external view returns (bool);
    
    function seeMateEraTokens(
    ) external view returns (uint256);

    function seeMateReward(
    ) external view returns (uint256);

    function seeMateTotalSupply(
    ) external view returns (uint256);

    function seeIfTokenIsWhitelisted(
        address token
    ) external view returns (bool);

}