// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EvvmMockStorage
 * @author jistro.eth
 * @dev Storage layout contract for EVVM proxy pattern implementation.
 *      This contract inherits all structures from EvvmMockStructs and
 *      defines the storage layout that will be used by the proxy pattern.
 *
 * @notice This contract should not be deployed directly, it's meant to be
 *         inherited by the implementation contracts to ensure they maintain
 *         the same storage layout.
 */

abstract contract CommonVariables {
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
}
