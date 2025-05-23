// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * Protocol Admin Facet -
 */
contract ProtocolFacet is AccessControl {
    // // TODO : replace with actual addresses
    //     ///@notice Check all addresses relating to revenue deposits including the burn address
    // ///@return RevenueSharesIO A struct containing all addresses relating to revenue deposits
    // function revenueShares() external view returns (RevenueSharesDTO memory) {
    //     return RevenueSharesDTO(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, s.daoTreasury, s.rarityFarming, s.treasuryAddress);
    // }

    ///@notice Query the $QUACK token address
    ///@return contract_ the deployed address of the $QUACK token contract
    function quackAddress() external view returns (address contract_) {
        contract_ = LibAppStorage.diamondStorage().quackTokenAddress;
    }
    
    ///@notice Query the treasury address
    ///@return address_ the deployed address of the treasury
    function getTreasuryAddress() external view returns (address address_) {
        address_ = LibAppStorage.diamondStorage().treasuryAddress;
    }
}
