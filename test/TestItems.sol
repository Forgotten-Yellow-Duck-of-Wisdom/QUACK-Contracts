// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.21;

// import "forge-std/Test.sol";
// import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
// import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
// import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";
// import {ItemType} from "../src/shared/Structs_Items.sol";
// contract TestItems is TestBaseContract {
//     uint256 cycleId;
//     Cycle cycle;
//     int16[] quackModifiers;
//     ///////////////////////////////////////////////////////////////////////////////////
//     // Utils
//     ///////////////////////////////////////////////////////////////////////////////////
//     function util_toString(uint256 value) internal pure returns (string memory) {
//         if (value == 0) {
//             return "0";
//         }
//         uint256 temp = value;
//         uint256 digits;
//         while (temp != 0) {
//             digits++;
//             temp /= 10;
//         }
//         bytes memory buffer = new bytes(digits);
//         while (value != 0) {
//             digits -= 1;
//             buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
//             value /= 10;
//         }
//         return string(buffer);
//     }
//     function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256 _bodyColorItemId) internal {
//         uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorItemId);
//         (cycleId, cycle) = diamond.currentCycle();
//         assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
//         assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
//         assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
//         assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
//         assertEq(cycle.bodyColorItemId, _bodyColorItemId, "util_createCycle: Invalid Body Color Item Id");
//     }

//     function util_createItemType(
//     string memory _name,
//     string memory _description,
//     address _author,
//     int16[] memory _characteristicsModifiers,
//     int16[] memory _statisticsModifiers,
//     bool[] memory _slotPositions,
//     uint8[] memory _allowedCollaterals,
//     uint256 _quackPrice,
//     uint256 _maxQuantity,
//     uint256 _totalQuantity,
//     uint32 _svgId,
//     uint8 _rarityScoreModifier,
//     bool _canPurchaseWithQuack,
//     uint16 _minLevel,
//     bool _canBeTransferred,
//     uint8 _category,
//     int16 _kinshipBonus,
//     uint32 _experienceBonus
// ) public {
//     // Create the ItemType struct with provided parameters
//     ItemType memory itemType = ItemType({
//         name: _name,
//         description: _description,
//         author: _author,
//         characteristicsModifiers: _characteristicsModifiers,
//         statisticsModifiers: _statisticsModifiers,
//         slotPositions: _slotPositions,
//         allowedCollaterals: _allowedCollaterals,
//         quackPrice: _quackPrice,
//         maxQuantity: _maxQuantity,
//         totalQuantity: _totalQuantity,
//         svgId: _svgId,
//         rarityScoreModifier: _rarityScoreModifier,
//         canPurchaseWithQuack: _canPurchaseWithQuack,
//         minLevel: _minLevel,
//         canBeTransferred: _canBeTransferred,
//         category: _category,
//         kinshipBonus: _kinshipBonus,
//         experienceBonus: _experienceBonus
//     });

//     // Add the new ItemType to the contract
//     ItemType[] memory items = new ItemType[](1);
//     items[0] = itemType;
//     diamond.addItemTypes(items);

//     // Retrieve the added ItemType to verify
//     ItemType memory item = diamond.getItemType(0);

//     // Assertions to ensure the item was created correctly
//     assertEq(item.name, _name, "Item name should match the input");
//     assertEq(item.description, _description, "Item description should match the input");
//     assertEq(item.author, _author, "Item author should match the input");

//     // Verify characteristics modifiers
//     for (uint256 i = 0; i < _characteristicsModifiers.length; i++) {
//         assertEq(
//             item.characteristicsModifiers[i],
//             _characteristicsModifiers[i],
//             string(abi.encodePacked("Characteristics modifier ", util_toString(i), " should match"))
//         );
//     }

//     // Verify statistics modifiers
//     for (uint256 i = 0; i < _statisticsModifiers.length; i++) {
//         assertEq(
//             item.statisticsModifiers[i],
//             _statisticsModifiers[i],
//             string(abi.encodePacked("Statistics modifier ", util_toString(i), " should match"))
//         );
//     }

