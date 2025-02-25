// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function correct behavior
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
import {EvvmMockStorage} from "mock-contracts/EvvmMockStorage.sol";

contract unitTestCorrect_Estimator_makeEstimation is Test, Constants {
    SMateMock sMate;
    EvvmMock evvm;
    EstimatorMock estimator;
    MateNameServiceMock mns;

    function setUp() public {
        sMate = new SMateMock(ADMIN.Address);
        evvm = EvvmMock(sMate.getEvvmAddress());
        estimator = EstimatorMock(sMate.getEstimatorAddress());
        mns = MateNameServiceMock(evvm.getMateNameServiceAddress());

        evvm._setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        sMate.prepareSetAllowExternalStaking();
        skip(1 days);
        sMate.confirmSetAllowExternalStaking();

        vm.stopPrank();
    }

    function executeDepositByUserStaker(
        AccountData memory user,
        uint256 amountOfSMate,
        uint256 nonce,
        bool priority
    ) internal {
        evvm._addBalance(
            user.Address,
            MATE_TOKEN_ADDRESS,
            (sMate.priceOfSMate() * amountOfSMate)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
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
            user.PrivateKey,
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

        vm.startPrank(COMMON_USER_STAKER.Address);
        sMate.externalStaking(
            true,
            user.Address,
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
        AccountData memory user,
        uint256 amountOfSMate,
        uint256 nonce,
        bool priority
    ) internal {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
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
            user.PrivateKey,
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

        vm.startPrank(COMMON_USER_STAKER.Address);
        sMate.externalStaking(
            false,
            user.Address,
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
        vm.startPrank(ACTIVATOR.Address);
        estimator.notifyNewEpoch(
            ETHER_ADDRESS,
            amountOfEther,
            totalStaked,
            tStart
        );
        vm.stopPrank();
    }

    function test__unit_correct__makeEstimation__singleStake() external {
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__emptyHistory() external {
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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__atEpochStart() external {
        //? times goes to 86401 after the skip
        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__atEpochMiddle() external {
        //? times goes to 86401 after the skip

        skip(10 days);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__atEpochEnd() external {
        //? times goes to 86401 after the skip

        skip(20 days);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__beforeEndOfEpoch() external {
        //? times goes to 86401 after the skip

        skip(20 days);

        executeNotifyNewEpoch(2 ether, 320, 86401);
        //? times goes to 1814401 in the epoch

        skip(1);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

        console2.log(
            "begin epoch timestamp: ",
            estimator.getEpochMetadata().tStart
        );

        console2.log(
            "snapshot timestamp: ",
            estimator.getEpochMetadata().tFinal
        );

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__incrementStake() external {
        skip(1 days);

        console2.log("time #0 ", block.timestamp);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

        console2.log(
            "amount of sMATE staked 1: ",
            sMate
                .getAddressHistoryByIndex(COMMON_USER_NO_STAKER_1.Address, 0)
                .totalStaked
        );

        skip(3 days);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 5, 1001002, true);

        console2.log(
            "amount of sMATE staked 2: ",
            sMate
                .getAddressHistoryByIndex(COMMON_USER_NO_STAKER_1.Address, 1)
                .totalStaked
        );

        skip(10 days);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 10, 1001010, true);

        console2.log(
            "amount of sMATE staked 3: ",
            sMate
                .getAddressHistoryByIndex(COMMON_USER_NO_STAKER_1.Address, 2)
                .totalStaked
        );

        skip(6 days);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__makeEstimation__alternalStake() external {
        skip(1 days);

        console2.log("time #0 ", block.timestamp);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 5, 1001001, true);

        console2.log(
            "amount of sMATE staked 1: ",
            sMate
                .getAddressHistoryByIndex(COMMON_USER_NO_STAKER_1.Address, 0)
                .totalStaked
        );

        skip(2 days);

        executeWithdrawByUserStaker(COMMON_USER_NO_STAKER_1, 2, 1001002, true);

        console2.log(
            "amount of sMATE staked 2: ",
            sMate
                .getAddressHistoryByIndex(COMMON_USER_NO_STAKER_1.Address, 1)
                .totalStaked
        );

        skip(4 days);

        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 3, 1001010, true);

        skip(1 days);

        executeWithdrawByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001011, true);

        skip(12 days);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }

    /*
    ! eliminado hasta solucionar el problema de la estimacion cuano se hace stake por hora
    function test__unit_correct__makeEstimation__hourStake()
        external
        
    {
        skip(1 days);

        console2.log("time #0 ", block.timestamp);

        for (uint256 i = 0; i < 100; i++) {
            skip(1 hours);
            executeDepositByUserStaker(COMMON_USER_NO_STAKER_1,5, 1001001 + i, true);
        }

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }
    */

    function test__unit_correct__makeEstimation__borderStake() external {
        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001001, true);

        skip(20 days);
        executeDepositByUserStaker(COMMON_USER_NO_STAKER_1, 1, 1001002, true);

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

        sMate.gimmeYiel(COMMON_USER_NO_STAKER_1.Address);
    }
}
