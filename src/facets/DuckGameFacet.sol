// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, EggDuckTraitsDTO, DucksIdsWithKinshipDTO, DuckStatusType} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC20} from "../libs/LibERC20.sol";
import {LibString} from "../libs/LibString.sol";
import {LibMaths} from "../libs/LibMaths.sol";
import {LibChainlinkVRF} from "../libs/LibChainlinkVRF.sol";

/**
 * Duck Game Facet -
 */
contract DuckGameFacet is AccessControl {
    event BuyEggs(address indexed _from, address indexed _to, uint256 _duckId, uint256 _price);

    event OpenEggs(uint256[] _tokenIds);

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ///////////////////////////////////////////////////////////

    // TODO : 1 or more egg can be purchased ?
    // todo : add non reentrancy guard
    ///@notice Allow an address to purchase a duck egg
    ///@param _to Address to send the egg once purchased
    function buyEggs(address _to) external returns (uint32 duckId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentCycleId = s.currentCycleId;
        require(currentCycleId == 1, "DuckGameFacet: Can only purchase from cycle 1");
        Cycle storage cycle = s.cycles[currentCycleId];
        uint256 price = cycle.eggsPrice;

        address sender = _msgSender();

        uint256 cycleCount = cycle.totalCount + 1;
        require(cycleCount <= cycle.cycleMaxSize, "DuckGameFacet: Exceeded max number of duck for this cycle");
        s.cycles[currentCycleId].totalCount = uint24(cycleCount);
        uint32 duckId = s.duckIdCounter;
        duckId_ = duckId;
        emit BuyEggs(sender, _to, duckId, price);
        s.ducks[duckId].owner = _to;
        s.ducks[duckId].cycleId = uint16(currentCycleId);
        s.duckIdIndexes[duckId] = s.duckIds.length;
        s.duckIds.push(duckId);
        s.ownerDuckIdIndexes[_to][duckId] = s.ownerDuckIds[_to].length;
        s.ownerDuckIds[_to].push(duckId);
        emit LibERC721.Transfer(address(0), _to, duckId);
        duckId++;
        s.duckIdCounter = duckId;

        LibERC20.safeTransferFrom(address(s.quackTokenAddress), sender, address(this), price);
        // LibDuck.purchase(sender, totalPrice);
    }

    function openEggs(uint256[] calldata _tokenIds) external payable {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = _msgSender();
        uint256 requestPrice = s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit, s.vrfNumWords);
        require(msg.value >= requestPrice * _tokenIds.length, "VRFFacet: Not enough native funds for chainlink VRF");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(s.ducks[tokenId].status == DuckStatusType.CLOSED_EGGS, "VRFFacet: Eggs is not closed");
            require(owner == s.ducks[tokenId].owner, "VRFFacet: Only duck owner can open an egg");
            require(s.ducks[tokenId].locked == false, "VRFFacet: Can't open eggs when it is locked");
            LibChainlinkVRF.requestRandomWords(tokenId, requestPrice);
        }
        emit OpenEggs(_tokenIds);
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
        isDuckOwner(_tokenId)
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
        isDuckOwner(_tokenId)
    {
        LibDuck.setDuckName(_tokenId, _name);
    }

    ///@notice Allow the owner of an NFT to interact with them.thereby increasing their kinship(petting)
    ///@dev only valid for claimed ducks
    ///@dev Kinship will only increase if the lastInteracted minus the current time is greater than or equal to 12 hours
    ///@param _tokenIds An array containing the token identifiers of the claimed ducks that are to be interacted with
    function interact(uint256[] calldata _tokenIds) external {
        address sender = _msgSender();
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            address owner = s.ducks[tokenId].owner;

            require(
                sender == owner || s.operators[owner][sender] || s.approved[tokenId] == sender
                    || s.petOperators[owner][sender],
                "DuckGameFacet: Not owner of token or approved"
            );

            require(s.ducks[tokenId].status == DuckStatusType.DUCK, "DuckGameFacet: Only valid for Duck");
            LibDuck.interact(tokenId);
        }
    }

    // TODO : wip characterisitcs
    // ///@notice Allow the owner of an NFT to spend skill points for it(basically to boost the numeric traits of that NFT)
    // ///@dev only valid for claimed ducks
    // ///@param _tokenId The identifier of the NFT to spend the skill points on
    // ///@param _values An array of four integers that represent the values of the skill points
    // function spendSkillPoints(uint256 _tokenId, int16[4] calldata _values)
    //     external
    //     onlyUnlocked(_tokenId)
    //     isDuckOwner(_tokenId)
    // {
    //     LibDuck.spendSkillPoints(_tokenId, _values);
    // }

    /// TODO : later upgrade
    // function resetSkillPoints(uint32 _tokenId)

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ///////////////////////////////////////////////////////////

    ///@notice Check if a string `_name` has not been assigned to another NFT
    ///@param _name Name to check
    ///@return available_ True if the name has not been taken, False otherwise
    function duckNameAvailable(string calldata _name) external view returns (bool available_) {
        available_ = LibAppStorage.diamondStorage().duckNamesUsed[LibString.validateAndLowerName(_name)];
    }

    ///@notice Check the latest Cycle identifier and details
    ///@return cycleId_ The latest cycle identifier
    ///@return cycle_ A struct containing the details about the latest cycle`

    function currentCycle() external view returns (uint256 cycleId_, Cycle memory cycle_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        cycleId_ = s.currentCycleId;
        cycle_ = s.cycles[cycleId_];
    }

    // TODO: replace 10 hardcoded value with constant EGG_DUCKS_NUM
    ///@notice Query all details associated with an NFT like collateralType,characteristics e.t.c
    ///@param _tokenId Identifier of the NFT to query
    ///@return eggDuckTraits_ A struct containing all details about the NFT with identifier `_tokenId`

    function eggDuckTraits(uint256 _tokenId) external view returns (EggDuckTraitsDTO[10] memory eggDuckTraits_) {
        eggDuckTraits_ = LibDuck.eggDuckTraits(_tokenId);
    }

    ///@notice Query the numeric traits of an NFT
    ///@dev Only valid for claimed Ducks
    ///@param _tokenId The identifier of the NFT to query
    ///@return characteristics_ An array containing integers,each representing the traits of the NFT with identifier `_tokenId`
    function getDuckCharacteristics(uint256 _tokenId) external view returns (int16[] memory characteristics_) {
        characteristics_ = LibDuck.getDuckCharacteristics(_tokenId);
    }

    ///@notice Query the skill reset count of an Duck
    ///@param _tokenId The identifier of the Duck to query
    ///@return respecCount_ The number of times an Duck has performed a skill reset
    function respecCount(uint32 _tokenId) external view returns (uint256 respecCount_) {
        respecCount_ = LibAppStorage.diamondStorage().duckRespecCount[_tokenId];
    }

    ///@notice Query the available skill points that can be used for an NFT
    ///@dev Will throw if the amount of skill points available is greater than or equal to the amount of skill points which have been used
    ///@param _tokenId The identifier of the NFT to query
    ///@return availableSkillPoints_ An unsigned integer which represents the available skill points of an NFT with identifier `_tokenId`
    function availableSkillPoints(uint256 _tokenId) public view returns (uint256 availableSkillPoints_) {
        availableSkillPoints_ = LibDuck.availableSkillPoints(_tokenId);
    }

    ///@notice Calculate the XP needed for an NFT to advance to the next level
    ///@dev Only valid for claimed Ducks
    ///@param _level The current level of an NFT
    ///@param _experience The current XP points gathered by an NFT
    ///@return requiredXp_ The XP required for the NFT to move to the next level
    function xpUntilNextLevel(uint16 _level, uint256 _experience) external view returns (uint256 requiredXp_) {
        requiredXp_ = LibDuck.getRequiredXP(_level, _experience);
    }

    function xpTable() external view returns (uint256[] memory xpTable_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint16 maxLevel = s.MAX_LEVEL;
        xpTable_ = new uint256[](maxLevel); // index level start at 0

        for (uint16 i = 0; i < maxLevel; i++) {
            xpTable_[i] = s.XP_TABLE[i];
        }
    }

    // TODO : rework or fetch for global duck infos
    // ///@notice Compute the rarity multiplier of an NFT
    // ///@dev Only valid for claimed Ducks
    // ///@param _characteristics An array of six integers each representing a numeric trait of an NFT
    // ///return multiplier_ The rarity multiplier of an NFT with numeric traits `_characteristics`
    // function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _characteristics)
    //     external
    //     pure
    //     returns (uint256 multiplier_)
    // {
    //     multiplier_ = LibMaths.rarityMultiplier(_characteristics);
    // }

    // TODO : rework or fetch for global duck infos
    // ///@notice Calculates the base rarity score, including collateral modifier
    // ///@dev Only valid for claimed Ducks
    // ///@param _characteristics An array of six integers each representing a numeric trait of an NFT
    // ///@return rarityScore_ The base rarity score of an NFT with numeric traits `_characteristics`
    // function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _characteristics)
    //     external
    //     pure
    //     returns (uint256 rarityScore_)
    // {
    //     rarityScore_ = LibMaths.baseRarityScore(_characteristics);
    // }

    ///@notice Check the modified traits and rarity score of an NFT(as a result of equipped wearables)
    ///@dev Only valid for claimed Ducks
    ///@param _tokenId Identifier of the NFT to query
    ///@return characteristics_ An array of six integers each representing a numeric trait(modified) of an NFT with identifier `_tokenId`
    ///@return rarityScore_ The modified rarity score of an NFT with identifier `_tokenId`
    //Only valid for claimed Ducks
    function modifiedCharacteristicsAndRarityScore(uint256 _tokenId)
        external
        view
        returns (int16[] memory characteristics_, uint256 rarityScore_)
    {
        (characteristics_, rarityScore_) = LibDuck.modifiedCharacteristicsAndRarityScore(_tokenId);
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
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32[] memory tokenIds = s.ownerDuckIds[_owner];
        uint256 length = all ? tokenIds.length : _count;
        tokenIdsWithKinship_ = new DucksIdsWithKinshipDTO[](length);

        if (!all) {
            require(_skip + _count <= tokenIds.length, "DuckGameFacet: Owner does not have up to that amount of tokens");
        }

        for (uint256 i; i < length; i++) {
            uint256 offset = i + _skip;
            uint32 tokenId = tokenIds[offset];
            if (s.ducks[tokenId].status == DuckStatusType.DUCK) {
                tokenIdsWithKinship_[i].tokenId = tokenId;
                tokenIdsWithKinship_[i].kinship = LibDuck.kinship(tokenId);
                tokenIdsWithKinship_[i].lastInteracted = s.ducks[tokenId].lastInteracted;
            }
        }
    }

    function isDuckLocked(uint256 _tokenId) external view returns (bool isLocked) {
        isLocked = LibAppStorage.diamondStorage().ducks[_tokenId].locked;
    }

    function getDuckBaseCharacteristics(uint32 _tokenId) public view returns (int16[] memory characteristics_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // cast to uint256 for CollateralTypes key
        uint256 cycleId = uint256(s.ducks[_tokenId].cycleId);
        uint256 randomNumber = s.ducks[_tokenId].randomNumber;
        address collateralType = s.ducks[_tokenId].collateralType;
        characteristics_ =
            LibMaths.calculateCharacteristics(randomNumber, s.collateralTypeInfo[collateralType], cycleId);
    }
}
