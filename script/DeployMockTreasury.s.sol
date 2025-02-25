// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/mock/TreasuryMock.sol";
import "../src/mock/TestToken.sol";

contract DeployMockTreasury is Script {
    TreasuryMock treasury;

    address token = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    function run() public {
        vm.broadcast();
        deployTreasury();
    }

    function deployTreasury() public returns (address treasuryAddress) {
        treasury = new TreasuryMock(token);
        treasuryAddress = address(treasury);
        console2.log("TreasuryMock address: ", treasuryAddress);
    }
}
