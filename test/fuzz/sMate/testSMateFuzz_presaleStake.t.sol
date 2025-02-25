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

contract testSMateFuzz_presaleStake is Test, Constants {
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
        sMate.prepareSetAllowInternalStaking();
        skip(1 days);
        sMate.confirmSetAllowInternalStaking();

        sMate.addPresaleStaker(COMMON_USER_STAKER.Address);
        sMate.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        sMate.addPresaleStaker(COMMON_USER_NO_STAKER_2.Address);
        sMate.addPresaleStaker(COMMON_USER_NO_STAKER_3.Address);

        vm.stopPrank();

        executePresaleStake(address(0), COMMON_USER_STAKER, true, 0, 1, true);
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

    function executePresaleStake(
        address fisher,
        AccountData memory userToInteract,
        bool isStaking,
        uint256 priorityFee,
        uint256 nonceSMate,
        bool giveForSMateAndPriorityFee
    ) private {
        if (giveForSMateAndPriorityFee) {
            giveMateToExecuteStaking(
                userToInteract.Address,
                isStaking ? 1 : 0,
                priorityFee
            );
        }

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userToInteract.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(sMate),
                "",
                MATE_TOKEN_ADDRESS,
                isStaking ? sMate.priceOfSMate() : priorityFee,
                isStaking ? priorityFee : 0,
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
            Erc191TestBuilder.buildMessageSignedForPresaleStake(
                isStaking,
                1,
                nonceSMate
            )
        );
        bytes memory signatureSMate = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(fisher);

        sMate.presaleStake(
            isStaking,
            userToInteract.Address,
            nonceSMate,
            signatureSMate,
            priorityFee,
            evvm.getNextCurrentSyncNonce(userToInteract.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function test__fuzz__presaleStake__S_nPF(
        bool[3] memory isStakingTwo,
        uint8[3] memory nonceSMate
    ) public {
        if (isStakingTwo[0]) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                0,
                uint256(nonceSMate[0]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                0,
                uint256(nonceSMate[0]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                0,
                uint256(nonceSMate[0]),
                true
            );
        }

        if (isStakingTwo[1]) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                0,
                uint256(nonceSMate[1]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                0,
                uint256(nonceSMate[1]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                0,
                uint256(nonceSMate[1]),
                true
            );
        }

        if (isStakingTwo[2]) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                0,
                uint256(nonceSMate[2]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                0,
                uint256(nonceSMate[2]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                0,
                nonceSMate[2],
                true
            );
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(
                ((isStakingTwo[0] ? 2 : 1) +
                    (isStakingTwo[1] ? 2 : 1) +
                    (isStakingTwo[2] ? 2 : 1))
            )
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
        if (isStakingTwo[0]) {
            assertEq(historyUser1[0].timestamp, block.timestamp);
            assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[0].amount, 1);
            assertEq(historyUser1[0].totalStaked, 1);

            assertEq(historyUser1[1].timestamp, block.timestamp);
            assert(historyUser1[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[1].amount, 1);
            assertEq(historyUser1[1].totalStaked, 2);
        } else {
            assertEq(historyUser1[0].timestamp, block.timestamp);
            assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[0].amount, 1);
            assertEq(historyUser1[0].totalStaked, 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));
        if (isStakingTwo[1]) {
            assertEq(historyUser2[0].timestamp, block.timestamp);
            assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[0].amount, 1);
            assertEq(historyUser2[0].totalStaked, 1);

            assertEq(historyUser2[1].timestamp, block.timestamp);
            assert(historyUser2[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[1].amount, 1);
            assertEq(historyUser2[1].totalStaked, 2);
        } else {
            assertEq(historyUser2[0].timestamp, block.timestamp);
            assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[0].amount, 1);
            assertEq(historyUser2[0].totalStaked, 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));
        if (isStakingTwo[2]) {
            assertEq(historyUser3[0].timestamp, block.timestamp);
            assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[0].amount, 1);
            assertEq(historyUser3[0].totalStaked, 1);

            assertEq(historyUser3[1].timestamp, block.timestamp);
            assert(historyUser3[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[1].amount, 1);
            assertEq(historyUser3[1].totalStaked, 2);
        } else {
            assertEq(historyUser3[0].timestamp, block.timestamp);
            assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[0].amount, 1);
            assertEq(historyUser3[0].totalStaked, 1);
        }
    }

    struct TxDataPresaleStakeSPF {
        bool executeTwoTx;
        uint16 priorityFee1;
        uint16 priorityFee2;
    }

    function test__fuzz__presaleStake__S_PF(
        TxDataPresaleStakeSPF[3] memory txData,
        uint8[3] memory nonceSMate
    ) public {
        if (txData[0].executeTwoTx) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                txData[0].priorityFee1,
                uint256(nonceSMate[0]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                txData[0].priorityFee2,
                uint256(nonceSMate[0]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                true,
                txData[0].priorityFee1,
                uint256(nonceSMate[0]),
                true
            );
        }

        if (txData[1].executeTwoTx) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                txData[1].priorityFee1,
                uint256(nonceSMate[1]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                txData[1].priorityFee2,
                uint256(nonceSMate[1]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                true,
                txData[1].priorityFee1,
                uint256(nonceSMate[1]),
                true
            );
        }

        if (txData[2].executeTwoTx) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                txData[2].priorityFee1,
                uint256(nonceSMate[2]),
                true
            );

            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                txData[2].priorityFee2,
                uint256(nonceSMate[2]) + 1,
                true
            );
        } else {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                true,
                txData[2].priorityFee1,
                uint256(nonceSMate[2]),
                true
            );
        }

        uint256 totalReward = 0;

        console2.log(
            "Reward per execution: %d",
            calculateRewardPerExecution(2)
        );

        for (uint8 i = 0; i < 3; i++) {
            totalReward +=
                calculateRewardPerExecution(txData[i].executeTwoTx ? 2 : 1) +
                (
                    txData[i].executeTwoTx
                        ? (uint256(txData[i].priorityFee1) +
                            uint256(txData[i].priorityFee2))
                        : uint256(txData[i].priorityFee1)
                );
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            totalReward
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
        if (txData[0].executeTwoTx) {
            assertEq(historyUser1[0].timestamp, block.timestamp);
            assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[0].amount, 1);
            assertEq(historyUser1[0].totalStaked, 1);

            assertEq(historyUser1[1].timestamp, block.timestamp);
            assert(historyUser1[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[1].amount, 1);
            assertEq(historyUser1[1].totalStaked, 2);
        } else {
            assertEq(historyUser1[0].timestamp, block.timestamp);
            assert(historyUser1[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser1[0].amount, 1);
            assertEq(historyUser1[0].totalStaked, 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));
        if (txData[1].executeTwoTx) {
            assertEq(historyUser2[0].timestamp, block.timestamp);
            assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[0].amount, 1);
            assertEq(historyUser2[0].totalStaked, 1);

            assertEq(historyUser2[1].timestamp, block.timestamp);
            assert(historyUser2[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[1].amount, 1);
            assertEq(historyUser2[1].totalStaked, 2);
        } else {
            assertEq(historyUser2[0].timestamp, block.timestamp);
            assert(historyUser2[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser2[0].amount, 1);
            assertEq(historyUser2[0].totalStaked, 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));
        if (txData[2].executeTwoTx) {
            assertEq(historyUser3[0].timestamp, block.timestamp);
            assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[0].amount, 1);
            assertEq(historyUser3[0].totalStaked, 1);

            assertEq(historyUser3[1].timestamp, block.timestamp);
            assert(historyUser3[1].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[1].amount, 1);
            assertEq(historyUser3[1].totalStaked, 2);
        } else {
            assertEq(historyUser3[0].timestamp, block.timestamp);
            assert(historyUser3[0].transactionType == DEPOSIT_IDENTIFIER);
            assertEq(historyUser3[0].amount, 1);
            assertEq(historyUser3[0].totalStaked, 1);
        }
    }

    function test__fuzz__presaleStake__uS_PF(
        uint32[3] memory priorityFee,
        uint8[3] memory nonceSMate
    ) public {
        for (uint8 i = 0; i < 3; i++) {
            console2.log("i:", i);
            console2.log("priorityFee:", i == 2 ? priorityFee[0] : 0);
            console2.log("is", i != 2 ? "stake" : "unstake");
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_1,
                i != 2,
                i == 2 ? priorityFee[0] : 0,
                uint256(nonceSMate[0]) + i,
                true
            );
        }

        for (uint8 i = 0; i < 3; i++) {
            console2.log("i:", i);
            console2.log("priorityFee:", i == 2 ? priorityFee[1] : 0);
            console2.log("is", i != 2 ? "stake" : "unstake");
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_2,
                i != 2,
                i == 2 ? priorityFee[1] : 0,
                uint256(nonceSMate[1]) + i,
                true
            );
        }

        for (uint8 i = 0; i < 3; i++) {
            executePresaleStake(
                COMMON_USER_STAKER.Address,
                COMMON_USER_NO_STAKER_3,
                i != 2,
                i == 2 ? priorityFee[2] : 0,
                uint256(nonceSMate[2]) + i,
                true
            );
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(9) +
                (uint256(priorityFee[0]) +
                    uint256(priorityFee[1]) +
                    uint256(priorityFee[2]))
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

        for (uint8 i = 0; i < 3; i++) {
            assertEq(historyUser1[i].timestamp, block.timestamp);
            assert(
                historyUser1[i].transactionType ==
                    (i == 2 ? WITHDRAW_IDENTIFIER : DEPOSIT_IDENTIFIER)
            );
            assertEq(historyUser1[i].amount, 1);
            assertEq(historyUser1[i].totalStaked, i == 2 ? 1 : i + 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));

        for (uint8 i = 0; i < 3; i++) {
            assertEq(historyUser2[i].timestamp, block.timestamp);
            assert(
                historyUser2[i].transactionType ==
                    (i == 2 ? WITHDRAW_IDENTIFIER : DEPOSIT_IDENTIFIER)
            );
            assertEq(historyUser2[i].amount, 1);
            assertEq(historyUser2[i].totalStaked, i == 2 ? 1 : i + 1);
        }

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));

        for (uint8 i = 0; i < 3; i++) {
            assertEq(historyUser3[i].timestamp, block.timestamp);
            assert(
                historyUser3[i].transactionType ==
                    (i == 2 ? WITHDRAW_IDENTIFIER : DEPOSIT_IDENTIFIER)
            );
            assertEq(historyUser3[i].amount, 1);
            assertEq(historyUser3[i].totalStaked, i == 2 ? 1 : i + 1);
        }
    }

    struct TxDataPresaleStakeRSuSRPF {
        bool isStaking;
        bool givesPriorityFee;
        uint16 priorityFee;
        uint8 timeToSkip;
    }

    function test__fuzz__presaleStake__RSuS_RPF(
        TxDataPresaleStakeRSuSRPF[260] memory user1Txs,
        TxDataPresaleStakeRSuSRPF[260] memory user2Txs,
        TxDataPresaleStakeRSuSRPF[260] memory user3Txs,
        uint8[3] memory nonceSMate,
        uint8 totalAmountTx
    ) external {
        vm.assume(totalAmountTx > 1);

        executePresaleStake(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_1,
            true,
            user1Txs[0].givesPriorityFee ? user1Txs[0].priorityFee : 0,
            uint256(nonceSMate[0]),
            true
        );

        executePresaleStake(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_2,
            true,
            user2Txs[0].givesPriorityFee ? user2Txs[0].priorityFee : 0,
            uint256(nonceSMate[1]),
            true
        );

        executePresaleStake(
            COMMON_USER_STAKER.Address,
            COMMON_USER_NO_STAKER_3,
            true,
            user3Txs[0].givesPriorityFee ? user3Txs[0].priorityFee : 0,
            uint256(nonceSMate[2]),
            true
        );

        uint256 totalPriorityFee = uint256(
            user1Txs[0].givesPriorityFee ? user1Txs[0].priorityFee : 0
        ) +
            uint256(
                user2Txs[0].givesPriorityFee ? user2Txs[0].priorityFee : 0
            ) +
            uint256(user3Txs[0].givesPriorityFee ? user3Txs[0].priorityFee : 0);

        uint256 amountTxSuccess = 3;

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(amountTxSuccess) + totalPriorityFee
        );

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_1.Address));

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
            1
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
            1
        );

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_2.Address));

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
            1
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
            1
        );

        assert(evvm.isMateStaker(COMMON_USER_NO_STAKER_3.Address));

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
            1
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
            1
        );

        uint8[3] memory stakeAmount = [1, 1, 1];

        for (uint256 i = 0; i < totalAmountTx - 1; i++) {
            if (user1Txs[i + 1].isStaking) {
                //el maximo es 2
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address) <
                    2
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_1.Address
                        ) == 0
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockStakingTime(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                        );
                    } else {
                        skip(uint256(user1Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_1,
                        true,
                        user1Txs[i + 1].givesPriorityFee
                            ? user1Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[0]) + i + 1,
                        true
                    );
                    amountTxSuccess++;

                    totalPriorityFee += user1Txs[i + 1].givesPriorityFee
                        ? uint256(user1Txs[i + 1].priorityFee)
                        : 0;

                    stakeAmount[0]++;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .transactionType,
                        DEPOSIT_IDENTIFIER
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
                        1
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
                        stakeAmount[0]
                    );
                }
            } else {
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address) >
                    0
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_1.Address
                        ) == 1
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockFullUnstakingTime(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                        );
                    } else {
                        skip(uint256(user1Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_1,
                        false,
                        user1Txs[i + 1].givesPriorityFee
                            ? user1Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[0]) + i + 1,
                        true
                    );
                    amountTxSuccess++;
                    totalPriorityFee += user1Txs[i + 1].givesPriorityFee
                        ? uint256(user1Txs[i + 1].priorityFee)
                        : 0;
                    stakeAmount[0]--;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_1.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) - 1
                            )
                            .transactionType,
                        WITHDRAW_IDENTIFIER
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
                        1
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
                        stakeAmount[0]
                    );
                }
            }

            if (user2Txs[i + 1].isStaking) {
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address) <
                    2
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_2.Address
                        ) == 0
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockStakingTime(
                                COMMON_USER_NO_STAKER_2.Address
                            )
                        );
                    } else {
                        skip(uint256(user2Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_2,
                        true,
                        user2Txs[i + 1].givesPriorityFee
                            ? user2Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[1]) + i + 1,
                        true
                    );
                    amountTxSuccess++;
                    totalPriorityFee += user2Txs[i + 1].givesPriorityFee
                        ? uint256(user2Txs[i + 1].priorityFee)
                        : 0;
                    stakeAmount[1]++;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .transactionType,
                        DEPOSIT_IDENTIFIER
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
                        1
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
                        stakeAmount[1]
                    );
                }
            } else {
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_2.Address) >
                    0
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_2.Address
                        ) == 1
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockFullUnstakingTime(
                                COMMON_USER_NO_STAKER_2.Address
                            )
                        );
                    } else {
                        skip(uint256(user2Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_2,
                        false,
                        user2Txs[i + 1].givesPriorityFee
                            ? user2Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[1]) + i + 1,
                        true
                    );
                    amountTxSuccess++;
                    totalPriorityFee += user2Txs[i + 1].givesPriorityFee
                        ? uint256(user2Txs[i + 1].priorityFee)
                        : 0;
                    stakeAmount[1]--;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_2.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_2.Address
                                ) - 1
                            )
                            .transactionType,
                        WITHDRAW_IDENTIFIER
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
                        1
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
                        stakeAmount[1]
                    );
                }
            }

            if (user3Txs[i + 1].isStaking) {
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address) <
                    2
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_3.Address
                        ) == 0
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockStakingTime(
                                COMMON_USER_NO_STAKER_3.Address
                            )
                        );
                    } else {
                        skip(uint256(user3Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_3,
                        true,
                        user3Txs[i + 1].givesPriorityFee
                            ? user3Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[2]) + i + 1,
                        true
                    );
                    amountTxSuccess++;
                    totalPriorityFee += user3Txs[i + 1].givesPriorityFee
                        ? uint256(user3Txs[i + 1].priorityFee)
                        : 0;
                    stakeAmount[2]++;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .transactionType,
                        DEPOSIT_IDENTIFIER
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
                        1
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
                        stakeAmount[2]
                    );
                }
            } else {
                if (
                    sMate.getUserAmountStaked(COMMON_USER_NO_STAKER_3.Address) >
                    0
                ) {
                    if (
                        sMate.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_3.Address
                        ) == 1
                    ) {
                        vm.warp(
                            sMate.getTimeToUserUnlockFullUnstakingTime(
                                COMMON_USER_NO_STAKER_3.Address
                            )
                        );
                    } else {
                        skip(uint256(user3Txs[i + 1].timeToSkip));
                    }

                    executePresaleStake(
                        COMMON_USER_STAKER.Address,
                        COMMON_USER_NO_STAKER_3,
                        false,
                        user3Txs[i + 1].givesPriorityFee
                            ? user3Txs[i + 1].priorityFee
                            : 0,
                        uint256(nonceSMate[2]) + i + 1,
                        true
                    );
                    amountTxSuccess++;
                    totalPriorityFee += user3Txs[i + 1].givesPriorityFee
                        ? uint256(user3Txs[i + 1].priorityFee)
                        : 0;
                    stakeAmount[2]--;

                    assertEq(
                        sMate
                            .getAddressHistoryByIndex(
                                COMMON_USER_NO_STAKER_3.Address,
                                sMate.getSizeOfAddressHistory(
                                    COMMON_USER_NO_STAKER_3.Address
                                ) - 1
                            )
                            .transactionType,
                        WITHDRAW_IDENTIFIER
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
                        1
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
                        stakeAmount[2]
                    );
                }
            }
        }

        assertEq(
            evvm.seeBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(amountTxSuccess) + totalPriorityFee
        );
    }
}
