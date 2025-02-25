// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)


/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for SMate function correct behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";

import {SMateMock} from "mock-contracts/SMateMock.sol";
import {MateNameServiceMock} from "mock-contracts/MateNameServiceMock.sol";
import {EvvmMock} from "mock-contracts/EvvmMock.sol";
import {Erc191TestBuilder} from "@RollAMate/libraries/Erc191TestBuilder.sol";
import {EstimatorMock} from "mock-contracts/EstimatorMock.sol";

contract testSMateFuzz_externalStaking is Test, Constants {
    /**
     * Naming Convention for Fuzz Test Functions
     * Basic Structure:
     * test__[typeOfTest]__[functionName]__[options]
     * General Rules:
     *  - Always start with "test__"
     *  - The name of the function to be executed must immediately follow "test__"
     *  - Options are added at the end, separated by underscores
     *
     * Example:
     * test__payNoMateStaking_sync__PF_nEX
     *
     * Example explanation:
     * Function to test: payNoMateStaking_sync
     * PF: Includes priority fee
     * nEX: Does not include executor execution
     *
     * Notes:
     * Separate different parts of the name with double underscores (__)
     *
     * Options fot this test:
     * - S: Staking
     * - uS: Unstaking
     * - SuS: Staking and Unstaking (very sus)>ඞ
     * - RSuS: Random Staking and Unstaking
     *
     * - nPF: No priority fee
     * - PF: Priority fee
     * - RPF: Random priority fee
     */

    SMateMock sMate;
    EvvmMock evvm;
    EstimatorMock estimator;

    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));

    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function setUp() public {
        sMate = new SMateMock(ADMIN.Address);

        evvm = EvvmMock(sMate.getEvvmAddress());

        estimator = EstimatorMock(sMate.getEstimatorAddress());

        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowExternalStaking();
        skip(1 days);
        sMate.confirmSetAllowExternalStaking();

        vm.stopPrank();

        executeExternalStaking(
            address(0),
            COMMON_USER_STAKER,
            true,
            true,
            0,
            1,
            0
        );

        assert(evvm.isMateStaker(COMMON_USER_STAKER.Address));
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.seeMateReward() * 2) * numberOfTx;
    }

    function giveMateToExecuteStaking(
        address userToInteract,
        uint256 sMateAmountToStake,
        uint256 priorityFee
    ) private {
        evvm._addBalance(
            userToInteract,
            MATE_TOKEN_ADDRESS,
            (sMate.priceOfSMate() * sMateAmountToStake) + priorityFee
        );
        evvm._addBalance(
            address(sMate),
            MATE_TOKEN_ADDRESS,
            evvm.seeMateReward() * (sMateAmountToStake * 1)
        );
    }

    function executeExternalStaking(
        address fisher,
        AccountData memory userToInteract,
        bool giveForSMateAndPriorityFee,
        bool isStaking,
        uint256 nonce,
        uint256 amountOfSMate,
        uint256 priorityFee_Evvm
    ) private {
        if (giveForSMateAndPriorityFee) {
            giveMateToExecuteStaking(
                userToInteract.Address,
                isStaking ? amountOfSMate : 0,
                priorityFee_Evvm
            );
        }

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userToInteract.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(sMate),
                "",
                MATE_TOKEN_ADDRESS,
                isStaking
                    ? (sMate.priceOfSMate() * amountOfSMate)
                    : priorityFee_Evvm,
                isStaking ? priorityFee_Evvm : 0,
                evvm.getNextCurrentSyncNonce(userToInteract.Address),
                false,
                address(sMate)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            userToInteract.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForExternalStaking(
                isStaking,
                amountOfSMate,
                nonce
            )
        );
        bytes memory signatureSMate = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(fisher);

        sMate.externalStaking(
            isStaking,
            userToInteract.Address,
            nonce,
            amountOfSMate,
            signatureSMate,
            priorityFee_Evvm,
            evvm.getNextCurrentSyncNonce(userToInteract.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();
    }

    struct DataExternalStakingSnPF {
        uint16 amountOfSMate;
        uint8 nonceSMate;
    }

    function test__fuzz__externalStaking__S_nPF(
        DataExternalStakingSnPF[3] memory dataUser
    ) public {
        vm.assume(dataUser[0].amountOfSMate > 0);
        vm.assume(dataUser[1].amountOfSMate > 0);
        vm.assume(dataUser[2].amountOfSMate > 0);

        console2.log("test__fuzz__externalStaking__S_nPF");
        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            dataUser[0].nonceSMate,
            dataUser[0].amountOfSMate,
            0
        );

        console2.log("user 1 staked");

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            dataUser[1].nonceSMate,
            dataUser[1].amountOfSMate,
            0
        );
        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            dataUser[2].nonceSMate,
            dataUser[2].amountOfSMate,
            0
        );

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(3)
        );

        SMateMock.HistoryMetadata[]
            memory historyUser1 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser2 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_2.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser3 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_3.Address)
            );

        historyUser1 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);
        historyUser2 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_2.Address);
        historyUser3 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_3.Address);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(historyUser1[0].timestamp, block.timestamp);
        assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser1[0].amount, dataUser[0].amountOfSMate);
        assertEq(historyUser1[0].totalStaked, dataUser[0].amountOfSMate);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));

        assertEq(historyUser2[0].timestamp, block.timestamp);
        assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser2[0].amount, dataUser[1].amountOfSMate);
        assertEq(historyUser2[0].totalStaked, dataUser[1].amountOfSMate);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));

        assertEq(historyUser3[0].timestamp, block.timestamp);
        assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser3[0].amount, dataUser[2].amountOfSMate);
        assertEq(historyUser3[0].totalStaked, dataUser[2].amountOfSMate);
    }

    struct DataExternalStakingSPF {
        uint16 amountOfSMate;
        uint8 nonceSMate;
        uint16 priorityFee;
    }

    function test__fuzz__externalStaking__S_PF(
        DataExternalStakingSPF[3] memory dataUser
    ) public {
        vm.assume(
            dataUser[0].amountOfSMate > 0 &&
                dataUser[1].amountOfSMate > 0 &&
                dataUser[2].amountOfSMate > 0 &&
                dataUser[0].priorityFee > 0 &&
                dataUser[1].priorityFee > 0 &&
                dataUser[2].priorityFee > 0
        );

        console2.log("test__fuzz__externalStaking__S_nPF");
        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            dataUser[0].nonceSMate,
            dataUser[0].amountOfSMate,
            dataUser[0].priorityFee
        );

        console2.log("user 1 staked");

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            dataUser[1].nonceSMate,
            dataUser[1].amountOfSMate,
            dataUser[1].priorityFee
        );
        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            dataUser[2].nonceSMate,
            dataUser[2].amountOfSMate,
            dataUser[2].priorityFee
        );

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(3) +
                uint256(dataUser[0].priorityFee) +
                uint256(dataUser[1].priorityFee) +
                uint256(dataUser[2].priorityFee)
        );

        SMateMock.HistoryMetadata[]
            memory historyUser1 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser2 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_2.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser3 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_3.Address)
            );

        historyUser1 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);
        historyUser2 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_2.Address);
        historyUser3 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_3.Address);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(historyUser1[0].timestamp, block.timestamp);
        assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser1[0].amount, dataUser[0].amountOfSMate);
        assertEq(historyUser1[0].totalStaked, dataUser[0].amountOfSMate);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));

        assertEq(historyUser2[0].timestamp, block.timestamp);
        assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser2[0].amount, dataUser[1].amountOfSMate);
        assertEq(historyUser2[0].totalStaked, dataUser[1].amountOfSMate);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));

        assertEq(historyUser3[0].timestamp, block.timestamp);
        assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser3[0].amount, dataUser[2].amountOfSMate);
        assertEq(historyUser3[0].totalStaked, dataUser[2].amountOfSMate);
    }

    struct DataExternalStakingUSnPF {
        uint16 amountOfSMateToStake;
        uint8 amountOfSMateToUnstake;
        uint8 nonceSMate;
    }

    function test__fuzz__externalStaking__uS_nPF(
        DataExternalStakingUSnPF[3] memory dataUser
    ) public {
        vm.assume(dataUser[0].amountOfSMateToStake > 0);
        vm.assume(dataUser[1].amountOfSMateToStake > 0);
        vm.assume(dataUser[2].amountOfSMateToStake > 0);

        vm.assume(
            dataUser[0].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );
        vm.assume(
            dataUser[1].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );
        vm.assume(
            dataUser[2].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(dataUser[0].nonceSMate),
            dataUser[0].amountOfSMateToStake,
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(dataUser[1].nonceSMate),
            dataUser[1].amountOfSMateToStake,
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(dataUser[2].nonceSMate),
            dataUser[2].amountOfSMateToStake,
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            false,
            uint256(dataUser[0].nonceSMate) + 1,
            dataUser[0].amountOfSMateToUnstake,
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            false,
            uint256(dataUser[1].nonceSMate) + 1,
            dataUser[1].amountOfSMateToUnstake,
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            false,
            uint256(dataUser[2].nonceSMate) + 1,
            dataUser[2].amountOfSMateToUnstake,
            0
        );

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(6)
        );

        SMateMock.HistoryMetadata[]
            memory historyUser1 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser2 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_2.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser3 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_3.Address)
            );

        historyUser1 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);
        historyUser2 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_2.Address);
        historyUser3 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_3.Address);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_1.Address));

        assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser1[0].amount, dataUser[0].amountOfSMateToStake);
        assertEq(historyUser1[0].totalStaked, dataUser[0].amountOfSMateToStake);

        assertEq(historyUser1[1].timestamp, block.timestamp);
        assert(historyUser1[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser1[1].amount, dataUser[0].amountOfSMateToUnstake);
        assertEq(
            historyUser1[1].totalStaked,
            dataUser[0].amountOfSMateToStake -
                dataUser[0].amountOfSMateToUnstake
        );

        assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser2[0].amount, dataUser[1].amountOfSMateToStake);
        assertEq(historyUser2[0].totalStaked, dataUser[1].amountOfSMateToStake);

        assert(historyUser2[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser2[1].amount, dataUser[1].amountOfSMateToUnstake);
        assertEq(
            historyUser2[1].totalStaked,
            dataUser[1].amountOfSMateToStake -
                dataUser[1].amountOfSMateToUnstake
        );

        assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser3[0].amount, dataUser[2].amountOfSMateToStake);
        assertEq(historyUser3[0].totalStaked, dataUser[2].amountOfSMateToStake);

        assert(historyUser3[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser3[1].amount, dataUser[2].amountOfSMateToUnstake);
        assertEq(
            historyUser3[1].totalStaked,
            dataUser[2].amountOfSMateToStake -
                dataUser[2].amountOfSMateToUnstake
        );
    }

    struct DataExternalStakingUSPF {
        uint16 amountOfSMateToStake;
        uint8 amountOfSMateToUnstake;
        uint16 nonceSMate;
        uint16 priorityFeeStake;
        uint16 priorityFeeUnstake;
    }

    function test__fuzz__externalStaking__uS_PF(
        DataExternalStakingUSPF[3] memory dataUser
    ) public {
        vm.assume(
            dataUser[0].priorityFeeStake > 0 &&
                dataUser[1].priorityFeeStake > 0 &&
                dataUser[2].priorityFeeStake > 0 &&
                dataUser[0].priorityFeeUnstake > 0 &&
                dataUser[1].priorityFeeUnstake > 0 &&
                dataUser[2].priorityFeeUnstake > 0
        );

        vm.assume(
            dataUser[0].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );
        vm.assume(
            dataUser[1].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );
        vm.assume(
            dataUser[2].amountOfSMateToStake >= uint16(type(uint8).max) + 1
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(dataUser[0].nonceSMate),
            dataUser[0].amountOfSMateToStake,
            dataUser[0].priorityFeeStake
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            false,
            uint256(dataUser[0].nonceSMate) + 1,
            dataUser[0].amountOfSMateToUnstake,
            dataUser[0].priorityFeeUnstake
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(dataUser[1].nonceSMate),
            dataUser[1].amountOfSMateToStake,
            dataUser[1].priorityFeeStake
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            false,
            uint256(dataUser[1].nonceSMate) + 1,
            dataUser[1].amountOfSMateToUnstake,
            dataUser[1].priorityFeeUnstake
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(dataUser[2].nonceSMate),
            dataUser[2].amountOfSMateToStake,
            dataUser[2].priorityFeeStake
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            false,
            uint256(dataUser[2].nonceSMate) + 1,
            dataUser[2].amountOfSMateToUnstake,
            dataUser[2].priorityFeeUnstake
        );

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(6) +
                uint256(dataUser[0].priorityFeeStake) +
                uint256(dataUser[1].priorityFeeStake) +
                uint256(dataUser[2].priorityFeeStake) +
                uint256(dataUser[0].priorityFeeUnstake) +
                uint256(dataUser[1].priorityFeeUnstake) +
                uint256(dataUser[2].priorityFeeUnstake)
        );

        SMateMock.HistoryMetadata[]
            memory historyUser1 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser2 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_2.Address)
            );

        SMateMock.HistoryMetadata[]
            memory historyUser3 = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_3.Address)
            );

        historyUser1 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);
        historyUser2 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_2.Address);
        historyUser3 = sMate.getAddressHistory(COMMON_USER_NO_STAKER_3.Address);

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(historyUser1[0].timestamp, block.timestamp);
        assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser1[0].amount, dataUser[0].amountOfSMateToStake);
        assertEq(historyUser1[0].totalStaked, dataUser[0].amountOfSMateToStake);

        assertEq(historyUser1[1].timestamp, block.timestamp);
        assert(historyUser1[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser1[1].amount, dataUser[0].amountOfSMateToUnstake);
        assertEq(
            historyUser1[1].totalStaked,
            dataUser[0].amountOfSMateToStake -
                dataUser[0].amountOfSMateToUnstake
        );

        assertEq(historyUser2[0].timestamp, block.timestamp);
        assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser2[0].amount, dataUser[1].amountOfSMateToStake);
        assertEq(historyUser2[0].totalStaked, dataUser[1].amountOfSMateToStake);

        assertEq(historyUser2[1].timestamp, block.timestamp);
        assert(historyUser2[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser2[1].amount, dataUser[1].amountOfSMateToUnstake);
        assertEq(
            historyUser2[1].totalStaked,
            dataUser[1].amountOfSMateToStake -
                dataUser[1].amountOfSMateToUnstake
        );

        assertEq(historyUser3[0].timestamp, block.timestamp);
        assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(historyUser3[0].amount, dataUser[2].amountOfSMateToStake);
        assertEq(historyUser3[0].totalStaked, dataUser[2].amountOfSMateToStake);

        assertEq(historyUser3[1].timestamp, block.timestamp);
        assert(historyUser3[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(historyUser3[1].amount, dataUser[2].amountOfSMateToUnstake);
        assertEq(
            historyUser3[1].totalStaked,
            dataUser[2].amountOfSMateToStake -
                dataUser[2].amountOfSMateToUnstake
        );
    }

    struct DataExternalStakingSuSnPF {
        bool[3] isStaking;
        uint8[3] amountOfSMate;
    }

    function test__fuzz__externalStaking__SuS_nPF(
        uint8 amountTotalOfTx,
        uint16[3] memory nonceSMate,
        uint16[3] memory initTxAmount,
        DataExternalStakingSuSnPF[256] memory dataUser
    ) public {
        vm.assume(initTxAmount[0] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[1] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[2] >= uint16(type(uint8).max) + 1);
        vm.assume(nonceSMate[0] > 0);
        vm.assume(nonceSMate[1] > 0);
        vm.assume(nonceSMate[2] > 0);

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(nonceSMate[0]) - 1,
            initTxAmount[0],
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(nonceSMate[1]) - 1,
            initTxAmount[1],
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(nonceSMate[2]) - 1,
            initTxAmount[2],
            0
        );

        uint16 txExecuted = 0;

        uint32[3] memory totalAmount = [
            uint32(initTxAmount[0]),
            uint32(initTxAmount[1]),
            uint32(initTxAmount[2])
        ];

        for (uint8 i = 0; i < amountTotalOfTx; i++) {
            if (dataUser[i].isStaking[0]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    true,
                    true,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    0
                );
                txExecuted++;

                totalAmount[0] += dataUser[i].amountOfSMate[0];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[0]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_1,
                        false,
                        false,
                        uint256(nonceSMate[0]) + uint256(i),
                        dataUser[i].amountOfSMate[0],
                        0
                    );
                    txExecuted++;

                    totalAmount[0] -= dataUser[i].amountOfSMate[0];

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[0]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[0]
                    );
                }
            }

            if (dataUser[i].isStaking[1]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    true,
                    true,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    0
                );
                txExecuted++;

                totalAmount[1] += dataUser[i].amountOfSMate[1];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );

                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );

                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[1]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_2,
                        false,
                        false,
                        uint256(nonceSMate[1]) + uint256(i),
                        dataUser[i].amountOfSMate[1],
                        0
                    );
                    txExecuted++;

                    totalAmount[1] -= dataUser[i].amountOfSMate[1];

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[1]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[1]
                    );
                }
            }

            if (dataUser[i].isStaking[2]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    true,
                    true,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    0
                );
                txExecuted++;

                totalAmount[2] += dataUser[i].amountOfSMate[2];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[2]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_3,
                        false,
                        false,
                        uint256(nonceSMate[2]) + uint256(i),
                        dataUser[i].amountOfSMate[2],
                        0
                    );
                    txExecuted++;

                    totalAmount[2] -= dataUser[i].amountOfSMate[2];

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[2]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[2]
                    );
                }
            }
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(txExecuted + 3)
        );
    }

    struct DataExternalStakingSuSPF {
        bool[3] isStaking;
        uint8[3] amountOfSMate;
        uint16[3] priorityFee;
    }

    function test__fuzz__externalStaking__SuS_PF(
        uint8 amountTotalOfTx,
        uint16[3] memory nonceSMate,
        uint16[3] memory initTxAmount,
        uint16[3] memory initPriorityFee,
        DataExternalStakingSuSPF[256] memory dataUser
    ) public {
        vm.assume(initTxAmount[0] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[1] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[2] >= uint16(type(uint8).max) + 1);
        vm.assume(nonceSMate[0] > 0);
        vm.assume(nonceSMate[1] > 0);
        vm.assume(nonceSMate[2] > 0);

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(nonceSMate[0]) - 1,
            initTxAmount[0],
            initPriorityFee[0]
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(nonceSMate[1]) - 1,
            initTxAmount[1],
            initPriorityFee[1]
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(nonceSMate[2]) - 1,
            initTxAmount[2],
            initPriorityFee[2]
        );

        uint16 txExecuted = 0;

        uint32[3] memory totalAmount = [
            uint32(initTxAmount[0]),
            uint32(initTxAmount[1]),
            uint32(initTxAmount[2])
        ];

        uint256 totalPriorityFee = uint256(initPriorityFee[0]) +
            uint256(initPriorityFee[1]) +
            uint256(initPriorityFee[2]);

        for (uint8 i = 0; i < amountTotalOfTx; i++) {
            if (dataUser[i].isStaking[0]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    true,
                    true,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    dataUser[i].priorityFee[0]
                );
                txExecuted++;

                totalAmount[0] += dataUser[i].amountOfSMate[0];

                totalPriorityFee += uint256(dataUser[i].priorityFee[0]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[0]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_1,
                        true,
                        false,
                        uint256(nonceSMate[0]) + uint256(i),
                        dataUser[i].amountOfSMate[0],
                        dataUser[i].priorityFee[0]
                    );
                    txExecuted++;

                    totalAmount[0] -= dataUser[i].amountOfSMate[0];

                    totalPriorityFee += uint256(dataUser[i].priorityFee[0]);

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[0]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[0]
                    );
                }
            }

            if (dataUser[i].isStaking[1]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    true,
                    true,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    dataUser[i].priorityFee[1]
                );
                txExecuted++;

                totalAmount[1] += dataUser[i].amountOfSMate[1];

                totalPriorityFee += uint256(dataUser[i].priorityFee[1]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );

                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );

                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[1]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_2,
                        true,
                        false,
                        uint256(nonceSMate[1]) + uint256(i),
                        dataUser[i].amountOfSMate[1],
                        dataUser[i].priorityFee[1]
                    );
                    txExecuted++;

                    totalAmount[1] -= dataUser[i].amountOfSMate[1];

                    totalPriorityFee += uint256(dataUser[i].priorityFee[1]);

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[1]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[1]
                    );
                }
            }

            if (dataUser[i].isStaking[2]) {
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    true,
                    true,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    dataUser[i].priorityFee[2]
                );
                txExecuted++;

                totalAmount[2] += dataUser[i].amountOfSMate[2];

                totalPriorityFee += uint256(dataUser[i].priorityFee[2]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[2]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address)
                ) {
                    executeExternalStaking(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_3,
                        true,
                        false,
                        uint256(nonceSMate[2]) + uint256(i),
                        dataUser[i].amountOfSMate[2],
                        dataUser[i].priorityFee[2]
                    );
                    txExecuted++;

                    totalAmount[2] -= dataUser[i].amountOfSMate[2];

                    totalPriorityFee += uint256(dataUser[i].priorityFee[2]);

                    assert(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .transactionType == WITHDRAW_IDENTIFIER
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .amount,
                        dataUser[i].amountOfSMate[2]
                    );
                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .totalStaked,
                        totalAmount[2]
                    );
                }
            }
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(txExecuted + 3) + totalPriorityFee
        );
    }

    struct DataExternalStakingRSuSnPF {
        bool[3] isStaking;
        uint16[3] amountOfSMate;
        uint32[3] timeToSkip;
    }

    function test__fuzz__externalStaking__RSuS_nPF(
        uint8 amountTotalOfTx,
        uint16[3] memory nonceSMate,
        uint16[3] memory initTxAmount,
        DataExternalStakingRSuSnPF[256] memory dataUser
    ) public {
        vm.assume(initTxAmount[0] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[1] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[2] >= uint16(type(uint8).max) + 1);
        vm.assume(nonceSMate[0] > 0);
        vm.assume(nonceSMate[1] > 0);
        vm.assume(nonceSMate[2] > 0);

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(nonceSMate[0]) - 1,
            initTxAmount[0],
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(nonceSMate[1]) - 1,
            initTxAmount[1],
            0
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(nonceSMate[2]) - 1,
            initTxAmount[2],
            0
        );

        uint32 txExecuted = 3;

        uint256[3] memory totalAmount = [
            uint256(initTxAmount[0]),
            uint256(initTxAmount[1]),
            uint256(initTxAmount[2])
        ];

        for (uint8 i = 0; i < amountTotalOfTx; i++) {
            if (dataUser[i].isStaking[0]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[0]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    true,
                    true,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    0
                );
                txExecuted++;

                totalAmount[0] += uint256(dataUser[i].amountOfSMate[0]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[0]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[0]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );

                    dataUser[i].amountOfSMate[0] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    false,
                    false,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    0
                );
                txExecuted++;

                totalAmount[0] -= uint256(dataUser[i].amountOfSMate[0]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            }

            if (dataUser[i].isStaking[1]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_2.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[1]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    true,
                    true,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    0
                );
                txExecuted++;

                totalAmount[1] += uint256(dataUser[i].amountOfSMate[1]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[1]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[1]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );

                    dataUser[i].amountOfSMate[1] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    false,
                    false,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    0
                );
                txExecuted++;

                totalAmount[1] -= uint256(dataUser[i].amountOfSMate[1]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            }

            if (dataUser[i].isStaking[2]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_3.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[2]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    true,
                    true,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    0
                );
                txExecuted++;

                totalAmount[2] += dataUser[i].amountOfSMate[2];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[2]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[2]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );

                    dataUser[i].amountOfSMate[2] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    false,
                    false,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    0
                );
                txExecuted++;

                totalAmount[2] -= dataUser[i].amountOfSMate[2];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            }
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(txExecuted)
        );
    }

    ////////////////////////////////////////////////////
    struct DataExternalStakingRSuSPF {
        bool[3] isStaking;
        uint16[3] amountOfSMate;
        uint16[3] priorityFee;
        uint32[3] timeToSkip;
    }

    function test__fuzz__externalStaking__RSuS_PF(
        uint8 amountTotalOfTx,
        uint16[3] memory nonceSMate,
        uint16[3] memory initPriorityFee,
        uint16[3] memory initTxAmount,
        DataExternalStakingRSuSPF[256] memory dataUser
    ) public {
        vm.assume(initTxAmount[0] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[1] >= uint16(type(uint8).max) + 1);
        vm.assume(initTxAmount[2] >= uint16(type(uint8).max) + 1);
        vm.assume(nonceSMate[0] > 0);
        vm.assume(nonceSMate[1] > 0);
        vm.assume(nonceSMate[2] > 0);

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            true,
            uint256(nonceSMate[0]) - 1,
            initTxAmount[0],
            initPriorityFee[0]
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            true,
            uint256(nonceSMate[1]) - 1,
            initTxAmount[1],
            initPriorityFee[1]
        );

        executeExternalStaking(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            true,
            uint256(nonceSMate[2]) - 1,
            initTxAmount[2],
            initPriorityFee[2]
        );

        uint32 txExecuted = 3;

        uint256 totalPriorityFeeReceived = uint256(initPriorityFee[0]) +
            uint256(initPriorityFee[1]) +
            uint256(initPriorityFee[2]);

        uint256[3] memory totalAmount = [
            uint256(initTxAmount[0]),
            uint256(initTxAmount[1]),
            uint256(initTxAmount[2])
        ];

        for (uint8 i = 0; i < amountTotalOfTx; i++) {
            if (dataUser[i].isStaking[0]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[0]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    true,
                    true,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    dataUser[i].priorityFee[0]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[0]);
                totalAmount[0] += uint256(dataUser[i].amountOfSMate[0]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[0]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[0]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );

                    dataUser[i].amountOfSMate[0] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_1,
                    true,
                    false,
                    uint256(nonceSMate[0]) + uint256(i),
                    dataUser[i].amountOfSMate[0],
                    dataUser[i].priorityFee[0]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[0]);
                totalAmount[0] -= uint256(dataUser[i].amountOfSMate[0]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[0]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_1.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_1.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[0]
                );
            }

            if (dataUser[i].isStaking[1]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_2.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[1]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    true,
                    true,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    dataUser[i].priorityFee[1]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[1]);
                totalAmount[1] += uint256(dataUser[i].amountOfSMate[1]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[1]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[1]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );

                    dataUser[i].amountOfSMate[1] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_2.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_2,
                    true,
                    false,
                    uint256(nonceSMate[1]) + uint256(i),
                    dataUser[i].amountOfSMate[1],
                    dataUser[i].priorityFee[1]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[1]);
                totalAmount[1] -= uint256(dataUser[i].amountOfSMate[1]);

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[1]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_2.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_2.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[1]
                );
            }

            if (dataUser[i].isStaking[2]) {
                if (
                    sMate.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_3.Address
                    ) != 0
                ) {
                    skip(dataUser[i].timeToSkip[2]);
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    true,
                    true,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    dataUser[i].priorityFee[2]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[2]);
                totalAmount[2] += dataUser[i].amountOfSMate[2];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            } else {
                if (
                    uint256(dataUser[i].amountOfSMate[2]) <
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address)
                ) {
                    skip(uint256(dataUser[i].timeToSkip[2]));
                } else {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );

                    dataUser[i].amountOfSMate[2] = uint16(
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_3.Address
                        )
                    );
                }
                executeExternalStaking(
                    COMMON_USER_STAKER.Address,
                    COMMON_USER_NO_STAKER_3,
                    true,
                    false,
                    uint256(nonceSMate[2]) + uint256(i),
                    dataUser[i].amountOfSMate[2],
                    dataUser[i].priorityFee[2]
                );
                txExecuted++;
                totalPriorityFeeReceived += uint256(dataUser[i].priorityFee[2]);
                totalAmount[2] -= dataUser[i].amountOfSMate[2];

                assert(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .amount,
                    dataUser[i].amountOfSMate[2]
                );
                assertEq(
                    sMate
                        .getAddressHistoryByIndex(
                            COMMON_USER_NO_STAKER_3.Address,
                            sMate.getSizeOfAddressHistory(
                                COMMON_USER_NO_STAKER_3.Address
                            ) - 1
                        )
                        .totalStaked,
                    totalAmount[2]
                );
            }
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(txExecuted) + totalPriorityFeeReceived
        );
    }
}
