// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**

░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
                                                             
 * @title AccountBook contract for Roll A Mate Protocol
 * @author jistro.eth ariutokintumi.eth
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
import {MateNameService} from "../mateNameService/MateNameService.sol";
import {SMate} from "@RollAMate/core/staking/SMate.sol";
import {SignatureRecover} from "@RollAMate/libraries/SignatureRecover.sol";
import {AdvancedStrings} from "@RollAMate/libraries/AdvancedStrings.sol";

contract Evvm is
    Ownable,
    AxelarExecutable,
    CCIPReceiver,
    OAppReceiver,
    OAppSender
{
    using SignatureRecover for *;
    using AdvancedStrings for *;

    struct PayData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        uint256 nonce;
        bool priority;
        address executor;
        bytes signature;
    }

    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    struct TreasuryMetadata {
        string AxelarChain;
        string AxelarAddress;
        uint64 CCIPChain;
        address CCIPAddress;
        uint32 HyperlaneChain;
        bytes32 HyperlaneAddress;
        uint32 LayerZeroChain;
        bytes32 LayerZeroAddress;
    }

    struct whitheListedTokenMetadata {
        bool isAllowed;
        address uniswapPool;
    }

    struct MateTokenomicsMetadata {
        uint256 totalSupply;
        uint256 eraTokens;
        uint256 reward;
        address mateAddress;
    }

    struct AddressTypeProposal {
        address actual;
        address proposal;
        uint256 timeToAccept;
    }

    struct UintTypeProposal {
        uint256 actual;
        uint256 proposal;
        uint256 timeToAccept;
    }

    MateTokenomicsMetadata private mate =
        MateTokenomicsMetadata({
            totalSupply: 2033333333000000000000000000,
            eraTokens: 2033333333000000000000000000 / 2,
            reward: 5000000000000000000,
            mateAddress: 0x0000000000000000000000000000000000000001
        });

    TreasuryMetadata private treasuryMetadata;

    //IAxelarGasService public immutable gasService;

    address private gasServiceAddress;

    AddressTypeProposal admin;

    address private whitelistTokenToBeAdded_address;
    address private whitelistTokenToBeAdded_pool;
    uint256 private whitelistTokenToBeAdded_dateToSet;

    UintTypeProposal private maxAmountToWithdraw;

    mapping(address => bytes1) private stakerList;

    address private routerCCIP;

    address private mailboxHyperlane;

    address private mateNameServiceAddress;

    address private sMateContractAddress;

    address constant ETH_ADDRESS = address(0);

    mapping(address user => mapping(address token => uint256 quantity))
        private balances;

    mapping(address user => uint256 nonce) private nextSyncUsedNonce;

    mapping(address user => mapping(uint256 nonce => bool isUsed))
        private asyncUsedNonce;

    mapping(address user => uint256 nonce) private nextFisherDepositNonce;

    mapping(address user => uint256 nonce) private nextFisherWithdrawalNonce;

    mapping(address token => whitheListedTokenMetadata)
        private whitelistedTokens;

    event MakeWithdrawal(
        address indexed user,
        address indexed token,
        uint8 indexed solutionId,
        bool usingMateStaking,
        uint256 amount
    );

    event MakePayment(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        bool usingMateStaking
    );

    event NewTokenWhitelisted(address indexed token, address indexed pool);

    constructor(
        address _initialOwner,
        address _AxelarGateway,
        address _AxelarGasService,
        address _CcipRouter,
        address _HyperlaneMailbox,
        address _LayerZeroEndpoint,
        address _sMateContractAddress
    )
        AxelarExecutable(_AxelarGateway)
        Ownable(_initialOwner)
        CCIPReceiver(_CcipRouter)
        OAppCore(_LayerZeroEndpoint, _initialOwner)
    {
        //gasService = IAxelarGasService(AxelarGasService);
        gasServiceAddress = _AxelarGasService;
        mailboxHyperlane = _HyperlaneMailbox;

        maxAmountToWithdraw.actual = 0.1 ether;

        sMateContractAddress = _sMateContractAddress;
    }

    function _setTreasuryMetadata(
        string memory _axelarTreasuryAddress,
        string memory _axelarTreasuryChain,
        address _ccipTreasuryAddress,
        uint64 _ccipTreasuryChain,
        address _hyperlaneTreasuryAddress,
        uint32 _hyperlaneTreasuryChain,
        address _layerZeroTreasuryAddress,
        uint32 _layerZeroTreasuryChain
    ) external onlyOwner {
        treasuryMetadata.AxelarAddress = _axelarTreasuryAddress;
        treasuryMetadata.AxelarChain = _axelarTreasuryChain;
        treasuryMetadata.CCIPAddress = _ccipTreasuryAddress;
        treasuryMetadata.CCIPChain = _ccipTreasuryChain;
        treasuryMetadata.HyperlaneAddress = bytes32(
            uint256(uint160(_hyperlaneTreasuryAddress))
        );
        treasuryMetadata.HyperlaneChain = _hyperlaneTreasuryChain;
        treasuryMetadata.LayerZeroAddress = bytes32(
            uint256(uint160(_layerZeroTreasuryAddress))
        );
        treasuryMetadata.LayerZeroChain = _layerZeroTreasuryChain;
        OAppCore.setPeer(
            treasuryMetadata.LayerZeroChain,
            treasuryMetadata.LayerZeroAddress
        );
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Withdrawal functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @notice Withdrawal for non sMate holders
     *  @param addressToReceive address to receive the tokens
     *  @param token token to send
     *  @param amount amount to send
     *  @param priorityFee the priorityFee to send to the user who sends the message
     *  @param signature the signature of the user who wants to send the message
     *  @param _solutionId the solution id to use for sending the message
     *                     1 -- Axelar
     *                     2 -- CCIP
     *                     3 -- Hyperlane
     *                     4 -- LayerZero
     *  @param _options the options to send with the message for defaullt
     *                  we recommend to use 2000 wei as gas fee and send
     *                  200000 gwei for paying the gas (only for LayerZero)
     */
    function withdrawalNoMateStaking_sync(
        address user,
        address addressToReceive,
        address token,
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable {
        if (
            !verifyMessageSignedForWithdrawal(
                user,
                addressToReceive,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[user],
                false,
                signature
            )
        ) {
            revert();
        }

        if (token == mate.mateAddress || balances[user][token] < amount) {
            revert();
        }

        if (token == ETH_ADDRESS) {
            if (amount > 100000000000000000) {
                revert();
            }
        } else {
            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistedTokens[token].uniswapPool,
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToWithdraw.actual) {
                revert();
            }
        }

        balances[user][token] -= amount;

        bytes memory payload = abi.encode(
            addressToReceive == address(0) ? user : addressToReceive,
            token,
            amount
        );

        nextSyncUsedNonce[user]++;

        makeCallCrossChain(payload, _solutionId, _options);

        emit MakeWithdrawal(
            addressToReceive == address(0) ? user : addressToReceive,
            token,
            _solutionId,
            false,
            amount
        );
    }

    /**
     *  @notice Withdrawal for sMate holders//fishers if the user is a sMate holder
     *          is rewarded with 5 mate tokens
     *  @param addressToReceive address to receive the tokens
     *  @param token token to send
     *  @param amount amount to send
     *  @param priorityFee the priorityFee to send to the user who sends the message
     *  @param nonce the nonce of the transaction to use
     *  @param signature the signature of the user who wants to send the message
     *  @param _solutionId the solution id to use for sending the message
     *                     1 -- Axelar
     *                     2 -- CCIP
     *                     3 -- Hyperlane
     *                     4 -- LayerZero
     *  @param _options the options to send with the message for defaullt
     *                  we recommend to use 2000 wei as gas fee and send
     *                  200000 gwei for paying the gas (only for LayerZero)
     */
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
    ) external payable {
        if (
            !verifyMessageSignedForWithdrawal(
                user,
                addressToReceive,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                signature
            )
        ) {
            revert();
        }
        if (
            token == mate.mateAddress ||
            asyncUsedNonce[user][nonce] ||
            balances[user][token] < amount
        ) {
            revert();
        }

        if (token == ETH_ADDRESS) {
            if (amount > 100000000000000000) {
                revert();
            }
        } else {
            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistedTokens[token].uniswapPool,
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToWithdraw.actual) {
                revert();
            }
        }

        balances[msg.sender][token] -= amount;

        bytes memory payload = abi.encode(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            amount
        );

        asyncUsedNonce[msg.sender][nonce] = true;

        makeCallCrossChain(payload, _solutionId, _options);

        emit MakeWithdrawal(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            _solutionId,
            true,
            amount
        );
    }

    /**
     *  @notice Withdrawal for sMate holders//fishers if the user is a sMate holder
     *          is rewarded
     *  @param user user who wants to withdraw
     *  @param addressToReceive address to receive the tokens
     *  @param token token to send
     *  @param amount amount to send
     *  @param priorityFee the priorityFee to send to the user who sends the message
     *  @param signature the signature of the user who wants to send the message
     *  @param _solutionId the solution id to use for sending the message
     *                     1 -- Axelar
     *                     2 -- CCIP
     *                     3 -- Hyperlane
     *                     4 -- LayerZero
     *  @param _options the options to send with the message for defaullt
     *                  we recommend to use 2000 wei as gas fee and send
     *                  200000 gwei for paying the gas (only for LayerZero)
     */
    function withdrawalMateStaking_sync(
        address user,
        address addressToReceive,
        address token,
        uint256 amount,
        uint256 priorityFee,
        bytes memory signature,
        uint8 _solutionId,
        bytes calldata _options
    ) external payable {
        if (
            !verifyMessageSignedForWithdrawal(
                user,
                addressToReceive,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[user],
                false,
                signature
            )
        ) {
            revert();
        }

        if (
            token == mate.mateAddress ||
            !isMateStaker(msg.sender) ||
            balances[user][token] < amount + priorityFee
        ) {
            revert();
        }

        if (token == ETH_ADDRESS) {
            if (amount > 100000000000000000) {
                revert();
            }
        } else {
            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistedTokens[token].uniswapPool,
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToWithdraw.actual) {
                revert();
            }
        }

        balances[user][token] -= (amount + priorityFee);

        balances[msg.sender][token] += priorityFee;

        bytes memory payload = abi.encode(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            amount
        );

        //giveReward(msg.sender, 1);
        balances[msg.sender][mate.mateAddress] += mate.reward;

        nextSyncUsedNonce[user]++;

        makeCallCrossChain(payload, _solutionId, _options);

        emit MakeWithdrawal(user, token, _solutionId, true, amount);
    }

    /**
     *  @notice Withdrawal for sMate holders//fishers if the user is a sMate holder
     *          is rewarded with 5 mate tokens
     *  @param user user who wants to withdraw
     *  @param addressToReceive address to receive the tokens
     *  @param token token to send
     *  @param amount amount to send
     *  @param priorityFee the priorityFee to send to the user who sends the message
     *  @param nonce the nonce of the transaction to use
     *  @param signature the signature of the user who wants to send the message
     *  @param _solutionId the solution id to use for sending the message
     *                     1 -- Axelar
     *                     2 -- CCIP
     *                     3 -- Hyperlane
     *                     4 -- LayerZero
     *  @param _options the options to send with the message for defaullt
     *                  we recommend to use 2000 wei as gas fee and send
     *                  200000 gwei for paying the gas (only for LayerZero)
     */
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
    ) external payable {
        if (
            !verifyMessageSignedForWithdrawal(
                user,
                addressToReceive,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                signature
            )
        ) {
            revert();
        }

        if (
            token == mate.mateAddress ||
            asyncUsedNonce[user][nonce] ||
            !isMateStaker(msg.sender) ||
            balances[user][token] < amount + priorityFee
        ) {
            revert();
        }

        if (token == ETH_ADDRESS) {
            if (amount > 100000000000000000) {
                revert();
            }
        } else {
            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistedTokens[token].uniswapPool,
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToWithdraw.actual) {
                revert();
            }
        }

        balances[user][token] -= (amount + priorityFee);

        balances[msg.sender][token] += priorityFee;

        bytes memory payload = abi.encode(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            amount
        );

        //giveReward(msg.sender, 1);
        balances[msg.sender][mate.mateAddress] += mate.reward;

        asyncUsedNonce[user][nonce] = true;

        makeCallCrossChain(payload, _solutionId, _options);

        emit MakeWithdrawal(
            addressToReceive == address(0) ? msg.sender : addressToReceive,
            token,
            _solutionId,
            true,
            amount
        );
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Pay functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @notice Pay function for non sMate holders (syncronous nonce)
     *  @param from user // who wants to pay
     *  @param to_address address of the receiver
     *  @param to_identity identity of the receiver
     *  @param token address of the token to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the sMate holder
     *  @param signature signature of the user who wants to send the message
     */
    function payNoMateStaking_sync(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[from],
                false,
                executor,
                signature
            )
        ) {
            revert();
        }

        if (executor != address(0)) {
            if (msg.sender != executor) {
                revert();
            }
        }

        address to = !Strings.equal(to_identity, "")
            ? MateNameService(mateNameServiceAddress)
                .verifyStrictAndGetOwnerOfIdentity(to_identity)
            : to_address;

        if (!_updateBalance(from, to, token, amount)) {
            revert();
        }

        nextSyncUsedNonce[from]++;

        emit MakePayment(from, to, token, amount, false);
    }

    /**
     *  @notice Pay function for non sMate holders (asyncronous nonce)
     *  @param from user // who wants to pay
     *  @param to_address address of the receiver
     *  @param to_identity identity of the receiver
     *  @param token address of the token to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the sMate holder
     *  @param nonce nonce of the transaction
     *  @param signature signature of the user who wants to send the message
     */
    function payNoMateStaking_async(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                executor,
                signature
            )
        ) {
            revert();
        }

        if (executor != address(0)) {
            if (msg.sender != executor) {
                revert();
            }
        }

        if (asyncUsedNonce[from][nonce]) {
            revert();
        }

        address to = !Strings.equal(to_identity, "")
            ? MateNameService(mateNameServiceAddress)
                .verifyStrictAndGetOwnerOfIdentity(to_identity)
            : to_address;

        if (!_updateBalance(from, to, token, amount)) {
            revert();
        }

        asyncUsedNonce[from][nonce] = true;

        emit MakePayment(from, to, token, amount, false);
    }

    /**
     *  @notice Pay function for sMate holders (syncronous nonce)
     *  @param from user // who wants to pay
     *  @param to_address address of the receiver
     *  @param to_identity identity of the receiver
     *  @param token address of the token to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the sMate holder
     *  @param signature signature of the user who wants to send the message
     */
    function payMateStaking_sync(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[from],
                false,
                executor,
                signature
            )
        ) {
            revert();
        }

        if (executor != address(0)) {
            if (msg.sender != executor) {
                revert();
            }
        }

        if (!isMateStaker(msg.sender)) {
            revert();
        }

        address to = !Strings.equal(to_identity, "")
            ? MateNameService(mateNameServiceAddress)
                .verifyStrictAndGetOwnerOfIdentity(to_identity)
            : to_address;

        if (!_updateBalance(from, to, token, amount)) {
            revert();
        }
        if (priorityFee > 0) {
            if (!_updateBalance(from, msg.sender, token, priorityFee)) {
                revert();
            }
        }
        _giveMateReward(msg.sender, 1);

        nextSyncUsedNonce[from]++;

        emit MakePayment(from, to, token, amount, true);
    }

    /**
     *  @notice Pay function for sMate holders (asyncronous nonce)
     *  @param from user // who wants to pay
     *  @param to_address address of the receiver
     *  @param to_identity identity of the receiver
     *  @param token address of the token to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the sMate holder
     *  @param nonce nonce of the transaction
     *  @param signature signature of the user who wants to send the message
     */
    function payMateStaking_async(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                executor,
                signature
            )
        ) {
            revert();
        }

        if (executor != address(0)) {
            if (msg.sender != executor) {
                revert();
            }
        }

        if (!isMateStaker(msg.sender) || asyncUsedNonce[from][nonce]) {
            revert();
        }

        address to = !Strings.equal(to_identity, "")
            ? MateNameService(mateNameServiceAddress)
                .verifyStrictAndGetOwnerOfIdentity(to_identity)
            : to_address;

        if (!_updateBalance(from, to, token, amount)) {
            revert();
        }
        if (priorityFee > 0) {
            if (!_updateBalance(from, msg.sender, token, priorityFee)) {
                revert();
            }
        }
        _giveMateReward(msg.sender, 1);

        asyncUsedNonce[from][nonce] = true;

        emit MakePayment(from, to, token, amount, true);
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Multiple pay function
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    /**
     *  @notice Pay function for despaching multiple transactions for non sMate holders
     *          (syncronous nonce)
     *  @param payData array of PayData it contains the data for the transactions
     *                 - from       user // who wants to pay
     *                 - to         receiver // who wants to receive
     *                 - token      address of the token to send
     *                 - amount     amount to send
     *                 - priorityFee        priorityFee to send to the sMate holder
     *                 - nonce      nonce of the transaction
     *                 - priority   priority of the transaction
     *                 - executor   executor of the transaction
     *                 - signature  signature of the user who wants to send the message
     *  @return successfulTransactions the number of successful transactions
     *          signaturesFailed list of the transactions that failed
     */
    function payMultiple(
        PayData[] memory payData
    )
        external
        returns (uint256 successfulTransactions, uint256 failedTransactions)
    {
        address to_aux;
        for (uint256 iteration = 0; iteration < payData.length; iteration++) {
            if (
                !verifyMessageSignedForPay(
                    payData[iteration].from,
                    payData[iteration].to_address,
                    payData[iteration].to_identity,
                    payData[iteration].token,
                    payData[iteration].amount,
                    payData[iteration].priorityFee,
                    payData[iteration].priority
                        ? payData[iteration].nonce
                        : nextSyncUsedNonce[payData[iteration].from],
                    payData[iteration].priority,
                    payData[iteration].executor,
                    payData[iteration].signature
                )
            ) {
                revert();
            }

            if (payData[iteration].executor != address(0)) {
                if (msg.sender != payData[iteration].executor) {
                    failedTransactions++;
                    continue;
                }
            }

            if (payData[iteration].priority) {
                /// @dev priority == true (async)

                if (
                    !asyncUsedNonce[payData[iteration].from][
                        payData[iteration].nonce
                    ]
                ) {
                    asyncUsedNonce[payData[iteration].from][
                        payData[iteration].nonce
                    ] = true;
                } else {
                    failedTransactions++;
                    continue;
                }
            } else {
                /// @dev priority == false (sync)

                if (
                    nextSyncUsedNonce[payData[iteration].from] ==
                    payData[iteration].nonce
                ) {
                    nextSyncUsedNonce[payData[iteration].from]++;
                } else {
                    failedTransactions++;
                    continue;
                }
            }

            to_aux = !Strings.equal(payData[iteration].to_identity, "")
                ? MateNameService(mateNameServiceAddress)
                    .verifyStrictAndGetOwnerOfIdentity(
                        payData[iteration].to_identity
                    )
                : payData[iteration].to_address;

            if (
                payData[iteration].priorityFee + payData[iteration].amount >
                balances[payData[iteration].from][payData[iteration].token]
            ) {
                failedTransactions++;
                continue;
            }

            if (
                !_updateBalance(
                    payData[iteration].from,
                    to_aux,
                    payData[iteration].token,
                    payData[iteration].amount
                )
            ) {
                failedTransactions++;
                continue;
            } else {
                if (
                    payData[iteration].priorityFee > 0 &&
                    isMateStaker(msg.sender)
                ) {
                    if (
                        !_updateBalance(
                            payData[iteration].from,
                            msg.sender,
                            payData[iteration].token,
                            payData[iteration].priorityFee
                        )
                    ) {
                        failedTransactions++;
                        continue;
                    }
                }

                successfulTransactions++;
            }
        }

        if (isMateStaker(msg.sender)) {
            _giveMateReward(msg.sender, successfulTransactions);
        }
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Disperse pay function
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @notice dispersePay function can send multiple payments to multiple addresses
     *  @dev the function can be used for both sMate holders and non sMate holders
     *  @param from address of the user who wants to send the payment
     *  @param toData array of DispersePayMetadata it contains the data for the transactions
     *                - amount     amount to send
     *                - to_address address of the receiver
     *                - to_identity identity of the receiver
     *                @notice if to_address is 0x0 the function will use the to_identity
     *                        to get the address
     *  @param token address of the token to send
     *  @param amount amount in total to send
     *  @param priorityFee the priorityFee to send to the fisher who wants to send the message
     *  @param nonce the nonce of the transaction async/s
     *  @param priority if the transaction is priority (async) or not (sync)
     *  @param executor the executor of the transaction
     *  @param signature the signature of the user who wants to send the message
     *                   the message is composed like this:
     *                   keccak256(abi.encode(toData)) + token + amount + priorityFee + nonce + priority + executor
     */
    function dispersePay(
        address from,
        DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priority,
        address executor,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForDispersePay(
                from,
                sha256(abi.encode(toData)),
                token,
                amount,
                priorityFee,
                priority ? nonce : nextSyncUsedNonce[from],
                priority,
                executor,
                signature
            )
        ) {
            revert();
        }

        if (executor != address(0)) {
            if (msg.sender != executor) {
                revert();
            }
        }

        if (priority) {
            if (asyncUsedNonce[from][nonce]) {
                revert();
            }
        }

        if (balances[from][token] < amount + priorityFee) {
            revert();
        }

        uint256 acomulatedAmount = 0;
        balances[from][token] -= (amount + priorityFee);

        address to_aux;

        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;

            if (!Strings.equal(toData[i].to_identity, "")) {
                if (
                    MateNameService(mateNameServiceAddress)
                        .strictVerifyIfIdentityExist(toData[i].to_identity)
                ) {
                    to_aux = MateNameService(mateNameServiceAddress)
                        .getOwnerOfIdentity(toData[i].to_identity);
                }
            } else {
                to_aux = toData[i].to_address;
            }

            balances[to_aux][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount) {
            revert();
        }

        if (isMateStaker(msg.sender)) {
            _giveMateReward(msg.sender, 1);
            balances[msg.sender][token] += priorityFee;
        } else {
            balances[from][token] += priorityFee;
        }

        if (priority) {
            asyncUsedNonce[from][nonce] = true;
        } else {
            nextSyncUsedNonce[from]++;
        }
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Contract Account Pay
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @notice caPay function is used to send a payment to a contract account (smart account)
     *  @param to address of the contract account
     *  @param token address of the token to send
     *  @param amount amount to send
     */
    function caPay(address to, address token, uint256 amount) external {
        uint size;
        address from = msg.sender;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        if (size == 0) {
            revert();
        }

        if (!_updateBalance(from, to, token, amount)) {
            revert();
        }

        if (isMateStaker(msg.sender)) {
            _giveMateReward(msg.sender, 1);
        }

        emit MakePayment(msg.sender, to, token, amount, true);
    }

    /**
     * @notice disperseCaPay function is used to send multiple payments to multiple contract accounts
     * @param toData array of SplitPayMetadata it contains the data for the transactions
     *               - amount     amount to send
     *               - to_address address of the receiver
     *               - to_identity identity of the receiver
     *               @notice if to_address is 0x0 the function will use the to_identity to get the address
     * @param token address of the token to send
     * @param amount amount in total to send
     */
    function disperseCaPay(
        DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) external {
        uint size;
        address from = msg.sender;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        if (size == 0) {
            revert();
        }

        uint256 acomulatedAmount = 0;
        if (balances[msg.sender][token] < amount) {
            revert();
        }

        balances[msg.sender][token] -= amount;

        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;
            if (acomulatedAmount > amount) {
                revert();
            }

            balances[toData[i].toAddress][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount) {
            revert();
        }

        if (isMateStaker(msg.sender)) {
            _giveMateReward(msg.sender, 1);
        }
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Fisher Bridge functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @notice This function is use to receive the deposit from the fisher bridge
     *  @param user address of the user who wants to deposit
     *  @param token address of the token to deposit if the token is 0x0 is ether
     *  @param priorityFee the priorityFee to send to the white fisher
     *  @param amount the amount to deposit
     *  @param signature the signature of the user who wants to send the message
     */
    function fisherDepositReceiver(
        address user,
        address addressToReceive,
        address token,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForFisherBridge(
                user,
                addressToReceive,
                nextFisherDepositNonce[user],
                token,
                priorityFee,
                amount,
                signature
            )
        ) {
            revert();
        }

        if (
            msg.sender != SMate(sMateContractAddress).getGoldenFisher() ||
            !whitelistedTokens[token].isAllowed
        ) {
            revert();
        }

        balances[user][token] += amount;

        balances[msg.sender][token] += priorityFee;

        //giveReward(msg.sender, 1);
        balances[msg.sender][mate.mateAddress] += mate.reward;

        nextFisherDepositNonce[user]++;
    }

    /**
     *  @notice This function is use to send the withdrawal to the fisher bridge
     *  @param user address of the user who wants to withdraw
     *  @param token address of the token to withdraw if the token is 0x0 is ether
     *  @param priorityFee the priorityFee to send to the white fisher
     *  @param amount the amount to withdraw
     *  @param signature the signature of the user who wants to send the message
     */
    function fisherWithdrawal(
        address user,
        address addressToReceive,
        address token,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external {
        if (
            !verifyMessageSignedForFisherBridge(
                user,
                addressToReceive,
                nextFisherWithdrawalNonce[user],
                token,
                priorityFee,
                amount,
                signature
            )
        ) {
            revert();
        }

        if (
            msg.sender != SMate(sMateContractAddress).getGoldenFisher() ||
            token == mate.mateAddress ||
            balances[user][token] < amount + priorityFee
        ) {
            revert();
        }

        if (token == ETH_ADDRESS) {
            if (amount > maxAmountToWithdraw.actual) {
                revert();
            }
        } else {
            uint256 amountOut = estimateAmountUsingUniswapV3Pool(
                whitelistedTokens[token].uniswapPool,
                token,
                uint128(amount),
                3000
            );

            if (amountOut > maxAmountToWithdraw.actual) {
                revert();
            }
        }

        balances[user][token] -= (amount + priorityFee);

        balances[msg.sender][token] += priorityFee;

        balances[msg.sender][mate.mateAddress] += mate.reward;

        nextFisherWithdrawalNonce[user]++;

        emit MakeWithdrawal(user, token, 0, true, amount);
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Admin/Owner functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    function setMNSAddress(address _mateNameServiceAddress) external onlyOwner {
        mateNameServiceAddress = _mateNameServiceAddress;
    }

    function proposeOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0) || _newOwner == owner()) {
            revert();
        }

        admin.proposal = _newOwner;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposalOwner() external onlyOwner {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    function acceptOwner() external {
        if (block.timestamp < admin.timeToAccept) {
            revert();
        }
        if (msg.sender != admin.proposal) {
            revert();
        }
        _transferOwnership(admin.proposal);

        admin.actual = admin.proposal;

        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice This next functions are used to whitelist tokens and set the uniswap pool for
     *         each token, the uniswap pool is used to calculate the limit of the amount to
     *         send in the withdrawal functions
     */

    function prepareTokenToBeWhitelisted(
        address token,
        address pool
    ) external onlyOwner {
        whitelistTokenToBeAdded_address = token;
        whitelistTokenToBeAdded_pool = pool;
        whitelistTokenToBeAdded_dateToSet = block.timestamp + 1 days;
    }

    function cancelPrepareTokenToBeWhitelisted() external onlyOwner {
        whitelistTokenToBeAdded_address = address(0);
        whitelistTokenToBeAdded_pool = address(0);
        whitelistTokenToBeAdded_dateToSet = 0;
    }

    function addTokenToWhitelist() external onlyOwner {
        if (block.timestamp < whitelistTokenToBeAdded_dateToSet) {
            revert();
        }
        whitelistedTokens[
            whitelistTokenToBeAdded_address
        ] = whitheListedTokenMetadata({
            isAllowed: true,
            uniswapPool: whitelistTokenToBeAdded_pool
        });

        whitelistedTokens[whitelistTokenToBeAdded_address].isAllowed = true;

        whitelistTokenToBeAdded_address = address(0);
        whitelistTokenToBeAdded_pool = address(0);
        whitelistTokenToBeAdded_dateToSet = 0;

        emit NewTokenWhitelisted(
            whitelistTokenToBeAdded_address,
            whitelistTokenToBeAdded_pool
        );
    }

    function changePool(address token, address pool) external onlyOwner {
        if (!whitelistedTokens[token].isAllowed) {
            revert();
        }
        whitelistedTokens[token].uniswapPool = pool;
    }

    function removeTokenWhitelist(address token) external onlyOwner {
        if (!whitelistedTokens[token].isAllowed) {
            revert();
        }
        whitelistedTokens[token].isAllowed = false;
        whitelistedTokens[token].uniswapPool = address(0);
    }

    function prepareMaxAmountToWithdraw(uint256 amount) external onlyOwner {
        maxAmountToWithdraw.proposal = amount;
        maxAmountToWithdraw.timeToAccept = block.timestamp + 1 days;
    }

    function cancelPrepareMaxAmountToWithdraw() external onlyOwner {
        maxAmountToWithdraw.proposal = 0;
        maxAmountToWithdraw.timeToAccept = 0;
    }

    function setMaxAmountToWithdraw() external onlyOwner {
        if (block.timestamp < maxAmountToWithdraw.timeToAccept) {
            revert();
        }
        maxAmountToWithdraw.actual = maxAmountToWithdraw.proposal;
        maxAmountToWithdraw.proposal = 0;
        maxAmountToWithdraw.timeToAccept = 0;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Uniswap V3 functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

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
            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB
        );
    }

    function estimateEthToTokenUsingUniswapV3Pool(
        address poolv3,
        address tokenOut,
        uint128 amountIn,
        uint32 secondsAgo
    ) public view returns (uint256 ammountOut) {
        (int24 tick, ) = OracleLibrary.consult(poolv3, secondsAgo);
        ammountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,
            tokenOut
        );
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Reward functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    function recalculateReward() public {
        if (mate.totalSupply > mate.eraTokens) {
            mate.eraTokens += ((mate.totalSupply - mate.eraTokens) / 2);
            balances[msg.sender][mate.mateAddress] +=
                mate.reward *
                getRandom(1, 5083);
            mate.reward = mate.reward / 2;
        } else {
            revert();
        }
    }

    function getRandom(
        uint256 min,
        uint256 max
    ) internal view returns (uint256) {
        return
            min +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % (max - min + 1));
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Bridge Cross Chain Protocols Functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     * @dev The next functions are used to make the cross chain calls to the different solutions
     */

    function makeCallCrossChain(
        bytes memory payload,
        uint8 _solutionId,
        bytes calldata _options
    ) public payable {
        if (_solutionId == 1) {
            /// @dev Axelar
            IAxelarGasService(gasServiceAddress).payNativeGasForContractCall{
                value: msg.value
            }(
                address(this),
                treasuryMetadata.AxelarChain,
                treasuryMetadata.AxelarAddress,
                payload,
                msg.sender
            );

            gateway.callContract(
                treasuryMetadata.AxelarChain,
                treasuryMetadata.AxelarAddress,
                payload
            );
        } else if (_solutionId == 2) {
            /// @dev CCIP
            Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                treasuryMetadata.CCIPAddress,
                payload,
                address(0)
            );
            uint256 fees = IRouterClient(i_router).getFee(
                treasuryMetadata.CCIPChain,
                evm2AnyMessage
            );
            if (fees > msg.value) {
                revert();
            }
            IRouterClient(i_router).ccipSend{value: msg.value}(
                treasuryMetadata.CCIPChain,
                evm2AnyMessage
            );
        } else if (_solutionId == 3) {
            /// @dev Hyperlane
            IMailbox(mailboxHyperlane).dispatch{value: msg.value}(
                treasuryMetadata.HyperlaneChain,
                treasuryMetadata.HyperlaneAddress,
                payload
            );
        } else if (_solutionId == 4) {
            /// @dev LayerZero
            _lzSend(
                treasuryMetadata.LayerZeroChain,
                payload,
                _options,
                MessagingFee(msg.value, 0),
                payable(msg.sender)
            );
        } else {
            revert();
        }
    }

    /// @dev function to receive the deposit from Axelar
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload_
    ) internal override {
        if (
            !Strings.equal(sourceChain, treasuryMetadata.AxelarChain) &&
            !Strings.equal(sourceAddress, treasuryMetadata.AxelarAddress)
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            payload_,
            (address, address, uint256)
        );

        balances[user][token] += amount;
    }

    /// @dev function to receive the deposit from CCIP
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        if (msg.sender != routerCCIP) {
            revert();
        }
        if (
            any2EvmMessage.sourceChainSelector != treasuryMetadata.CCIPChain ||
            abi.decode(any2EvmMessage.sender, (address)) !=
            treasuryMetadata.CCIPAddress
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            any2EvmMessage.data,
            (address, address, uint256)
        );

        balances[user][token] += amount;
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
            _sender != treasuryMetadata.HyperlaneAddress &&
            _origin != treasuryMetadata.HyperlaneChain
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            _data,
            (address, address, uint256)
        );

        balances[user][token] += amount;
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
            senderEid != treasuryMetadata.LayerZeroChain ||
            sender != treasuryMetadata.LayerZeroAddress
        ) {
            revert();
        }

        (address user, address token, uint256 amount) = abi.decode(
            payload,
            (address, address, uint256)
        );

        balances[user][token] += amount;
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

    function oAppVersion()
        public
        pure
        override(OAppReceiver, OAppSender)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (0, RECEIVER_VERSION);
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Internal functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    //▰▰Balance functions▰▰
    function _updateBalance(
        address from,
        address to,
        address token,
        uint256 value
    ) internal returns (bool) {
        uint256 fromBalance = balances[from][token];
        uint256 toBalance = balances[to][token];
        if (fromBalance < value) {
            return false;
        } else {
            balances[from][token] = fromBalance - value;

            balances[to][token] = toBalance + value;

            return (toBalance + value == balances[to][token]);
        }
    }

    function _giveMateReward(
        address user,
        uint256 amount
    ) internal returns (bool) {
        uint256 mateReward = mate.reward * amount;
        uint256 userBalance = balances[user][mate.mateAddress];

        balances[user][mate.mateAddress] = userBalance + mateReward;

        return (userBalance + mateReward == balances[user][mate.mateAddress]);
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Signature functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    /**
     *  @dev using EIP-191 (https://eips.ethereum.org/EIPS/eip-191) can be used to sign and
     *       verify messages, the next functions are used to verify the messages signed
     *       by the users
     */

    /**
     *  @notice This function is used to verify the message signed for the withdrawal
     *  @param signer user who signed the message
     *  @param addressToReceive address of the receiver
     *  @param _token address of the token to withdraw
     *  @param _amount amount to withdraw
     *  @param _priorityFee priorityFee to send to the white fisher
     *  @param _nonce nonce of the transaction
     *  @param _priority_boolean if the transaction is priority or not
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForWithdrawal(
        address signer,
        address addressToReceive,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    _priority_boolean ? "920f3d76" : "52896a1f",
                    ",",
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    AdvancedStrings.addressToString(_token),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_priorityFee),
                    ",",
                    Strings.toString(_nonce),
                    ",",
                    _priority_boolean ? "true" : "false"
                ),
                signature,
                signer
            );
    }

    /**
     *  @notice This function is used to verify the message signed for the payment
     *  @param signer user who signed the message
     *  @param _receiverAddress address of the receiver
     *  @param _receiverIdentity identity of the receiver
     *
     *  @notice if the _receiverAddress is 0x0 the function will use the _receiverIdentity
     *
     *  @param _token address of the token to send
     *  @param _amount amount to send
     *  @param _priorityFee priorityFee to send to the sMate holder
     *  @param _nonce nonce of the transaction
     *  @param _priority_boolean if the transaction is priority or not
     *  @param _executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForPay(
        address signer,
        address _receiverAddress,
        string memory _receiverIdentity,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        address _executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    _priority_boolean ? "f4e1895b" : "4faa1fa2",
                    ",",
                    _receiverAddress == address(0)
                        ? _receiverIdentity
                        : AdvancedStrings.addressToString(_receiverAddress),
                    ",",
                    AdvancedStrings.addressToString(_token),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_priorityFee),
                    ",",
                    Strings.toString(_nonce),
                    ",",
                    _priority_boolean ? "true" : "false",
                    ",",
                    AdvancedStrings.addressToString(_executor)
                ),
                signature,
                signer
            );
    }

    /**
     *  @notice This function is used to verify the message signed for the dispersePay
     *  @param signer user who signed the message
     *  @param hashList hash of the list of the transactions, the hash is calculated
     *                  using sha256(abi.encode(toData))
     *  @param _token token address to send
     *  @param _amount amount to send
     *  @param _priorityFee priorityFee to send to the fisher who wants to send the message
     *  @param _nonce nonce of the transaction
     *  @param _priority_boolean if the transaction is priority or not
     *  @param _executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForDispersePay(
        address signer,
        bytes32 hashList,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        address _executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "f27f71db",
                    ",",
                    AdvancedStrings.bytes32ToString(hashList),
                    ",",
                    AdvancedStrings.addressToString(_token),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_priorityFee),
                    ",",
                    Strings.toString(_nonce),
                    ",",
                    _priority_boolean ? "true" : "false",
                    ",",
                    AdvancedStrings.addressToString(_executor)
                ),
                signature,
                signer
            );
    }

    /**
     *  @notice This function is used to verify the message signed for the fisher bridge
     *  @param signer user who signed the message
     *  @param addressToReceive address of the receiver
     *  @param _nonce nonce of the transaction
     *  @param tokenAddress address of the token to deposit
     *  @param _priorityFee priorityFee to send to the white fisher
     *  @param _amount amount to deposit
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForFisherBridge(
        address signer,
        address addressToReceive,
        uint256 _nonce,
        address tokenAddress,
        uint256 _priorityFee,
        uint256 _amount,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    Strings.toString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(tokenAddress),
                    ",",
                    Strings.toString(_priorityFee),
                    ",",
                    Strings.toString(_amount)
                ),
                signature,
                signer
            );
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Exclusive staking functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    function pointStaker(address user, bytes1 answer) public {
        if (msg.sender != sMateContractAddress) {
            revert();
        }
        stakerList[user] = answer;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    // Getter functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

    function getMateNameServiceAddress() external view returns (address) {
        return mateNameServiceAddress;
    }

    function getSMateContractAddress() external view returns (address) {
        return sMateContractAddress;
    }

    function getMaxAmountToWithdraw() external view returns (uint256) {
        return maxAmountToWithdraw.actual;
    }

    function getNextCurrentSyncNonce(
        address user
    ) external view returns (uint256) {
        return nextSyncUsedNonce[user];
    }

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return asyncUsedNonce[user][nonce];
    }

    function getNextFisherWithdrawalNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherWithdrawalNonce[user];
    }

    function getNextFisherDepositNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherDepositNonce[user];
    }

    function seeBalance(
        address user,
        address token
    ) external view returns (uint256) {
        return balances[user][token];
    }

    function isMateStaker(address user) public view returns (bool) {
        return stakerList[user] == 0x01;
    }

    function seeMateEraTokens() public view returns (uint256) {
        return mate.eraTokens;
    }

    function seeMateReward() public view returns (uint256) {
        return mate.reward;
    }

    function seeMateTotalSupply() public view returns (uint256) {
        return mate.totalSupply;
    }

    function seeIfTokenIsWhitelisted(address token) public view returns (bool) {
        return whitelistedTokens[token].isAllowed;
    }

    function getTokenUniswapPool(address token) public view returns (address) {
        return whitelistedTokens[token].uniswapPool;
    }
}
