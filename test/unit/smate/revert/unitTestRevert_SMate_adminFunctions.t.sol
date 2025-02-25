// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for 
 * @notice some functions has evvm functions that are implemented
 *         and dosent need to be tested here
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {EvvmMockStructs} from "mock-contracts/EvvmMockStructs.sol";

import {SMateMock} from "mock-contracts/SMateMock.sol";
import {MateNameServiceMock} from "mock-contracts/MateNameServiceMock.sol";
import {EvvmMock} from "mock-contracts/EvvmMock.sol";
import {Erc191TestBuilder} from "@RollAMate/libraries/Erc191TestBuilder.sol";
import {EstimatorMock} from "mock-contracts/EstimatorMock.sol";
import {EvvmMockStorage} from "mock-contracts/EvvmMockStorage.sol";

contract unitTestRevert_SMate_adminFunctions is Test, Constants {
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
    }

    function test__unitRevert__addPresaleStaker__nonOwner() external {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unitRevert__addPresaleStakers__nonOwner() external {
        address[] memory stakers = new address[](2);
        stakers[0] = makeAddr("alice");
        stakers[1] = makeAddr("bob");

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.addPresaleStakers(stakers);
        vm.stopPrank();
    }

    function test__unitRevert__proposeAdmin__nonOwner() external {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalAdmin__nonOwner() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.rejectProposalAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewAdmin__nonNewOwner() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(ADMIN.Address);
        vm.expectRevert();
        sMate.acceptNewAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewAdmin__notInTime() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
        vm.warp(block.timestamp + 10 hours);
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.acceptNewAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__proposeGoldenFisher__nonOwner() external {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalGoldenFisher__nonOwner() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 2 hours);
        vm.stopPrank();
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.rejectProposalGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewGoldenFisher__nonOwner() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.acceptNewGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewGoldenFisher__notInTime() external {
        vm.startPrank(ADMIN.Address);
        sMate.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        sMate.acceptNewGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__proposeSetSecondsToUnlockStaking__nonOwner()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalSetSecondsToUnlockStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.rejectProposalSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__acceptSetSecondsToUnlockStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__acceptSetSecondsToUnlockStaking__notInTime()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.proposeSetSecondsToUnlockStaking(2 days);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        sMate.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareSetSecondsToUnllockFullUnstaking__nonOwner()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();
    }

    function test__unitRevert__cancelSetSecondsToUnllockFullUnstaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.cancelSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetSecondsToUnllockFullUnstaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetSecondsToUnllockFullUnstaking__notInTime()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        sMate.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareSetAllowExternalStaking__nonOwner()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.prepareSetAllowExternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__cancelSetAllowExternalStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowExternalStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.cancelSetAllowExternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetAllowExternalStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowExternalStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.confirmSetAllowExternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetAllowExternalStaking__notInTime()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowExternalStaking();
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        sMate.confirmSetAllowExternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareSetAllowInternalStaking__nonOwner()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.prepareSetAllowInternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__cancelSetAllowInternalStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowInternalStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.cancelSetAllowInternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetAllowInternalStaking__nonOwner()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowInternalStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert();
        sMate.confirmSetAllowInternalStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetAllowInternalStaking__notInTime()
        external
    {
        vm.startPrank(ADMIN.Address);
        sMate.prepareSetAllowInternalStaking();
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        sMate.confirmSetAllowInternalStaking();
        vm.stopPrank();
    }
}
