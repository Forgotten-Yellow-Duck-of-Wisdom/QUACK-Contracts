// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.21;

// import "forge-std/Test.sol";
// import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
// import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
// import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";

// contract TestCollateral is TestBaseContract {
//     uint256 cycleId;
//     Cycle cycle;
//     int16[] quackModifiers;
//     ///////////////////////////////////////////////////////////////////////////////////
//     // Utils
//     ///////////////////////////////////////////////////////////////////////////////////

//     function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256 _bodyColorItemId) internal {
//         uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorItemId);
//         (cycleId, cycle) = diamond.currentCycle();
//         assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
//         assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
//         assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
//         assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
//         assertEq(cycle.bodyColorItemId, _bodyColorItemId, "util_createCycle: Invalid Body Color Item Id");
//     }

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
//     }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Tests Collaterals
//     ///////////////////////////////////////////////////////////////////////////////////
//     function testAddMultipleCollaterals() public {
//         // First check that QUACK collateral is added
//         uint256 initialCollateralCount = diamond.getCycleCollateralsAddresses(cycleId).length;
//         assertEq(initialCollateralCount, 1, "testAddMultipleCollaterals: Initial collateral count is not 1");
//         CollateralTypeDTO memory quackCollateral = diamond.getCycleCollateralInfo(cycleId, 0);
//         assertEq(
//             quackCollateral.collateralType,
//             address(quackToken),
//             "testAddMultipleCollaterals: Incorrect collateral address"
//         );
//         assertEq(quackCollateral.delisted, false, "testAddMultipleCollaterals: Incorrect collateral delisted status");
//         assertEq(
//             quackCollateral.primaryColor,
//             bytes3(0x000000),
//             "testAddMultipleCollaterals: Incorrect collateral primary color"
//         );
//         assertEq(
//             quackCollateral.secondaryColor,
//             bytes3(0x000000),
//             "testAddMultipleCollaterals: Incorrect collateral secondary color"
//         );
//         for (uint256 q = 0; q < quackCollateral.modifiers.length; q++) {
//             assertEq(
//                 quackCollateral.modifiers[q], quackModifiers[q], "testAddMultipleCollaterals: Incorrect modifier value"
//             );
//         }

//         // Create multiples modifiers
//         int16[] memory modifiers1 = new int16[](6);
//         modifiers1[0] = -1;
//         modifiers1[1] = 0;
//         modifiers1[2] = 1;
//         modifiers1[3] = -1;
//         modifiers1[4] = 2;
//         modifiers1[5] = 2;

//         int16[] memory modifiers2 = new int16[](6);
//         modifiers2[0] = 2;
//         modifiers2[1] = 2;
//         modifiers2[2] = 2;
//         modifiers2[3] = 2;
//         modifiers2[4] = -2;
//         modifiers2[5] = -2;

//         int16[] memory modifiers3 = new int16[](6);
//         modifiers3[0] = 1;
//         modifiers3[1] = -2;
//         modifiers3[2] = 2;
//         modifiers3[3] = 1;
//         modifiers3[4] = -1;
//         modifiers3[5] = 0;

//         // Add QUACK, tUSDC, tWETH as collaterals
//         CollateralTypeDTO[] memory collateralTypes = new CollateralTypeDTO[](3);
//         collateralTypes[0] =
//             CollateralTypeDTO(address(quackToken), modifiers1, bytes3(0x000001), bytes3(0x000001), false);
//         collateralTypes[1] = CollateralTypeDTO(address(tUSDC), modifiers2, bytes3(0x000002), bytes3(0x000002), true);
//         collateralTypes[2] = CollateralTypeDTO(address(tWETH), modifiers3, bytes3(0x000003), bytes3(0x000003), false);

//         // Since QUACK is already added, the first collateral should be replaced
//         diamond.addCollateralTypes(cycleId, collateralTypes);

//         uint256 updatedCollateralCount = diamond.getCycleCollateralsAddresses(cycleId).length;
//         assertEq(updatedCollateralCount, 3, "testAddMultipleCollaterals: Collateral types not added correctly");
//         // Check that the new collaterals are added correctly
//         for (uint256 i = 0; i < collateralTypes.length; i++) {
//             CollateralTypeDTO memory addedCollateral = diamond.getCycleCollateralInfo(cycleId, i);
//             assertEq(
//                 addedCollateral.collateralType,
//                 collateralTypes[i].collateralType,
//                 "testAddMultipleCollaterals: Incorrect collateral address"
//             );
//             assertEq(
//                 addedCollateral.delisted,
//                 collateralTypes[i].delisted,
//                 "testAddMultipleCollaterals: Incorrect collateral delisted status"
//             );

//             assertEq(
//                 addedCollateral.primaryColor,
//                 collateralTypes[i].primaryColor,
//                 "testAddMultipleCollaterals: Incorrect collateral primary color"
//             );

//             assertEq(
//                 addedCollateral.secondaryColor,
//                 collateralTypes[i].secondaryColor,
//                 "testAddMultipleCollaterals: Incorrect collateral secondary color"
//             );

//             // Verify modifiers
//             for (uint256 j = 0; j < collateralTypes[i].modifiers.length; j++) {
//                 assertEq(
//                     addedCollateral.modifiers[j],
//                     collateralTypes[i].modifiers[j],
//                     "testAddMultipleCollaterals: Incorrect modifier value"
//                 );
//                 // assertTrue(
//                 //     addedCollateral.modifiers[j] == 2 || addedCollateral.modifiers[j] == 1
//                 //         || addedCollateral.modifiers[j] == -1 || addedCollateral.modifiers[j] == -2,
//                 //     "Invalid modifier value"
//                 // );
//             }
//         }
//     }

//     // TODO: add test for increase staking collateral
//     // TODO: add test for decrease staking collateral
//     // TODO: add test for delist collateral
//     // TODO: add test multiple cycles collaterals
// }
