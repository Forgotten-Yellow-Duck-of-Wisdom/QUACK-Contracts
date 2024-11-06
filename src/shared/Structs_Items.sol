// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// struct Dimensions {
//     uint8 x;
//     uint8 y;
//     uint8 width;
//     uint8 height;
// }

enum ItemTypeCategory {
    WEARABLE,
    BADGE,
    CONSUMABLE,
    SKILL,
    CURRENCY // (no decimals ?)
}

struct ItemType {
    //The name of the item
    string name;
    string description;
    address author;
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    int16[] characteristicsModifiers;
    //[WEARABLE + CONSUMABLE(TODO?) ONLY] How much the wearable modifies each stat. Should not be more than +-5 total
    int16[] statisticsModifiers;
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    uint8[] allowedCollaterals;
    // // SVG x,y,width,height
    // Dimensions dimensions;
    //How much $QUACK this item costs
    uint256 quackPrice;
    //Total number that can be minted of this item.
    uint256 maxQuantity;
    //The total quantity of this item minted so far
    uint256 totalQuantity;
    //The svgId of the item
    uint32 svgId;
    //Number from 1-50.
    uint8 rarityScoreModifier;
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithQuack;
    //The minimum Quack level required to use this item. Default is 1.
    uint16 minLevel;
    bool canBeTransferred;
    // enum ItemTypeCategory
    uint8 category;
    //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    int16 kinshipBonus;
    //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) experience
    uint32 experienceBonus;
}

struct ItemTypeDTO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct ItemIdDTO {
    uint256 itemId;
    uint256 balance;
}

// struct WearableSet {
//     string name;
//     uint8[] allowedCollaterals;
//     uint16[] wearableIds; // The tokenIdS of each piece of the set
//     int8[TRAIT_BONUSES_NUM] traitsBonuses;
// }
