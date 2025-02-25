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

contract testMateNameServiceFuzz_preAndRegistrationUsername is Test {
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

    function test__fuzz__preRegistrationUsername__nPF(
        uint8 nonceMNS,
        uint16 clowNumber,
        uint16 seed
    ) external {
        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        vm.assume((seed / 2) >= 4);
        string memory username = makeUsername(seed);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceMNS
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.preRegistrationUsername(
            user,
            nonceMNS,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);
        console2.log("---|verifided|---");
    }

    function test__fuzz__preRegistrationUsername__asyncPF(
        uint8 nonceMNS,
        uint8 nonceEVVM,
        uint16 seed,
        uint16 clowNumber,
        uint72 priorityFee
    ) external {
        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        vm.assume((seed / 2) >= 4);
        string memory username = makeUsername(seed);

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
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
                priorityFee,
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

        mns.preRegistrationUsername(
            user,
            nonceMNS,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            priorityFee,
            signatureMNS,
            nonceEVVM,
            true,
            signatureEVVM
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);
        console2.log("---|verifided|---");
    }

    function test__fuzz__preRegistrationUsername__syncPF(
        uint8 nonceMNS,
        uint16 seed,
        uint16 clowNumber,
        uint72 priorityFee
    ) external {
        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        vm.assume((seed / 2) >= 4);
        string memory username = makeUsername(seed);

        evvm._addBalance(user, MATE_TOKEN_ADDRESS, priorityFee);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
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
                priorityFee,
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

        mns.preRegistrationUsername(
            user,
            nonceMNS,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            priorityFee,
            signatureMNS,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);
        console2.log("---|verifided|---");
    }

    function test_registrationUsername__async__nPF(
        uint16 nonceMNS_preRegistration,
        uint16 nonceMNS_registration,
        uint16 nonceEVVM,
        uint16 clowNumber,
        uint16 seed
    ) external {
        vm.assume((seed / 2) >= 4);
        vm.assume(nonceMNS_preRegistration != nonceMNS_registration);

        string memory username = makeUsername(seed);

        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            100 * (evvm.seeMateReward())
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceMNS_preRegistration
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.preRegistrationUsername(
            user,
            nonceMNS_preRegistration,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);

        vm.warp(block.timestamp + 40 minutes);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                username,
                clowNumber,
                nonceMNS_registration
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
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

        mns.registrationUsername(
            user,
            nonceMNS_registration,
            username,
            clowNumber,
            signatureMNS,
            0,
            nonceEVVM,
            true,
            signatureEVVM
        );

        (seeUser, ) = mns.getIdentityBasicMetadata(username);

        assert(user == seeUser);
    }

    function test_registrationUsername__sync__nPF(
        uint16 nonceMNS_preRegistration,
        uint16 nonceMNS_registration,
        uint16 clowNumber,
        uint16 seed
    ) external {
        vm.assume((seed / 2) >= 4);
        vm.assume(nonceMNS_preRegistration != nonceMNS_registration);

        string memory username = makeUsername(seed);

        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            100 * (evvm.seeMateReward())
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceMNS_preRegistration
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.preRegistrationUsername(
            user,
            nonceMNS_preRegistration,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);

        vm.warp(block.timestamp + 40 minutes);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                username,
                clowNumber,
                nonceMNS_registration
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
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

        mns.registrationUsername(
            user,
            nonceMNS_registration,
            username,
            clowNumber,
            signatureMNS,
            0,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );

        (seeUser, ) = mns.getIdentityBasicMetadata(username);

        assert(user == seeUser);
    }

    function test_registrationUsername__async__PF(
        uint16 nonceMNS_preRegistration,
        uint16 nonceMNS_registration,
        uint16 nonceEVVM,
        uint16 clowNumber,
        uint72 priorityFee,
        uint16 seed
    ) external {
        vm.assume((seed / 2) >= 4);
        vm.assume(nonceMNS_preRegistration != nonceMNS_registration);

        string memory username = makeUsername(seed);

        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            100 * (evvm.seeMateReward()) + priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceMNS_preRegistration
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.preRegistrationUsername(
            user,
            nonceMNS_preRegistration,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);

        vm.warp(block.timestamp + 40 minutes);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                username,
                clowNumber,
                nonceMNS_registration
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
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

        mns.registrationUsername(
            user,
            nonceMNS_registration,
            username,
            clowNumber,
            signatureMNS,
            priorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        (seeUser, ) = mns.getIdentityBasicMetadata(username);

        assert(user == seeUser);
    }

    function test_registrationUsername__sync__PF(
        uint16 nonceMNS_preRegistration,
        uint16 nonceMNS_registration,
        uint16 clowNumber,
        uint72 priorityFee,
        uint16 seed
    ) external {
        vm.assume((seed / 2) >= 4);
        vm.assume(nonceMNS_preRegistration != nonceMNS_registration);

        string memory username = makeUsername(seed);

        address user = seed % 2 == 0 ? USER1 : USER2;
        uint256 userPrivateKey = user == USER1
            ? USER1_PRIVATE_KEY
            : USER2_PRIVATE_KEY;

        evvm._addBalance(
            user,
            MATE_TOKEN_ADDRESS,
            100 * (evvm.seeMateReward()) + priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceMNS_preRegistration
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        mns.preRegistrationUsername(
            user,
            nonceMNS_preRegistration,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
        (address seeUser, ) = mns.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );
        assert(user == seeUser);

        vm.warp(block.timestamp + 40 minutes);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                username,
                clowNumber,
                nonceMNS_registration
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            userPrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
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

        mns.registrationUsername(
            user,
            nonceMNS_registration,
            username,
            clowNumber,
            signatureMNS,
            priorityFee,
            evvm.getNextCurrentSyncNonce(user),
            false,
            signatureEVVM
        );

        (seeUser, ) = mns.getIdentityBasicMetadata(username);

        assert(user == seeUser);
    }

    function makeUsername(
        uint16 seed
    ) private pure returns (string memory username) {
        /// creas un nombre de usuario aleatorio de seed/2 caracteres
        /// este debe ser de la A-Z y a-z
        bytes memory usernameBytes = new bytes(seed / 2);
        for (uint256 i = 0; i < seed / 2; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(seed, i))) % 52;
            if (random < 26) {
                usernameBytes[i] = bytes1(uint8(random + 65));
            } else {
                usernameBytes[i] = bytes1(uint8(random + 71));
            }
        }
        username = string(usernameBytes);
    }
}
