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

contract unitTestCorrect_Estimator_adminFunctions is Test, Constants {
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

    function test__unit_correct__setActivatorProposal() external {
        vm.startPrank(ACTIVATOR.Address);
        estimator.setActivatorProposal(WILDCARD_USER.Address);
        vm.stopPrank();

        assertEq(
            estimator.getActivatorMetadata().proposal,
            WILDCARD_USER.Address
        );

        assertEq(
            estimator.getActivatorMetadata().timeToAccept,
            block.timestamp + 1 days
        );
    }

    function test__unit_correct__cancelActivatorProposal() external {
        vm.startPrank(ACTIVATOR.Address);
        estimator.setActivatorProposal(WILDCARD_USER.Address);
        estimator.cancelActivatorProposal();
        vm.stopPrank();

        assertEq(estimator.getActivatorMetadata().actual, ACTIVATOR.Address);
        assertEq(estimator.getActivatorMetadata().proposal, address(0));
        assertEq(estimator.getActivatorMetadata().timeToAccept, 0);
    }

    function test__unit_correct__acceptActivatorProposal() external {
        vm.startPrank(ACTIVATOR.Address);
        estimator.setActivatorProposal(WILDCARD_USER.Address);
        skip(1 days);
        estimator.acceptActivatorProposal();
        vm.stopPrank();

        assertEq(
            estimator.getActivatorMetadata().actual,
            WILDCARD_USER.Address
        );
        assertEq(estimator.getActivatorMetadata().proposal, address(0));
        assertEq(estimator.getActivatorMetadata().timeToAccept, 0);
    }

    function test__unit_correct__setEvvmAddressProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setEvvmAddressProposal(WILDCARD_USER.Address);
        vm.stopPrank();

        assertEq(
            estimator.getEvvmAddressMetadata().proposal,
            WILDCARD_USER.Address
        );

        assertEq(
            estimator.getEvvmAddressMetadata().timeToAccept,
            block.timestamp + 1 days
        );
    }

    function test__unit_correct__cancelEvvmAddressProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setEvvmAddressProposal(WILDCARD_USER.Address);
        estimator.cancelEvvmAddressProposal();
        vm.stopPrank();

        assertEq(estimator.getEvvmAddressMetadata().actual, address(evvm));
        assertEq(estimator.getEvvmAddressMetadata().proposal, address(0));
        assertEq(estimator.getEvvmAddressMetadata().timeToAccept, 0);
    }

    function test__unit_correct__acceptEvvmAddressProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setEvvmAddressProposal(WILDCARD_USER.Address);
        skip(1 days);
        estimator.acceptEvvmAddressProposal();
        vm.stopPrank();

        assertEq(
            estimator.getEvvmAddressMetadata().actual,
            WILDCARD_USER.Address
        );
        assertEq(estimator.getEvvmAddressMetadata().proposal, address(0));
        assertEq(estimator.getEvvmAddressMetadata().timeToAccept, 0);
    }

    function test__unit_correct__setAddressSMateProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAddressSMateProposal(WILDCARD_USER.Address);
        vm.stopPrank();

        assertEq(
            estimator.getAddressSMateMetadata().proposal,
            WILDCARD_USER.Address
        );

        assertEq(
            estimator.getAddressSMateMetadata().timeToAccept,
            block.timestamp + 1 days
        );
    }

    function test__unit_correct__cancelAddressSMateProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAddressSMateProposal(WILDCARD_USER.Address);
        estimator.cancelAddressSMateProposal();
        vm.stopPrank();

        assertEq(estimator.getAddressSMateMetadata().actual, address(sMate));
        assertEq(estimator.getAddressSMateMetadata().proposal, address(0));
        assertEq(estimator.getAddressSMateMetadata().timeToAccept, 0);
    }

    function test__unit_correct__acceptAddressSMateProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAddressSMateProposal(WILDCARD_USER.Address);
        skip(1 days);
        estimator.acceptAddressSMateProposal();
        vm.stopPrank();

        assertEq(
            estimator.getAddressSMateMetadata().actual,
            WILDCARD_USER.Address
        );
        assertEq(estimator.getAddressSMateMetadata().proposal, address(0));
        assertEq(estimator.getAddressSMateMetadata().timeToAccept, 0);
    }

    function test__unit_correct__setAdminProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAdminProposal(WILDCARD_USER.Address);
        vm.stopPrank();

        assertEq(
            estimator.getAdminMetadata().proposal,
            WILDCARD_USER.Address
        );

        assertEq(
            estimator.getAdminMetadata().timeToAccept,
            block.timestamp + 1 days
        );
    }   

    function test__unit_correct__cancelAdminProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAdminProposal(WILDCARD_USER.Address);
        estimator.cancelAdminProposal();
        vm.stopPrank();

        assertEq(estimator.getAdminMetadata().actual, ADMIN.Address);
        assertEq(estimator.getAdminMetadata().proposal, address(0));
        assertEq(estimator.getAdminMetadata().timeToAccept, 0);
    }

    function test__unit_correct__acceptAdminProposal() external {
        vm.startPrank(ADMIN.Address);
        estimator.setAdminProposal(WILDCARD_USER.Address);
        skip(1 days);
        estimator.acceptAdminProposal();
        vm.stopPrank();

        assertEq(
            estimator.getAdminMetadata().actual,
            WILDCARD_USER.Address
        );
        assertEq(estimator.getAdminMetadata().proposal, address(0));
        assertEq(estimator.getAdminMetadata().timeToAccept, 0);
    }
}
