// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {LibDiamond} from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import {MetaContext} from "./MetaContext.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";

/**
 * @dev Caller/sender must be admin / contract owner.
 */
error CallerMustBeAdminError();

/**
 * @dev Access control module.
 */
abstract contract AccessControl is MetaContext {
    modifier isAdmin() {
        if (LibDiamond.contractOwner() != _msgSender()) {
            revert CallerMustBeAdminError();
        }
        _;
    }

    modifier onlyDuckOwner(uint256 _tokenId) {
        require(
            _msgSender() == LibAppStorage.diamondStorage().ducks[_tokenId].owner,
            "LibApAccessControl: Only Duck owner can call this function"
        );
        _;
    }

    modifier onlyUnlocked(uint256 _tokenId) {
        require(
            LibAppStorage.diamondStorage().ducks[_tokenId].locked == false,
            "LibAppStorage: Only callable on unlocked Duck"
        );
        _;
    }

    modifier onlyLocked(uint256 _tokenId) {
        require(
            LibAppStorage.diamondStorage().ducks[_tokenId].locked == true, "LibAppStorage: Only callable on locked Duck"
        );
        _;
    }

    modifier onlyGameQnG() {
        require(
            _msgSender() == LibAppStorage.diamondStorage().gameQnGAuthorityAddress,
            "LibAppStorage: Only callable by GameQnGAuthority contract"
        );
        _;
    }
}
