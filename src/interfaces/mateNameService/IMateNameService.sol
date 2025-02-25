// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*  

██╗███╗   ███╗███╗   ██╗███████╗
██║████╗ ████║████╗  ██║██╔════╝
██║██╔████╔██║██╔██╗ ██║███████╗
██║██║╚██╔╝██║██║╚██╗██║╚════██║
██║██║ ╚═╝ ██║██║ ╚████║███████║
╚═╝╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝

 *  @title Interface MATE Name Service
 *  @author jistro.eth ariutokintumi.eth
 *  @notice This contract is designed to register and manage usernames for
 *          the MATE metaprotocol
 */

interface IMateNameService {
    
    struct OfferMetadata {
        address offerer;
        uint256 expireDate;
        uint256 amount;
    }

    function seePriceToRenew(
        string memory _identity
    ) external view returns (uint256 price);

    function getPriceToFlushCustomMetadata(
        string memory _identity
    ) external view returns (uint256 price);

    function checkIfMNSNonceIsAvailable(
        address _user,
        uint256 _nonce
    ) external view returns (bool);

    function isIdentityAvailable(
        string memory _username
    ) external view returns (bool);

    function getIdentityBasicMetadata(
        string memory _username
    ) external view returns (
        address,
        uint256
    );

    function getFullCustomMetadataOfIdentity(
        string memory _username
    ) external view returns (
        string[] memory
    );

    function getOwnerOfIdentity(
        string memory _username
    ) external view returns (address);

    function getOffersOfUsername(
        string memory _username
    ) external view returns (
        OfferMetadata[] memory offers
    );

    function getLengthOfOffersUsername(
        string memory _username
    ) external view returns (
        uint256 length
    );
    
    function getExpireDateOfUsername(
        string memory _phoneNumber
    ) external view returns (uint256);
    
}