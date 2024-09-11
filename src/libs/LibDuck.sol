// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {DuckInfo, DuckInfoMemory, EggDuckTraitsDTO} from "../shared/Structs_Ducks.sol";
import {
    AppStorage, 
    LibAppStorage, 
    NUMERIC_TRAITS_NUM, 
    EQUIPPED_WEARABLE_SLOTS, 
    TRAIT_BONUSES_NUM, 
    EGG_DUCKS_NUM,
    STATUS_DUCK,
    STATUS_OPEN_EGG,
    STATUS_CLOSED_EGG,
    STATUS_VRF_PENDING
    } from "./LibAppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibERC721} from "./LibERC721.sol";

// error ERC20NotEnoughBalance(address sender);

library LibDuck {


    //   /**
    //    * @dev Emitted when a token is minted.
    //    */
    //   event ERC20Minted(address token, address to, uint256 amount);
    function internalTransferFrom(address _sender, address _from, address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_to != address(0), "DuckFacet: Can't transfer to 0 address");
        require(_from != address(0), "DuckFacet: _from can't be 0 address");
        require(_from == s.ducks[_tokenId].owner, "DuckFacet: _from is not owner, transfer failed");
        require(
            _sender == _from || s.operators[_from][_sender] || _sender == s.approved[_tokenId],
            "DuckFacet: Not owner or approved to transfer"
        );
        transfer(_from, _to, _tokenId);
        // LibERC721Marketplace.updateERC721Listing(address(this), _tokenId, _from);
    }

    function transfer(address _from, address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint256 index = s.ownerDuckIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerDuckIds[_from].length - 1;
        if (index != lastIndex) {
            uint32 lastTokenId = s.ownerDuckIds[_from][lastIndex];
            s.ownerDuckIds[_from][index] = lastTokenId;
            s.ownerDuckIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerDuckIds[_from].pop();
        delete s.ownerDuckIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.ducks[_tokenId].owner = _to;
        s.ownerDuckIdIndexes[_to][_tokenId] = s.ownerDuckIds[_to].length;
        s.ownerDuckIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }

    ///////////////////////////////////////////
    // MARK: Getters
    ///////////////////////////////////////////

    function getDuckInfo(uint256 _tokenId) internal view returns (DuckInfoMemory memory duckInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        duckInfo_.tokenId = _tokenId;
        duckInfo_.owner = s.ducks[_tokenId].owner;
        duckInfo_.randomNumber = s.ducks[_tokenId].randomNumber;
        duckInfo_.status = s.ducks[_tokenId].status;
        duckInfo_.cycleId = s.ducks[_tokenId].cycleId;
        if (duckInfo_.status == STATUS_DUCK) {
            duckInfo_.name = s.ducks[_tokenId].name;
            duckInfo_.equippedWearables = s.ducks[_tokenId].equippedWearables;
            duckInfo_.collateral = s.ducks[_tokenId].collateralType;
            duckInfo_.escrow = s.ducks[_tokenId].escrow;
            duckInfo_.stakedAmount = IERC20(duckInfo_.collateral).balanceOf(duckInfo_.escrow);
            duckInfo_.minimumStake = s.ducks[_tokenId].minimumStake;
            duckInfo_.kinship = kinship(_tokenId);
            duckInfo_.lastInteracted = s.ducks[_tokenId].lastInteracted;
            duckInfo_.experience = s.ducks[_tokenId].experience;
            duckInfo_.toNextLevel = xpUntilNextLevel(s.ducks[_tokenId].experience);
            duckInfo_.level = duckLevel(s.ducks[_tokenId].experience);
            duckInfo_.usedSkillPoints = s.ducks[_tokenId].usedSkillPoints;
            duckInfo_.numericTraits = s.ducks[_tokenId].numericTraits;
            duckInfo_.baseRarityScore = baseRarityScore(duckInfo_.numericTraits);
            (duckInfo_.modifiedNumericTraits, duckInfo_.modifiedRarityScore) = modifiedTraitsAndRarityScore(_tokenId);
            duckInfo_.locked = s.ducks[_tokenId].locked;
            // TODO : wip add items
            // duckInfo_.items = LibItems.itemBalancesOfTokenWithTypes(address(this), _tokenId);
        }
    }

    function kinship(uint256 _tokenId) internal view returns (uint256 score_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_tokenId];
        uint256 lastInteracted = duck.lastInteracted;
        uint256 interactionCount = duck.interactionCount;
        uint256 interval = block.timestamp - lastInteracted;

        uint256 daysSinceInteraction = interval / 24 hours;

        if (interactionCount > daysSinceInteraction) {
            score_ = interactionCount - daysSinceInteraction;
        }
    }

    function xpUntilNextLevel(uint256 _experience) internal pure returns (uint256 requiredXp_) {
        uint256 currentLevel = duckLevel(_experience);
        requiredXp_ = ((currentLevel ** 2) * 50) - _experience;
    }

    function duckLevel(uint256 _experience) internal pure returns (uint256 level_) {
        if (_experience > 490050) {
            return 99;
        }

        level_ = (sqrt(2 * _experience) / 10);
        return level_ + 1;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    //Calculates the base rarity score, including collateral modifier

    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits)
        internal
        pure
        returns (uint256 _rarityScore)
    {
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = _numericTraits[i];
            if (number >= 50) {
                _rarityScore += uint256(number) + 1;
            } else {
                _rarityScore += uint256(int256(100) - number);
            }
        }
    }

    //Only valid for claimed Ducks
    function modifiedTraitsAndRarityScore(uint256 _tokenId)
        internal
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_, uint256 rarityScore_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == STATUS_DUCK, "DuckFacet: Must be claimed");
        DuckInfo storage duck = s.ducks[_tokenId];
        numericTraits_ = getNumericTraits(_tokenId);
        // TODO : wip items
        uint256 wearableBonus;
        // for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
        //     uint256 wearableId = duck.equippedWearables[slot];
        //     if (wearableId == 0) {
        //         continue;
        //     }
        //     ItemType storage itemType = s.itemTypes[wearableId];
        //     //Add on trait modifiers
        //     for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
        //         numericTraits_[j] += itemType.traitModifiers[j];
        //     }
        //     wearableBonus += itemType.rarityScoreModifier;
        // }
        uint256 baseRarity = baseRarityScore(numericTraits_);
        rarityScore_ = baseRarity + wearableBonus;
    }

    function getNumericTraits(uint256 _tokenId)
        internal
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //Check if trait boosts from consumables are still valid
        int256 boostDecay = int256((block.timestamp - s.ducks[_tokenId].lastTemporaryBoost) / 24 hours);
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = s.ducks[_tokenId].numericTraits[i];
            int256 boost = s.ducks[_tokenId].temporaryTraitBoosts[i];

            if (boost > 0 && boost > boostDecay) {
                number += boost - boostDecay;
            } else if ((boost * -1) > boostDecay) {
                number += boost + boostDecay;
            }
            numericTraits_[i] = int16(number);
        }
    }

    function eggDuckTraits(
        uint256 _tokenId
    ) internal view returns (EggDuckTraitsDTO[EGG_DUCKS_NUM] memory eggDuckTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == STATUS_OPEN_EGG, "DuckFacet: Egg not open");

        uint256 randomNumber = s.eggIdToRandomNumber[_tokenId];

        uint256 cycleId = s.ducks[_tokenId].cycleId;

        for (uint256 i; i < eggDuckTraits_.length; i++) {
            EggDuckTraitsDTO memory single = singleEggDuckTraits(cycleId, randomNumber, i);
            eggDuckTraits_[i].randomNumber = single.randomNumber;
            eggDuckTraits_[i].collateralType = single.collateralType;
            eggDuckTraits_[i].minimumStake = single.minimumStake;
            eggDuckTraits_[i].numericTraits = single.numericTraits;
        }
    }

    function singleEggDuckTraits(
        uint256 _cycleId,
        uint256 _randomNumber,
        uint256 _option
    ) internal view returns (EggDuckTraitsDTO memory singleEggDuckTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 randomNumberN = uint256(keccak256(abi.encodePacked(_randomNumber, _option)));
        singleEggDuckTraits_.randomNumber = randomNumberN;

        address collateralType = s.cycleCollateralTypes[_cycleId][randomNumberN % s.cycleCollateralTypes[_cycleId].length];
        singleEggDuckTraits_.numericTraits = toNumericTraits(randomNumberN, s.collateralTypeInfo[collateralType].modifiers, _cycleId);
        singleEggDuckTraits_.collateralType = collateralType;

        // TODO : wip dynamic collateral price
        // CollateralTypeInfo memory collateralInfo = s.collateralTypeInfo[collateralType];
        // uint256 conversionRate = collateralInfo.conversionRate;

        // //Get rarity multiplier
        // uint256 multiplier = rarityMultiplier(singleEggDuckTraits_.numericTraits);

        // //First we get the base price of our collateral in terms of DAI
        // uint256 collateralDAIPrice = ((10 ** IERC20(collateralType).decimals()) / conversionRate);

        // //Then multiply by the rarity multiplier
        // singleEggDuckTraits_.minimumStake = collateralDAIPrice * multiplier;

        // TODO : until no minimum stake fixed, set to 1
        singleEggDuckTraits_.minimumStake = 1;
    }

