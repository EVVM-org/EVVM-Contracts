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

contract testMateNameServiceFuzz_offers is Test {
    SMateMock sMate;
    EvvmMock evvm;
    MateNameServiceMock mns;

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

    modifier prepareUsername() {
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked("test", uint256(777))),
                10
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.preRegistrationUsername(
            USER1,
            10,
            keccak256(abi.encodePacked("test", uint256(777))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );

        console2.log(
            "travel to time from: ",
            block.timestamp,
            " to: ",
            block.timestamp + 40 minutes
        );
        vm.warp(block.timestamp + 40 minutes);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                20
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                20,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.registrationUsername(
            USER1,
            20,
            "test",
            777,
            signatureMNS,
            0,
            20,
            true,
            signatureEVVM
        );
        _;
    }

    function setUp() public {
        sMate = new SMateMock(USER2);

        evvm = EvvmMock(sMate.getEvvmAddress());
        mns = MateNameServiceMock(evvm.getMateNameServiceAddress());

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

    function test__fuzz__makeOffer__async__nPF(
        uint16 nonceMNS,
        uint16 nonceEVVM,
        uint72 amountToOffer,
        uint16 seed
    ) external prepareUsername {
        vm.assume(amountToOffer > 0);

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, amountToOffer);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                expiration,
                amountToOffer,
                nonceMNS
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                amountToOffer,
                0,
                nonceEVVM,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.makeOffer(
            user,
            nonceMNS,
            "test",
            amountToOffer,
            expiration,
            0,
            signatureMNS,
            nonceEVVM,
            true,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", 0);

        assert(checkData.offerer == user);
    }

    function test__fuzz__makeOffer__sync__nPF(
        uint16 nonceMNS,
        uint72 amountToOffer,
        uint16 seed
    ) external prepareUsername {
        vm.assume(amountToOffer > 0);

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, amountToOffer);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                expiration,
                amountToOffer,
                nonceMNS
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                amountToOffer,
                0,
                evvm.getNextCurrentSyncNonce(user),
                false,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.makeOffer(
            user,
            nonceMNS,
            "test",
            amountToOffer,
            expiration,
            0,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", 0);

        assert(checkData.offerer == user);
    }

    function test__fuzz__makeOffer__async__PF(
        uint16 nonceMNS,
        uint16 nonceEVVM,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed
    ) external prepareUsername {
        vm.assume(amountToOffer > 0);
        vm.assume(priorityFee > 0);

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            uint256(amountToOffer) + uint256(priorityFee)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                expiration,
                amountToOffer,
                nonceMNS
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                amountToOffer,
                priorityFee,
                nonceEVVM,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.makeOffer(
            user,
            nonceMNS,
            "test",
            amountToOffer,
            expiration,
            priorityFee,
            signatureMNS,
            nonceEVVM,
            true,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", 0);

        assert(checkData.offerer == user);
    }

    function test__fuzz__makeOffer__sync__PF(
        uint16 nonceMNS,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed
    ) external prepareUsername {
        vm.assume(amountToOffer > 0);
        vm.assume(priorityFee > 0);

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            5000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            uint256(amountToOffer) + uint256(priorityFee)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                expiration,
                amountToOffer,
                nonceMNS
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                amountToOffer,
                priorityFee,
                evvm.getNextCurrentSyncNonce(user),
                false,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.makeOffer(
            user,
            nonceMNS,
            "test",
            amountToOffer,
            expiration,
            priorityFee,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", 0);

        assert(checkData.offerer == user);
    }

    function test__fuzz__withdrawOffer__nPF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint16 nonceMNS_withdraw,
        uint72 amountToOffer,
        uint16 seed,
        uint8 numberToWithdraw
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_withdraw > 0
        );

        nonceMNS_withdraw = uint16(bound(uint256(nonceMNS_offer), 0, 5000));
        nonceMNS_offer = uint16(bound(uint256(nonceEVVM_offer), 5006, 10000));

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToWithdraw = uint8(bound(uint256(numberToWithdraw), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, uint256(amountToOffer));

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                numberToWithdraw,
                nonceMNS_withdraw
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.withdrawOffer(
            user,
            nonceMNS_withdraw,
            "test",
            numberToWithdraw,
            0,
            signatureMNS,
            0,
            false,
            ""
        );

        checkData = mns.getSingleOfferOfUsername("test", numberToWithdraw);

        assert(checkData.offerer == address(0));
    }

    function test__fuzz__withdrawOffer__async__PF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint16 nonceMNS_withdraw,
        uint16 nonceEVVM_withdraw,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed,
        uint8 numberToWithdraw
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_withdraw > 0
        );

        nonceMNS_withdraw = uint16(bound(uint256(nonceMNS_offer), 0, 5000));
        nonceMNS_offer = uint16(bound(uint256(nonceEVVM_offer), 5006, 10000));

        nonceEVVM_withdraw = uint16(
            bound(uint256(nonceEVVM_withdraw), 0, 5000)
        );
        nonceEVVM_offer = uint16(bound(uint256(nonceEVVM_offer), 5006, 10000));

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToWithdraw = uint8(bound(uint256(numberToWithdraw), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            uint256(amountToOffer) + uint256(priorityFee)
        );

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                numberToWithdraw,
                nonceMNS_withdraw
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priorityFee,
                0,
                nonceEVVM_withdraw,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.withdrawOffer(
            user,
            nonceMNS_withdraw,
            "test",
            numberToWithdraw,
            priorityFee,
            signatureMNS,
            nonceEVVM_withdraw,
            true,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", numberToWithdraw);

        assert(checkData.offerer == address(0));
    }

    function test__fuzz__withdrawOffer__sync__PF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint16 nonceMNS_withdraw,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed,
        uint8 numberToWithdraw
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_withdraw > 0
        );

        nonceMNS_withdraw = uint16(bound(uint256(nonceMNS_withdraw), 0, 5000));
        nonceMNS_offer = uint16(bound(uint256(nonceMNS_offer), 5006, 10000));

        nonceEVVM_offer = uint16(bound(uint256(nonceEVVM_offer), 5006, 10000));

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToWithdraw = uint8(bound(uint256(numberToWithdraw), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            uint256(amountToOffer) + uint256(priorityFee)
        );

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                numberToWithdraw,
                nonceMNS_withdraw
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priorityFee,
                0,
                evvm.getNextCurrentSyncNonce(user),
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.withdrawOffer(
            user,
            nonceMNS_withdraw,
            "test",
            numberToWithdraw,
            priorityFee,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );

        checkData = mns.getSingleOfferOfUsername("test", numberToWithdraw);

        assert(checkData.offerer == address(0));
    }

    function test__fuzz__acceptOffer__nPF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint32 nonceMNS_accept,
        uint72 amountToOffer,
        uint16 seed,
        uint8 numberToAccept
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_accept > 0
        );

        nonceMNS_accept = uint32(bound(uint256(nonceMNS_accept), 20000, 60000));
        nonceMNS_offer = uint16(bound(uint256(nonceMNS_offer), 5000, 10000));

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToAccept = uint8(bound(uint256(numberToAccept), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, uint256(amountToOffer));

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "test",
                numberToAccept,
                nonceMNS_accept
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.acceptOffer(
            USER1,
            nonceMNS_accept,
            "test",
            numberToAccept,
            0,
            signatureMNS,
            0,
            false,
            ""
        );

        (address seeUser, ) = mns.getIdentityBasicMetadata("test");

        assert(user == seeUser);
    }

    function test__fuzz__acceptOffer__async__PF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint32 nonceMNS_accept,
        uint32 nonceEVVM_accept,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed,
        uint8 numberToAccept
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_accept > 0
        );

        nonceMNS_accept = uint32(bound(uint256(nonceMNS_accept), 20000, 60000));
        nonceMNS_offer = uint16(bound(uint256(nonceMNS_offer), 5000, 10000));

        nonceEVVM_accept = uint32(
            bound(uint256(nonceEVVM_accept), 20000, 60000)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToAccept = uint8(bound(uint256(numberToAccept), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, uint256(amountToOffer));
        evvm._addBalance(USER1, MATE_TOKEN_ADDRESS, uint256(priorityFee));

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "test",
                numberToAccept,
                nonceMNS_accept
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priorityFee,
                0,
                nonceEVVM_accept,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.acceptOffer(
            USER1,
            nonceMNS_accept,
            "test",
            numberToAccept,
            priorityFee,
            signatureMNS,
            nonceEVVM_accept,
            true,
            signatureEVVM
        );

        (address seeUser, ) = mns.getIdentityBasicMetadata("test");

        assert(user == seeUser);
    }

    function test__fuzz__acceptOffer__sync__PF(
        uint16 nonceMNS_offer,
        uint16 nonceEVVM_offer,
        uint32 nonceMNS_accept,
        uint32 nonceEVVM_accept,
        uint72 amountToOffer,
        uint72 priorityFee,
        uint16 seed,
        uint8 numberToAccept
    ) external prepareUsername {
        vm.assume(
            (amountToOffer / 4) > 0 &&
                nonceMNS_offer > 0 &&
                nonceEVVM_offer > 0 &&
                nonceMNS_accept > 0
        );

        nonceMNS_accept = uint32(bound(uint256(nonceMNS_accept), 20000, 60000));
        nonceMNS_offer = uint16(bound(uint256(nonceMNS_offer), 5000, 10000));

        nonceEVVM_accept = uint32(
            bound(uint256(nonceEVVM_accept), 20000, 60000)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        amountToOffer = (amountToOffer / 4) * 4;

        numberToAccept = uint8(bound(uint256(numberToAccept), 0, 3));

        MateNameServiceMock.OfferMetadata memory checkData;

        uint256 expiration = bound(
            seed,
            4121818753, //Fri Aug 13 2100 05:39:13 GMT+0000
            9000000000
        );

        address user = expiration % 2 == 0 ? USER2 : USER3;

        uint256 userPrivateKey = user == USER2
            ? USER2_PRIVATE_KEY
            : USER3_PRIVATE_KEY;

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, uint256(amountToOffer));
        evvm._addBalance(USER1, MATE_TOKEN_ADDRESS, uint256(priorityFee));

        for (uint i = 0; i < 4; i++) {
            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForMakeOffer(
                    "test",
                    expiration,
                    amountToOffer / 4,
                    nonceMNS_offer + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                userPrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    amountToOffer / 4,
                    0,
                    nonceEVVM_offer + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.makeOffer(
                user,
                nonceMNS_offer + i,
                "test",
                amountToOffer / 4,
                expiration,
                0,
                signatureMNS,
                nonceEVVM_offer + i,
                true,
                signatureEVVM
            );

            checkData = mns.getSingleOfferOfUsername("test", i);

            assert(checkData.offerer == user);
        }

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "test",
                numberToAccept,
                nonceMNS_accept
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priorityFee,
                0,
                evvm.getNextCurrentSyncNonce(USER1),
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.acceptOffer(
            USER1,
            nonceMNS_accept,
            "test",
            numberToAccept,
            priorityFee,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(USER1),
            false,
            signatureEVVM
        );

        (address seeUser, ) = mns.getIdentityBasicMetadata("test");

        assert(user == seeUser);
    }
}