//     // Verify slot positions
//     for (uint256 i = 0; i < _slotPositions.length; i++) {
//         assertEq(
//             item.slotPositions[i],
//             _slotPositions[i],
//             string(abi.encodePacked("Slot position ", util_toString(i), " should match"))
//         );
//     }

//     // Verify allowed collaterals
//     for (uint256 i = 0; i < _allowedCollaterals.length; i++) {
//         assertEq(
//             item.allowedCollaterals[i],
//             _allowedCollaterals[i],
//             string(abi.encodePacked("Allowed collateral ", util_toString(i), " should match"))
//         );
//     }

//     // Verify other attributes
//     assertEq(item.quackPrice, _quackPrice, "Quack price should match the input");
//     assertEq(item.maxQuantity, _maxQuantity, "Max quantity should match the input");
//     assertEq(item.totalQuantity, _totalQuantity, "Total quantity should match the input");
//     assertEq(item.svgId, _svgId, "SVG ID should match the input");
//     assertEq(item.rarityScoreModifier, _rarityScoreModifier, "Rarity score modifier should match the input");
//     assertEq(item.canPurchaseWithQuack, _canPurchaseWithQuack, "Can purchase with quack should match the input");
//     assertEq(item.minLevel, _minLevel, "Min level should match the input");
//     assertEq(item.canBeTransferred, _canBeTransferred, "Can be transferred should match the input");
//     assertEq(item.category, _category, "Category should match the input");
//     assertEq(item.kinshipBonus, _kinshipBonus, "Kinship bonus should match the input");
//     assertEq(item.experienceBonus, _experienceBonus, "Experience bonus should match the input");
// }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Setup
//     ///////////////////////////////////////////////////////////////////////////////////
//     function setUp() public virtual override {
//         super.setUp();

//         // TODO : test larger cycle max size
//         // create First Duck Cycle
//         util_createCycle(1000, 1, 0);

//         // add QUACK as collateral to first cycle
//         quackModifiers = new int16[](6);
//         quackModifiers[0] = -2;
//         quackModifiers[1] = 1;
//         quackModifiers[2] = 2;
//         quackModifiers[3] = 1;
//         quackModifiers[4] = 0;
//         quackModifiers[5] = -1;
//         // Create a dynamic array of CollateralTypeDTO
//         CollateralTypeDTO[] memory collateralTypes = new CollateralTypeDTO[](1);
//         collateralTypes[0] =
//             CollateralTypeDTO(address(quackToken), quackModifiers, bytes3(0x000000), bytes3(0x000000), false);

//         // Add collateral
//         diamond.addCollateralTypes(cycleId, collateralTypes);
//         uint256 mintPrice = cycle.eggsPrice;
//         quackToken.approve(address(diamond), mintPrice);
//         uint256 duckId = diamond.buyEggs(account0);
//         uint256 vrfPrice = diamond.getVRFRequestPrice();
//         uint256[] memory ids = new uint256[](1);
//         ids[0] = 0;
//         diamond.openEggs{value: vrfPrice}(ids);
//         uint256 minStake = 1;
//         uint256 chosenDuck = 1;
//         quackToken.approve(address(diamond), minStake);
//         diamond.claimDuck(ids[0], chosenDuck, minStake);
//     }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Tests Items
//     ///////////////////////////////////////////////////////////////////////////////////

//     // function test_createItemType() public {
//     //     util_createItemType(
//     //         "Green",
//     //         "Body Color - Green",
//     //         account0,
//     //         quackModifiers,
//     //         quackModifiers,
//     //         quackModifiers,
//     //         quackModifiers,
//     //         0,
//     //         0,
//     //         0,
//     //         0,
//     //         0,
//     //         false,
//     //         0,
//     //         true,
//     //         0,
//     //         0,
//     //         0
//     //     );
//     // }

//     function test_buyItem() public {

//     }

//     // function test_consumeItem() public {

//     // }

//     // function test_equipWearable() public {

//     // }
// }
