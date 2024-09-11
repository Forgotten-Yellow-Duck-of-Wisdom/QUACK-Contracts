// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, DuckInfoMemory, EggDuckTraitsDTO} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage, EGG_DUCKS_NUM} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * Duck Game Facet - 
 */
contract DuckGameFacet is AccessControl {

    // TODO : 1 or more egg can be purchased ?
    ///@notice Allow an address to purchase a duck egg 
    ///@param _to Address to send the egg once purchased
    ///@param _ghst The amount of GHST the buyer is willing to pay //calculation will be done to know how much portal he recieves based on the cycle's portal price
    // function buyEgg(address _to, uint256 _ghst) external {
    //     uint256 currentCycleId = s.currentCycleId;
    //     // require(currentCycleId == 1, "DuckGameFacet: Can only purchase from cycle 1");
    //     Cycle storage cycle = s.cycles[currentCycleId];
    //     uint256 price = cycle.portalPrice;
    //     require(_ghst >= price, "Not enough GHST to buy portals");
    //     uint256[3] memory tiers;
    //     tiers[0] = price * 5;
    //     tiers[1] = tiers[0] + (price * 2 * 10);
    //     tiers[2] = tiers[1] + (price * 3 * 10);
    //     require(_ghst <= tiers[2], "Can't buy more than 25");
    //     address sender = _msgSender();
    //     uint256 numToPurchase;
    //     uint256 totalPrice;
    //     if (_ghst <= tiers[0]) {
    //         numToPurchase = _ghst / price;
    //         totalPrice = numToPurchase * price;
    //     } else {
    //         if (_ghst <= tiers[1]) {
    //             numToPurchase = (_ghst - tiers[0]) / (price * 2);
    //             totalPrice = tiers[0] + (numToPurchase * (price * 2));
    //             numToPurchase += 5;
    //         } else {
    //             numToPurchase = (_ghst - tiers[1]) / (price * 3);
    //             totalPrice = tiers[1] + (numToPurchase * (price * 3));
    //             numToPurchase += 15;
    //         }
    //     }
    //     uint256 cycleCount = cycle.totalCount + numToPurchase;
    //     require(cycleCount <= cycle.cycleMaxSize, "DuckGameFacet: Exceeded max number of duck for this cycle");
    //     s.cycles[currentCycleId].totalCount = uint24(cycleCount);
    //     uint32 duckId = s.duckIdCounter;
    //     emit BuyPortals(sender, _to, duckId, numToPurchase, totalPrice);
    //     for (uint256 i; i < numToPurchase; i++) {
    //         s.ducks[duckId].owner = _to;
    //         s.ducks[duckId].cycleId = uint16(currentCycleId);
    //         s.duckIdIndexes[duckId] = s.duckIds.length;
    //         s.duckIds.push(duckId);
    //         s.duckIdIndexes[_to][duckId] = s.duckIds[_to].length;
    //         s.duckIds[_to].push(duckId);
    //         emit LibERC721.Transfer(address(0), _to, duckId);
    //         duckId++;
    //     }
    //     s.duckIdCounter = duckId;
    //     // LibDuck.verify(duckId);
    //     LibDuck.purchase(sender, totalPrice);
    // }

    ///@notice Check if a string `_name` has not been assigned to another NFT
    ///@param _name Name to check
    ///@return available_ True if the name has not been taken, False otherwise
    function duckNameAvailable(string calldata _name) external view returns (bool available_) {
        available_ = s.duckNamesUsed[LibDuck.validateAndLowerName(_name)];
    }

    ///@notice Check the latest Cycle identifier and details
    ///@return cycleId_ The latest cycle identifier
    ///@return cycle_ A struct containing the details about the latest cycle`

    function currentCycle() external view returns (uint256 cycleId_, Cycle memory cycle_) {
        cycleId_ = s.currentCycleId;
        cycle_ = s.cycles[cycleId_];
    }

    function eggDuckTraits(
        uint256 _tokenId
    ) external view returns (EggDuckTraitsDTO[EGG_DUCKS_NUM] memory eggDuckTraits_) {
        eggDuckTraits_ = LibDuck.eggDuckTraits(_tokenId);
    }
}
