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

import {Constants} from "test/Constants.sol";

import {SMateMock} from "mock-contracts/SMateMock.sol";
import {MateNameServiceMock} from "mock-contracts/MateNameServiceMock.sol";
import {EvvmMock} from "mock-contracts/EvvmMock.sol";
import {Erc191TestBuilder} from "@RollAMate/libraries/Erc191TestBuilder.sol";
import {EstimatorMock} from "mock-contracts/EstimatorMock.sol";
import {EvvmMockStorage} from "mock-contracts/EvvmMockStorage.sol";

contract testEVVMUnit_proxy is Test, Constants {
    /**
     * Naming Convention for Fuzz Test Functions
     * Basic Structure:
     * test__[typeOfTest]__[functionName]__[options]
     * General Rules:
     *  - Always start with "test__"
     *  - The name of the function to be executed must immediately follow "test__"
     *  - Options are added at the end, separated by underscores
     *
     * Example:
     * test__init__payNoMateStaking_sync__PF_nEX
     *
     * Example explanation:
     * Function to test: payNoMateStaking_sync
     * PF: Includes priority fee
     * nEX: Does not include executor execution
     *
     * Notes:
     * Separate different parts of the name with double underscores (__)
     *
     * For this unit test two users execute 2 pay transactions before and
     * after the update, so insetad of the name of the function proxy we
     * going to use TxAndUseProxy to make the test more readable and
     * understandable
     *
     * Options fot this test:
     * - xU: Evvm updates x number of times
     */

    SMateMock sMate;
    EvvmMock evvm;
    EstimatorMock estimator;

    ExtraFunctionsV1 v1;
    address addressV1;

    ExtraFunctionsV2 v2;
    address addressV2;

    ExtraFunctionsV3 v3;
    address addressV3;

    CounterDummy counter;
    address addressCounter;

    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));

    function setUp() public {
        sMate = new SMateMock(ADMIN.Address);
        evvm = EvvmMock(sMate.getEvvmAddress());
        estimator = EstimatorMock(sMate.getEstimatorAddress());

        v1 = new ExtraFunctionsV1();
        addressV1 = address(v1);

        v2 = new ExtraFunctionsV2();
        addressV2 = address(v2);

        counter = new CounterDummy();
        addressCounter = address(counter);
        v3 = new ExtraFunctionsV3(address(addressCounter));
        addressV3 = address(v3);

        vm.stopPrank();
    }

    function makePayment(
        bool giveTokensForPayment,
        AccountData memory userToInteract,
        address addressTo,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee
    ) internal {
        if (giveTokensForPayment) {
            evvm._addBalance(
                userToInteract.Address,
                tokenAddress,
                amount + priorityFee
            );
        }
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            userToInteract.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                addressTo,
                "",
                tokenAddress,
                amount,
                priorityFee,
                evvm.getNextCurrentSyncNonce(userToInteract.Address),
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
            userToInteract.Address,
            addressTo,
            "",
            tokenAddress,
            amount,
            priorityFee,
            address(0),
            signatureEVVM
        );
    }

    function updateImplementation(address newImplementation) internal {
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(newImplementation);
        skip(30 days);
        evvm.acceptImplementation();
        vm.stopPrank();
    }

    function test__fuzz__acceptImplementation(uint256 time) public {
        vm.assume(time >= 30 days);
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(addressV1);
        skip(time);
        evvm.acceptImplementation();
        vm.stopPrank();

        assertEq(evvm.getCurrentImplementation(), addressV1);
        assertEq(evvm.getProposalImplementation(), address(0));
        assertEq(evvm.getTimeToAcceptImplementation(), 0);
    }

    function test__fuzz__rejectUpgrade(uint256 time) public {
        vm.assume(time < 30 days);
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(addressV1);
        skip(time);
        evvm.rejectUpgrade();
        vm.stopPrank();

        assertEq(evvm.getCurrentImplementation(), address(0));
        assertEq(evvm.getProposalImplementation(), address(0));
        assertEq(evvm.getTimeToAcceptImplementation(), 0);
    }

    /// @notice because we tested in others init thes the pay
    ///         with no implementation we begin with 1 update
    function test__fuzz__TxAndUseProxy__1U(
        uint48 amount,
        bool giveEthForPayment
    ) public {
        vm.assume(amount >= 1000);

        uint256 amountUser1 = 200;
        uint256 amountUser2 = uint256(amount) - 200;

        makePayment(
            true,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            uint256(amount),
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            200,
            0
        );

        updateImplementation(addressV1);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = amountUser1 - 100;

        IExtraFunctionsV1(address(evvm)).burnToken(
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 100;
        amountUser2 = amountUser2 + amountUser1;

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            amountUser1,
            0
        );

        makePayment(
            true,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );
    }

    function test__fuzz__TxAndUseProxy__2U(
        uint48 amount,
        bool giveEthForPayment
    ) public {
        vm.assume(amount >= 1000);

        uint256 amountUser1 = 200;
        uint256 amountUser2 = uint256(amount) - 200;

        makePayment(
            true,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            uint256(amount),
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            200,
            0
        );

        updateImplementation(addressV1);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = amountUser1 - 100;

        IExtraFunctionsV1(address(evvm)).burnToken(
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 100;
        amountUser2 = amountUser2 + amountUser1;

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            amountUser1,
            0
        );

        makePayment(
            true,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        updateImplementation(addressV2);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        IExtraFunctionsV2(address(evvm)).fullTransfer(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
        );

        amountUser1 = 0;
        amountUser2 += 100;

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 50;
        amountUser2 -= 50;

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            50,
            0
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );
    }

    function test__fuzz__TxAndUseProxy__3U(
        uint48 amount,
        bool giveEthForPayment
    ) public {
        vm.assume(amount >= 1000);

        uint256 amountUser1 = 200;
        uint256 amountUser2 = uint256(amount) - 200;

        makePayment(
            true,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            uint256(amount),
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            200,
            0
        );

        updateImplementation(addressV1);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = amountUser1 - 100;

        IExtraFunctionsV1(address(evvm)).burnToken(
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 100;
        amountUser2 = amountUser2 + amountUser1;

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            amountUser1,
            0
        );

        makePayment(
            true,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        updateImplementation(addressV2);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        IExtraFunctionsV2(address(evvm)).fullTransfer(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
        );

        amountUser1 = 0;
        amountUser2 += 100;

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 50;
        amountUser2 -= 50;

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            50,
            0
        );

        updateImplementation(addressV3);

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );

        amountUser1 = 0;

        IExtraFunctionsV3(address(evvm)).burnToken(
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            50
        );

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );

        assertEq(IExtraFunctionsV3(address(evvm)).getCounter(), 1);

        makePayment(
            false,
            COMMON_USER_NO_STAKER_2,
            COMMON_USER_NO_STAKER_1.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            500,
            0
        );

        makePayment(
            false,
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS,
            100,
            0
        );

        amountUser1 = 400;
        amountUser2 -= 400;

        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_1.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser1
        );
        assertEq(
            evvm.seeBalance(
                COMMON_USER_NO_STAKER_2.Address,
                giveEthForPayment ? ETHER_ADDRESS : MATE_TOKEN_ADDRESS
            ),
            amountUser2
        );
    }
}

