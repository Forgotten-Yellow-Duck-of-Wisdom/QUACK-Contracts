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

    function util_createCycle(uint24 _cycleMaxSize, uint256 _eggPrice, uint256 _bodyColorItemId) internal {
        uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, _bodyColorItemId);
        (cycleId, cycle) = diamond.currentCycle();
        assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
        assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
        assertEq(cycle.eggsPrice, _eggPrice, "util_createCycle: Invalid Egg Price");
        assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
        assertEq(cycle.bodyColorItemId, _bodyColorItemId, "util_createCycle: Invalid Body Color Item Id");
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Setup
    ///////////////////////////////////////////////////////////////////////////////////
    function setUp() public virtual override {
        super.setUp();

        // TODO : test larger cycle max size
        // create First Duck Cycle
        util_createCycle(1000, 1, 0);

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
    }

    function testFailMintEggsInsufficientBalance() public {
        // Attempt to mint without sufficient balance
        vm.expectRevert("Insufficient balance");
        diamond.buyEggs(account1);
    }

    function testMintFullEggsSupply() public {
        uint256 cycleMaxSize = cycle.cycleMaxSize;
        uint256 mintPrice = cycle.eggsPrice;

        // Approve QUACK tokens for spending
        quackToken.approve(address(diamond), mintPrice * cycleMaxSize);

        // Mint ducks until the cycle is full
        for (uint256 i = 0; i < cycleMaxSize; i++) {
            uint64 duckId = diamond.buyEggs(account0);
            assertEq(diamond.ownerOf(duckId), account0, "Duck not minted to correct address");
        }

        // Assert cycle is full
        (, Cycle memory updatedCycle) = diamond.currentCycle();
        assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle not full");

        // Attempt to mint one more duck, should fail
        vm.expectRevert("DuckGameFacet: Exceeded max number of duck for this cycle");
        diamond.buyEggs(account0);
    }

    function testBasicDuckHatching() public {
        testBasicEggsMint();
        uint256 vrfPrice = diamond.getVRFRequestPrice();
        uint64[] memory ids = new uint64[](1);
        ids[0] = 0;
        diamond.openEggs{value: vrfPrice}(ids);
        uint256 minStake = 1;
        uint256 chosenDuck = 1;
        quackToken.approve(address(diamond), minStake);
        diamond.claimDuck(ids[0], chosenDuck, minStake);

        DuckInfoDTO memory duckInfo = diamond.getDuckInfo(0);
        assertEq(uint256(duckInfo.status), uint256(DuckStatusType.DUCK), "Duck not hatched");
        assertEq(duckInfo.collateral, address(quackToken), "Duck not hatched");
    }

    // function testDuckLevel() public {
    //     testBasicDuckHatching();
    //     uint256[] memory xpTable = diamond.xpTable();
    //     for (uint256 i = 0; i < xpTable.length; i++) {
    //         console2.log("XP Table Level", i, ":", xpTable[i]);
    //     }
    // }
}
