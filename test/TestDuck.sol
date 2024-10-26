// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";

contract TestDuck is TestBaseContract {
    uint16 cycleId;
    Cycle cycle;
    int16[] quackModifiers;
    ///////////////////////////////////////////////////////////////////////////////////
    // Utils
    ///////////////////////////////////////////////////////////////////////////////////

    function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256[] memory _bodyColorIds) internal {
        uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorIds);
        (cycleId, cycle) = diamond.currentCycle();
        assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
        assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
        assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
        assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
        assertEq(
            cycle.allowedBodyColorIds.length,
            _bodyColorIds.length,
            "util_createCycle: Invalid Allowed Body Color Item Id"
        );
        for (uint256 i; i < _bodyColorIds.length; i++) {
            assertEq(
                cycle.allowedBodyColorIds[i],
                _bodyColorIds[i],
                "util_createCycle: Invalid Allowed Body Color Item Id"
            );
        }
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
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Tests Ducks
    ///////////////////////////////////////////////////////////////////////////////////
    function testBasicEggsMint() public {
        uint256 initialBalance = quackToken.balanceOf(account0);
        uint256 mintPrice = cycle.eggsPrice;
        // quackToken.mint(account1, 1000000000000000000);
        // Approve QUACK tokens for spending
        quackToken.approve(address(diamond), mintPrice);

        // Mint a duck
        uint64 duckId = diamond.buyEggs(account0);

        // Assert duck was minted
        assertEq(diamond.ownerOf(duckId), account0, "Egg not minted to correct address");
        assertEq(diamond.balanceOf(account0), 1, "Incorrect duck balance");

        // Assert QUACK tokens were spent
        assertEq(quackToken.balanceOf(account0), initialBalance - mintPrice, "Incorrect QUACK balance after mint");

        // Assert cycle state updated
        (, Cycle memory updatedCycle) = diamond.currentCycle();
        assertEq(updatedCycle.totalCount, 1, "Cycle total count not updated");

        DuckInfoDTO memory duckInfo = diamond.getDuckInfo(duckId);
        assertEq(uint256(duckInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Duck should be in EGG state");
        assertEq(duckInfo.experience, 0, "Duck should start with 0 XP");
        assertEq(duckInfo.level, 0, "Eggs should start at level 0");
    }

function testFailMintEggsInsufficientBalance() public {
    // Get initial balances
    uint256 initialBalance = quackToken.balanceOf(account1);
    uint256 mintPrice = cycle.eggsPrice;
    
    // Verify initial state
    assertEq(initialBalance, 0, "Account1 should start with 0 balance");
    
    // Try to approve tokens (should fail as account1 has no balance)
    vm.startPrank(account1);
    vm.expectRevert("ERC20: insufficient balance");
    quackToken.approve(address(diamond), mintPrice);
    vm.stopPrank();

    // Try direct mint (should fail)
    vm.expectRevert("ERC20: insufficient allowance");
    diamond.buyEggs(account1);

    // Verify no state changes occurred
    assertEq(quackToken.balanceOf(account1), 0, "Balance should remain 0");
    assertEq(diamond.balanceOf(account1), 0, "Should have no eggs");
}

function testMintFullEggsSupply() public {
    uint256 cycleMaxSize = cycle.cycleMaxSize;
    uint256 mintPrice = cycle.eggsPrice;
    uint256 initialBalance = quackToken.balanceOf(account0);

    // Approve QUACK tokens for spending
    quackToken.approve(address(diamond), mintPrice * cycleMaxSize);

    // Track all minted IDs
    uint64[] memory mintedIds = new uint64[](cycleMaxSize);

    // Mint ducks until the cycle is full
    for (uint256 i = 0; i < cycleMaxSize; i++) {
        uint64 duckId = diamond.buyEggs(account0);
        mintedIds[i] = duckId;
        
        // Verify each minted egg
        assertEq(diamond.ownerOf(duckId), account0, "Duck not minted to correct address");
        
        DuckInfoDTO memory duckInfo = diamond.getDuckInfo(duckId);
        assertEq(uint256(duckInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Duck should be in EGG state");
        assertEq(duckInfo.experience, 0, "Duck should start with 0 XP");
        assertEq(duckInfo.level, 0, "Eggs should start at level 0");
    }

    // Assert final state
    (, Cycle memory updatedCycle) = diamond.currentCycle();
    assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle not full");
    assertEq(diamond.balanceOf(account0), cycleMaxSize, "Incorrect final balance");
    assertEq(
        quackToken.balanceOf(account0), 
        initialBalance - (mintPrice * cycleMaxSize), 
        "Incorrect final QUACK balance"
    );

    // Attempt to mint one more duck, should fail
    vm.expectRevert("DuckGameFacet: Exceeded max number of duck for this cycle");
    diamond.buyEggs(account0);

    // Verify cycle state didn't change after failed mint
    (, updatedCycle) = diamond.currentCycle();
    assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle count should not change after failed mint");
}

function testEggRepicking() public {
    // First mint an egg and open it
    testBasicEggsMint();
    
    uint256 vrfPrice = diamond.getVRFRequestPrice();
    uint64[] memory ids = new uint64[](1);
    ids[0] = 0;
    
    // Verify initial egg state before opening
    DuckInfoDTO memory eggInfo = diamond.getDuckInfo(0);
    assertEq(uint256(eggInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Initial state should be CLOSED_EGGS");
    
    // Open egg with VRF
    diamond.openEggs{value: vrfPrice}(ids);
    
    // Verify egg state after opening
    eggInfo = diamond.getDuckInfo(0);
    assertEq(uint256(eggInfo.status), uint256(DuckStatusType.OPEN_EGG), "Egg should be in OPEN_EGG state");
    
    // Test multiple repicks and verify state changes
    for (uint256 i = 0; i < 2; i++) {
        // Store pre-repick state
        uint8 repickCount = diamond.getEggRepickCount(0);
        
        // Perform repick
        diamond.repickEgg(0);
        
        // Verify status remains correct
        DuckInfoDTO memory postRepick = diamond.getDuckInfo(0);
        assertEq(uint256(postRepick.status), uint256(DuckStatusType.OPEN_EGG), "Egg should remain OPEN_EGG after repick");
        
        // Verify repick count increased
        assertTrue(diamond.getEggRepickCount(0) == repickCount + 3, "Repick count should increase");
    }
    
    // Test failure cases
    vm.expectRevert("DuckGameFacet: Egg not open");
    diamond.repickEgg(999); // Non-existent egg
    
    // Claim the duck to test repicking after claiming
    uint256 minStake = 1;
    uint256 chosenDuck = 9;
    quackToken.approve(address(diamond), minStake);
    diamond.claimDuck(ids[0], chosenDuck, minStake);
    
    vm.expectRevert("DuckGameFacet: Egg not open");
    diamond.repickEgg(0); // Already claimed duck
}

function testBasicDuckHatching() public {
    // First mint an egg
    testBasicEggsMint();
    
    // Get initial state
    uint256 initialBalance = quackToken.balanceOf(account0);
    uint256 vrfPrice = diamond.getVRFRequestPrice();
    
    // Setup egg opening
    uint64[] memory ids = new uint64[](1);
    ids[0] = 0;
    
    // Verify initial egg state
    DuckInfoDTO memory eggInfo = diamond.getDuckInfo(0);
    assertEq(uint256(eggInfo.status), uint256(DuckStatusType.CLOSED_EGGS), "Initial state should be CLOSED_EGGS");
    
    // Open egg with VRF and verify payment
    uint256 preVrfBalance = address(account0).balance;
    diamond.openEggs{value: vrfPrice}(ids);
    assertEq(address(account0).balance, preVrfBalance - vrfPrice, "VRF payment incorrect");
    
    // Verify egg state after opening
    eggInfo = diamond.getDuckInfo(0);
    assertEq(uint256(eggInfo.status), uint256(DuckStatusType.OPEN_EGG), "Egg should be in OPEN_EGGS state");
    
    // Setup for claiming
    uint256 minStake = 1;
    uint256 chosenDuck = 1;
    
    // Approve tokens for staking
    quackToken.approve(address(diamond), minStake);
    
    // Get pre-claim state
    uint256 preClaimBalance = quackToken.balanceOf(account0);
    
    // Claim the duck
    diamond.claimDuck(ids[0], chosenDuck, minStake);
    
    // Verify final state
    DuckInfoDTO memory duckInfo = diamond.getDuckInfo(0);
    assertEq(uint256(duckInfo.status), uint256(DuckStatusType.DUCK), "Duck not hatched");
    assertEq(duckInfo.collateral, address(quackToken), "Wrong collateral address");
    assertEq(duckInfo.stakedAmount, minStake, "Wrong staked amount");
    assertEq(quackToken.balanceOf(account0), preClaimBalance - minStake, "Wrong final balance");
    
    // Verify initial duck properties based on LibDuck.sol
    assertEq(uint40(block.timestamp - 12 hours), duckInfo.lastInteracted, "Wrong last interaction time");
    // assertEq(uint40(50), duckInfo.interactionCount, "Wrong interaction count");
    assertEq(uint40(block.timestamp), duckInfo.hatchTime, "Wrong hatch time");
    assertEq(uint40(block.timestamp), duckInfo.satiationTime, "Wrong satiation time");
    
    // Verify duck ownership hasn't changed
    assertEq(diamond.ownerOf(0), account0, "Duck ownership should remain unchanged");
}

    // function testDuckLevel() public {
    //     testBasicDuckHatching();
    //     uint256[] memory xpTable = diamond.xpTable();
    //     for (uint256 i = 0; i < xpTable.length; i++) {
    //         console2.log("XP Table Level", i, ":", xpTable[i]);
    //     }
    // }
}
