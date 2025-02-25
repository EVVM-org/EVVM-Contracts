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

contract unitTestCorrect_Estimator_notifyNewEpoch is Test, Constants {
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

    function test__unit_correct__notifyNewEpoch() external {
        vm.startPrank(ACTIVATOR.Address);
        estimator.notifyNewEpoch(
            ETHER_ADDRESS,
            4.2069 ether,
            1500,
            block.timestamp - 20 hours
        );
        vm.stopPrank();

        EstimatorMock.EpochMetadata memory epoch = estimator.getEpochMetadata();

        assertEq(epoch.tokenPool, ETHER_ADDRESS);
        assertEq(epoch.totalPool, 4.2069 ether);
        assertEq(epoch.totalStaked, 1500);
        assertEq(epoch.tFinal, block.timestamp);
        assertEq(epoch.tStart, block.timestamp - 20 hours);
    }
}
