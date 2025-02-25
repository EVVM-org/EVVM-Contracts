// SPDX-License-Identifier: MIT

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

import {SMateMock} from "mock-contracts/SMateMock.sol";
import {MateNameServiceMock} from "mock-contracts/MateNameServiceMock.sol";
import {EvvmMock} from "mock-contracts/EvvmMock.sol";
import {Erc191TestBuilder} from "@RollAMate/libraries/Erc191TestBuilder.sol";
import {EstimatorMock} from "mock-contracts/EstimatorMock.sol";

contract testEstimatorFuzz is Test {
    SMateMock sMate;
    EvvmMock evvm;
    EstimatorMock estimator;

    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;

    //mate stakers
    address USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address USER4 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    //no mate stakers
    address USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    //golden staker
    address USER5 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

    address USER_STAKER = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;

    address ACTIVATOR_ADDRESS = USER2;

    address OWNER_USERNAME_DUMMY = USER3;

    uint256 constant USER1_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 constant USER2_PRIVATE_KEY =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    uint256 constant USER3_PRIVATE_KEY =
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    uint256 constant USER4_PRIVATE_KEY =
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    uint256 constant USER5_PRIVATE_KEY =
        0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba;

    uint256 constant USER_STAKER_PRIVATE_KEY =
        0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e;

    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));

    modifier allowExternalStaking() {
        vm.startPrank(USER2);
        sMate.prepareSetAllowExternalStaking();
        sMate.prepareSetSecondsToUnllockFullUnstaking(0);
        skip(1 days); //? times goes to 86401 after the skip
        sMate.confirmSetAllowExternalStaking();
        sMate.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
        console2.log("allowExternalStaking has been set", block.timestamp);
        _;
    }

    function setUp() public {
        sMate = new SMateMock(USER2);

        evvm = EvvmMock(sMate.getEvvmAddress());

        estimator = EstimatorMock(sMate.getEstimatorAddress());

        evvm._addBalance(USER1, address(0), 1000000 ether);
        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            1000000000000000000000000000 * 10 ** 18
        );
        evvm._addBalance(
            USER1,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            10000000 * 10 ** 6
        );
        evvm._addBalance(USER2, address(0), 10000000 ether);
        evvm._addBalance(USER2, MATE_TOKEN_ADDRESS, 10000000 * 10 ** 18);
        evvm._addBalance(
            USER2,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            10000000 * 10 ** 6
        );

        evvm._setPointStaker(USER1, 0x01);
        evvm._setPointStaker(USER4, 0x01);
    }

    function executeDepositByUserStaker(
        uint256 amountOfSMate,
        uint256 nonce,
        bool priority
    ) internal {
        evvm._addBalance(
            USER_STAKER,
            MATE_TOKEN_ADDRESS,
            (sMate.priceOfSMate() * amountOfSMate)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER_STAKER_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(sMate),
                "",
                MATE_TOKEN_ADDRESS,
                sMate.priceOfSMate() * amountOfSMate,
                0 ether,
                nonce,
                priority,
                address(sMate)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER_STAKER_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForExternalStaking(
                true,
                amountOfSMate,
                nonce
            )
        );
        bytes memory signatureSMate = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(USER4);
        sMate.externalStaking(
            true,
            USER_STAKER,
            nonce,
            amountOfSMate,
            signatureSMate,
            0,
            nonce,
            priority,
            signatureEVVM
        );
        vm.stopPrank();
    }

    function executeWithdrawByUserStaker(
        uint256 amountOfSMate,
        uint256 nonce,
        bool priority
    ) internal {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER_STAKER_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(sMate),
                "",
                MATE_TOKEN_ADDRESS,
                sMate.priceOfSMate() * amountOfSMate,
                0 ether,
                nonce,
                priority,
                address(sMate)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER_STAKER_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForExternalStaking(
                false,
                amountOfSMate,
                nonce
            )
        );
        bytes memory signatureSMate = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(USER4);
        sMate.externalStaking(
            false,
            USER_STAKER,
            nonce,
            amountOfSMate,
            signatureSMate,
            0,
            nonce,
            priority,
            signatureEVVM
        );
        vm.stopPrank();
    }

    function executeNotifyNewEpoch(
        uint256 amountOfEther,
        uint256 totalStaked,
        uint256 tStart
    ) internal {
        evvm._addBalance(address(sMate), ETHER_ADDRESS, amountOfEther);
        vm.startPrank(ACTIVATOR_ADDRESS);
        estimator.notifyNewEpoch(
            ETHER_ADDRESS,
            amountOfEther,
            totalStaked,
            tStart
        );
        vm.stopPrank();
    }

    function test__fuzz__makeEstimation__singleStake(
        uint32 amountOfSMate
    ) external allowExternalStaking {
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(bound(amountOfSMate, 1, 320), 1001001, true);

        skip(20 days);

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    function test__fuzz__makeEstimation__atEpochStart(
        uint32 amountOfSMate
    ) external allowExternalStaking {
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(bound(amountOfSMate, 1, 320), 1001001, true);

        skip(20 days);

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    function test__fuzz__makeEstimation__atEpochMiddle(
        uint32 amountOfSMate
    ) external allowExternalStaking {
        skip(10 days);

        executeDepositByUserStaker(bound(amountOfSMate, 1, 320), 1001001, true);

        skip(10 days);

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    function test__fuzz__makeEstimation__atEpochEnd(
        uint32 amountOfSMate
    ) external allowExternalStaking {
        //? times goes to 86401 after the skip

        skip(20 days);

        executeDepositByUserStaker(bound(amountOfSMate, 1, 320), 1001001, true);

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    /**
        20 - 1 dia   - 0  
        10 - 2 dias  - 1  
        05 - 4 dias  - 2 
        04 - 5 dias  - 3  
        02 - 10 dias - 4
     */

    function test__fuzz__makeEstimation__singleStake(
        uint32 salt,
        uint8 amountOfSMateToStake
    ) external allowExternalStaking {
        uint256 timeToPass = bound(salt, 0, 19);
        skip(timeToPass * 1 days);
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(
            bound(amountOfSMateToStake, 1, 320),
            1001001,
            true
        );

        skip(20 days - (timeToPass * 1 days));

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    function test__fuzz__makeEstimation__doubleStake(
        uint32 saltJump1,
        uint32 saltJump2,
        uint8 amountOfSMateToStakeJump1,
        uint8 amountOfSMateToStakeJump2
    ) external allowExternalStaking {
        uint256 timeToPass1 = bound(saltJump1, 0, 10);
        uint256 timeToPass2 = bound(saltJump2, 0, 10);
        skip(saltJump1 * 1 days);
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump1, 1, 160),
            1001001,
            true
        );

        skip(saltJump2 * 1 days);

        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump2, 1, 160),
            1001002,
            true
        );

        skip(20 days - ((timeToPass1 * 1 days) + (timeToPass2 * 1 days)));

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }

    function test__fuzz__makeEstimation__cuadrupleStake(
        uint32 saltJump1,
        uint32 saltJump2,
        uint32 saltJump3,
        uint32 saltJump4,
        uint8 amountOfSMateToStakeJump1,
        uint8 amountOfSMateToStakeJump2,
        uint8 amountOfSMateToStakeJump3,
        uint8 amountOfSMateToStakeJump4
    ) external allowExternalStaking {
        uint256 timeToPass1 = bound(saltJump1, 0, 5);
        uint256 timeToPass2 = bound(saltJump2, 0, 5);
        uint256 timeToPass3 = bound(saltJump3, 0, 5);
        uint256 timeToPass4 = bound(saltJump4, 0, 5);
        skip(saltJump1 * 1 days);
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump1, 1, 80),
            1001001,
            true
        );

        skip(saltJump2 * 1 days);

        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump2, 1, 80),
            1001002,
            true
        );

        skip(saltJump3 * 1 days);

        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump3, 1, 80),
            1001003,
            true
        );

        skip(timeToPass4 * 1 days);

        executeDepositByUserStaker(
            bound(amountOfSMateToStakeJump4, 1, 80),
            1001004,
            true
        );

        skip(
            20 days -
                ((timeToPass1 * 1 days) +
                    (timeToPass2 * 1 days) +
                    (timeToPass3 * 1 days) +
                    (timeToPass4 * 1 days))
        );

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(USER_STAKER);
    }
}
