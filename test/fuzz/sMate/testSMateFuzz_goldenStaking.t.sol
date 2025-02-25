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

contract testSMateFuzz_goldenStaking is Test, Constants {
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
     * - FuS: Full Unstaking
     * - RE: Re-staking (staking after full unstaking)
     * - SuS: Staking and Unstaking (very sus)>ඞ
     * - RSuS: Random Staking and Unstaking
     */

    SMateMock sMate;
    EvvmMock evvm;
    EstimatorMock estimator;

    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));

    modifier allowExternalStaking() {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowExternalStaking();
        vm.warp(block.timestamp + 1 days);
        sMate.confirmSetAllowExternalStaking();
        vm.stopPrank();
        _;
    }

    modifier allowInternalStaking() {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowInternalStaking();
        vm.warp(block.timestamp + 1 days);
        sMate.confirmSetAllowInternalStaking();
        vm.stopPrank();
        _;
    }

    modifier setPresaleStake(address userToBeAdded) {
        vm.startPrank(ADMIN.Address);
        sMate.addPresaleStaker(userToBeAdded);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        sMate = new SMateMock(ADMIN.Address);

        evvm = EvvmMock(sMate.getEvvmAddress());

        estimator = EstimatorMock(sMate.getEstimatorAddress());
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

    /**
     * @notice Function to execute the golden staking
     * @param isStaking: boolean to know if the user is staking or unstaking
     * @param sMateAmount: amount of sMate to stake or unstake
     * @param giveMATE: boolean to know if the user will receive MATE to execute the staking
     */
    function executeGoldenStaking(
        bool isStaking,
        uint256 sMateAmount,
        bool giveMATE
    ) private {
        if (giveMATE) {
            giveMateToExecuteStaking(GOLDEN_STAKER.Address, sMateAmount, 0);
        }

        if (isStaking) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                GOLDEN_STAKER.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(sMate),
                    "",
                    MATE_TOKEN_ADDRESS,
                    sMate.priceOfSMate() * sMateAmount,
                    0,
                    evvm.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
                    false,
                    address(sMate)
                )
            );
            bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
                v,
                r,
                s
            );

            vm.startPrank(GOLDEN_STAKER.Address);

            sMate.goldenStaking(true, sMateAmount, signatureEVVM);

            vm.stopPrank();
        } else {
            vm.startPrank(GOLDEN_STAKER.Address);

            sMate.goldenStaking(false, sMateAmount, "");

            vm.stopPrank();
        }
    }

    function test__fuzz__goldenStaking_S(uint256 sMateAmountToStake) external {
        sMateAmountToStake = bound(sMateAmountToStake, 1, 100);
        giveMateToExecuteStaking(GOLDEN_STAKER.Address, sMateAmountToStake, 0);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            GOLDEN_STAKER.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(sMate),
                "",
                MATE_TOKEN_ADDRESS,
                sMate.priceOfSMate() * sMateAmountToStake,
                0,
                evvm.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
                false,
                address(sMate)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        sMate.goldenStaking(true, sMateAmountToStake, signatureEVVM);

        vm.stopPrank();

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(1)
        );

        assert(evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, sMateAmountToStake);
        assertEq(history[0].totalStaked, sMateAmountToStake);
    }

    function test__fuzz__goldenStaking_uS(
        uint256 sMateAmountToStake,
        uint256 sMateAmountToUnstake,
        uint8 salt
    ) external {
        sMateAmountToStake = bound(sMateAmountToStake, 3, 1000);

        sMateAmountToUnstake = bound(
            sMateAmountToUnstake,
            1,
            sMateAmountToStake - 1
        );

        executeGoldenStaking(true, sMateAmountToStake, true);

        console.log("Salt: ", salt);

        skip(uint256(salt));

        executeGoldenStaking(false, sMateAmountToUnstake, false);

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(2) +
                (sMate.priceOfSMate() * sMateAmountToUnstake)
        );

        assert(evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        assertEq(history[0].timestamp, block.timestamp - salt);
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, sMateAmountToStake);
        assertEq(history[0].totalStaked, sMateAmountToStake);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(history[1].amount, sMateAmountToUnstake);
        assertEq(
            history[1].totalStaked,
            sMateAmountToStake - sMateAmountToUnstake
        );
    }

    function test__fuzz__goldenStaking_FuS(uint256 sMateAmount) external {
        sMateAmount = bound(sMateAmount, 1, 1000);

        executeGoldenStaking(true, sMateAmount, true);

        vm.warp(
            sMate.getTimeToUserUnlockFullUnstakingTime(GOLDEN_STAKER.Address)
        );

        executeGoldenStaking(false, sMateAmount, false);

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(2) +
                (sMate.priceOfSMate() * sMateAmount)
        );

        assert(!evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        console2.log("verify history");
        assertEq(history[0].timestamp, 1);
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, sMateAmount);
        assertEq(history[0].totalStaked, sMateAmount);

        console.log("timestamp: ", block.timestamp);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(history[1].amount, sMateAmount);
        assertEq(history[1].totalStaked, 0);
    }

    function test__fuzz__goldenStaking_RE(uint256 sMateAmount) external {
        sMateAmount = bound(sMateAmount, 1, 1000);

        executeGoldenStaking(true, sMateAmount, true);

        vm.warp(
            sMate.getTimeToUserUnlockFullUnstakingTime(GOLDEN_STAKER.Address)
        );

        executeGoldenStaking(false, sMateAmount, false);

        vm.warp(sMate.getTimeToUserUnlockStakingTime(GOLDEN_STAKER.Address));

        executeGoldenStaking(true, sMateAmount, false);

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(3)
        );

        assert(evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        console2.log("verify history");
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, sMateAmount);
        assertEq(history[0].totalStaked, sMateAmount);

        assert(history[1].transactionType == WITHDRAW_IDENTIFIER);
        assertEq(history[1].amount, sMateAmount);
        assertEq(history[1].totalStaked, 0);

        assert(history[2].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[2].amount, sMateAmount);
        assertEq(history[2].totalStaked, sMateAmount);
    }

    function test__fuzz__goldenStaking_SuS(
        uint256 sMateAmountToStake,
        uint8 amountTx,
        bool[300] memory execution,
        uint8[300] memory amount,
        uint8[300] memory timeToSkip
    ) external {
        sMateAmountToStake = bound(sMateAmountToStake, 1, 100);

        executeGoldenStaking(true, sMateAmountToStake, true);

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(1)
        );

        assert(evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, sMateAmountToStake);
        assertEq(history[0].totalStaked, sMateAmountToStake);

        uint256 amountStaked = sMateAmountToStake;
        uint8 indexHistory = 0;
        for (uint8 i = 0; i < amountTx; i++) {
            console.log("iteration: ", i);
            console.log("execution: ", execution[i]);
            console.log(
                "total staked: ",
                sMate.getUserAmountStaked(GOLDEN_STAKER.Address)
            );
            console.log("amount: ", amount[i]);
            if (execution[i]) {
                //staking

                skip(uint256(timeToSkip[i]));

                executeGoldenStaking(true, amount[i], true);

                amountStaked += amount[i];
                indexHistory++;

                history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

                assertEq(history[indexHistory].timestamp, block.timestamp);
                assert(
                    history[indexHistory].transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(history[indexHistory].amount, amount[i]);
                assertEq(history[indexHistory].totalStaked, amountStaked);
            } else {
                //unstaking
                // si el total staked es menor o igual a 1 no se puede unstakear saltar
                // si se pasa de la cantidad total staked saltar
                if (
                    sMate.getUserAmountStaked(GOLDEN_STAKER.Address) <= 1 ||
                    sMate.getUserAmountStaked(GOLDEN_STAKER.Address) <=
                    amount[i]
                ) {
                    continue;
                } else {
                    skip(uint256(timeToSkip[i]));

                    executeGoldenStaking(false, amount[i], false);

                    amountStaked -= amount[i];
                    indexHistory++;

                    history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

                    assertEq(history[indexHistory].timestamp, block.timestamp);
                    assert(
                        history[indexHistory].transactionType ==
                            WITHDRAW_IDENTIFIER
                    );
                    assertEq(history[indexHistory].amount, amount[i]);
                    assertEq(history[indexHistory].totalStaked, amountStaked);
                }
            }
        }
    }

    function test__fuzz__goldenStaking_RSuS(
        uint8 maxAmountOfSMateToStake,
        uint8 initAmountOfSMateToStake,
        uint8 amountTx,
        bool[300] memory execution,
        uint8[300] memory amount,
        uint8[300] memory timeToSkip
    ) external {

        vm.assume(maxAmountOfSMateToStake > 10);

        initAmountOfSMateToStake = uint8(
            bound(initAmountOfSMateToStake, 10, maxAmountOfSMateToStake-1)
        );

        giveMateToExecuteStaking(
            GOLDEN_STAKER.Address,
            maxAmountOfSMateToStake,
            0
        );

        executeGoldenStaking(true, initAmountOfSMateToStake, false);

        assertEq(
            evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
            calculateRewardPerExecution(1) +
                (sMate.priceOfSMate() * maxAmountOfSMateToStake) -
                (sMate.priceOfSMate() * initAmountOfSMateToStake)
        );

        assert(evvm.isMateStaker(GOLDEN_STAKER.Address));

        SMateMock.HistoryMetadata[]
            memory history = new SMateMock.HistoryMetadata[](
                sMate.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_IDENTIFIER);
        assertEq(history[0].amount, initAmountOfSMateToStake);
        assertEq(history[0].totalStaked, initAmountOfSMateToStake);

        uint256 amountStaked = initAmountOfSMateToStake;
        uint8 indexHistory = 0;
        for (uint8 i = 0; i < amountTx; i++) {
            history = sMate.getAddressHistory(GOLDEN_STAKER.Address);
            if (execution[i]) {
                //staking

                if (amountStaked + amount[i] > maxAmountOfSMateToStake) {
                    continue;
                }

                if (
                    history[indexHistory].totalStaked == 0 &&
                    history[indexHistory].transactionType == WITHDRAW_IDENTIFIER
                ) {
                    vm.warp(
                        sMate.getTimeToUserUnlockStakingTime(
                            GOLDEN_STAKER.Address
                        )
                    );
                } else {
                    skip(uint256(timeToSkip[i]));
                }

                executeGoldenStaking(true, amount[i], false);

                amountStaked += amount[i];
                indexHistory++;

                history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

                assertEq(history[indexHistory].timestamp, block.timestamp);
                assert(
                    history[indexHistory].transactionType == DEPOSIT_IDENTIFIER
                );
                assertEq(history[indexHistory].amount, amount[i]);
                assertEq(history[indexHistory].totalStaked, amountStaked);

                assertEq(
                    amountStaked,
                    sMate.getUserAmountStaked(GOLDEN_STAKER.Address)
                );

                assertEq(
                    evvm.seeBalance(GOLDEN_STAKER.Address, MATE_TOKEN_ADDRESS),
                    calculateRewardPerExecution(indexHistory + 1) +
                        (sMate.priceOfSMate() * maxAmountOfSMateToStake) -
                        (sMate.priceOfSMate() * amountStaked)
                );
            } else {
                //unstaking
                // validar que lo que se unstakea no termine en menos de 0
                //ejemplo si se tiene 10 y se quiere unstakear 20 debemos cambiar el valor a 10
                if (amountStaked <= amount[i]) {
                    amount[i] = uint8(
                        sMate.getUserAmountStaked(GOLDEN_STAKER.Address)
                    );
                }


                if (sMate.getUserAmountStaked(GOLDEN_STAKER.Address) == amount[i]) {
                    vm.warp(
                        sMate.getTimeToUserUnlockFullUnstakingTime(
                            GOLDEN_STAKER.Address
                        )
                    );
                } else {
                    skip(uint256(timeToSkip[i]));
                }

                executeGoldenStaking(false, amount[i], false);

                amountStaked -= amount[i];
                indexHistory++;

                history = sMate.getAddressHistory(GOLDEN_STAKER.Address);

                assertEq(history[indexHistory].timestamp, block.timestamp);
                assert(
                    history[indexHistory].transactionType == WITHDRAW_IDENTIFIER
                );
                assertEq(history[indexHistory].amount, amount[i]);
                assertEq(history[indexHistory].totalStaked, amountStaked);
            }
        }
    }
}
