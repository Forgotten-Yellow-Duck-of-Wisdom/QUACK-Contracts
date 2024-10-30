// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";
import {ItemType} from "../src/shared/Structs_Items.sol";
contract TestItems is TestBaseContract {
    uint16 cycleId;
    Cycle cycle;
    int16[] quackModifiers;
    ///////////////////////////////////////////////////////////////////////////////////
    // Utils
    ///////////////////////////////////////////////////////////////////////////////////
    function util_toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256[] memory _bodyColorIds) internal {
        uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorIds);
        (cycleId, cycle) = diamond.currentCycle();
        assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
        assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
        assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
        assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
        for (uint256 i; i < _bodyColorIds.length; i++) {
            assertEq(cycle.allowedBodyColorIds[i], _bodyColorIds[i], "util_createCycle: Invalid Allowed Body Color Item Id");
        }
    }

function util_createItemType(ItemType memory _itemType) public {
    // Add the new ItemType to the contract
    ItemType[] memory items = new ItemType[](1);
    items[0] = _itemType;
    diamond.addItemTypes(items);

    // Retrieve the added ItemType to verify
    ItemType memory item = diamond.getItemType(0);

    // Assertions to ensure the item was created correctly
    assertEq(item.name, _itemType.name, "Item name should match the input");
    assertEq(item.description, _itemType.description, "Item description should match the input");
    assertEq(item.author, _itemType.author, "Item author should match the input");

    // Verify characteristics modifiers
    for (uint256 i = 0; i < _itemType.characteristicsModifiers.length; i++) {
        assertEq(
            item.characteristicsModifiers[i],
            _itemType.characteristicsModifiers[i],
            string(abi.encodePacked("Characteristics modifier ", util_toString(i), " should match"))
        );
    }

    // Verify statistics modifiers
    for (uint256 i = 0; i < _itemType.statisticsModifiers.length; i++) {
        assertEq(
            item.statisticsModifiers[i],
            _itemType.statisticsModifiers[i],
            string(abi.encodePacked("Statistics modifier ", util_toString(i), " should match"))
        );
    }

    // Verify slot positions
    for (uint256 i = 0; i < _itemType.slotPositions.length; i++) {
        assertEq(
            item.slotPositions[i],
            _itemType.slotPositions[i],
            string(abi.encodePacked("Slot position ", util_toString(i), " should match"))
        );
    }

    // Verify allowed collaterals
    for (uint256 i = 0; i < _itemType.allowedCollaterals.length; i++) {
        assertEq(
            item.allowedCollaterals[i],
            _itemType.allowedCollaterals[i],
            string(abi.encodePacked("Allowed collateral ", util_toString(i), " should match"))
        );
    }

    // Verify other attributes
    assertEq(item.quackPrice, _itemType.quackPrice, "Quack price should match the input");
    assertEq(item.maxQuantity, _itemType.maxQuantity, "Max quantity should match the input");
    assertEq(item.totalQuantity, _itemType.totalQuantity, "Total quantity should match the input");
    assertEq(item.svgId, _itemType.svgId, "SVG ID should match the input");
    assertEq(item.rarityScoreModifier, _itemType.rarityScoreModifier, "Rarity score modifier should match the input");
    assertEq(item.canPurchaseWithQuack, _itemType.canPurchaseWithQuack, "Can purchase with quack should match the input");
    assertEq(item.minLevel, _itemType.minLevel, "Min level should match the input");
    assertEq(item.canBeTransferred, _itemType.canBeTransferred, "Can be transferred should match the input");
    assertEq(item.category, _itemType.category, "Category should match the input");
    assertEq(item.kinshipBonus, _itemType.kinshipBonus, "Kinship bonus should match the input");
    assertEq(item.experienceBonus, _itemType.experienceBonus, "Experience bonus should match the input");
}

    ///////////////////////////////////////////////////////////////////////////////////
    // Setup
    ///////////////////////////////////////////////////////////////////////////////////
    function setUp() public virtual override {
        super.setUp();

        // TODO : test larger cycle max size
        // create First Duck Cycle
        uint256[] memory colorItemIds = new uint256[](1);
        colorItemIds[0] = 0;
        util_createCycle(1000, 1, colorItemIds);

        // add QUACK as collateral to first cycle
        quackModifiers = new int16[](6);
        quackModifiers[0] = -2;
        quackModifiers[1] = 1;
        quackModifiers[2] = 2;
        quackModifiers[3] = 1;
        quackModifiers[4] = 0;
        quackModifiers[5] = -1;
        // Create a dynamic array of CollateralTypeDTO
        CollateralTypeDTO[] memory collateralTypes = new CollateralTypeDTO[](1);
        collateralTypes[0] =
            CollateralTypeDTO(address(quackToken), quackModifiers, bytes3(0x000000), bytes3(0x000000), false);

        // Add collateral
        diamond.addCollateralTypes(cycleId, collateralTypes);
        uint256 mintPrice = cycle.eggsPrice;
        quackToken.approve(address(diamond), mintPrice);
        uint256 duckId = diamond.buyEggs(account0);
        uint256 vrfPrice = diamond.getVRFRequestPrice();
        uint64[] memory ids = new uint64[](1);
        ids[0] = 0;
        diamond.openEggs{value: vrfPrice}(ids);
        uint256 minStake = 1;
        uint256 chosenDuck = 1;
        quackToken.approve(address(diamond), minStake);
        diamond.claimDuck(ids[0], chosenDuck, minStake);
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Tests Items
    ///////////////////////////////////////////////////////////////////////////////////

function test_createConsumableItem() public {
   // Create statistics modifiers array
    int16[] memory statsModifiers = new int16[](6);
    statsModifiers[0] = 10;  // HEALTH +10
    statsModifiers[1] = 5;   // MANA +5
    statsModifiers[2] = 0;   // SPECIAL no change
    statsModifiers[3] = 15;  // ENERGY +15
    statsModifiers[4] = 20;  // FOOD +20
    statsModifiers[5] = -5;  // SANITY -5

    ItemType memory itemType = ItemType({
        name: "Health Potion",
        description: "Restores health and energy",
        author: account0,
        characteristicsModifiers: new int16[](6),
        statisticsModifiers: statsModifiers,
        slotPositions: new bool[](9),
        allowedCollaterals: new uint8[](1),
        quackPrice: 100,
        maxQuantity: 1000,
        totalQuantity: 0,
        svgId: 1,
        rarityScoreModifier: 0,
        canPurchaseWithQuack: true,
        minLevel: 0,
        canBeTransferred: true,
        category: 2,
        kinshipBonus: 5,
        experienceBonus: 100
    });

    util_createItemType(itemType);

    // Verify the item was created correctly
    ItemType memory item = diamond.getItemType(0);
    assertEq(uint8(item.category), 2, "Item should be a consumable");
    assertEq(item.kinshipBonus, 5, "Wrong kinship bonus");
    assertEq(item.experienceBonus, 100, "Wrong experience bonus");
}

function test_useConsumable() public {
    // First create a consumable item
    test_createConsumableItem();
    
    // Get initial duck state
    DuckInfoDTO memory initialDuck = diamond.getDuckInfo(0);
    
    // Buy the consumable
    uint256 itemPrice = 100; // from creation above
    quackToken.approve(address(diamond), itemPrice);

    uint256[] memory itemIds = new uint256[](1);
    itemIds[0] = 0; // first item
    uint256[] memory quantities = new uint256[](1);
    quantities[0] = 1; // buy 1 potion
    
    // Use corrected function signature with _to parameter
    diamond.purchaseItemsWithQuack(account0, itemIds, quantities);
    
    // Use the consumable
    diamond.useConsumables(0, itemIds, quantities);
    
    // Get updated duck state
    DuckInfoDTO memory updatedDuck = diamond.getDuckInfo(0);
    
    // Verify changes
    assertEq(updatedDuck.statistics[0], initialDuck.statistics[0] + 10, "Health should increase by 10");
    assertEq(updatedDuck.statistics[1], initialDuck.statistics[1] + 5, "Mana should increase by 5");
    assertEq(updatedDuck.statistics[3], initialDuck.statistics[3] + 15, "Energy should increase by 15");
    assertEq(updatedDuck.statistics[4], initialDuck.statistics[4] + 20, "Food should increase by 20");
    // assertEq(updatedDuck.kinship, initialDuck.kinship + 5, "Kinship should increase by 5"); // TODO : check if it's working
    assertEq(updatedDuck.experience, initialDuck.experience + 100, "Experience should increase by 100");
}

// function test_useConsumableFailures() public {
//     // First create a consumable item
//     test_createConsumableItem();
    
//     // Try to use consumable without buying it
//     uint256[] memory itemIds = new uint256[](1);
//     itemIds[0] = 0;
//     uint256[] memory quantities = new uint256[](1);
//     quantities[0] = 1;
    
//     vm.expectRevert("ERC1155: insufficient balance");
//     diamond.useConsumables(0, itemIds, quantities);
    
//     // Try to use consumable with wrong duck ID
//     vm.expectRevert("LibDuck: Only valid for Hatched Duck");
//     diamond.useConsumables(999, itemIds, quantities);
    
//     // Try to use consumable with mismatched arrays
//     uint256[] memory wrongQuantities = new uint256[](2);
//     vm.expectRevert("ItemsFacet: _itemIds length != _quantities length");
//     diamond.useConsumables(0, itemIds, wrongQuantities);
// }

// function test_consumableStatLimits() public {
//     // First create a consumable with very high stat modifications
//     int16[] memory statsModifiers = new int16[](6);
//     statsModifiers[0] = 1000; // Very high health boost
    
//     // Create the consumable with high stats
//     ItemType memory itemType = ItemType({
//         name: "Mega Potion",
//         description: "Massive stat boost",
//         author: account0,
//         characteristicsModifiers: new int16[](6),
//         statisticsModifiers: statsModifiers,
//         slotPositions: new bool[](9),
//         allowedCollaterals: new uint8[](1),
//         quackPrice: 100,
//         maxQuantity: 1000,
//         totalQuantity: 0,
//         svgId: 1,
//         rarityScoreModifier: 0,
//         canPurchaseWithQuack: true,
//         minLevel: 0,
//         canBeTransferred: true,
//         category: 2,
//         kinshipBonus: 0,
//         experienceBonus: 0
//     });
    
//     util_createItemType(itemType);
    
//     // Buy and use the consumable
//     quackToken.approve(address(diamond), 100);
    
//     uint256[] memory itemIds = new uint256[](1);
//     itemIds[0] = 0;
//     uint256[] memory quantities = new uint256[](1);
//     quantities[0] = 1;
//     diamond.purchaseItemsWithQuack(account0, itemIds, quantities);
    
//     // Use the consumable
//     diamond.useConsumables(0, itemIds, quantities);
    
//     // Verify stats don't exceed max values
//     DuckInfoDTO memory duck = diamond.getDuckInfo(0);
//     assertLe(duck.statistics[0], duck.maxStatistics[0], "Stat should not exceed max value");
// }


    // function test_buyItem() public {

    // }

    // function test_consumeItem() public {

    // }

    // function test_equipWearable() public {

    // }
}
