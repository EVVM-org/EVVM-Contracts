// SPDX-License-Identifier: MIT

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
import {EvvmMockStructs} from "mock-contracts/EvvmMockStructs.sol";

contract testEVVMFuzz_payMultiple is Test {
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
    struct PaymultipleSignatureMetadata {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes signatureEVVM;
    }

    function test__fuzz__payMultiple__async_nSMate_nPF_nEX(
        uint256 amountToSend_0,
        uint256 nonce_0,
        uint256 amountToSend_1,
        uint256 nonce_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        nonce_0 = bound(nonce_0, 0, 100 * 10 ** 30);
        nonce_1 = bound(nonce_1, 0, 100 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_0));
        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_1));

        vm.assume(nonce_0 != nonce_1);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                0,
                nonce_0,
                true,
                address(0)
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: 0,
            nonce: nonce_0,
            priority: true,
            executor: address(0),
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                0,
                nonce_1,
                true,
                address(0)
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: 0,
            nonce: nonce_1,
            priority: true,
            executor: address(0),
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(USER3);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__async_nSMate_PF_nEX(
        uint256 amountToSend_0,
        uint256 priorityFee_0,
        uint256 nonce_0,
        uint256 amountToSend_1,
        uint256 priorityFee_1,
        uint256 nonce_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        priorityFee_0 = bound(priorityFee_0, 0, 1 ** 30);
        priorityFee_1 = bound(priorityFee_1, 0, 1 ** 30);
        nonce_0 = bound(nonce_0, 0, 100 * 10 ** 30);
        nonce_1 = bound(nonce_1, 0, 100 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_0));
        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_1));

        vm.assume(nonce_0 != nonce_1);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                priorityFee_0,
                nonce_0,
                true,
                address(0)
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: priorityFee_0,
            nonce: nonce_0,
            priority: true,
            executor: address(0),
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                priorityFee_1,
                nonce_1,
                true,
                address(0)
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: priorityFee_1,
            nonce: nonce_1,
            priority: true,
            executor: address(0),
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(USER3);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__async_nSMate_nPF_EX(
        uint256 amountToSend_0,
        uint256 nonce_0,
        uint256 amountToSend_1,
        uint256 nonce_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        nonce_0 = bound(nonce_0, 0, 100 * 10 ** 30);
        nonce_1 = bound(nonce_1, 0, 100 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_0));
        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_1));

        vm.assume(nonce_0 != nonce_1);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        address executor = (amountToSend_0 % 2 == 0) ? USER4 : USER3;

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                0,
                nonce_0,
                true,
                executor
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: 0,
            nonce: nonce_0,
            priority: true,
            executor: executor,
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                0,
                nonce_1,
                true,
                executor
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: 0,
            nonce: nonce_1,
            priority: true,
            executor: executor,
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(executor);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__async_nSMate_PF_EX(
        uint256 amountToSend_0,
        uint256 priorityFee_0,
        uint256 nonce_0,
        uint256 amountToSend_1,
        uint256 priorityFee_1,
        uint256 nonce_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        priorityFee_0 = bound(priorityFee_0, 0, 1 ** 30);
        priorityFee_1 = bound(priorityFee_1, 0, 1 ** 30);
        nonce_0 = bound(nonce_0, 0, 100 * 10 ** 30);
        nonce_1 = bound(nonce_1, 0, 100 * 10 ** 30);

        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_0));
        vm.assume(!evvm.getIfUsedAsyncNonce(USER5, nonce_1));

        vm.assume(nonce_0 != nonce_1);

        evvm._addBalance(
            USER4,
            ETHER_ADDRESS,
            amountToSend_0 + amountToSend_1 + priorityFee_0 + priorityFee_1
        );

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        address executor = (amountToSend_0 % 2 == 0) ? USER4 : USER3;

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                priorityFee_0,
                nonce_0,
                true,
                executor
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: priorityFee_0,
            nonce: nonce_0,
            priority: true,
            executor: executor,
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                priorityFee_1,
                nonce_1,
                true,
                executor
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: priorityFee_1,
            nonce: nonce_1,
            priority: true,
            executor: executor,
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(executor);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__sync_nSMate_nPF_nEX(
        uint256 amountToSend_0,
        uint256 amountToSend_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                0,
                evvm.getNextCurrentSyncNonce(USER4),
                false,
                address(0)
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: 0,
            nonce: evvm.getNextCurrentSyncNonce(USER4),
            priority: false,
            executor: address(0),
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                0,
                evvm.getNextCurrentSyncNonce(USER4) + 1,
                false,
                address(0)
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: 0,
            nonce: evvm.getNextCurrentSyncNonce(USER4) + 1,
            priority: false,
            executor: address(0),
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(USER3);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__sync_nSMate_PF_nEX(
        uint256 amountToSend_0,
        uint256 priorityFee_0,
        uint256 amountToSend_1,
        uint256 priorityFee_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        priorityFee_0 = bound(priorityFee_0, 0, 1 ** 30);
        priorityFee_1 = bound(priorityFee_1, 0, 1 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        uint256 nonce_0 = evvm.getNextCurrentSyncNonce(USER4);
        uint256 nonce_1 = nonce_0 + 1;

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                priorityFee_0,
                nonce_0,
                false,
                address(0)
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: priorityFee_0,
            nonce: nonce_0,
            priority: false,
            executor: address(0),
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                priorityFee_1,
                nonce_1,
                false,
                address(0)
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: priorityFee_1,
            nonce: nonce_1,
            priority: false,
            executor: address(0),
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(USER3);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__sync_nSMate_nPF_EX(
        uint256 amountToSend_0,
        uint256 amountToSend_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);

        evvm._addBalance(USER4, ETHER_ADDRESS, amountToSend_0 + amountToSend_1);

        uint256 nonce_0 = evvm.getNextCurrentSyncNonce(USER4);
        uint256 nonce_1 = nonce_0 + 1;

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        address executor = (amountToSend_0 % 2 == 0) ? USER4 : USER3;

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                0,
                nonce_0,
                false,
                executor
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: 0,
            nonce: nonce_0,
            priority: false,
            executor: executor,
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                0,
                nonce_1,
                false,
                executor
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: 0,
            nonce: nonce_1,
            priority: false,
            executor: executor,
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(executor);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }

    function test__fuzz__payMultiple__sync_nSMate_PF_EX(
        uint256 amountToSend_0,
        uint256 priorityFee_0,
        uint256 amountToSend_1,
        uint256 priorityFee_1
    ) external {
        amountToSend_0 = bound(amountToSend_0, 0, 99 * 10 ** 30);
        amountToSend_1 = bound(amountToSend_1, 0, 99 * 10 ** 30);
        priorityFee_0 = bound(priorityFee_0, 0, 1 ** 30);
        priorityFee_1 = bound(priorityFee_1, 0, 1 ** 30);

        evvm._addBalance(
            USER4,
            ETHER_ADDRESS,
            amountToSend_0 + amountToSend_1 + priorityFee_0 + priorityFee_1
        );

        uint256 nonce_0 = evvm.getNextCurrentSyncNonce(USER4);
        uint256 nonce_1 = nonce_0 + 1;

        PaymultipleSignatureMetadata[]
            memory payDataSignature = new PaymultipleSignatureMetadata[](2);

        EvvmMockStructs.PayData[]
            memory payData = new EvvmMockStructs.PayData[](2);

        address executor = (amountToSend_0 % 2 == 0) ? USER4 : USER3;

        (
            payDataSignature[0].v,
            payDataSignature[0].r,
            payDataSignature[0].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                USER3,
                "",
                ETHER_ADDRESS,
                amountToSend_0,
                priorityFee_0,
                nonce_0,
                false,
                executor
            )
        );
        payDataSignature[0].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[0].v,
                payDataSignature[0].r,
                payDataSignature[0].s
            );

        payData[0] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: USER3,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: amountToSend_0,
            priorityFee: priorityFee_0,
            nonce: nonce_0,
            priority: false,
            executor: executor,
            signature: payDataSignature[0].signatureEVVM
        });

        (
            payDataSignature[1].v,
            payDataSignature[1].r,
            payDataSignature[1].s
        ) = vm.sign(
            USER4_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amountToSend_1,
                priorityFee_1,
                nonce_1,
                false,
                executor
            )
        );
        payDataSignature[1].signatureEVVM = Erc191TestBuilder
            .buildERC191Signature(
                payDataSignature[1].v,
                payDataSignature[1].r,
                payDataSignature[1].s
            );

        payData[1] = EvvmMockStructs.PayData({
            from: USER4,
            to_address: address(0),
            to_identity: "dummy",
            token: ETHER_ADDRESS,
            amount: amountToSend_1,
            priorityFee: priorityFee_1,
            nonce: nonce_1,
            priority: false,
            executor: executor,
            signature: payDataSignature[1].signatureEVVM
        });

        uint256 amountBefore = evvm.seeBalance(USER3, ETHER_ADDRESS);

        vm.startPrank(executor);
        (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory status
        ) = evvm.payMultiple(payData);
        vm.stopPrank();

        for (uint256 i = 0; i < status.length; i++) {
            if (status[i]) {
                console2.log("Transaction ", i, " was successful");
            } else {
                console2.log("Transaction ", i, " failed");
            }
        }

        assertEq(successfulTransactions, 2);
        assertEq(failedTransactions, 0);
        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountBefore + amountToSend_0 + amountToSend_1
        );
    }
}
