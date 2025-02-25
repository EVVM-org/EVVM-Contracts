// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EvvmMockStructs
 * @dev Library of common structures used across EVVM and its services.
 *      This contract serves as a shared type system for the entire ecosystem,
 *      ensuring consistency in data structures between the core EVVM and
 *      external service contracts.
 *
 * @notice This contract should be inherited by both EVVM and service contracts
 *         that need to interact with these data structures.
 */

abstract contract EvvmMockStructs {
    struct PayData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        uint256 nonce;
        bool priority;
        address executor;
        bytes signature;
    }

    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    struct TreasuryMetadata {
        string AxelarChain;
        string AxelarAddress;
        uint64 CCIPChain;
        address CCIPAddress;
        uint32 HyperlaneChain;
        bytes32 HyperlaneAddress;
        uint32 LayerZeroChain;
        bytes32 LayerZeroAddress;
    }

    struct whitheListedTokenMetadata {
        bool isAllowed;
        address uniswapPool;
    }

    struct MateTokenomicsMetadata {
        uint256 totalSupply;
        uint256 eraTokens;
        uint256 reward;
        address mateAddress;
    }

    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }
}
