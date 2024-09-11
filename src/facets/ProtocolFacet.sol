// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {RevenueSharesDTO} from "../shared/Structs.sol";
import {Cycle, DuckInfoMemory} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
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
        contract_ = s.quackTokenAddress;
    }
}
