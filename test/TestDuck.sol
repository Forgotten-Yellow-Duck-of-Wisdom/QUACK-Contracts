// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.21;

// import "forge-std/Test.sol";
// import {TestBaseContract} from "./utils/TestBaseContract.sol";
// import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
// import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";

// contract TestDuck is TestBaseContract {
//     uint16 cycleId;
//     Cycle cycle;
//     int16[] quackModifiers;
//     ///////////////////////////////////////////////////////////////////////////////////
//     // Utils
//     ///////////////////////////////////////////////////////////////////////////////////

//     function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256[] memory _bodyColorIds) internal {
//         uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorIds);
//         (cycleId, cycle) = diamond.currentCycle();
//         assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
//         assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
//         assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
//         assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
//         assertEq(
//             cycle.allowedBodyColorIds.length,
//             _bodyColorIds.length,
//             "util_createCycle: Invalid Allowed Body Color Item Id"
//         );
//         for (uint256 i; i < _bodyColorIds.length; i++) {
//             assertEq(
//                 cycle.allowedBodyColorIds[i], _bodyColorIds[i], "util_createCycle: Invalid Allowed Body Color Item Id"
//             );
//         }
//     }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Setup
//     ///////////////////////////////////////////////////////////////////////////////////
//     function setUp() public virtual override {
//         super.setUp();

//         // TODO : test larger cycle max size
//         // create First Duck Cycle
//         uint256[] memory colorItemIds = new uint256[](1);
//         colorItemIds[0] = 0;
//         util_createCycle(1000, 1, colorItemIds);

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
				
//         // Set game manager to account0 to allow XP grants
//         diamond.setGameManager(account0, true);
//     }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Tests Ducks
//     ///////////////////////////////////////////////////////////////////////////////////
//     function testBasicEggsMint() public {
//         uint256 initialBalance = quackToken.balanceOf(account0);
//         uint256 mintPrice = cycle.eggsPrice;
//         // quackToken.mint(account1, 1000000000000000000);
//         // Approve QUACK tokens for spending
//         quackToken.approve(address(diamond), mintPrice);

//         // Mint a duck
//         uint64 duckId = diamond.buyEggs(account0);

//         // Assert duck was minted
//         assertEq(diamond.ownerOf(duckId), account0, "Egg not minted to correct address");
//         assertEq(diamond.balanceOf(account0), 1, "Incorrect duck balance");

//         // Assert QUACK tokens were spent
//         assertEq(quackToken.balanceOf(account0), initialBalance - mintPrice, "Incorrect QUACK balance after mint");

//         // Assert cycle state updated
//         (, Cycle memory updatedCycle) = diamond.currentCycle();
//         assertEq(updatedCycle.totalCount, 1, "Cycle total count not updated");

//         DuckInfoDTO memory duckInfo = diamond.getDuckInfo(duckId);
//         assertEq(uint256(duckInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Duck should be in EGG state");
//         assertEq(duckInfo.experience, 0, "Duck should start with 0 XP");
//         assertEq(duckInfo.level, 0, "Eggs should start at level 0");

//         uint64[] memory duckIds = new uint64[](1);
//         duckIds[0] = 0;
//         uint256[] memory amounts = new uint256[](1);
//         amounts[0] = 1000;	
//         diamond.grantExperience(duckIds, amounts);
//     }

//     function testFailMintEggsInsufficientBalance() public {
//         // Get initial balances
//         uint256 initialBalance = quackToken.balanceOf(account1);
//         uint256 mintPrice = cycle.eggsPrice;

//         // Verify initial state
//         assertEq(initialBalance, 0, "Account1 should start with 0 balance");

//         // Try to approve tokens (should fail as account1 has no balance)
//         vm.startPrank(account1);
//         vm.expectRevert("ERC20: insufficient balance");
//         quackToken.approve(address(diamond), mintPrice);
//         vm.stopPrank();

//         // Try direct mint (should fail)
//         vm.expectRevert("ERC20: insufficient allowance");
//         diamond.buyEggs(account1);

//         // Verify no state changes occurred
//         assertEq(quackToken.balanceOf(account1), 0, "Balance should remain 0");
//         assertEq(diamond.balanceOf(account1), 0, "Should have no eggs");
//     }

