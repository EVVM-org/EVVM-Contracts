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

contract testEVVMFuzz_disperseCaPay is Test {
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
    function test__fuzz__disperseCaPay__noSMate(uint256 amountToSend) external {
        amountToSend = (bound(amountToSend, 100, 99 * 10 ** 30) / 2) * 2;

        evvm._addBalance(address(this), ETHER_ADDRESS, amountToSend);

        EvvmMockStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmMockStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmMockStructs.DisperseCaPayMetadata({
            amount: amountToSend / 2,
            toAddress: USER3
        });

        toData[1] = EvvmMockStructs.DisperseCaPayMetadata({
            amount: amountToSend / 2,
            toAddress: USER5
        });

        uint256 amountEthUser3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountEthUser5Before = evvm.seeBalance(USER5, ETHER_ADDRESS);

        evvm.disperseCaPay(toData, ETHER_ADDRESS, amountToSend);

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountEthUser3Before + (amountToSend / 2)
        );

        assertEq(
            evvm.seeBalance(USER5, ETHER_ADDRESS),
            amountEthUser5Before + (amountToSend / 2)
        );
    }

    function test__fuzz__disperseCaPay__SMate(uint256 amountToSend) external {
        amountToSend = (bound(amountToSend, 100, 99 * 10 ** 30) / 2) * 2;

        evvm._addBalance(address(this), ETHER_ADDRESS, amountToSend);
        evvm._setPointStaker(address(this), 0x01);

        EvvmMockStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmMockStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmMockStructs.DisperseCaPayMetadata({
            amount: amountToSend / 2,
            toAddress: USER3
        });

        toData[1] = EvvmMockStructs.DisperseCaPayMetadata({
            amount: amountToSend / 2,
            toAddress: USER5
        });

        uint256 amountEthUser3Before = evvm.seeBalance(USER3, ETHER_ADDRESS);
        uint256 amountEthUser5Before = evvm.seeBalance(USER5, ETHER_ADDRESS);
        uint256 amountCaMateBefore = evvm.seeBalance(
            address(this),
            MATE_TOKEN_ADDRESS
        );

        evvm.disperseCaPay(toData, ETHER_ADDRESS, amountToSend);

        assertEq(
            evvm.seeBalance(USER3, ETHER_ADDRESS),
            amountEthUser3Before + (amountToSend / 2)
        );

        assertEq(
            evvm.seeBalance(USER5, ETHER_ADDRESS),
            amountEthUser5Before + (amountToSend / 2)
        );

        assertEq(
            evvm.seeBalance(address(this), MATE_TOKEN_ADDRESS),
            amountCaMateBefore + evvm.seeMateReward()
        );
    }
}
