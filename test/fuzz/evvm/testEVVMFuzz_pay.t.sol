// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)


/**

:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     

 * @title unit test for EVVM function correct behavior
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
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AdvancedStrings} from "@RollAMate/libraries/AdvancedStrings.sol";

contract testEVVMFuzz_pay is Test {
    SMateMock sMate;
    EvvmMock evvm;

    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;

    /*
        |        |  USER1  |  USER2  |  USER3  |  USER4  |  USER5  |
        |--------|---------|---------|---------|---------|---------|
        | MATE   |    X    |    X    |         |         |         |
        | ETH    |    X    |    X    |         |         |         |
        | staker |    X    |         |         |    X    |         |
        | golden |         |         |         |         |    X    |
        |----------------------------------------------------------|
     */

    address USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    address USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    address USER4 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    address USER5 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

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

    function setUp() public {
        sMate = new SMateMock(USER2);

        evvm = EvvmMock(sMate.getEvvmAddress());

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

    /*function testConstructorEVVM() external view {
        console2.log("evvm owner : ", evvm.owner());
        assert(evvm.owner() == USER2);
    }*/

    /**
     * Naming Convention for Fuzz Test Functions
     * Basic Structure:
     * test__[typeOfTest]__[functionName]__[options]
     * General Rules:
     *  - Always start with "test__"
     *  - The name of the function to be executed must immediately follow "test__"
     *  - Options are added at the end, separated by underscores
     *
     * Options for Payment Functions:
     * Add these options at the end of the name, in the following order:
     *  a) Priority Fee:
     *      PF: Includes priority fee
     *      nPF: No priority fee
     *  b) Executor:
     *      EX: Includes executor execution
     *      nEX: Does not include executor execution
     *  d) Identity:
     *     ID: Uses a MNS identity
     *     AD: Uses an address
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
     */
    function test__fuzz__payNoMateStaking_sync__nPF_nEX_AD(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER3, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER4,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER3),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        evvm.payNoMateStaking_sync(
            USER3,
            USER4,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            address(0),
            signatureEVVM
        );

        assertEq(evvm.seeBalance(USER4, ETHER_ADDRESS), amountToSend);
    }

    function test__fuzz__payNoMateStaking_sync__nPF_EX_AD(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER3, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER4,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER3),
                false,
                (amountToSend % 2 == 0) ? USER4 : USER3
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank((amountToSend % 2 == 0) ? USER4 : USER3);

        evvm.payNoMateStaking_sync(
            USER3,
            USER4,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            (amountToSend % 2 == 0) ? USER4 : USER3,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(evvm.seeBalance(USER4, ETHER_ADDRESS), amountToSend);
    }

    function test__fuzz__payNoMateStaking_async__nPF_nEX_AD(
        uint256 amountToSend,
        uint256 nonce
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER3, nonce));

        evvm._addBalance(USER3, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER4,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER4Before = evvm.seeBalance(USER4, ETHER_ADDRESS);

        evvm.payNoMateStaking_async(
            USER3,
            USER4,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            address(0),
            signatureEVVM
        );

        assertEq(
            evvm.seeBalance(USER4, ETHER_ADDRESS),
            amountUSER4Before + amountToSend
        );
    }

    function test__fuzz__payNoMateStaking_async__nPF_EX_AD(
        uint256 amountToSend,
        uint256 nonce
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER3, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER4,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                (amountToSend % 2 == 0) ? USER4 : USER3
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank((amountToSend % 2 == 0) ? USER4 : USER3);

        uint256 amountUSER4Before = evvm.seeBalance(USER4, ETHER_ADDRESS);

        evvm.payNoMateStaking_async(
            USER3,
            USER4,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            (amountToSend % 2 == 0) ? USER4 : USER3,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER4, ETHER_ADDRESS),
            amountUSER4Before + amountToSend
        );
    }

    function test__fuzz__payNoMateStaking_sync__nPF_nEX_ID(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER3),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNERBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );

        evvm.payNoMateStaking_sync(
            USER4,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            address(0),
            signatureEVVM
        );

        assertEq(
            evvm.seeBalance(OWNER_USERNAME_DUMMY, ETHER_ADDRESS),
            amountOWNERBefore + amountToSend
        );
    }

    function test__fuzz__payNoMateStaking_sync__nPF_EX_ID(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER3),
                false,
                (amountToSend % 2 == 0) ? USER4 : USER3
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank((amountToSend % 2 == 0) ? USER4 : USER3);

        uint256 amountOWNERBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );

        evvm.payNoMateStaking_sync(
            USER4,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            (amountToSend % 2 == 0) ? USER4 : USER3,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.seeBalance(OWNER_USERNAME_DUMMY, ETHER_ADDRESS),
            amountOWNERBefore + amountToSend
        );
    }

    function test__fuzz__payNoMateStaking_async__nPF_nEX_ID(
        uint256 amountToSend,
        uint256 nonce
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER4, nonce));

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNERBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );

        evvm.payNoMateStaking_async(
            USER4,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            address(0),
            signatureEVVM
        );

        assertEq(
            evvm.seeBalance(OWNER_USERNAME_DUMMY, ETHER_ADDRESS),
            amountOWNERBefore + amountToSend
        );
    }

    function test__fuzz__payNoMateStaking_async__nPF_EX_ID(
        uint256 amountToSend,
        uint256 nonce
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                (amountToSend % 2 == 0) ? USER4 : USER3
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank((amountToSend % 2 == 0) ? USER4 : USER3);

        uint256 amountOWNERBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );

        evvm.payNoMateStaking_async(
            USER4,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            (amountToSend % 2 == 0) ? USER4 : USER3,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.seeBalance(OWNER_USERNAME_DUMMY, ETHER_ADDRESS),
            amountOWNERBefore + amountToSend
        );
    }

    function test__fuzz__payMateStaking_sync__nPF_nEX_AD(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(USER4);
        evvm.payMateStaking_sync(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_sync__PF_nEX_AD(
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        evvm._addBalance(USER5, ETHER_ADDRESS, (amountToSend + priorityFee));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(USER4);
        evvm.payMateStaking_sync(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_sync__nPF_EX_AD(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        evvm._addBalance(USER5, ETHER_ADDRESS, (amountToSend));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_sync(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_sync__PF_EX_AD(
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        evvm._addBalance(USER5, ETHER_ADDRESS, (amountToSend + priorityFee));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountExecutorBefore_ETH = evvm.seeBalance(
            executor,
            ETHER_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_sync(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
        assertEq(
            evvm.seeBalance(executor, ETHER_ADDRESS),
            amountExecutorBefore_ETH + priorityFee
        );
    }

    function test__fuzz__payMateStaking_sync__nPF_nEX_ID(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(USER4);
        evvm.payMateStaking_sync(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_sync__PF_nEX_ID(
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountUSER4Before_ETH = evvm.seeBalance(USER4, ETHER_ADDRESS);

        vm.startPrank(USER4);
        evvm.payMateStaking_sync(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );

        assertEq(
            evvm.seeBalance(USER4, ETHER_ADDRESS),
            amountUSER4Before_ETH + priorityFee
        );
    }

    function test__fuzz__payMateStaking_sync__nPF_EX_ID(
        uint256 amountToSend
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_sync(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_sync__PF_EX_ID(
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                evvm.getNextCurrentSyncNonce(USER5),
                false,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_sync(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_async__nPF_nEX_AD(
        uint256 nonce,
        uint256 amountToSend
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(USER4);
        evvm.payMateStaking_async(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_async__PF_nEX_AD(
        uint256 nonce,
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountUSER4Before_ETH = evvm.seeBalance(USER4, ETHER_ADDRESS);

        vm.startPrank(USER4);
        evvm.payMateStaking_async(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            nonce,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
        assertEq(
            evvm.seeBalance(USER4, ETHER_ADDRESS),
            amountUSER4Before_ETH + priorityFee
        );
    }

    function test__fuzz__payMateStaking_async__nPF_EX_AD(
        uint256 nonce,
        uint256 amountToSend
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_async(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_async__PF_EX_AD(
        uint256 nonce,
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                nonce,
                true,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountUSER3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountExecutorBefore_ETH = evvm.seeBalance(
            executor,
            ETHER_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_async(
            USER5,
            USER3,
            "",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            nonce,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountUSER3Before + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
        assertEq(
            evvm.seeBalance(executor, ETHER_ADDRESS),
            amountExecutorBefore_ETH + priorityFee
        );
    }

    function test__fuzz__payMateStaking_async__nPF_nEX_ID(
        uint256 nonce,
        uint256 amountToSend
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(USER4);
        evvm.payMateStaking_async(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_async__PF_nEX_ID(
        uint256 nonce,
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                nonce,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountUSER4Before_MATE = evvm.seeBalance(
            USER4,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountUSER4Before_ETH = evvm.seeBalance(USER4, ETHER_ADDRESS);

        vm.startPrank(USER4);
        evvm.payMateStaking_async(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            nonce,
            address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(USER4, MATE_TOKEN_ADDRESS),
            amountUSER4Before_MATE + evvm.seeMateReward()
        );

        assertEq(
            evvm.seeBalance(USER4, ETHER_ADDRESS),
            amountUSER4Before_ETH + priorityFee
        );
    }

    function test__fuzz__payMateStaking_async__nPF_EX_ID(
        uint256 nonce,
        uint256 amountToSend
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                0,
                nonce,
                true,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_async(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            0,
            nonce,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
    }

    function test__fuzz__payMateStaking_async__PF_EX_ID(
        uint256 nonce,
        uint256 amountToSend,
        uint256 priorityFee
    ) external {
        nonce = bound(nonce, 0, 100 * 10 ** 30);
        amountToSend = bound(amountToSend, 0, 99 * 10 ** 30);
        priorityFee = bound(priorityFee, 0, 99 * 10 ** 30);

        address executor = (amountToSend % 2 == 0) ? USER4 : USER1;

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce));

        evvm._addBalance(USER5, ETHER_ADDRESS, amountToSend + priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER5_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend,
                priorityFee,
                nonce,
                true,
                executor
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        uint256 amountOWNER_USERNAME_DUMMYBefore = evvm.seeBalance(
            OWNER_USERNAME_DUMMY,
            ETHER_ADDRESS
        );
        uint256 amountExecutorBefore_MATE = evvm.seeBalance(
            executor,
            MATE_TOKEN_ADDRESS
        );
        uint256 amountExecutorBefore_ETH = evvm.seeBalance(
            executor,
            ETHER_ADDRESS
        );

        vm.startPrank(executor);
        evvm.payMateStaking_async(
            USER5,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amountToSend,
            priorityFee,
            nonce,
            executor,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountOWNER_USERNAME_DUMMYBefore + amountToSend
        );
        assertEq(
            evvm.seeBalance(executor, MATE_TOKEN_ADDRESS),
            amountExecutorBefore_MATE + evvm.seeMateReward()
        );
        assertEq(
            evvm.seeBalance(executor, ETHER_ADDRESS),
            amountExecutorBefore_ETH + priorityFee
        );
    }
}
