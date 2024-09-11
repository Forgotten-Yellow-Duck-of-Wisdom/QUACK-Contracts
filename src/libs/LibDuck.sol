// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {
    DuckInfo,
    DuckInfoMemory,
    EggDuckTraitsDTO,
    DuckStatus,
    NUMERIC_TRAITS_NUM,
    EQUIPPED_WEARABLE_SLOTS,
    TRAIT_BONUSES_NUM,
    EGG_DUCKS_NUM
} from "../shared/Structs_Ducks.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {CollateralEscrow} from "../facades/CollateralEscrow.sol";
import {LibERC721} from "./LibERC721.sol";
import {LibString} from "./LibString.sol";
import {LibMaths} from "./LibMaths.sol";
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

    ///@notice Allows the owner of an NFT(Portal) to claim an Duck provided it has been unlocked
    ///@dev Will throw if the Portal(with identifier `_tokenid`) has not been opened(Unlocked) yet
    ///@dev If the NFT(Portal) with identifier `_tokenId` is listed for sale on the baazaar while it is being unlocked, that listing is cancelled
    ///@param _tokenId The identifier of NFT to claim an Duck from
    ///@param _option The index of the Duck to claim(1-10)
    ///@param _stakeAmount Minimum amount of collateral tokens needed to be sent to the new Duck escrow contract
    function claimDuck(uint256 _tokenId, address _owner, uint256 _option, uint256 _stakeAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_tokenId];
        require(duck.status == DuckStatus.OPEN_EGG, "DuckGameFacet: Egg not open");
        require(_option < EGG_DUCKS_NUM, "DuckGameFacet: Only 10 duck options available");
        uint256 randomNumber = s.tokenIdToRandomNumber[_tokenId];
        uint256 hauntId = s.ducks[_tokenId].hauntId;

        EggDuckTraitsDTO memory option = singleEggDuckTraits(hauntId, randomNumber, _option);
        duck.randomNumber = option.randomNumber;
        duck.numericTraits = option.numericTraits;
        duck.collateralType = option.collateralType;
        duck.minimumStake = option.minimumStake;
        duck.lastInteracted = uint40(block.timestamp - 12 hours);
        duck.interactionCount = 50;
        duck.claimTime = uint40(block.timestamp);

        require(_stakeAmount >= option.minimumStake, "DuckGameFacet: _stakeAmount less than minimum stake");

        duck.status = DuckStatus.DUCK;
        // TODO : wip events
        // emit DuckClaimed(_tokenId);

        address escrow = address(new CollateralEscrow(option.collateralType));
        duck.escrow = escrow;
        (bool success,) = IERC20(option.collateralType).transferFrom(_owner, escrow, _stakeAmount);
        if (!success) {
            revert("DuckGameFacet: Transfer failed");
        }
        // LibERC20.transferFrom(option.collateralType, _owner, escrow, _stakeAmount);
        // TODO : Duck Marcketplace
        // LibERC721Marketplace.cancelERC721Listing(address(this), _tokenId, _owner);
    }

    ///@notice Allows the owner of a NFT to set a name for it
    ///@dev only valid for claimed Ducks
    ///@dev Will throw if the name has been used for another claimed Duck
    ///@param _tokenId the identifier if the NFT to name
    ///@param _name Preferred name to give the claimed Duck
    function setDuckName(uint256 _tokenId, string calldata _name) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == DuckStatus.DUCK, "DuckGameFacet: Must claim Duck before setting name");
        string memory lowerName = LibString.validateAndLowerName(_name);
        string memory existingName = s.ducks[_tokenId].name;
        if (bytes(existingName).length > 0) {
            delete s.duckNamesUsed[LibString.validateAndLowerName(existingName)];
        }
        require(!s.duckNamesUsed[lowerName], "DuckGameFacet: Duck name used already");
        s.duckNamesUsed[lowerName] = true;
        s.ducks[_tokenId].name = _name;
        // TODO : wip events    
        // emit SetDuckName(_tokenId, existingName, _name);
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
        if (duckInfo_.status == DuckStatus.DUCK) {
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
            duckInfo_.baseRarityScore = LibMaths.baseRarityScore(duckInfo_.numericTraits);
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

        level_ = (LibMaths.sqrt(2 * _experience) / 10);
        return level_ + 1;
    }

    //Only valid for claimed Ducks
    function modifiedTraitsAndRarityScore(uint256 _tokenId)
        internal
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_, uint256 rarityScore_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == DuckStatus.DUCK, "DuckFacet: Must be claimed");
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
        uint256 baseRarity = LibMaths.baseRarityScore(numericTraits_);
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

    function eggDuckTraits(uint256 _tokenId)
        internal
        view
        returns (EggDuckTraitsDTO[EGG_DUCKS_NUM] memory eggDuckTraits_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == DuckStatus.OPEN_EGG, "DuckFacet: Egg not open");

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

    function singleEggDuckTraits(uint256 _cycleId, uint256 _randomNumber, uint256 _option)
        internal
        view
        returns (EggDuckTraitsDTO memory singleEggDuckTraits_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 randomNumberN = uint256(keccak256(abi.encodePacked(_randomNumber, _option)));
        singleEggDuckTraits_.randomNumber = randomNumberN;

        address collateralType =
            s.cycleCollateralTypes[_cycleId][randomNumberN % s.cycleCollateralTypes[_cycleId].length];
        singleEggDuckTraits_.numericTraits =
            LibMaths.toNumericTraits(randomNumberN, s.collateralTypeInfo[collateralType].modifiers, _cycleId);
        singleEggDuckTraits_.collateralType = collateralType;

        // TODO : wip dynamic collateral price
        // CollateralTypeInfo memory collateralInfo = s.collateralTypeInfo[collateralType];
        // uint256 conversionRate = collateralInfo.conversionRate;

        // //Get rarity multiplier
        // uint256 multiplier = LibMaths.rarityMultiplier(singleEggDuckTraits_.numericTraits);

        // //First we get the base price of our collateral in terms of DAI
        // uint256 collateralDAIPrice = ((10 ** IERC20(collateralType).decimals()) / conversionRate);

        // //Then multiply by the rarity multiplier
        // singleEggDuckTraits_.minimumStake = collateralDAIPrice * multiplier;

        // TODO : until no minimum stake fixed, set to 1
        singleEggDuckTraits_.minimumStake = 1;
    }

    ///@notice Allow the owner of an NFT to spend skill points for it(basically to boost the numeric traits of that NFT)
    ///@dev only valid for claimed ducks
    ///@param _tokenId The identifier of the NFT to spend the skill points on
    ///@param _values An array of four integers that represent the values of the skill points
    function spendSkillPoints(uint256 _tokenId, int16[4] calldata _values) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //To test: Prevent underflow (is this ok?), see require below
        uint256 totalUsed;
        for (uint256 index; index < _values.length; index++) {
            totalUsed += LibMaths.abs(_values[index]);

            s.ducks[_tokenId].numericTraits[index] += _values[index];
        }
        // handles underflow
        require(availableSkillPoints(_tokenId) >= totalUsed, "DuckGameFacet: Not enough skill points");
        //Increment used skill points
        s.ducks[_tokenId].usedSkillPoints += totalUsed;
        // TODO : wip events
        // emit SpendSkillpoints(_tokenId, _values);
    }

    ///@notice Query the available skill points that can be used for an NFT
    ///@dev Will throw if the amount of skill points available is greater than or equal to the amount of skill points which have been used
    ///@param _tokenId The identifier of the NFT to query
    ///@return   An unsigned integer which represents the available skill points of an NFT with identifier `_tokenId`
    function availableSkillPoints(uint256 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 skillPoints = LibDuck.calculateSkillPoints(_tokenId);
        uint256 usedSkillPoints = s.ducks[_tokenId].usedSkillPoints;
        require(skillPoints >= usedSkillPoints, "LibDuck: Used skill points is greater than skill points");
        return skillPoints - usedSkillPoints;
    }

    function calculateSkillPoints(uint256 _tokenId, uint256 experience, uint256 claimTime)
        internal
        view
        returns (uint256)
    {
        uint256 level = duckLevel(experience);
        uint256 skillPoints = (level / 3);

        uint256 ageDifference = block.timestamp - claimTime;
        return skillPoints + calculateSkillPointsByAge(ageDifference);
    }

    function calculateSkillPointsByAge(uint256 _age) internal pure returns (uint256) {
        uint256 skillPointsByAge = 0;
        uint256[10] memory fibSequence = [uint256(1), 2, 3, 5, 8, 13, 21, 34, 55, 89];
        for (uint256 i = 0; i < fibSequence.length; i++) {
            if (_age > fibSequence[i] * 2300000) {
                skillPointsByAge++;
            } else {
                break;
            }
        }
        return skillPointsByAge;
    }

    /////////////////////////////////////////////////////////////////////////////////
    // Internal Checks
    /////////////////////////////////////////////////////////////////////////////////
}
