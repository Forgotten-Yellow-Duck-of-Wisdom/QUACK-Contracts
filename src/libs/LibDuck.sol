// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {
    DuckInfo,
    DuckInfoDTO,
    EggDuckTraitsDTO,
    DuckStatusType,
    DuckCharacteristicsType,
    DuckStatisticsType,
    DuckWearableSlot,
    DuckBadgeSlot
} from "../shared/Structs_Ducks.sol";
import {CollateralTypeInfo} from "../shared/Structs.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {CollateralEscrow} from "../facades/CollateralEscrow.sol";
import {LibERC721} from "./LibERC721.sol";
import {LibERC20} from "./LibERC20.sol";
import {LibString} from "./LibString.sol";
import {LibMaths} from "./LibMaths.sol";

import "forge-std/Test.sol";
// error ERC20NotEnoughBalance(address sender);

library LibDuck {
    event DuckInteract(uint64 indexed duckId, uint256 kinship);
    event EggOpened(uint64 indexed duckId);
    event DuckXPAdded(uint64 indexed duckId, uint256 level, uint256 xp);
    event DuckLevelUp(uint64 indexed duckId, uint256 level);
    ///////////////////////////////////////////
    // MARK: Write functions
    ///////////////////////////////////////////

    // called by Chainlink vrf callback
    function openEggWithVRF(uint256 _requestId, uint256[] memory _randomWords) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint64 duckId = s.vrfRequestIdToDuckId[_requestId];
        require(s.ducks[duckId].status == DuckStatusType.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[duckId].status = DuckStatusType.OPEN_EGG;
        s.duckIdToRandomNumber[duckId] = _randomWords[0];
        s.eggRepickOptions[duckId] = 0;

        emit EggOpened(duckId);
    }

    ///@notice Allows the owner of an NFT(Portal) to claim an Duck provided it has been unlocked
    ///@dev Will throw if the Portal(with identifier `_duckId`) has not been opened(Unlocked) yet
    ///@dev If the NFT(Portal) with identifier `_duckId` is listed for sale on the baazaar while it is being unlocked, that listing is cancelled
    ///@param _duckId The identifier of NFT to claim an Duck from
    ///@param _option The index of the Duck to claim(1-10)
    ///@param _stakeAmount Minimum amount of collateral tokens needed to be sent to the new Duck escrow contract
    function claimDuck(uint64 _duckId, address _owner, uint256 _option, uint256 _stakeAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_duckId];
        // console2.log("duck.status", uint256(duck.status));
        require(duck.status == DuckStatusType.OPEN_EGG, "DuckGameFacet: Egg not open");
        require(
            _option >= (s.eggRepickOptions[_duckId] + 1) && _option <= (s.eggRepickOptions[_duckId] + 3),
            "DuckGameFacet: Invalid option"
        );
        uint256 randomNumber = s.duckIdToRandomNumber[_duckId];
        uint16 cycleId = s.ducks[_duckId].cycleId;

        EggDuckTraitsDTO memory option = singleEggDuckTraits(cycleId, randomNumber, _option);
        duck.randomNumber = option.randomNumber;
        duck.collateralType = option.collateralType;
        duck.minimumStake = option.minimumStake;
        duck.lastInteracted = uint40(block.timestamp - 12 hours);
        duck.interactionCount = 50;
        duck.hatchTime = uint40(block.timestamp);
        duck.satiationTime = uint40(block.timestamp); // instant food possible
        // assign characteristics
        for (uint16 i; i < option.characteristics.length; i++) {
            duck.characteristics[uint16(i)] = option.characteristics[i];
        }
        // TODO : wip base statistics
        // // assign statistics
        for (uint16 i; i < uint16(type(DuckStatisticsType).max); i++) {
            uint16 maxStat = option.statistics[i];
            duck.maxStatistics[i] = maxStat;
            duck.statistics[i] = maxStat / 2;
        }

        require(_stakeAmount >= option.minimumStake, "DuckGameFacet: _stakeAmount less than minimum stake");

        duck.status = DuckStatusType.DUCK;
        // TODO : wip events
        // emit DuckClaimed(_duckId);

        address escrow = address(new CollateralEscrow(option.collateralType));
        duck.escrow = escrow;

        LibERC20.safeTransferFrom(option.collateralType, _owner, escrow, _stakeAmount);
        // TODO : Duck Marcketplace
        // LibERC721Marketplace.cancelERC721Listing(address(this), _duckId, _owner);
    }

    ///@notice Allows the owner of a NFT to set a name for it
    ///@dev only valid for claimed Ducks
    ///@dev Will throw if the name has been used for another claimed Duck
    ///@param _duckId the identifier if the NFT to name
    ///@param _name Preferred name to give the claimed Duck
    function setDuckName(uint64 _duckId, string calldata _name) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_duckId].status == DuckStatusType.DUCK, "DuckGameFacet: Must claim Duck before setting name");
        string memory lowerName = LibString.validateAndLowerName(_name);
        string memory existingName = s.ducks[_duckId].name;
        if (bytes(existingName).length > 0) {
            delete s.duckNamesUsed[LibString.validateAndLowerName(existingName)];
        }
        require(!s.duckNamesUsed[lowerName], "DuckGameFacet: Duck name used already");
        s.duckNamesUsed[lowerName] = true;
        s.ducks[_duckId].name = _name;
        // TODO : wip events
        // emit SetDuckName(_duckId, existingName, _name);
    }

    function interact(uint64 _duckId) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lastInteracted = s.ducks[_duckId].lastInteracted;
        // if interacted less than 12 hours ago
        if (block.timestamp < lastInteracted + 12 hours) {
            return false;
        }

        uint256 interactionCount = s.ducks[_duckId].interactionCount;
        uint256 interval = block.timestamp - lastInteracted;
        uint256 daysSinceInteraction = interval / 1 days;
        uint256 l_kinship;
        if (interactionCount > daysSinceInteraction) {
            l_kinship = interactionCount - daysSinceInteraction;
        }

        uint256 hateBonus;

        if (l_kinship < 40) {
            hateBonus = 2;
        }
        l_kinship += 1 + hateBonus;
        s.ducks[_duckId].interactionCount = l_kinship;

        s.ducks[_duckId].lastInteracted = uint40(block.timestamp);
        emit DuckInteract(_duckId, l_kinship);
        return true;
    }

    function purchase(address _from, uint256 _quackAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 share = (_quackAmount * 25) / 100;

        // Using 0x000000000000000000000000000000000000dEaD  as burn address.
        address quackTokenAddress = s.quackTokenAddress;
        LibERC20.safeTransferFrom(quackTokenAddress, _from, address(0x000000000000000000000000000000000000dEaD), share);
        LibERC20.safeTransferFrom(quackTokenAddress, _from, s.treasuryAddress, share);
        LibERC20.safeTransferFrom(quackTokenAddress, _from, s.farmingAddress, share);
        LibERC20.safeTransferFrom(quackTokenAddress, _from, s.daoAddress, share);
    }

    function internalTransferFrom(address _sender, address _from, address _to, uint64 _duckId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_to != address(0), "DuckFacet: Can't transfer to 0 address");
        require(_from != address(0), "DuckFacet: _from can't be 0 address");
        require(_from == s.ducks[_duckId].owner, "DuckFacet: _from is not owner, transfer failed");
        require(
            _sender == _from || s.operators[_from][_sender] || _sender == s.approved[_duckId],
            "DuckFacet: Not owner or approved to transfer"
        );
        transfer(_from, _to, _duckId);
        // LibERC721Marketplace.updateERC721Listing(address(this), _duckId, _from);
    }

    function transfer(address _from, address _to, uint64 _duckId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint64 index = s.ownerDuckIdIndexes[_from][_duckId];
        uint64 lastIndex = uint64(s.ownerDuckIds[_from].length - 1);
        if (index != lastIndex) {
            uint64 lastDuckId = s.ownerDuckIds[_from][lastIndex];
            s.ownerDuckIds[_from][index] = lastDuckId;
            s.ownerDuckIdIndexes[_from][lastDuckId] = index;
        }
        s.ownerDuckIds[_from].pop();
        delete s.ownerDuckIdIndexes[_from][_duckId];
        if (s.approved[_duckId] != address(0)) {
            delete s.approved[_duckId];
            emit LibERC721.Approval(_from, address(0), _duckId);
        }
        // add
        s.ducks[_duckId].owner = _to;
        s.ownerDuckIdIndexes[_to][_duckId] = uint64(s.ownerDuckIds[_to].length);
        s.ownerDuckIds[_to].push(uint64(_duckId));
        emit LibERC721.Transfer(_from, _to, _duckId);
    }

    // TODO : rework !!
    // ///@notice Allow the owner of an NFT to spend skill points for it(basically to boost the numeric traits of that NFT)
    // ///@dev only valid for claimed ducks
    // ///@param _duckId The identifier of the NFT to spend the skill points on
    // ///@param _values An array of four integers that represent the values of the skill points
    // function spendSkillPoints(uint64 _duckId, int16[4] calldata _values) internal {
    //     AppStorage storage s = LibAppStorage.diamondStorage();
    //     //To test: Prevent underflow (is this ok?), see require below
    //     uint256 totalUsed;
    //     for (uint16 index; index < _values.length; index++) {
    //         totalUsed += LibMaths.abs(_values[index]);

    //         s.ducks[_duckId].characteristics[index] += _values[index];
    //     }
    //     // handles underflow
    //     require(availableSkillPoints(_duckId) >= totalUsed, "DuckGameFacet: Not enough skill points");
    //     //Increment used skill points
    //     s.ducks[_duckId].usedSkillPoints += totalUsed;
    //     // TODO : wip events
    //     // emit SpendSkillpoints(_duckId, _values);
    // }

    ///////////////////////////////////////////
    // MARK: Read functions
    ///////////////////////////////////////////

    function getDuckInfo(uint64 _duckId) internal view returns (DuckInfoDTO memory duckInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        duckInfo_.duckId = _duckId;
        duckInfo_.owner = s.ducks[_duckId].owner;
        duckInfo_.hatchTime = s.ducks[_duckId].hatchTime;
        duckInfo_.randomNumber = s.ducks[_duckId].randomNumber;
        duckInfo_.status = s.ducks[_duckId].status;
        duckInfo_.cycleId = s.ducks[_duckId].cycleId;
        if (duckInfo_.status == DuckStatusType.DUCK) {
            int16[] memory characteristics = getCharacteristicsArray(s.ducks[_duckId]);
            duckInfo_.name = s.ducks[_duckId].name;
            duckInfo_.equippedWearables = getEquippedWearablesArray(s.ducks[_duckId]);
            duckInfo_.equippedBadges = getEquippedBadgesArray(s.ducks[_duckId]);
            duckInfo_.collateral = s.ducks[_duckId].collateralType;
            duckInfo_.escrow = s.ducks[_duckId].escrow;
            duckInfo_.stakedAmount = IERC20(duckInfo_.collateral).balanceOf(duckInfo_.escrow);
            duckInfo_.minimumStake = s.ducks[_duckId].minimumStake;
            duckInfo_.kinship = kinship(_duckId);
            duckInfo_.lastInteracted = s.ducks[_duckId].lastInteracted;
            duckInfo_.satiationTime = s.ducks[_duckId].satiationTime;
            duckInfo_.experience = s.ducks[_duckId].experience;
            duckInfo_.toNextLevel = getRequiredXP(s.ducks[_duckId].level, duckInfo_.experience);
            duckInfo_.level = s.ducks[_duckId].level;
            duckInfo_.usedSkillPoints = s.ducks[_duckId].usedSkillPoints;
            duckInfo_.characteristics = characteristics;
            duckInfo_.statistics = getStatisticsArray(s.ducks[_duckId]);
            duckInfo_.baseRarityScore = LibMaths.baseRarityScore(characteristics);
            (duckInfo_.modifiedCharacteristics, duckInfo_.modifiedRarityScore) =
                modifiedCharacteristicsAndRarityScore(_duckId);
            duckInfo_.locked = s.ducks[_duckId].locked;
            // TODO : wip add items
            // duckInfo_.items = LibItems.itemBalancesOfTokenWithTypes(address(this), _duckId);
        }
    }

    function kinship(uint64 _duckId) internal view returns (uint256 score_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_duckId];
        uint256 lastInteracted = duck.lastInteracted;
        uint256 interactionCount = duck.interactionCount;
        uint256 interval = block.timestamp - lastInteracted;

        uint256 daysSinceInteraction = interval / 24 hours;

        if (interactionCount > daysSinceInteraction) {
            score_ = interactionCount - daysSinceInteraction;
        }
    }

    /**
     * @notice Adds XP to a Duck and updates its level accordingly.
     * @param _duckId The duckId to update.
     * @param xp The amount of XP to add.
     */
    function addXP(uint64 _duckId, uint256 xp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_duckId];
        emit DuckXPAdded(_duckId, duck.level, xp);

        // Continue adding XP and handling level-ups until either XP is exhausted or max level is reached
        while (xp > 0 && duck.level < s.MAX_LEVEL) {
            uint256 remainingXP = s.XP_TABLE[duck.level] - duck.experience;

            if (xp >= remainingXP) {
                // Sufficient XP to level up
                xp -= remainingXP;
                duck.level++;
                duck.experience = 0;
                emit DuckLevelUp(_duckId, duck.level);
                if (duck.level >= s.MAX_LEVEL) {
                    // Duck has reached max level; exit the loop immediately (save gas)
                    break;
                }
            } else {
                // Not enough XP to level up; add remaining XP
                duck.experience += xp;
                xp = 0;
            }
        }
    }

    /**
     * @notice Retrieves the cumulative XP required for a specific level.
     * @param level The level for which to retrieve the XP requirement.
     * @return xp The cumulative XP required to reach the given level.
     */
    function getRequiredXP(uint16 level, uint256 experience) internal view returns (uint256 xp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (level >= s.MAX_LEVEL) {
            xp = 0;
        } else {
            xp = s.XP_TABLE[level] - experience;
        }
    }

    ///////////////////////////////////////////

    //Only valid for claimed Ducks
    function modifiedCharacteristicsAndRarityScore(uint64 _duckId)
        internal
        view
        returns (int16[] memory characteristics_, uint256 rarityScore_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_duckId].status == DuckStatusType.DUCK, "DuckFacet: Must be claimed");
        characteristics_ = getDuckCharacteristics(_duckId);
        // TODO : wip items / work on characteristics mapping directly
        // DuckInfo storage duck = s.ducks[_duckId];
        uint256 wearableBonus;
        // for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
        //     uint256 wearableId = duck.equippedWearables[slot];
        //     if (wearableId == 0) {
        //         continue;
        //     }
        //     ItemType storage itemType = s.itemTypes[wearableId];
        //     //Add on trait modifiers
        //     for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
        //         characteristics_[j] += itemType.traitModifiers[j];
        //     }
        //     wearableBonus += itemType.rarityScoreModifier;
        // }
        uint256 baseRarity = LibMaths.baseRarityScore(characteristics_);
        rarityScore_ = baseRarity + wearableBonus;
    }

    function getDuckCharacteristics(uint64 _duckId) internal view returns (int16[] memory characteristics_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //Check if trait boosts from consumables are still valid
        int256 boostDecay = int256((block.timestamp - s.ducks[_duckId].lastTemporaryBoost) / 24 hours);
        uint256 characteristicsCount = uint256(type(DuckCharacteristicsType).max) + 1;
        characteristics_ = new int16[](characteristicsCount);
        for (uint16 i; i < characteristicsCount; i++) {
            // console2.log("i", i);
            int256 number = s.ducks[_duckId].characteristics[uint16(i)];
            // console2.log("number", number);
            int256 boost = s.ducks[_duckId].temporaryCharacteristicsBoosts[uint16(i)];
            // console2.log("boost", boost);

            if (boost > 0 && boost > boostDecay) {
                number += boost - boostDecay;
            } else if ((boost * -1) > boostDecay) {
                number += boost + boostDecay;
            }
            characteristics_[i] = int16(number);
        }
    }

    function eggDuckTraits(uint64 _duckId) internal view returns (EggDuckTraitsDTO[3] memory eggDuckTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_duckId].status == DuckStatusType.OPEN_EGG, "DuckFacet: Egg not open");

        uint256 randomNumber = s.duckIdToRandomNumber[_duckId];

        uint16 cycleId = s.ducks[_duckId].cycleId;

        uint8 option = s.eggRepickOptions[_duckId];
        for (uint16 i = 1; i <= eggDuckTraits_.length; i++) {
            EggDuckTraitsDTO memory single = singleEggDuckTraits(cycleId, randomNumber, option + i);
            eggDuckTraits_[i].randomNumber = single.randomNumber;
            eggDuckTraits_[i].collateralType = single.collateralType;
            eggDuckTraits_[i].minimumStake = single.minimumStake;
            eggDuckTraits_[i].characteristics = single.characteristics;
            eggDuckTraits_[i].statistics = single.statistics;
        }
    }

    function singleEggDuckTraits(uint16 _cycleId, uint256 _randomNumber, uint256 _option)
        internal
        view
        returns (EggDuckTraitsDTO memory singleEggDuckTraits_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 randomNumberN = uint256(keccak256(abi.encodePacked(_randomNumber, _option)));
        singleEggDuckTraits_.randomNumber = randomNumberN;

        address collateralType =
            s.cycleCollateralTypes[_cycleId][randomNumberN % s.cycleCollateralTypes[_cycleId].length];
        singleEggDuckTraits_.characteristics =
            LibMaths.calculateCharacteristics(randomNumberN, s.collateralTypeInfo[collateralType], _cycleId);
            singleEggDuckTraits_.statistics =
            LibMaths.calculateMaxStatistics(randomNumberN, s.collateralTypeInfo[collateralType], singleEggDuckTraits_.characteristics);
        singleEggDuckTraits_.collateralType = collateralType;
        singleEggDuckTraits_.bodyColorId = s.cycles[_cycleId].allowedBodyColorIds[randomNumberN % s.cycles[_cycleId].allowedBodyColorIds.length];

        // TODO : wip dynamic collateral price
        // CollateralTypeInfo memory collateralInfo = s.collateralTypeInfo[collateralType];
        // uint256 conversionRate = collateralInfo.conversionRate;

        // //Get rarity multiplier
        // uint256 multiplier = LibMaths.rarityMultiplier(singleEggDuckTraits_.characteristics);

        // //First we get the base price of our collateral in terms of DAI
        // uint256 collateralDAIPrice = ((10 ** IERC20(collateralType).decimals()) / conversionRate);

        // //Then multiply by the rarity multiplier
        // singleEggDuckTraits_.minimumStake = collateralDAIPrice * multiplier;

        // TODO : until no minimum stake fixed, set to 1
        singleEggDuckTraits_.minimumStake = 1;
    }

    // TODO : @dev - wip skills systems
    // ///@notice Query the available skill points that can be used for an NFT
    // ///@dev Will throw if the amount of skill points available is greater than or equal to the amount of skill points which have been used
    // ///@param _duckId The identifier of the NFT to query
    // ///@return   An unsigned integer which represents the available skill points of an NFT with identifier `_duckId`
    // function availableSkillPoints(uint64 _duckId) internal view returns (uint256) {
    //     AppStorage storage s = LibAppStorage.diamondStorage();
    //     uint256 skillPoints = LibDuck.calculateSkillPoints(s.ducks[_duckId].level, s.ducks[_duckId].hatchTime);
    //     uint256 usedSkillPoints = s.ducks[_duckId].usedSkillPoints;
    //     require(skillPoints >= usedSkillPoints, "LibDuck: Used skill points is greater than skill points");
    //     return skillPoints - usedSkillPoints;
    // }

    // function calculateSkillPoints(uint256 level, uint256 hatchTime) internal view returns (uint256) {
    //     uint256 skillPoints = (level / 3);
    //     uint256 ageDifference = block.timestamp - hatchTime;
    //     return skillPoints + calculateSkillPointsByAge(ageDifference);
    // }

    // function calculateSkillPointsByAge(uint256 _age) internal pure returns (uint256) {
    //     uint256 skillPointsByAge = 0;
    //     uint256[10] memory fibSequence = [uint256(1), 2, 3, 5, 8, 13, 21, 34, 55, 89];
    //     for (uint256 i = 0; i < fibSequence.length; i++) {
    //         if (_age > fibSequence[i] * 2300000) {
    //             skillPointsByAge++;
    //         } else {
    //             break;
    //         }
    //     }
    //     return skillPointsByAge;
    // }

    /////////////////////////////////////////////////////////////////////////////////
    // Utils
    /////////////////////////////////////////////////////////////////////////////////

    function getCharacteristicsArray(DuckInfo storage duckInfo)
        internal
        view
        returns (int16[] memory characteristicsArray_)
    {
        uint16 characteristicsCount = uint16(type(DuckCharacteristicsType).max) + 1;
        characteristicsArray_ = new int16[](characteristicsCount);

        for (uint16 i = 0; i < characteristicsCount; i++) {
            characteristicsArray_[i] = duckInfo.characteristics[i];
        }
    }

    function getModifiersArray(CollateralTypeInfo storage collateral)
        internal
        view
        returns (int16[] memory modifiersArray_)
    {
        uint16 characteristicsCount = uint16(type(DuckCharacteristicsType).max) + 1;
        modifiersArray_ = new int16[](characteristicsCount);

        for (uint16 i = 0; i < characteristicsCount; i++) {
            modifiersArray_[i] = collateral.modifiers[i];
        }
    }

    function getStatisticsArray(DuckInfo storage duckInfo) internal view returns (uint16[] memory statisticsArray_) {
        uint16 statisticsCount = uint16(type(DuckStatisticsType).max) + 1;
        statisticsArray_ = new uint16[](statisticsCount);

        for (uint16 i = 0; i < statisticsCount; i++) {
            statisticsArray_[i] = duckInfo.statistics[i];
        }
    }

    function getEquippedWearablesArray(DuckInfo storage duckInfo)
        internal
        view
        returns (uint256[] memory wearablesArray_)
    {
        uint256 wearableCount = uint256(type(DuckWearableSlot).max) + 1;

        wearablesArray_ = new uint256[](wearableCount);

        for (uint16 i = 0; i < wearableCount; i++) {
            wearablesArray_[i] = duckInfo.equippedWearables[i];
        }
    }

    function getEquippedBadgesArray(DuckInfo storage duckInfo) internal view returns (uint256[] memory badgesArray_) {
        uint256 badgesCount = uint256(type(DuckBadgeSlot).max) + 1;

        badgesArray_ = new uint256[](badgesCount);

        for (uint16 i = 0; i < badgesCount; i++) {
            badgesArray_[i] = duckInfo.equippedBadges[i];
        }
    }
}