//     function testMintFullEggsSupply() public {
//         uint256 cycleMaxSize = cycle.cycleMaxSize;
//         uint256 mintPrice = cycle.eggsPrice;
//         uint256 initialBalance = quackToken.balanceOf(account0);

//         // Approve QUACK tokens for spending
//         quackToken.approve(address(diamond), mintPrice * cycleMaxSize);

//         // Track all minted IDs
//         uint64[] memory mintedIds = new uint64[](cycleMaxSize);

//         // Mint ducks until the cycle is full
//         for (uint256 i = 0; i < cycleMaxSize; i++) {
//             uint64 duckId = diamond.buyEggs(account0);
//             mintedIds[i] = duckId;

//             // Verify each minted egg
//             assertEq(diamond.ownerOf(duckId), account0, "Duck not minted to correct address");

//             DuckInfoDTO memory duckInfo = diamond.getDuckInfo(duckId);
//             assertEq(uint256(duckInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Duck should be in EGG state");
//             assertEq(duckInfo.experience, 0, "Duck should start with 0 XP");
//             assertEq(duckInfo.level, 0, "Eggs should start at level 0");
//         }

//         // Assert final state
//         (, Cycle memory updatedCycle) = diamond.currentCycle();
//         assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle not full");
//         assertEq(diamond.balanceOf(account0), cycleMaxSize, "Incorrect final balance");
//         assertEq(
//             quackToken.balanceOf(account0), initialBalance - (mintPrice * cycleMaxSize), "Incorrect final QUACK balance"
//         );

//         // Attempt to mint one more duck, should fail
//         vm.expectRevert("DuckGameFacet: Exceeded max number of duck for this cycle");
//         diamond.buyEggs(account0);

//         // Verify cycle state didn't change after failed mint
//         (, updatedCycle) = diamond.currentCycle();
//         assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle count should not change after failed mint");
//     }

//     function testEggRepicking() public {
//         // First mint an egg and open it
//         testBasicEggsMint();

//         uint256 vrfPrice = diamond.getVRFRequestPrice();
//         uint64[] memory ids = new uint64[](1);
//         ids[0] = 0;

//         // Verify initial egg state before opening
//         DuckInfoDTO memory eggInfo = diamond.getDuckInfo(0);
//         assertEq(uint256(eggInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Initial state should be CLOSED_EGGS");

//         // Open egg with VRF
//         diamond.openEggs{value: vrfPrice}(ids);

//         // Verify egg state after opening
//         eggInfo = diamond.getDuckInfo(0);
//         assertEq(uint256(eggInfo.status), uint256(DuckStatusType.OPEN_EGG), "Egg should be in OPEN_EGG state");

//         // Test multiple repicks and verify state changes
//         for (uint256 i = 0; i < 2; i++) {
//             // Store pre-repick state
//             uint8 repickCount = diamond.getEggRepickCount(0);

//             // Perform repick
//             diamond.repickEgg(0);

//             // Verify status remains correct
//             DuckInfoDTO memory postRepick = diamond.getDuckInfo(0);
//             assertEq(
//                 uint256(postRepick.status), uint256(DuckStatusType.OPEN_EGG), "Egg should remain OPEN_EGG after repick"
//             );
// 						EggDuckTraitsDTO[3] memory eggDuckTraits = diamond.eggDuckTraits(0);
// 						console2.log("eggDuckTraits", eggDuckTraits[0].randomNumber);
//             // Verify repick count increased
//             assertTrue(diamond.getEggRepickCount(0) == repickCount + 3, "Repick count should increase");
//         }

//         // Test failure cases
//         vm.expectRevert("DuckGameFacet: Egg not open");
//         diamond.repickEgg(999); // Non-existent egg

//         // Claim the duck to test repicking after claiming
//         uint256 minStake = 1;
//         uint256 chosenDuck = 9;
//         quackToken.approve(address(diamond), minStake);
//         diamond.claimDuck(ids[0], chosenDuck, minStake);

//         vm.expectRevert("DuckGameFacet: Egg not open");
//         diamond.repickEgg(0); // Already claimed duck
//     }

