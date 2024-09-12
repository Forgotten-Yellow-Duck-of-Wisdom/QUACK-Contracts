// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, EggDuckTraitsDTO, DucksIdsWithKinshipDTO} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";
import {LibMaths} from "../libs/LibMaths.sol";
// import {} from "../libs/LibAppStorage.sol";
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
        available_ = s.duckNamesUsed[LibString.validateAndLowerName(_name)];
    }

    ///@notice Check the latest Cycle identifier and details
    ///@return cycleId_ The latest cycle identifier
    ///@return cycle_ A struct containing the details about the latest cycle`

    function currentCycle() external view returns (uint256 cycleId_, Cycle memory cycle_) {
        cycleId_ = s.currentCycleId;
        cycle_ = s.cycles[cycleId_];
    }

    // TODO: replace 10 hardcoded value with constant EGG_DUCKS_NUM
    ///@notice Query all details associated with an NFT like collateralType,numericTraits e.t.c
    ///@param _tokenId Identifier of the NFT to query
    ///@return eggDuckTraits_ A struct containing all details about the NFT with identifier `_tokenId`

    function eggDuckTraits(uint256 _tokenId) external view returns (EggDuckTraitsDTO[10] memory eggDuckTraits_) {
        eggDuckTraits_ = LibDuck.eggDuckTraits(_tokenId);
    }

    ///@notice Query the numeric traits of an NFT
    ///@dev Only valid for claimed Ducks
    ///@param _tokenId The identifier of the NFT to query
    ///@return numericTraits_ A six-element array containing integers,each representing the traits of the NFT with identifier `_tokenId`
    function getNumericTraits(uint256 _tokenId)
        external
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_)
    {
        numericTraits_ = LibDuck.getNumericTraits(_tokenId);
    }

    ///@notice Query the skill reset count of an Duck
    ///@param _tokenId The identifier of the Duck to query
    ///@return respecCount_ The number of times an Duck has performed a skill reset
    function respecCount(uint32 _tokenId) external view returns (uint256 respecCount_) {
        respecCount_ = s.duckRespecCount[_tokenId];
    }

    ///@notice Query the available skill points that can be used for an NFT
    ///@dev Will throw if the amount of skill points available is greater than or equal to the amount of skill points which have been used
    ///@param _tokenId The identifier of the NFT to query
    ///@return   An unsigned integer which represents the available skill points of an NFT with identifier `_tokenId`
    function availableSkillPoints(uint256 _tokenId) public view returns (uint256 availableSkillPoints_) {
        availableSkillPoints_ = LibDuck.availableSkillPoints(_tokenId);
    }

    ///@notice Calculate level given the XP(experience points)
    ///@dev Only valid for claimed Ducks
    ///@param _experience the current XP gathered by an NFT
    ///@return level_ The level of an NFT with experience `_experience`
    function duckLevel(uint256 _experience) external pure returns (uint256 level_) {
        level_ = LibDuck.duckLevel(_experience);
    }

    ///@notice Calculate the XP needed for an NFT to advance to the next level
    ///@dev Only valid for claimed Ducks
    ///@param _experience The current XP points gathered by an NFT
    ///@return requiredXp_ The XP required for the NFT to move to the next level
    function xpUntilNextLevel(uint256 _experience) external pure returns (uint256 requiredXp_) {
        requiredXp_ = LibDuck.xpUntilNextLevel(_experience);
    }

    ///@notice Compute the rarity multiplier of an NFT
    ///@dev Only valid for claimed Ducks
    ///@param _numericTraits An array of six integers each representing a numeric trait of an NFT
    ///return multiplier_ The rarity multiplier of an NFT with numeric traits `_numericTraits`
    function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _numericTraits)
        external
        pure
        returns (uint256 multiplier_)
    {
        multiplier_ = LibMaths.rarityMultiplier(_numericTraits);
    }

    ///@notice Calculates the base rarity score, including collateral modifier
    ///@dev Only valid for claimed Ducks
    ///@param _numericTraits An array of six integers each representing a numeric trait of an NFT
    ///@return rarityScore_ The base rarity score of an NFT with numeric traits `_numericTraits`
    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits)
        external
        pure
        returns (uint256 rarityScore_)
    {
        rarityScore_ = LibMaths.baseRarityScore(_numericTraits);
    }

    ///@notice Check the modified traits and rarity score of an NFT(as a result of equipped wearables)
    ///@dev Only valid for claimed Ducks
    ///@param _tokenId Identifier of the NFT to query
    ///@return numericTraits_ An array of six integers each representing a numeric trait(modified) of an NFT with identifier `_tokenId`
    ///@return rarityScore_ The modified rarity score of an NFT with identifier `_tokenId`
    //Only valid for claimed Ducks
    function modifiedTraitsAndRarityScore(uint256 _tokenId)
        external
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_, uint256 rarityScore_)
    {
        (numericTraits_, rarityScore_) = LibDuck.modifiedTraitsAndRarityScore(_tokenId);
    }

    ///@notice Check the kinship of an NFT
    ///@dev Only valid for claimed Ducks
    ///@dev Default kinship value is 50
    ///@param _tokenId Identifier of the NFT to query
    ///@return score_ The kinship of an NFT with identifier `_tokenId`
    function kinship(uint256 _tokenId) external view returns (uint256 score_) {
        score_ = LibDuck.kinship(_tokenId);
    }

    ///@notice Query the tokenId,kinship and lastInteracted values of a set of NFTs belonging to an address
    ///@dev Will throw if `_count` is greater than the number of NFTs owned by `_owner`
    ///@param _owner Address to query
    ///@param _count Number of NFTs to check
    ///@param _skip Number of NFTs to skip while querying
    ///@param all If true, query all NFTs owned by `_owner`; if false, query `_count` NFTs owned by `_owner`
    ///@return tokenIdsWithKinship_ An array of structs where each struct contains the `tokenId`,`kinship`and `lastInteracted` of each NFT
    function tokenIdsWithKinship(address _owner, uint256 _count, uint256 _skip, bool all)
        external
        view
        returns (DucksIdsWithKinshipDTO[] memory tokenIdsWithKinship_)
    {
        uint32[] memory tokenIds = s.ownerTokenIds[_owner];
        uint256 length = all ? tokenIds.length : _count;
        tokenIdsWithKinship_ = new DucksIdsWithKinshipDTO[](length);

        if (!all) {
            require(_skip + _count <= tokenIds.length, "DuckGameFacet: Owner does not have up to that amount of tokens");
        }

        for (uint256 i; i < length; i++) {
            uint256 offset = i + _skip;
            uint32 tokenId = tokenIds[offset];
            if (s.ducks[tokenId].status == DuckStatus.DUCK) {
                tokenIdsWithKinship_[i].tokenId = tokenId;
                tokenIdsWithKinship_[i].kinship = LibDuck.kinship(tokenId);
                tokenIdsWithKinship_[i].lastInteracted = s.ducks[tokenId].lastInteracted;
            }
        }
    }

    ///@notice Allows the owner of an NFT(Portal) to claim an Duck provided it has been unlocked
    ///@dev Will throw if the Portal(with identifier `_tokenid`) has not been opened(Unlocked) yet
    ///@dev If the NFT(Portal) with identifier `_tokenId` is listed for sale on the baazaar while it is being unlocked, that listing is cancelled
    ///@param _tokenId The identifier of NFT to claim an Duck from
    ///@param _option The index of the Duck to claim(1-10)
    ///@param _stakeAmount Minimum amount of collateral tokens needed to be sent to the new Duck escrow contract
    function claimDuck(uint256 _tokenId, uint256 _option, uint256 _stakeAmount)
        external
        onlyUnlocked(_tokenId)
        onlyDuckOwner(_tokenId)
    {
        LibDuck.claimDuck(_tokenId, _msgSender(), _option, _stakeAmount);
    }

    ///@notice Allows the owner of a NFT to set a name for it
    ///@dev only valid for claimed Ducks
    ///@dev Will throw if the name has been used for another claimed Duck
    ///@param _tokenId the identifier if the NFT to name
    ///@param _name Preferred name to give the claimed Duck
    function setDuckName(uint256 _tokenId, string calldata _name)
        external
        onlyUnlocked(_tokenId)
        onlyDuckOwner(_tokenId)
    {
        LibDuck.setDuckName(_tokenId, _name);
    }

    ///@notice Allow the owner of an NFT to interact with them.thereby increasing their kinship(petting)
    ///@dev only valid for claimed ducks
    ///@dev Kinship will only increase if the lastInteracted minus the current time is greater than or equal to 12 hours
    ///@param _tokenIds An array containing the token identifiers of the claimed ducks that are to be interacted with
    function interact(uint256[] calldata _tokenIds) external {
        address sender = _msgSender();
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            address owner = s.ducks[tokenId].owner;

            require(
                sender == owner || s.operators[owner][sender] || s.approved[tokenId] == sender
                    || s.petOperators[owner][sender] || "DuckGameFacet: Not owner of token or approved"
            );

            require(s.ducks[tokenId].status == DuckStatus.DUCK, "DuckGameFacet: Only valid for Duck");
            LibDuck.interact(tokenId);
        }
    }

    ///@notice Allow the owner of an NFT to spend skill points for it(basically to boost the numeric traits of that NFT)
    ///@dev only valid for claimed ducks
    ///@param _tokenId The identifier of the NFT to spend the skill points on
    ///@param _values An array of four integers that represent the values of the skill points
    function spendSkillPoints(uint256 _tokenId, int16[4] calldata _values)
        external
        onlyUnlocked(_tokenId)
        onlyDuckOwner(_tokenId)
    {
        LibDuck.spendSkillPoints(_tokenId, _values);
    }

    function isDuckLocked(uint256 _tokenId) external view returns (bool isLocked) {
        isLocked = s.ducks[_tokenId].locked;
    }

    /// TODO : later upgrade
    // function resetSkillPoints(uint32 _tokenId)

    function getDuckBaseNumericTraits(uint32 _tokenId)
        public
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_)
    {
        // cast to uint256 for CollateralTypes key
        uint256 cycleId = uint256(s.ducks[_tokenId].cycleId);
        uint256 randomNumber = s.ducks[_tokenId].randomNumber;
        address collateralType = s.ducks[_tokenId].collateralType;
        numericTraits_ = LibMaths.toNumericTraits(randomNumber, s.collateralTypeInfo[collateralType].modifiers, cycleId);
    }
}
