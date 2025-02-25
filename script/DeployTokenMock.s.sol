// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/mock/EvvmMock.sol";
import "../src/mock/TreasuryMock.sol";
import "../src/mock/TestToken.sol";

contract DeployTokenMock is Script {
    EvvmMock evvm;
    TreasuryMock treasury;
    TestToken testToken;

    function run() public {
        vm.broadcast();
        deployToken();
    
    }

    function deployToken() public returns (address testTokenAddress) {
        testToken = new TestToken(msg.sender);
        testTokenAddress = address(testToken);
        console2.log("TestToken address: ", testTokenAddress);
    }

    
}
