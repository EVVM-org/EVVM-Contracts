// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function revert behavior
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
import {AdvancedStrings} from "@RollAMate/libraries/AdvancedStrings.sol";

contract unitTestRevert_MateNameService_ is
    Test,
    Constants
{
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

    

    function addBalance(
        address user,
        address token,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm._addBalance(user, token, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function makePreRegistrationUsernameSignature(
        string memory username,
        uint256 clowNumber,
        uint256 nonceMNS,
        bool givePriorityFee,
        uint256 priorityFeeAmount,
        uint256 nonceEVVM,
        bool priorityEVVM
    )
        private
        view
        returns (bytes memory signatureMNS, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (givePriorityFee) {
            (v, r, s) = vm.sign(
                COMMON_USER_NO_STAKER_1.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                    keccak256(abi.encodePacked(username, uint256(clowNumber))),
                    nonceMNS
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
            (v, r, s) = vm.sign(
                COMMON_USER_NO_STAKER_1.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    priorityFeeAmount,
                    0,
                    nonceEVVM,
                    priorityEVVM,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        } else {
            (v, r, s) = vm.sign(
                COMMON_USER_NO_STAKER_1.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                    keccak256(abi.encodePacked(username, uint256(clowNumber))),
                    nonceMNS
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
            signatureEVVM = "";
        }
    }

    /**
     * Function to test: 
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */
    
    /*
    function test__unitRevert__preRegistrationUsername__diferentSignature_user()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked("test", uint256(777))),
                10
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
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
    }

    function test__unitRevert__preRegistrationUsername__diferentSignature_nonce()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked("test", uint256(777))),
                100
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
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
    }

    function test__unitRevert__preRegistrationUsername__diferentSignature_usernameHash()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked("test", uint256(707))),
                10
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
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
    }

    function test__unitRevert__preRegistrationUsername_signature_MnsNonceUsed()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;

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

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                keccak256(abi.encodePacked("nulluser", uint256(777))),
                10
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.preRegistrationUsername(
            USER1,
            10,
            keccak256(abi.encodePacked("nulluser", uint256(777))),
            0,
            signatureMNS,
            0,
            false,
            hex""
        );
    }

    function test__unitRevert__registrationUsername_diferentUser()
        external
        setPreRegistrationUsername //test
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER2,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername_diferentUsername()
        external
        setPreRegistrationUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "fail",
                777,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER2,
            10001,
            "fail",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername_diferentClowNumber()
        external
        setPreRegistrationUsername //test
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                555,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            555,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername_sameMnsNonceUsed()
        external
        setPreRegistrationUsername //test
        setPreRegistrationUsernameTwo //second
    {
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                10001
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
                10001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );

        (user, ) = mns.getIdentityBasicMetadata("test");

        assert(user == USER1);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "second",
                777,
                10001
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
                20002,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "second",
            777,
            signatureMNS,
            0,
            20002,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername__diferentSignature_user()
        external
        setPreRegistrationUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername__diferentSignature_username()
        external
        setPreRegistrationUsername //test
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "fail",
                777,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername__diferentSignature_clowNumber()
        external
        setPreRegistrationUsername //test
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                555,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername__diferentSignature_MNS_nonce()
        external
        setPreRegistrationUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                10201
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                100 * (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__registrationUsername_diferentPayment()
        external
        setPreRegistrationUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        console2.log("time travel from: ", block.timestamp);
        vm.warp(block.timestamp + 40 minutes);
        console2.log("to: ", block.timestamp);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                "test",
                777,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                (evvm.seeMateReward()),
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.registrationUsername(
            USER1,
            10001,
            "test",
            777,
            signatureMNS,
            0,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_nonExistentUsername()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "fake",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.0001 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "fake",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_MnsNonceUsed()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.0001 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
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
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.0001 ether,
                10001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                20002,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            20002,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_nonExistentAmount()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_expireDate() external prepareUsername {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                block.timestamp,
                0.0001 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            block.timestamp,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer__diferentSignature_user()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.0001 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_diferentExpirationDate()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST + 500,
                0.0001 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_diferentAmount()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.00000009 ether,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__makeOffer_diferentMnsNonce()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                "test",
                EXPIRATION_DATE_DEFAULT_FOR_TEST,
                0.0001 ether,
                10201
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                0.0001 ether,
                0,
                10001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.makeOffer(
            USER2,
            10001,
            "test",
            0.0001 ether,
            EXPIRATION_DATE_DEFAULT_FOR_TEST,
            0,
            signatureMNS,
            10001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__withdrawOffer_diferentUser()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER3,
            10001,
            "test",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer_usernameHasNoOffer()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "dummy",
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "dummy",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer_MnsNonceUsed()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                0,
                111000111
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10,
            "test",
            0,
            111000111,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer_diferentSlot()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                1,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "test",
            1,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer__diferentSignature_user()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER3_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "test",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer__diferentSignature_username()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "fail",
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "test",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer__diferentSignature_slot()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                1,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "test",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__withdrawOffer__diferentSignature_MnsNonce()
        external
        prepareUsernameAndOffer
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                "test",
                0,
                10501
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.withdrawOffer(
            USER2,
            10001,
            "test",
            0,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__acceptOffer__diferentUser()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer("test", 0, 10001)
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER2, 10001, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__mnsNonceUsed()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer("test", 0, 10)
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__nonExistentUsername()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer("fail", 0, 10001)
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10001, "fail", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__nonExistentSlot()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "test",
                888,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(
            USER1,
            10001,
            "test",
            888,
            0,
            signatureMNS,
            0,
            false,
            ""
        );
    }

    function test__unitRevert__acceptOffer__diferentSignature_user()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer("test", 0, 10001)
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10001, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__diferentSignature_username()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "testfail",
                0,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10001, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__diferentSignature_slot()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                "test",
                888,
                10001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10001, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__acceptOffer__diferentSignature_mnsNonce()
        external
        prepareUsernameAndOffer
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer("test", 0, 10801)
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.acceptOffer(USER1, 10001, "test", 0, 0, signatureMNS, 0, false, "");
    }

    function test__unitRevert__renewUsername_wrongUser()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "test",
                4294423320
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                7000000000000,
                0,
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER2,
            4294423320,
            "test",
            7000000000000,
            signatureMNS,
            0,
            false,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__nonceMnsAlreadyUse()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername("test", 10)
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                7000000000000,
                0,
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            10,
            "test",
            7000000000000,
            signatureMNS,
            0,
            false,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__wrongUsername()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "testfail",
                4294423320
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("testfail"),
                7000000000000,
                0,
                false,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            4294423320,
            "testfail",
            7000000000000,
            signatureMNS,
            0,
            false,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__signatureWrongUser()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "test",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                7000000000000,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            100010001,
            "test",
            7000000000000,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__signatureWrongUsername()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "test1",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                7000000000000,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            100010001,
            "test",
            7000000000000,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__signature_wrongNonce()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "test",
                100010001000
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                7000000000000,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            100010001,
            "test",
            7000000000000,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__renewUsername__limit() external prepareUsername {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;

        for (uint256 i = 0; i < 99; i++) {
            //console2.log("renewing username iteration #", i);
            (v, r, s) = vm.sign(
                USER1_PRIVATE_KEY,
                Erc191TestBuilder.buildMessageSignedForRenewUsername(
                    "test",
                    100010001000 + i
                )
            );
            signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
            //console2.logBytes(signatureMNS);

            (v, r, s) = vm.sign(
                USER1_PRIVATE_KEY,
                Erc191TestBuilder.buildMessageSignedForPay(
                    address(mns),
                    "",
                    MATE_TOKEN_ADDRESS,
                    mns.seePriceToRenew("test"),
                    0,
                    100010001000 + i,
                    true,
                    address(mns)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
            //console2.logBytes(signatureEVVM);

            mns.renewUsername(
                USER1,
                100010001000 + i,
                "test",
                0,
                signatureMNS,
                100010001000 + i,
                true,
                signatureEVVM
            );
        }

        //console2.log("renewing username iteration #100 (revert expected)");
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                "test",
                100010001000 + 100
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);
        //console2.logBytes(signatureMNS);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                mns.seePriceToRenew("test"),
                0,
                100010001000 + 100,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        //console2.logBytes(signatureEVVM);

        vm.expectRevert();
        mns.renewUsername(
            USER1,
            100010001000 + 100,
            "test",
            0,
            signatureMNS,
            100010001000 + 100,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata_wrongUser()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "test>done",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER2,
            1000001,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__mnsNonceUsed()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "test>done",
                10
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            10,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__identityNonExistent()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "testfail",
                "test>done",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "testfail",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__valueNoAdded()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "test",
            "",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__diferentSignature_user()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "test>done",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__diferentSignature_username()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test111",
                "test>done",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__diferentSignature_value()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "test>bad",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__addCustomMetadata__diferentSignature_mnsNonce()
        external
        prepareUsername
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                "test",
                "test>done",
                1000001888
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.addCustomMetadata(
            USER1,
            1000001,
            "test",
            "test>done",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata_diferentUser()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                1,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER2,
            100010001,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata_mnsNonceUsed()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                1,
                10
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            10,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata_identityNonExistent()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "testfail",
                1,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "testfail",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata_keyOutOfBounds()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                1000,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "test",
            1000,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata__diferentSignature_user()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                1,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata__diferentSignature_username()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "testfail",
                1,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata__diferentSignature_id()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                5,
                100010001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__removeCustomMetadata__diferentSignature_mnsNonce()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                "test",
                1,
                800080008
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                10 * evvm.seeMateReward(),
                0,
                100010001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );
        vm.expectRevert();
        mns.removeCustomMetadata(
            USER1,
            100010001,
            "test",
            1,
            0,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata_diferent_user()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "test"
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "test",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER2,
            1000001,
            "test",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata_mnsNonceUsed()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "test"
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "test",
                10
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER1,
            10,
            "test",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata_identityNonExistent()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "testfail"
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "testfail",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER1,
            1000001,
            "testfail",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata__diferentSignature_user()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "test"
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "test",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER1,
            1000001,
            "test",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata__diferentSignature_mnsNonce()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "test"
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "test",
                10000010008
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER1,
            1000001,
            "test",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushCustomMetadata__diferentSignature_identity()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 priceFlushCustomMetadata = mns.getPriceToFlushCustomMetadata(
            "test"
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                "testfail",
                1000001
            )
        );
        bytes memory signatureMNS = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushCustomMetadata,
                0,
                1000001,
                true,
                address(mns)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.expectRevert();
        mns.flushCustomMetadata(
            USER1,
            1000001,
            "test",
            0,
            signatureMNS,
            1000001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername_diferentUser()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "test",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER2,
            "test",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername_identityNonExistent()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "testfail",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "testfail",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername_mns_used()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername("test", 10)
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "test",
            0,
            10,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername__diferentSignature_user()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "test",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER2_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "test",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername__diferentSignature_identity()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "testfail",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "test",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    function test__unitRevert__flushUsername__diferentSignature_mnsNonce()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "test",
                1000100010008
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "test",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }

    /*
    function test__unitRevert__flushUsername_signature_()
        external
        prepareUsernameWith10CustomMetadata
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureMNS;
        bytes memory signatureEVVM;
        uint256 priceFlushName = mns.getPriceToFlushUsername("test");

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                "test",
                100010001
            )
        );
        signatureMNS = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            USER1_PRIVATE_KEY,
            Erc191TestBuilder.buildMessageSignedForPay(
                address(mns),
                "",
                MATE_TOKEN_ADDRESS,
                priceFlushName,
                0,
                100010001,
                true,
                address(mns)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.expectRevert();
        mns.flushUsername(
            USER1,
            "test",
            0,
            100010001,
            signatureMNS,
            100010001,
            true,
            signatureEVVM
        );
    }
    */
   /*
    function test__unitRevert__changeOwner_nonOwner()
        external
        prepareUsernameAndOffer
    {
        vm.startPrank(USER1);
        vm.expectRevert();
        mns.changeOwner(USER1);
        vm.stopPrank();
    }

    function test__unitRevert__changeOwner_address0()
        external
        prepareUsernameAndOffer
    {
        vm.startPrank(USER2);
        vm.expectRevert();
        mns.changeOwner(address(0));
        vm.stopPrank();
    }

    function test__unitRevert__cancelChangeOwner_nonOwner()
        external
        prepareUsernameAndOffer
    {
        vm.startPrank(USER2);
        mns.changeOwner(USER1);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.cancelChangeOwner();
        vm.stopPrank();
    }

    function test__unitRevert__claimOwner_nonNewOwner()
        external
        prepareUsernameAndOffer
    {
        vm.startPrank(USER2);
        mns.changeOwner(USER1);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(USER2);
        vm.expectRevert();
        mns.claimOwner();
        vm.stopPrank();
    }

    function test__unitRevert__claimOwner_dateToClaim()
        external
        prepareUsernameAndOffer
    {
        vm.startPrank(USER2);
        mns.changeOwner(USER1);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.claimOwner();
        vm.stopPrank();
    }

    function test__unitRevert__prepareWithdrawMateTokens_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER1);
        vm.expectRevert();
        mns.prepareWithdrawMateTokens(10);
        vm.stopPrank();
    }

    function test__unitRevert__prepareWithdrawMateTokens_amount0()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        vm.expectRevert();
        mns.prepareWithdrawMateTokens(0);
        vm.stopPrank();
    }

    function test__unitRevert__prepareWithdrawMateTokens_amountMoreThanExpected()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        vm.expectRevert();
        mns.prepareWithdrawMateTokens(9550 ether);
        vm.stopPrank();
    }

    function test__unitRevert__cancelWithdrawMateTokens_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.prepareWithdrawMateTokens(10);
        vm.stopPrank();

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.cancelWithdrawMateTokens();
        vm.stopPrank();
    }

    function test__unitRevert__claimWithdrawMateTokens_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.prepareWithdrawMateTokens(10);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.claimWithdrawMateTokens();
        vm.stopPrank();
    }

    function test__unitRevert__claimWithdrawMateTokens_dateToClaim()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.prepareWithdrawMateTokens(10);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(USER2);
        vm.expectRevert();
        mns.claimWithdrawMateTokens();
        vm.stopPrank();
    }

    function test__unitRevert__changeEvvmAddress_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER1);
        vm.expectRevert();
        mns.changeEvvmAddress(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        vm.stopPrank();
    }

    function test__unitRevert__changeEvvmAddress_address_0()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        vm.expectRevert();
        mns.changeEvvmAddress(address(0));
        vm.stopPrank();
    }

    function test__unitRevert__cancelChangeEvvmAddress_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.changeEvvmAddress(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        vm.stopPrank();

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.cancelChangeEvvmAddress();
        vm.stopPrank();
    }

    function test__unitRevert__makeChangeEvvmAddress_nonOwner()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.changeEvvmAddress(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(USER1);
        vm.expectRevert();
        mns.cancelChangeEvvmAddress();
        vm.stopPrank();
    }

    function test__unitRevert__makeChangeEvvmAddress_dateToClaim()
        external
        prepareUsername
    {
        vm.startPrank(USER2);
        mns.changeEvvmAddress(
            address(0x104fBc016F4bb334D775a19E8A6510109AC63E00)
        );
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        mns.makeChangeEvvmAddress();
        vm.stopPrank();
    }
    */
}
