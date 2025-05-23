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

    modifier isDuckOwner(uint64 _tokenId) {
        require(
            _msgSender() == LibAppStorage.diamondStorage().ducks[_tokenId].owner,
            "LibApAccessControl: Only Duck owner can call this function"
        );
        _;
    }

    modifier onlyUnlocked(uint64 _tokenId) {
        require(
            LibAppStorage.diamondStorage().ducks[_tokenId].locked == false,
            "LibAppStorage: Only callable on unlocked Duck"
        );
        _;
    }

    modifier onlyLocked(uint64 _tokenId) {
        require(
            LibAppStorage.diamondStorage().ducks[_tokenId].locked == true, "LibAppStorage: Only callable on locked Duck"
        );
        _;
    }

    modifier isGameManager() {
        require(
            LibAppStorage.diamondStorage().allowedGameManager[_msgSender()],
            "LibAppStorage: Only callable by Game Manager"
        );
        _;
    }
}