interface IExtraFunctionsV1 {
    function burnToken(address user, address token, uint256 amount) external;
}

contract ExtraFunctionsV1 is EvvmMockStorage {
    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;
    }
}

interface IExtraFunctionsV2 {
    function burnToken(address user, address token, uint256 amount) external;

    function fullTransfer(address from, address to, address token) external;
}

contract ExtraFunctionsV2 is EvvmMockStorage {
    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;
    }

    function fullTransfer(address from, address to, address token) external {
        balances[to][token] += balances[from][token];
        balances[from][token] -= balances[from][token];
    }
}

interface IExtraFunctionsV3 {
    function burnToken(address user, address token, uint256 amount) external;

    function getCounter() external view returns (uint256);
}

// Primero definimos la interfaz
interface ICounter {
    function increment() external;

    function getCounter() external view returns (uint256);
}

contract ExtraFunctionsV3 is EvvmMockStorage {
    address public immutable counterAddress;

    /*
    Interfaces ✅
    - Genera CALL opcode -> Mantiene storage contexts separados
    - ABI encoding/decoding correcto y validado
    - Type safety en tiempo de compilación
    - Función selector validation automática
    - Memory layout predecible
    - Proper external call stack management
    - Previene storage slot collisions
    - Mantiene el scope de variables correcto

    Type Casting Directo ❌
    - Puede resultar en DELEGATECALL no intencionado
    - Storage slot collisions por compartir contexto
    - Memory corruption risks por layout incorrecto
    - Bypasses compiler type checks
    - Función selector matching impredecible
    - Stack manipulation riesgosa
    - Storage layout conflicts
    - State variable shadowing
    
     */

    constructor(address _counterAddress) {
        counterAddress = _counterAddress;
    }

    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;
        /* Usamos la interfaz y call en lugar de delegatecall
        (bool success,) = counterAddress.call(
            abi.encodeWithSignature("increment()")
        );
        if (!success) {
            revert();
        }*/

        ICounter(counterAddress).increment();
    }

    function getCounter() external view returns (uint256) {
        // Usamos la interfaz para la llamada
        (bool success, bytes memory data) = counterAddress.staticcall(
            abi.encodeWithSignature("getCounter()")
        );
        if (!success) {
            revert();
        }
        return abi.decode(data, (uint256));
    }
}

contract CounterDummy {
    uint256 counterNum;

    function increment() external {
        counterNum++;
    }

    function getCounter() external view returns (uint256) {
        return counterNum;
    }
}
