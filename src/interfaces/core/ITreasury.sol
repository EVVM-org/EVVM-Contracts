// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

dP d888888P                                                                
88    88                                                                   
88    88    88d888b. .d8888b. .d8888b. .d8888b. dP    dP 88d888b. dP    dP 
88    88    88'  `88 88ooood8 88'  `88 Y8ooooo. 88    88 88'  `88 88    88 
88    88    88       88.  ... 88.  .88       88 88.  .88 88       88.  .88 
dP    dP    dP       `88888P' `88888P8 `88888P' `88888P' dP       `8888P88 
ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo~~~~.88~
                                                                   d8888P  

 * @title Treasury contract for Roll A Mate Protocol
 * @author 
 * @notice 
 */

interface ITreasury {
    //═════════════════════════════════════════════════════════════════════════════════════
    // Deposit functions
    //═════════════════════════════════════════════════════════════════════════════════════
    function deposit(
        address addressToReceive,
        address token,
        uint256 amount,
        uint8 solutionId,
        bytes calldata options
    ) external payable;

    //═════════════════════════════════════════════════════════════════════════════════════
    // Fisher bridge functions
    //═════════════════════════════════════════════════════════════════════════════════════
   
    function fisherDepositETH(
        address addressToReceive,
        uint256 priorityFee,
        bytes memory signature
    ) external payable;

    function fisherDepositERC20(
        address addressToReceive,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature
    ) external;

    function fisherWithdrawalReceiver(
        address user,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external;

    //═════════════════════════════════════════════════════════════════════════════════════
    // User functions
    //═════════════════════════════════════════════════════════════════════════════════════

    function getMaxAmountToDeposit() external view returns (uint256);

    function getNextFisherDepositNonce(
        address user
    ) external view returns (uint256);

    function getNextFisherWithdrawalNonce(
        address user
    ) external view returns (uint256);

    function getTokensWhitelistPool(
        address tokenAddress
    ) external view returns (address);

    function getIfTokenIsWhitelisted(
        address tokenAddress
    ) external view returns (bool);
}