//     function testBasicDuckHatching() public {
//         // First mint an egg
//         testBasicEggsMint();

//         // Get initial state
//         uint256 initialBalance = quackToken.balanceOf(account0);
//         uint256 vrfPrice = diamond.getVRFRequestPrice();

//         // Setup egg opening
//         uint64[] memory ids = new uint64[](1);
//         ids[0] = 0;

//         // Verify initial egg state
//         DuckInfoDTO memory eggInfo = diamond.getDuckInfo(0);
//         assertEq(uint256(eggInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Initial state should be CLOSED_EGGS");

//         // Open egg with VRF and verify payment
//         uint256 preVrfBalance = address(account0).balance;
//         diamond.openEggs{value: vrfPrice}(ids);
//         assertEq(address(account0).balance, preVrfBalance - vrfPrice, "VRF payment incorrect");

//         // Verify egg state after opening
//         eggInfo = diamond.getDuckInfo(0);
//         assertEq(uint256(eggInfo.status), uint256(DuckStatusType.OPEN_EGG), "Egg should be in OPEN_EGGS state");

//         // Setup for claiming
//         uint256 minStake = 1;
//         uint256 chosenDuck = 1;

//         // Approve tokens for staking
//         quackToken.approve(address(diamond), minStake);

//         // Get pre-claim state
//         uint256 preClaimBalance = quackToken.balanceOf(account0);

//         // Claim the duck
//         diamond.claimDuck(ids[0], chosenDuck, minStake);

//         // Verify final state
//         DuckInfoDTO memory duckInfo = diamond.getDuckInfo(0);
//         assertEq(uint256(duckInfo.status), uint256(DuckStatusType.DUCK), "Duck not hatched");
//         assertEq(duckInfo.collateral, address(quackToken), "Wrong collateral address");
//         assertEq(duckInfo.stakedAmount, minStake, "Wrong staked amount");
//         assertEq(quackToken.balanceOf(account0), preClaimBalance - minStake, "Wrong final balance");

//         // Verify initial duck properties based on LibDuck.sol
//         assertEq(uint40(block.timestamp - 12 hours), duckInfo.lastInteracted, "Wrong last interaction time");
//         // assertEq(uint40(50), duckInfo.interactionCount, "Wrong interaction count");
//         assertEq(uint40(block.timestamp), duckInfo.hatchTime, "Wrong hatch time");
//         assertEq(uint40(block.timestamp), duckInfo.satiationTime, "Wrong satiation time");

//         // Verify duck ownership hasn't changed
//         assertEq(diamond.ownerOf(0), account0, "Duck ownership should remain unchanged");
//     }

// 	// TODO : refacto with +1 level granted for hatching
//     // function testDuckLeveling() public {
//     //     // First get a hatched duck
//     //     testBasicDuckHatching();


//     //     // Get initial duck state
//     //     DuckInfoDTO memory initialDuck = diamond.getDuckInfo(0);
//     //     assertEq(initialDuck.level, 0, "Duck should start at level 0");
//     //     assertEq(initialDuck.experience, 0, "Duck should start with 0 XP");

//     //     // Get XP table and verify its size
//     //     uint256[] memory xpTable = diamond.xpTable();
//     //     assertEq(xpTable.length, 100, "XP table should have 100 levels");

//     //     // Verify first few known XP thresholds from InitDiamond.sol
//     //     assertEq(xpTable[0], 246, "Wrong XP for level 0");
//     //     assertEq(xpTable[1], 271, "Wrong XP for level 1");
//     //     assertEq(xpTable[2], 296, "Wrong XP for level 2");
//     //     assertEq(xpTable[3], 320, "Wrong XP for level 3");

//     //     // Test progressive leveling through multiple levels
//     //     for (uint256 i = 0; i < 10; i++) {
//     //         uint256 requiredXp = diamond.xpUntilNextLevel(uint16(i), 0);
//     //         assertEq(requiredXp, xpTable[i], "XP until next level mismatch");

