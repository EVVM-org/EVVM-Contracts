// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;

/**

d888888P                                                                
   88                                                                   
   88    88d888b. .d8888b. .d8888b. .d8888b. dP    dP 88d888b. dP    dP 
   88    88'  `88 88ooood8 88'  `88 Y8ooooo. 88    88 88'  `88 88    88 
   88    88       88.  ... 88.  .88       88 88.  .88 88       88.  .88 
   dP    dP       `88888P' `88888P8 `88888P' `88888P' dP       `8888P88 
oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo~~~~.88~
                                                                d8888P  

 * @title Treasury contract for Roll A Mate Protocol
 * @author 
 * @notice 
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

import {OAppReceiver, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import {OAppSender, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {OAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";

import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {SignatureRecover} from "@RollAMate/libraries/SignatureRecover.sol";

import {AdvancedStrings} from "@RollAMate/libraries/AdvancedStrings.sol";

contract Treasury is Ownable, AxelarExecutable, CCIPReceiver, OAppReceiver {
    using SignatureRecover for *;

    struct EvvmMetadata {
        string axelarChain;
        string axelarAddress;
        uint64 ccipChain;
        address ccipAddress;
        uint32 hyperlaneChain;
        bytes32 hyperlaneAddress;
        uint32 layerZeroChain;
        bytes32 layerZeroAddress;
    }

    EvvmMetadata private evvmMetadata;

    IAxelarGasService public immutable gasService;
    SourceOApp public immutable lzSenderApp;

    address routerCCIP;
    address mailboxHyperlane;

    address constant goldenFisher = 0x63c3774531EF83631111Fe2Cf01520Fb3F5A68F7;

    address private whiteListChangeOwner_proposal;
    uint256 private whiteListChangeOwner_dateToAccept;

    address private whitelistTokenToBeAdded_address;
    address private whitelistTokenToBeAdded_pool;
    uint256 private whitelistTokenToBeAdded_dateToSet;

    uint256 private maxAmountToDeposit;
    uint256 private maxAmountToDeposit_proposal;
    uint256 private maxAmountToDeposit_dateToAccept;

    mapping(address user => uint256 nonce) private nextFisherDepositNonce;

    mapping(address user => uint256 nonce) private nextFisherWithdrawalNonce;

    mapping(address token => address pool) private whitelistTokenUniswapPool;

    event DepositIntoRollAMate(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint8 solutionId
    );

    event FisherMakeDeposit(bytes indexed signature);

    event NewTokenWhitelisted(address indexed token, address indexed pool);

    constructor(
        address initialOwner,
        address AxelarGateway,
        address AxelarGasService,
        address CcipRouter,
        address HyperlaneMailbox,
        address LayerZeroEndpoint
    )
        AxelarExecutable(AxelarGateway)
        Ownable(initialOwner)
        CCIPReceiver(CcipRouter)
        OAppCore(LayerZeroEndpoint, initialOwner)
    {
        gasService = IAxelarGasService(AxelarGasService);
        mailboxHyperlane = HyperlaneMailbox;
        lzSenderApp = new SourceOApp(LayerZeroEndpoint, address(this));
        maxAmountToDeposit = 0.1 ether;
    }

    function _setEvvmMetadata(
        string memory _axelarEvvmAddress,
        string memory _axelarEvvmChain,
        address _ccipEvvmAddress,
        uint64 _ccipEvvmChain,
        address _hyperlaneEvvmAddress,
        uint32 _hyperlaneEvvmChain,
        address _layerZeroEvvmAddress,
        uint32 _layerZeroEvvmChain
    ) external onlyOwner {
        evvmMetadata.axelarAddress = _axelarEvvmAddress;
        evvmMetadata.axelarChain = _axelarEvvmChain;
        evvmMetadata.ccipAddress = _ccipEvvmAddress;
        evvmMetadata.ccipChain = _ccipEvvmChain;
        evvmMetadata.hyperlaneAddress = bytes32(
            uint256(uint160(_hyperlaneEvvmAddress))
        );
        evvmMetadata.hyperlaneChain = _hyperlaneEvvmChain;
        evvmMetadata.layerZeroAddress = bytes32(
            uint256(uint160(_layerZeroEvvmAddress))
        );
        evvmMetadata.layerZeroChain = _layerZeroEvvmChain;
        lzSenderApp.setPeer(
            evvmMetadata.layerZeroChain,
            evvmMetadata.layerZeroAddress
        );
        OAppCore.setPeer(
            evvmMetadata.layerZeroChain,
            evvmMetadata.layerZeroAddress
        );
    }

    //═Deposit functions═══════════════════════════════════════════════════════════════════════════

    /**
     *  @dev deposit ETH or ERC20 tokens from Ethereum to Roll a Mate
     *  @param addressToReceive the address of the user to receive the deposit
     *  @param token the address of the token to deposit, 0x0 for ETH
     *  @param amount the amount to deposit
     *                 if you want to deposit ETH, send the
     *                 amount + gas fee to use in the cross chain message
     *  @param solutionId the solution id to use for sending the message
     *                     1 -- Axelar
     *                     2 -- CCIP
     *                     3 -- Hyperlane
     *                     4 -- LayerZero
     *  @param options the options to send with the message for defaullt
     *                  we recommend to use 2000 wei as gas fee and send
     *                  200000 gwei for paying the gas (only for LayerZero)
     *  @notice for ETH first deposit to the contract and
     *          then call this function with the amount of the deposit
     */
    function deposit(
        address addressToReceive,
        address token,
        uint256 amount,
        uint8 solutionId,
        bytes calldata options
    ) external payable {
        uint256 gasFeeToPay = msg.value;
        if (token == address(0)) {
            if (msg.value < amount || amount > maxAmountToDeposit) {
                revert();
            }

            gasFeeToPay = msg.value - amount;
        } else {
            if (whitelistTokenUniswapPool[token] == address(0)) {
                revert();
            }

            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistTokenUniswapPool[token],
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToDeposit) {
                revert();
            }

            if (
                !IERC20(token).transferFrom(msg.sender, address(this), amount)
            ) {
                revert();
            }
        }

        bytes memory payload = abi.encode(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            amount
        );

        if (solutionId == 1) {
            /// @dev Axelar
            gasService.payNativeGasForContractCall{value: gasFeeToPay}(
                address(this),
                evvmMetadata.axelarChain,
                evvmMetadata.axelarAddress,
                payload,
                msg.sender
            );

            gateway.callContract(
                evvmMetadata.axelarChain,
                evvmMetadata.axelarAddress,
                payload
            );
        } else if (solutionId == 2) {
            /// @dev CCIP
            Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                evvmMetadata.ccipAddress,
                payload,
                address(0)
            );

            uint256 fees = IRouterClient(i_router).getFee(
                evvmMetadata.ccipChain,
                evm2AnyMessage
            );

            if (fees > gasFeeToPay) {
                revert();
            }

            IRouterClient(i_router).ccipSend{value: gasFeeToPay}(
                evvmMetadata.ccipChain,
                evm2AnyMessage
            );
        } else if (solutionId == 3) {
            /// @dev Hyperlane
            IMailbox(mailboxHyperlane).dispatch{value: gasFeeToPay}(
                evvmMetadata.hyperlaneChain,
                evvmMetadata.hyperlaneAddress,
                payload
            );
        } else if (solutionId == 4) {
            /// @dev LayerZero
            lzSenderApp.send{value: gasFeeToPay}(
                evvmMetadata.layerZeroChain,
                payload,
                options,
                msg.sender
            );
        } else {
            revert();
        }

        emit DepositIntoRollAMate(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            amount,
            solutionId
        );
    }

    //═Fisher bridge functions═════════════════════════════════════════════════════════════════════

    /**
     *  @notice This function is use to send just ETH to the fisher bridge
     *  @param priorityFee the priorityFee to send to the white fisher
     *  @param signature the signature of the user who wants to send the message
     *                   a signature is contructed with a message like this:
     *                   "addressToReceive,nonce,priorityFee,amount"
     */
    function fisherDepositETH(
        address addressToReceive,
        uint256 priorityFee,
        bytes memory signature
    ) external payable {
        if (
            !verifyMessageSignedForFisherBridgeETH(
                msg.sender,
                addressToReceive == address(0) ? msg.sender : addressToReceive,
                nextFisherDepositNonce[msg.sender],
                priorityFee,
                (msg.value - priorityFee),
                signature
            )
        ) {
            revert();
        }

        if ((msg.value - priorityFee) > maxAmountToDeposit) {
            revert();
        }

        nextFisherDepositNonce[msg.sender]++;

        emit FisherMakeDeposit(signature);
    }

    /**
     *  @notice This function is use to send onky ERC20 token to the fisher bridge
     *  @param tokenAddress address of the token to deposit
     *  @param amount the amount to withdraw
     *  @param priorityFee the priorityFee to send to the white fisher
     *  @param signature the signature of the user who wants to send the message
     *                   a signature is contructed with a message like this:
     *                  "addressToReceive,nonce,priorityFee,amount"
     */
    function fisherDepositERC20(
        address addressToReceive,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForFisherBridgeERC20(
                msg.sender,
                addressToReceive == address(0) ? msg.sender : addressToReceive,
                nextFisherDepositNonce[msg.sender],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) {
            revert("");
        }

        if (whitelistTokenUniswapPool[tokenAddress] == address(0)) {
            revert();
        }

        uint256 amountOut = estimateAmountUsingUniswapV3Pool(
            whitelistTokenUniswapPool[tokenAddress],
            tokenAddress,
            uint128(amount),
            3000
        );

        if (amountOut > maxAmountToDeposit) {
            revert();
        }

        if (
            !IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                (amount + priorityFee)
            )
        ) {
            revert();
        }

        nextFisherDepositNonce[msg.sender]++;

        emit FisherMakeDeposit(signature);
    }

    /**
     *  @notice This function is use to receive the withdrawal of the fisher bridge
     *  @param user the address of the user to receive the withdrawal
     *  @param tokenAddress the address of the token to receive
     *  @param priorityFee the priorityFee to receive
     *  @param amount the amount to receive
     *  @param signature the signature of the user
     */
    function fisherWithdrawalReceiver(
        address user,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external {
        if (msg.sender != goldenFisher) {
            revert();
        }
        if (
            !verifyMessageSignedForFisherBridgeERC20(
                user,
                addressToReceive == address(0) ? msg.sender : addressToReceive,
                nextFisherWithdrawalNonce[user],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) {
            revert();
        }

        nextFisherWithdrawalNonce[user]++;

        withdraw(user, tokenAddress, amount);
    }

    //═Admin/Owner tools═══════════════════════════════════════════════════════════════════════════

    /**
     *  @notice transferOwnership, cancelTransferOwnership and claimOwner are a form to
     *          transfer the ownership of the contract to a new owner, the way to do this
     *          is to call the function transferOwnership with the address of the new owner
     *          when is called there is a 24 hours window to cancel the transfer, if the
     *          transfer is not canceled the new owner can claim the ownership
     */

    /**
     *  @notice This function is used to prepare the transfer of the ownership of the contract
     *  @param newOwner the address of the new owner
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        whiteListChangeOwner_proposal = newOwner;
        whiteListChangeOwner_dateToAccept = block.timestamp + 1 days;
    }

    /**
     *  @notice This function is used to cancel the transfer of the ownership of the contract
     *          the function can be called only by actual owner of the contract
     */
    function rejectProposeOwner() public onlyOwner {
        whiteListChangeOwner_proposal = address(0);
        whiteListChangeOwner_dateToAccept = 0;
    }

    /**
     *  @notice This function is used to claim the ownership of the contract
     *          the function can be called only by the new owner of the contract
     */
    function acceptOwner() public {
        if (whiteListChangeOwner_dateToAccept < block.timestamp) {
            revert();
        }
        _transferOwnership(whiteListChangeOwner_proposal);

        whiteListChangeOwner_proposal = address(0);
        whiteListChangeOwner_dateToAccept = 0;
    }

    /**
     * @notice This next functions are used to whitelist tokens using the uniswap v3 pools
     *        the function is used to add a token to the whitelist and the address of the
     *        uniswap v3 pool to use for the estimation of the amount of the token to send
     *        the way to prepare the token to be added is to call the function
     *        prepareTokenToBeWhitelisted with the address of the token and the address of the
     *        uniswap v3 pool, then we have 24 hours to cancel the preparation, if the preparation
     *        is not canceled we can call the function addTokenToWhitelist to add the token to the
     *        whitelist
     * @notice ONLY the ERC20 tokens CAN be added to the whitelist and the pool must be a uniswap v3 pool
     */

    /**
     *  @notice This function is used to prepare a token to be added to the whitelist
     *  @param token the address of the token to be added
     *  @param pool the address of the uniswap v3 pool to use for the estimation
     */
    function prepareTokenToBeWhitelisted(
        address token,
        address pool
    ) public onlyOwner {
        whitelistTokenToBeAdded_address = token;
        whitelistTokenToBeAdded_pool = pool;
        whitelistTokenToBeAdded_dateToSet = block.timestamp + 1 days;
    }

    /**
     *  @notice This function is used to cancel the preparation of the token to be added
     */
    function cancelPrepareTokenToBeWhitelisted() public onlyOwner {
        whitelistTokenToBeAdded_address = address(0);
        whitelistTokenToBeAdded_pool = address(0);
        whitelistTokenToBeAdded_dateToSet = 0;
    }

    /**
     * @notice This function is used to add the token to the whitelist
     */
    function addTokenToWhitelist() public onlyOwner {
        if (whitelistTokenToBeAdded_dateToSet < block.timestamp) {
            revert();
        }
        whitelistTokenUniswapPool[
            whitelistTokenToBeAdded_address
        ] = whitelistTokenToBeAdded_pool;
        whitelistTokenToBeAdded_address = address(0);
        whitelistTokenToBeAdded_pool = address(0);
        whitelistTokenToBeAdded_dateToSet = 0;

        emit NewTokenWhitelisted(
            whitelistTokenToBeAdded_address,
            whitelistTokenToBeAdded_pool
        );
    }

    /**
     *  @notice This function is used to remove a token imidiatly from the whitelist
     *  @param tokenAddress the address of the token to remove
     */
    function removeTokenFromWhitelist(address tokenAddress) public onlyOwner {
        whitelistTokenUniswapPool[tokenAddress] = address(0);
    }

    /**
     *  @notice This function is used to see if a token is in the whitelist
     *  @param tokenAddress the address of the token to see
     *  @return true if the token is in the whitelist, false otherwise
     */
    function seeTokenWhitelist(
        address tokenAddress
    ) public view returns (bool) {
        return whitelistTokenUniswapPool[tokenAddress] != address(0);
    }

    /**
     * @notice prepareMaxAmountToDeposit, cancelPrepareMaxAmountToDeposit and setMaxAmountToDeposit
     *         are used to set the max amount to deposit, the way to do this is to call the function
     *         prepareMaxAmountToDeposit with the new amount to set, then we have 24 hours to cancel
     *         the preparation, if the preparation is not canceled we can call the function
     *         setMaxAmountToDeposit to set the new amount
     */

    /**
     *  @notice This function is used to set the max amount to deposit
     *  @param amount the new amount to set
     */
    function proposeMaxAmountToDeposit(uint256 amount) public onlyOwner {
        maxAmountToDeposit_proposal = amount;
        maxAmountToDeposit_dateToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice This function is used to cancel the preparation of the max amount to deposit
     */
    function rejectProposeMaxAmountToDeposit() public onlyOwner {
        maxAmountToDeposit_proposal = 0;
        maxAmountToDeposit_dateToAccept = 0;
    }

    /**
     *  @notice This function is used to set the max amount to deposit
     */
    function acceptyMaxAmountToDeposit() public onlyOwner {
        if (maxAmountToDeposit_dateToAccept < block.timestamp) {
            revert();
        }
        maxAmountToDeposit = maxAmountToDeposit_proposal;
        maxAmountToDeposit_proposal = 0;
        maxAmountToDeposit_dateToAccept = 0;
    }

    //═Uniswap functions═══════════════════════════════════════════════════════════════════════════

    /**
     *  @dev This function is used to estimate the amount of a token using a uniswap v3 pool
     *       the function uses the OracleLibrary from the uniswap v3 periphery contracts to
     *       calculate the amount of a token to send in ETH (For simplicity the function uses
     *       the WETH token as the output token)
     *  @param poolv3 address of the uniswap v3 pool
     *  @param tokenIn address of the token to send
     *  @param amountIn amount of the token to send
     *  @param secondsAgo the seconds ago to use for the calculation
     */
    function estimateAmountUsingUniswapV3Pool(
        address poolv3,
        address tokenIn,
        uint128 amountIn,
        uint32 secondsAgo
    ) public view returns (uint256 ammountOut) {
        (int24 tick, ) = OracleLibrary.consult(poolv3, secondsAgo);
        ammountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            tokenIn,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
    }

    //═Withdraw functions ═════════════════════════════════════════════════════════════════════════

    /**
     *  @dev withdraw ETH or ERC20 tokens from Roll a Mate to Ethereum
     *  @param _user the address of the user to withdraw
     *  @param _token the address of the token to withdraw, 0x0 for ETH
     */
    function withdraw(address _user, address _token, uint256 _amount) internal {
        if (_token == address(0)) {
            payable(_user).transfer(_amount);
        } else {
            IERC20(_token).transfer(_user, _amount);
        }
    }

    //═Signature functions ════════════════════════════════════════════════════════════════════════

    /**
     *  @notice This function is used to verify the signature of the user who wants to
     *          interact with the fisherBridgeERC20 function
     * @param signer the address of the signer
     *
     * @param addressToReceive address of the account to receive the deposit
     * @param nonce nonce of nextFisherDepositNonce
     * @param tokenAddress token address
     * @param priorityFee priority fee for fishers
     * @param amount amount to deposit
     * @param signature signature of the user
     */
    function verifyMessageSignedForFisherBridgeERC20(
        address signer,
        address addressToReceive,
        uint256 nonce,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            signer ==
            SignatureRecover.recoverSigner(
                string.concat(
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    Strings.toString(nonce),
                    ",",
                    AdvancedStrings.addressToString(tokenAddress),
                    ",",
                    Strings.toString(priorityFee),
                    ",",
                    Strings.toString(amount)
                ),
                signature
            );
    }

    /**
     *  @notice This function is used to verify the signature of the user who wants to
     *         interact with the fisherBridgeETH function
     * @param signer address of the signer
     * @param addressToReceive address of the account to receive the deposit
     * @param nonce nonce of nextFisherDepositNonce
     * @param priorityFee priority fee for fishers
     * @param amount amount to deposit
     * @param signature signature of the user
     */
    function verifyMessageSignedForFisherBridgeETH(
        address signer,
        address addressToReceive,
        uint256 nonce,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            signer ==
            SignatureRecover.recoverSigner(
                string.concat(
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    Strings.toString(nonce),
                    ",",
                    Strings.toString(priorityFee),
                    ",",
                    Strings.toString(amount)
                ),
                signature
            );
    }

    //═Cross chain functions═══════════════════════════════════════════════════════════════════════

    /// @dev function to receive the deposit from Axelar
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload_
    ) internal override {
        if (
            !Strings.equal(sourceChain, evvmMetadata.axelarChain) &&
            !Strings.equal(sourceAddress, evvmMetadata.axelarAddress)
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        withdraw(user, token, amount);
    }

    /// @dev function to receive the deposit from CCIP
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        if (msg.sender != routerCCIP) {
            revert();
        }
        if (
            any2EvmMessage.sourceChainSelector != evvmMetadata.ccipChain ||
            abi.decode(any2EvmMessage.sender, (address)) !=
            evvmMetadata.ccipAddress
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            any2EvmMessage.data,
            (address, address, uint256)
        );

        withdraw(user, token, amount);
    }

    /// @dev function to receive the deposit from Hyperlane
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != mailboxHyperlane) {
            revert();
        }
        if (
            _sender != evvmMetadata.hyperlaneAddress &&
            _origin != evvmMetadata.hyperlaneChain
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            _data,
            (address, address, uint256)
        );

        withdraw(user, token, amount);
    }

    /// @dev function to receive the deposit from LayerZero
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        uint32 senderEid = _origin.srcEid;
        bytes32 sender = _origin.sender;
        if (
            senderEid != evvmMetadata.layerZeroChain ||
            sender != evvmMetadata.layerZeroAddress
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            payload,
            (address, address, uint256)
        );

        withdraw(user, token, amount);
    }

    /// @dev function to build the message for CCIP
    function _buildCCIPMessage(
        address _receiver,
        bytes memory _payload,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: _payload, // ABI-encoded payload
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit
                    Client.EVMExtraArgsV1({gasLimit: 200_000})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }

    function lookLzSenderApp() public view returns (address) {
        return address(lzSenderApp);
    }

    function oAppVersion()
        public
        pure
        override(OAppReceiver)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (0, RECEIVER_VERSION);
    }

    //═User functions══════════════════════════════════════════════════════════════════════════════

    function getMaxAmountToDeposit() external view returns (uint256) {
        return maxAmountToDeposit;
    }

    function getNextFisherDepositNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherDepositNonce[user];
    }

    function getNextFisherWithdrawalNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherWithdrawalNonce[user];
    }

    function getTokensWhitelistPool(
        address tokenAddress
    ) external view returns (address) {
        return whitelistTokenUniswapPool[tokenAddress];
    }

    function getIfTokenIsWhitelisted(
        address tokenAddress
    ) external view returns (bool) {
        return whitelistTokenUniswapPool[tokenAddress] != address(0);
    }
}

contract SourceOApp is OAppSender {
    /**
     * @notice Initializes the OApp with the source chain's endpoint address.
     * @param _endpoint The endpoint address.
     * @param _owner The OApp child contract owner.
     */
    constructor(
        address _endpoint,
        address _owner
    ) OAppCore(_endpoint, _owner) Ownable(msg.sender) {}

    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _message The message.
     * @param _options Message execution options (e.g., for sending gas to destination).
     * @param _payInLzToken Whether to return fee in ZRO token.
     */
    function quote(
        uint32 _dstEid,
        string memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    function send(
        uint32 _dstEid,
        bytes memory _payload,
        bytes calldata _options,
        address whoGetRefund
    ) external payable {
        // Encodes the message before invoking _lzSend.
        _lzSend(
            _dstEid,
            _payload,
            _options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(whoGetRefund)
        );
    }
}
