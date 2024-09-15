// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {
    DuckInfo,
    DuckInfoDTO,
    EggDuckTraitsDTO,
    DuckStatusType,
    DuckCharacteristicsType,
    DuckStatisticsType
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
    event DuckInteract(uint256 indexed _tokenId, uint256 kinship);
    event EggOpened(uint256 indexed tokenId);

    ///////////////////////////////////////////
    // MARK: Write functions
    ///////////////////////////////////////////

    function openEggWithVRF(uint256 _requestId, uint256[] memory _randomWords) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];
        require(s.ducks[tokenId].status == DuckStatusType.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[tokenId].status = DuckStatusType.OPEN_EGG;
        s.eggIdToRandomNumber[tokenId] = _randomWords[0];

        emit EggOpened(tokenId);
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
        console2.log("duck.status", uint256(duck.status));
        require(duck.status == DuckStatusType.OPEN_EGG, "DuckGameFacet: Egg not open");
        require(_option < 10, "DuckGameFacet: Only 10 duck options available");
        uint256 randomNumber = s.eggIdToRandomNumber[_tokenId];
        uint256 cycleId = s.ducks[_tokenId].cycleId;

        EggDuckTraitsDTO memory option = singleEggDuckTraits(cycleId, randomNumber, _option);
        duck.randomNumber = option.randomNumber;
        duck.collateralType = option.collateralType;
        duck.minimumStake = option.minimumStake;
        duck.lastInteracted = uint40(block.timestamp - 12 hours);
        duck.interactionCount = 50;
        duck.hatchTime = uint40(block.timestamp);
        // assign characteristics
        for (uint256 i; i < option.characteristics.length; i++) {
            duck.characteristics[uint16(i)] = option.characteristics[i];
        }
        // TODO : wip base statistics
        // // assign statistics
        // for (uint256 i; i < option.statistics.length; i++) {
        //     EnumerableMap.set(duck.statistics, i, option.statistics[i]);
        // }

        require(_stakeAmount >= option.minimumStake, "DuckGameFacet: _stakeAmount less than minimum stake");

        duck.status = DuckStatusType.DUCK;
        // TODO : wip events
        // emit DuckClaimed(_tokenId);

        address escrow = address(new CollateralEscrow(option.collateralType));
        duck.escrow = escrow;

        LibERC20.safeTransferFrom(option.collateralType, _owner, escrow, _stakeAmount);
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
        require(s.ducks[_tokenId].status == DuckStatusType.DUCK, "DuckGameFacet: Must claim Duck before setting name");
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

        function interact(uint256 _tokenId) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lastInteracted = s.ducks[_tokenId].lastInteracted;
        // if interacted less than 12 hours ago
        if (block.timestamp < lastInteracted + 12 hours) {
            return false;
        }

        uint256 interactionCount = s.ducks[_tokenId].interactionCount;
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
        s.ducks[_tokenId].interactionCount = l_kinship;

        s.ducks[_tokenId].lastInteracted = uint40(block.timestamp);
        emit DuckInteract(_tokenId, l_kinship);
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

    // TODO : rework !!
    ///@notice Allow the owner of an NFT to spend skill points for it(basically to boost the numeric traits of that NFT)
    ///@dev only valid for claimed ducks
    ///@param _tokenId The identifier of the NFT to spend the skill points on
    ///@param _values An array of four integers that represent the values of the skill points
    function spendSkillPoints(uint256 _tokenId, int16[4] calldata _values) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //To test: Prevent underflow (is this ok?), see require below
        uint256 totalUsed;
        for (uint16 index; index < _values.length; index++) {
            totalUsed += LibMaths.abs(_values[index]);

            s.ducks[_tokenId].characteristics[index] += _values[index];
        }
        // handles underflow
        require(availableSkillPoints(_tokenId) >= totalUsed, "DuckGameFacet: Not enough skill points");
        //Increment used skill points
        s.ducks[_tokenId].usedSkillPoints += totalUsed;
        // TODO : wip events
        // emit SpendSkillpoints(_tokenId, _values);
    }

    ///////////////////////////////////////////
    // MARK: Read functions
    ///////////////////////////////////////////

    function getDuckInfo(uint256 _tokenId) internal view returns (DuckInfoDTO memory duckInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        duckInfo_.tokenId = _tokenId;
        duckInfo_.owner = s.ducks[_tokenId].owner;
        duckInfo_.hatchTime = s.ducks[_tokenId].hatchTime;
        duckInfo_.randomNumber = s.ducks[_tokenId].randomNumber;
        duckInfo_.status = s.ducks[_tokenId].status;
        duckInfo_.cycleId = s.ducks[_tokenId].cycleId;
        if (duckInfo_.status == DuckStatusType.DUCK) {
            int16[] memory characteristics = getCharacteristicsArray(s.ducks[_tokenId]);
            duckInfo_.name = s.ducks[_tokenId].name;
            duckInfo_.equippedWearables = getEquippedWearablesArray(s.ducks[_tokenId]);
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
            duckInfo_.characteristics = characteristics;
            duckInfo_.statistics = getStatisticsArray(s.ducks[_tokenId]);
            duckInfo_.baseRarityScore = LibMaths.baseRarityScore(characteristics);
            (duckInfo_.modifiedCharacteristics, duckInfo_.modifiedRarityScore) =
                modifiedCharacteristicsAndRarityScore(_tokenId);
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

    ///////////////////////////////////////////
    // Old Version XP calculation
    // function xpUntilNextLevel(uint256 _experience) internal pure returns (uint256 requiredXp_) {
    //     uint256 currentLevel = duckLevel(_experience);
    //     requiredXp_ = ((currentLevel ** 2) * 50) - _experience;
    // }

    // function duckLevel(uint256 _experience) internal pure returns (uint256 level_) {
    //     if (_experience > 490050) {
    //         return 99;
    //     }

    //     level_ = (LibMaths.sqrt(2 * _experience) / 10);
    //     return level_ + 1;
    // }
    ///////////////////////////////////////////
    // New Version XP calculation

        /**
     * @notice Adds XP to a Duck and updates its level accordingly.
     * @param _tokenId The duckId to update.
     * @param xp The amount of XP to add.
     */
    function addXP(uint256 _tokenId, uint256 xp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_tokenId];
        duck.experience += xp;
        if (duck.experience >= getCumulativeXP(s.MAX_LEVEL)) {
            duck.experience = getCumulativeXP(s.MAX_LEVEL);
            duck.level = s.MAX_LEVEL;
        } else {
            duck.level = calculateLevel(duck.experience);
        }
    }


        /**
     * @notice Retrieves the cumulative XP required for a specific level.
     * @param level The level for which to retrieve the XP requirement.
     * @return xp The cumulative XP required to reach the given level.
     */
    function getCumulativeXP(uint256 level) internal pure returns (uint256 xp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(level <= s.MAX_LEVEL, "LibDuck: Level exceeds max level");
        xp = s.XP_TABLE[level];
    }

    /**
     * @notice Determines the current level based on total XP using binary search.
     * @param totalXP The total accumulated XP of the Duck.
     * @return level The current level of the Duck.
     */
    function calculateLevel(uint256 totalXP) internal pure returns (uint256 level) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 left = 1;
        uint256 right = s.MAX_LEVEL;
        uint256 mid;

        while (left <= right) {
            mid = (left + right) / 2;
            uint256 xpAtMid = getCumulativeXP(mid);

            if (totalXP < xpAtMid) {
                right = mid - 1;
            } else {
                uint256 xpAtNext = mid < s.MAX_LEVEL ? getCumulativeXP(mid + 1) : xpAtMid;
                if (totalXP < xpAtNext) {
                    return mid;
                }
                left = mid + 1;
            }
        }

        return s.MAX_LEVEL;
    }
    ///////////////////////////////////////////


    //Only valid for claimed Ducks
    function modifiedCharacteristicsAndRarityScore(uint256 _tokenId)
        internal
        view
        returns (int16[] memory characteristics_, uint256 rarityScore_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == DuckStatusType.DUCK, "DuckFacet: Must be claimed");
        characteristics_ = getDuckCharacteristics(_tokenId);
        // TODO : wip items / work on characteristics mapping directly
        // DuckInfo storage duck = s.ducks[_tokenId];
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

    function getDuckCharacteristics(uint256 _tokenId) internal view returns (int16[] memory characteristics_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //Check if trait boosts from consumables are still valid
        int256 boostDecay = int256((block.timestamp - s.ducks[_tokenId].lastTemporaryBoost) / 24 hours);
        uint256 characteristicsCount = uint256(type(DuckCharacteristicsType).max) + 1;
        characteristics_ = new int16[](characteristicsCount);
        for (uint256 i; i < characteristicsCount; i++) {
            // console2.log("i", i);
            int256 number = s.ducks[_tokenId].characteristics[uint16(i)];
            // console2.log("number", number);
            int256 boost = s.ducks[_tokenId].temporaryCharacteristicsBoosts[uint16(i)];
            // console2.log("boost", boost);

            if (boost > 0 && boost > boostDecay) {
                number += boost - boostDecay;
            } else if ((boost * -1) > boostDecay) {
                number += boost + boostDecay;
            }
            characteristics_[i] = int16(number);
        }
    }

    function eggDuckTraits(uint256 _tokenId) internal view returns (EggDuckTraitsDTO[10] memory eggDuckTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.ducks[_tokenId].status == DuckStatusType.OPEN_EGG, "DuckFacet: Egg not open");

        uint256 randomNumber = s.eggIdToRandomNumber[_tokenId];

        uint256 cycleId = s.ducks[_tokenId].cycleId;

        for (uint256 i; i < eggDuckTraits_.length; i++) {
            EggDuckTraitsDTO memory single = singleEggDuckTraits(cycleId, randomNumber, i);
            eggDuckTraits_[i].randomNumber = single.randomNumber;
            eggDuckTraits_[i].collateralType = single.collateralType;
            eggDuckTraits_[i].minimumStake = single.minimumStake;
            eggDuckTraits_[i].characteristics = single.characteristics;
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
        singleEggDuckTraits_.characteristics =
            LibMaths.calculateCharacteristics(randomNumberN, s.collateralTypeInfo[collateralType], _cycleId);
        singleEggDuckTraits_.collateralType = collateralType;

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



    ///@notice Query the available skill points that can be used for an NFT
    ///@dev Will throw if the amount of skill points available is greater than or equal to the amount of skill points which have been used
    ///@param _tokenId The identifier of the NFT to query
    ///@return   An unsigned integer which represents the available skill points of an NFT with identifier `_tokenId`
    function availableSkillPoints(uint256 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 skillPoints =
            LibDuck.calculateSkillPoints(_tokenId, s.ducks[_tokenId].experience, s.ducks[_tokenId].hatchTime);
        uint256 usedSkillPoints = s.ducks[_tokenId].usedSkillPoints;
        require(skillPoints >= usedSkillPoints, "LibDuck: Used skill points is greater than skill points");
        return skillPoints - usedSkillPoints;
    }

    function calculateSkillPoints(uint256 _tokenId, uint256 experience, uint256 hatchTime)
        internal
        view
        returns (uint256)
    {
        uint256 level = duckLevel(experience);
        uint256 skillPoints = (level / 3);

        uint256 ageDifference = block.timestamp - hatchTime;
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
    // Utils
    /////////////////////////////////////////////////////////////////////////////////

    function getCharacteristicsArray(DuckInfo storage duckInfo)
        internal
        view
        returns (int16[] memory characteristicsArray_)
    {
        uint256 characteristicsCount = uint256(type(DuckCharacteristicsType).max) + 1;
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
        uint256 characteristicsCount = uint256(type(DuckCharacteristicsType).max) + 1;
        modifiersArray_ = new int16[](characteristicsCount);

        for (uint16 i = 0; i < characteristicsCount; i++) {
            modifiersArray_[i] = collateral.modifiers[i];
        }
    }

    function getStatisticsArray(DuckInfo storage duckInfo) internal view returns (int16[] memory statisticsArray_) {
        uint256 statisticsCount = uint256(type(DuckStatisticsType).max) + 1;
        statisticsArray_ = new int16[](statisticsCount);

        for (uint16 i = 0; i < statisticsCount; i++) {
            statisticsArray_[i] = duckInfo.statistics[i];
        }
    }

    function getEquippedWearablesArray(DuckInfo storage duckInfo)
        internal
        view
        returns (uint256[] memory wearablesArray_)
    {
        // TODO : set total equipped wearable count
        // uint256 wearableCount = uint256(type(DuckCharacteristicsType).max) + 1;
        uint256 wearableCount = 16;

        wearablesArray_ = new uint256[](wearableCount);

        for (uint16 i = 0; i < wearableCount; i++) {
            wearablesArray_[i] = duckInfo.equippedWearables[i];
        }
    }
}
