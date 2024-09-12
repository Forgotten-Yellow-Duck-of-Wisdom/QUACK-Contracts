// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant EGG_DUCKS_NUM = 10;

/////////////////////////////////
/// MARK: Storage structs
/////////////////////////////////

enum DuckStatus {
    CLOSED_EGG,
    VRF_PENDING,
    OPEN_EGG,
    DUCK
}

struct EggDuckTraitsDTO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

struct Cycle {
    //The max size of the Cycle
    uint256 cycleMaxSize;
    uint256 eggPrice;
    uint24 totalCount;
}

struct DucksIdsWithKinshipDTO {
    uint256 tokenId;
    uint256 kinship;
    uint256 lastInteracted;
}

struct DuckInfo {
    // owner address
    address owner;
    address collateralType;
    //The escrow address this Duck manages.
    address escrow;
    string name;
    uint16 cycleId;
    //The block timestamp when this Duck was claimed
    uint40 claimTime;
    uint256 randomNumber;
    uint256 experience;
    //The number of skill points this Duck has already used
    uint256 usedSkillPoints;
    //How many times the owner of this Duck has interacted with it.
    uint256 interactionCount;
    //The last time this Character was interacted with
    uint40 lastInteracted;
    uint40 lastTemporaryBoost;
    //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 minimumStake;
    // vrf
    bytes3 bodyColor;
    DuckStatus status; // 0 == egg, 1 == VRF_PENDING, 2 == open egg, 3 == Duck
    bool locked;
    //The currently equipped wearables of the Duck
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;
    // Sixteen 16 bit ints.  [Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int16[NUMERIC_TRAITS_NUM] numericTraits;
}

/////////////////////////////////
/// MARK: Memory structs (DTO)
/////////////////////////////////

struct DuckInfoDTO {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    DuckStatus status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Duck. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Duck has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current Duck level
    uint256 cycleId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
}
// ItemTypeIO[] items; // TODO: add items
