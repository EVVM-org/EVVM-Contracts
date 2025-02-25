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

contract testMateNameServiceFuzz_removeCustomMetadata is Test {
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

    modifier prepareUsernameAndCustomMetadata(uint256 seed) {
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            ((10 * evvm.seeMateReward()) * 11) + (100 * (evvm.seeMateReward()))
        );

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

        string memory customMetadata;

        for (uint i = 0; i < 10; i++) {
            customMetadata = getARandomCustomMetadata(seed + i);

            (v, r, s) = vm.sign(
                USER1_PRIVATE_KEY,
                Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                    "test",
                    customMetadata,
                    888 + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

            (v, r, s) = vm.sign(
                USER1_PRIVATE_KEY,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    10 * evvm.seeMateReward(),
                    0,
                    888 + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

            mns.addCustomMetadata(
                USER1,
                888 + i,
                "test",
                customMetadata,
                0,
                signatureMNS,
                888 + i,
                true,
                signatureEVVM
            );

            string memory seeCustomMetadata = mns
                .getSingleCustomMetadataOfIdentity("test", i);

            assertEq(
                bytes(seeCustomMetadata).length,
                bytes(customMetadata).length
            );

            assertEq(
                keccak256(bytes(seeCustomMetadata)),
                keccak256(bytes(customMetadata))
            );
        }
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

    function test__fuzz__removeCustomMetadata__async__nPF(
        uint16 nonceMNS,
        uint16 nonceEVVM,
        uint16 seed
    ) external prepareUsernameAndCustomMetadata(seed) {
        nonceMNS = uint16(bound(nonceMNS, 1000, type(uint16).max - 10));
        nonceEVVM = uint16(bound(nonceEVVM, 1000, type(uint16).max - 10));
        uint8 indexToDelete = uint8(bound(seed, 0, 9));

        vm.assume(nonceMNS != nonceEVVM);

        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            mns.getPriceToRemoveCustomMetadata()
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                indexToDelete,
                nonceMNS
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.getPriceToRemoveCustomMetadata(),
                0,
                nonceEVVM,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        string memory beforePontIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete + 1);

        mns.removeCustomMetadata(
            USER1,
            nonceMNS,
            "test",
            indexToDelete,
            0,
            signatureMNS,
            nonceEVVM,
            true,
            signatureEVVM
        );

        string memory afterDeleteIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete);

        assertEq(
            bytes(afterDeleteIndexCustomMetadata).length,
            bytes(beforePontIndexCustomMetadata).length
        );
        assertEq(
            keccak256(bytes(afterDeleteIndexCustomMetadata)),
            keccak256(bytes(beforePontIndexCustomMetadata))
        );
    }

    function test__fuzz__removeCustomMetadata__sync__nPF(
        uint16 nonceMNS,
        uint16 seed
    ) external prepareUsernameAndCustomMetadata(seed) {
        nonceMNS = uint16(bound(nonceMNS, 1000, type(uint16).max - 10));
        uint8 indexToDelete = uint8(bound(seed, 0, 9));

        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            mns.getPriceToRemoveCustomMetadata()
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                indexToDelete,
                nonceMNS
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.getPriceToRemoveCustomMetadata(),
                0,
                evvm.getNextCurrentSyncNonce(USER1),
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        string memory beforePontIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete + 1);

        mns.removeCustomMetadata(
            USER1,
            nonceMNS,
            "test",
            indexToDelete,
            0,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(USER1),
            false,
            signatureEVVM
        );

        string memory afterDeleteIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete);

        assertEq(
            bytes(afterDeleteIndexCustomMetadata).length,
            bytes(beforePontIndexCustomMetadata).length
        );
        assertEq(
            keccak256(bytes(afterDeleteIndexCustomMetadata)),
            keccak256(bytes(beforePontIndexCustomMetadata))
        );
    }

    function test__fuzz__removeCustomMetadata__async__PF(
        uint16 nonceMNS,
        uint16 nonceEVVM,
        uint16 priorityFee,
        uint16 seed
    ) external prepareUsernameAndCustomMetadata(seed) {
        nonceMNS = uint16(bound(nonceMNS, 1000, type(uint16).max - 10));
        nonceEVVM = uint16(bound(nonceEVVM, 1000, type(uint16).max - 10));
        uint8 indexToDelete = uint8(bound(seed, 0, 9));

        vm.assume(nonceMNS != nonceEVVM);

        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            mns.getPriceToRemoveCustomMetadata() + uint256(priorityFee)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                indexToDelete,
                nonceMNS
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.getPriceToRemoveCustomMetadata(),
                priorityFee,
                nonceEVVM,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        string memory beforePontIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete + 1);

        mns.removeCustomMetadata(
            USER1,
            nonceMNS,
            "test",
            indexToDelete,
            priorityFee,
            signatureMNS,
            nonceEVVM,
            true,
            signatureEVVM
        );

        string memory afterDeleteIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete);

        assertEq(
            bytes(afterDeleteIndexCustomMetadata).length,
            bytes(beforePontIndexCustomMetadata).length
        );
        assertEq(
            keccak256(bytes(afterDeleteIndexCustomMetadata)),
            keccak256(bytes(beforePontIndexCustomMetadata))
        );
    }

    function test__fuzz__removeCustomMetadata__sync__PF(
        uint16 nonceMNS,
        uint16 priorityFee,
        uint16 seed
    ) external prepareUsernameAndCustomMetadata(seed) {
        nonceMNS = uint16(bound(nonceMNS, 1000, type(uint16).max - 10));
        uint8 indexToDelete = uint8(bound(seed, 0, 9));

        evvm._addBalance(
            USER1,
            MATE_TOKEN_ADDRESS,
            mns.getPriceToRemoveCustomMetadata() + uint256(priorityFee)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                indexToDelete,
                nonceMNS
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.getPriceToRemoveCustomMetadata(),
                priorityFee,
                evvm.getNextCurrentSyncNonce(USER1),
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        string memory beforePontIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete + 1);

        mns.removeCustomMetadata(
            USER1,
            nonceMNS,
            "test",
            indexToDelete,
            priorityFee,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(USER1),
            false,
            signatureEVVM
        );

        string memory afterDeleteIndexCustomMetadata = mns
            .getSingleCustomMetadataOfIdentity("test", indexToDelete);

        assertEq(
            bytes(afterDeleteIndexCustomMetadata).length,
            bytes(beforePontIndexCustomMetadata).length
        );
        assertEq(
            keccak256(bytes(afterDeleteIndexCustomMetadata)),
            keccak256(bytes(beforePontIndexCustomMetadata))
        );
    }

    function getARandomCustomMetadata(
        uint256 seed
    ) internal view returns (string memory customMetadata) {
        for (uint i = 0; i < 10; i++) {
            customMetadata = string(
                abi.encodePacked(
                    customMetadata,
                    Strings.toString(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    customMetadata,
                                    seed,
                                    block.timestamp
                                )
                            )
                        ) % 10
                    )
                )
            );
        }
    }
}