/// @notice Generates numeric traits for a duck based on a random number, modifiers, and cycle ID
/// @dev Different algorithms are used for Cycle 1 and other cycles to create varied trait distributions
/// @param _randomNumber A seed used to generate random trait values
/// @param _modifiers An array of modifiers to adjust the base trait values
/// @param _cycleId Determines which algorithm to use for trait generation
/// @return numericTraits_ An array of numeric traits for the duck
    function toNumericTraits(
        uint256 _randomNumber,
        int16[NUMERIC_TRAITS_NUM] memory _modifiers,
        uint256 _cycleId
    ) internal pure returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_) {
        if (_cycleId == 1) {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value /= 2;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        } else {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value = value - 100;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        }
    }

    function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) internal pure returns (uint256 multiplier) {
        uint256 rarityScore = baseRarityScore(_numericTraits);
        if (rarityScore < 300) return 10;
        else if (rarityScore >= 300 && rarityScore < 450) return 10;
        else if (rarityScore >= 450 && rarityScore <= 525) return 25;
        else if (rarityScore >= 526 && rarityScore <= 580) return 100;
        else if (rarityScore >= 581) return 1000;
    }



    /////////////////////////////////////////////////////////////////////////////////
    // Internal Checks
    /////////////////////////////////////////////////////////////////////////////////
}