//     //         // Split XP into chunks of 1000 or less
//     //         uint256 remainingXp = xpTable[i];
//     //         while (remainingXp > 0) {
//     //             uint256 xpChunk = remainingXp > 1000 ? 1000 : remainingXp;
//     //             // console2.log(" =>>>>>>>xp chunk", xpChunk)
//     //             uint64[] memory duckIds = new uint64[](1);
//     //             duckIds[0] = 0;
//     //             uint256[] memory amounts = new uint256[](1);
//     //             amounts[0] = xpChunk;
//     //             diamond.grantExperience(duckIds, amounts);
//     //             remainingXp -= xpChunk;
//     //         }

//     //         // Verify level up
//     //         DuckInfoDTO memory updatedDuck = diamond.getDuckInfo(0);
//     //         assertEq(updatedDuck.level, i + 1, "Duck should level up");
//     //         assertEq(updatedDuck.experience, 0, "Experience should reset after level up");
//     //     }

//     //     // // TODO : fix partiel xp testing
//     //     // // Test partial leveling
//     //     // uint256 partialXp = 240;
//     //     // uint64[] memory partialDuckIds = new uint64[](1);
//     //     // partialDuckIds[0] = 0;
//     //     // uint256[] memory partialAmounts = new uint256[](1);
//     //     // partialAmounts[0] = partialXp;
//     //     // diamond.grantExperience(partialDuckIds, partialAmounts);

//     //     DuckInfoDTO memory partialDuck = diamond.getDuckInfo(0);
//     //     // // TODO : fix partiel xp testing
//     //     // assertEq(partialDuck.level, 10, "Level shouldn't change for partial XP");
//     //     // assertEq(partialDuck.experience, partialXp, "Wrong partial XP amount");

//     //     // Test approaching max level
//     //     for (uint256 i = partialDuck.level; i < xpTable.length - 1; i++) {
//     //         uint256 remainingXp = xpTable[i];
//     //         while (remainingXp > 0) {
//     //             // Ensure we never grant more than 1000 XP at a time
//     //             uint256 xpChunk = remainingXp > 1000 ? 1000 : remainingXp;
//     //             uint64[] memory duckIds = new uint64[](1);
//     //             duckIds[0] = 0;
//     //             uint256[] memory amounts = new uint256[](1);
//     //             amounts[0] = xpChunk;
//     //             diamond.grantExperience(duckIds, amounts);
//     //             remainingXp -= xpChunk;

//     //             // Add a small delay between chunks
//     //             vm.warp(block.timestamp + 1);
//     //         } // tODO : check if perfect amount of xp = level up and 0 xp ? if a bit more xp, is xp well added ?

//     //         // Verify level progression
//     //         DuckInfoDTO memory currentDuck = diamond.getDuckInfo(0);
//     //         assertEq(currentDuck.level, i + 1, "Wrong level after XP grant");
//     //         assertEq(currentDuck.experience, 0, "Experience should be 0 after level up");
//     //     }

//     //     // Verify max level state
//     //     DuckInfoDTO memory maxLevelDuck = diamond.getDuckInfo(0);
//     //     assertEq(maxLevelDuck.level, 99, "Should reach max level");
//     //     assertEq(maxLevelDuck.experience, 0, "Should have 0 XP at max level");

//     //     // Test XP grant at max level
//     //     uint64[] memory maxDuckIds = new uint64[](1);
//     //     maxDuckIds[0] = 0;
//     //     uint256[] memory maxAmounts = new uint256[](1);
//     //     maxAmounts[0] = 1000;
//     //     diamond.grantExperience(maxDuckIds, maxAmounts);

//     //     // Verify XP doesn't accumulate at max level
//     //     DuckInfoDTO memory postMaxDuck = diamond.getDuckInfo(0);
//     //     assertEq(postMaxDuck.level, 99, "Level should not exceed max");
//     //     // // TODO : fix accumulation xp testing
//     //     // assertEq(postMaxDuck.experience, 0, "XP should not accumulate at max level");

//     //     // Test failure cases
//     //     vm.startPrank(account1);
//     //     vm.expectRevert("LibAppStorage: Only callable by Game Manager");
//     //     diamond.grantExperience(maxDuckIds, maxAmounts);
//     //     vm.stopPrank();
//     // }
// }
