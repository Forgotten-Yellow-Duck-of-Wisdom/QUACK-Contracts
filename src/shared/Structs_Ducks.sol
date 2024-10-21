// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/////////////////////////////////
/// MARK: ENUM: Duck Types
/////////////////////////////////

enum DuckStatusType {
    CLOSED_EGGS,
    VRF_PENDING,
    OPEN_EGG,
    DUCK
}

enum DuckCharacteristicsType {
    STRENGTH,
    AGILITY,
    INTELLIGENCE,
    PERCEPTION,
    CHARISME,
    LUCK
}

enum DuckStatisticsType {
    HEALTH,
    MANA,
    SPECIAL,
    ENERGY,
    FOOD,
    SANITY
}

enum DuckWearableSlot {
    BODY,
    FACE,
    EYES,
    HEAD,
    MOUTH,
    HAND_LEFT,
    HAND_RIGHT,
    FEET,
    SPECIAL
}

enum DuckBadgeSlot {
    BADGE_1,
    BADGE_2,
    BADGE_3,
    BADGE_4,
    BADGE_5,
    BADGE_6
}

// For later upgrades
// enum DuckTraitType {
// }

/////////////////////////////////
/// MARK: STORAGE
/////////////////////////////////
struct Cycle {
    //The max number of ducks of the Cycle
    uint256 cycleMaxSize;
    uint256 eggsPrice;
    uint24 totalCount;
    uint256[] allowedBodyColorItemIds;
}
// uint256[] allowedWearableItemIds;

struct DuckInfo {
    // owner address
    address owner;
    address collateralType;
    //The escrow address this Duck manages.
    address escrow;
    string name;
    uint16 cycleId;
    //The block timestamp when this Duck was claimed
    uint40 hatchTime;
    // TODO : update to mapping uint uint to store multiple random number (create enum ?)
    uint256 randomNumber;
    uint256 experience;
    uint16 level;
    //The number of skill points this Duck has already used
    uint256 usedSkillPoints;
    //How many times the owner of this Duck has interacted with it.
    uint256 interactionCount;
    //The last time this Duck was interacted with
    uint40 lastInteracted;
    uint40 lastTemporaryBoost;
    uint40 satiationTime; // how many time before need to eat
    //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 minimumStake;
    // vrf
    uint256 bodyColorItemId;
    DuckStatusType status; // 0 == egg, 1 == VRF_PENDING, 2 == open egg, 3 == Duck
    bool locked;
    //The currently equipped wearables of the Duck
    mapping(uint16 => uint256) equippedWearables;
    //The currently equipped badges of the Duck
    mapping(uint16 => uint256) equippedBadges;
    // DuckCharacteristicsType => value
    mapping(uint16 => int16) characteristics;
    // DuckCharacteristicsType => value
    mapping(uint16 => int16) temporaryCharacteristicsBoosts;
    // DuckStatisticsType => value
    mapping(uint16 => uint16) statistics;
    // DuckStatisticsType => value
    mapping(uint16 => uint16) maxStatistics;
    mapping(uint16 => int16) traits;
}

/////////////////////////////////
/// MARK: Memory structs (DTO)
/////////////////////////////////
struct EggDuckTraitsDTO {
    uint256 randomNumber;
    int16[] characteristics;
    uint16[] statistics;
    // int16[] traits;
    address collateralType;
    uint256 minimumStake;
    uint256 bodyColorItemId;
}

struct DuckInfoDTO {
    uint64 duckId;
    string name;
    address owner;
    uint40 hatchTime;
    // TODO : update to mapping uint uint to store multiple random number (create enum ?)
    uint256 randomNumber;
    DuckStatusType status;
    int16[] characteristics;
    int16[] modifiedCharacteristics;
    uint16[] statistics;
    uint16[] maxStatistics;
    // int16[] traits;
    uint256[] equippedWearables;
    uint256[] equippedBadges;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    //The kinship value of this Duck. Default is 50.
    uint256 kinship;
    uint256 lastInteracted;
    //How much XP this Duck has accrued. Begins at 0.
    uint256 experience;
    uint256 toNextLevel;
    //number of skill points used
    uint256 usedSkillPoints;
    //the current Duck level
    uint16 level;
    uint256 cycleId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
}
// ItemTypeIO[] items; // TODO: add items

struct DucksIdsWithKinshipDTO {
    uint256 tokenId;
    uint256 kinship;
    uint256 lastInteracted;
}
