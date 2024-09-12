// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
import {Cycle, DuckStatus, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";

contract ProtocolTest is TestBaseContract {
    uint256 cycleId;
		Cycle cycle;

///////////////////////////////////////////////////////////////////////////////////
// Utils
///////////////////////////////////////////////////////////////////////////////////
	function util_createCycle(uint256 _cycleMaxSize, uint256 _eggPrice) internal {
				uint256 createdId = diamond.createCycle(_cycleMaxSize, _eggPrice, bytes3("0x000000"));
        (cycleId, cycle) = diamond.currentCycle();
				assertEq(createdId, cycleId, "util_createCycle: Invalid Cycle Id");
        assertEq(cycle.cycleMaxSize, _cycleMaxSize, "util_createCycle: Invalid Cycle Max Size");
				assertEq(cycle.eggPrice, _eggPrice, "util_createCycle: Invalid Egg Price");	
				assertEq(cycle.totalCount, 0, "util_createCycle: Invalid Total Count");
	}

function util_addCollateral(uint256 _cycleId, CollateralTypeDTO[] calldata _collateralTypes) internal {
    uint256 initialCollateralCount = diamond.getCollateralTypesCount(_cycleId);

    diamond.addCollateralTypes(_cycleId, _collateralTypes);

    uint256 updatedCollateralCount = diamond.getCollateralTypesCount(_cycleId);
    assertEq(updatedCollateralCount, initialCollateralCount + _collateralTypes.length, "util_addCollateral: Collateral types not added correctly");

    for (uint256 i = 0; i < _collateralTypes.length; i++) {
        CollateralTypeDTO memory addedCollateral = diamond.getCollateralType(_cycleId, initialCollateralCount + i);
        assertEq(addedCollateral.collateralAddress, _collateralTypes[i].collateralAddress, "util_addCollateral: Incorrect collateral address");
        assertEq(addedCollateral.info.delisted, _collateralTypes[i].info.delisted, "util_addCollateral: Incorrect collateral delisted status");
        
        // Verify modifiers
        for (uint256 j = 0; j < NUMERIC_TRAITS_NUM; j++) {
            assertEq(addedCollateral.info.modifiers[j], _collateralTypes[i].info.modifiers[j], "util_addCollateral: Incorrect modifier value");
            assertTrue(
                addedCollateral.info.modifiers[j] == 2 ||
                addedCollateral.info.modifiers[j] == 1 ||
                addedCollateral.info.modifiers[j] == -1 ||
                addedCollateral.info.modifiers[j] == -2,
                "Invalid modifier value"
            );
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////
// Setup
///////////////////////////////////////////////////////////////////////////////////
		function setUp() public virtual override {
        super.setUp();

        // create First Duck Cycle
				util_createCycle(10000, 1);

				// add QUACK as collateral to first cycle
				util_addCollateral(cycleId, [CollateralTypeDTO(address(quackToken), CollateralTypeInfo(int16[NUMERIC_TRAITS_NUM](1000000000000000000), false))]);
		}

///////////////////////////////////////////////////////////////////////////////////
// Tests
///////////////////////////////////////////////////////////////////////////////////
    function testBasicEggsMint() public {
        uint256 initialBalance = quackToken.balanceOf(address(this));
        uint256 mintPrice = cycle.eggPrice;

        // Approve QUACK tokens for spending
        quackToken.approve(address(diamond), mintPrice);

        // Mint a duck
        uint256 duckId = diamond.mintDuck(cycleId);

        // Assert duck was minted
        assertEq(diamond.ownerOf(duckId), address(this), "Egg not minted to correct address");
        assertEq(diamond.balanceOf(address(this)), 1, "Incorrect duck balance");

        // Assert QUACK tokens were spent
        assertEq(quackToken.balanceOf(address(this)), initialBalance - mintPrice, "Incorrect QUACK balance after mint");

        // Assert cycle state updated
        (,Cycle memory updatedCycle) = diamond.currentCycle();
        assertEq(updatedCycle.totalCount, 1, "Cycle total count not updated");
    }

			function testFailMintEggsInsufficientBalance() public {
        uint256 mintPrice = cycle.eggPrice;
        
        // Attempt to mint without sufficient balance
        vm.expectRevert("Insufficient balance");
        diamond.mintDuck(cycleId);
    }

function testMintFullEggsSupply() public {
    uint256 cycleMaxSize = cycle.cycleMaxSize;
    uint256 mintPrice = cycle.eggPrice;

    // Approve QUACK tokens for spending
    quackToken.approve(address(diamond), mintPrice * cycleMaxSize);

    // Mint ducks until the cycle is full
    for (uint256 i = 0; i < cycleMaxSize; i++) {
        uint256 duckId = diamond.mintDuck(cycleId);
        assertEq(diamond.ownerOf(duckId), address(this), "Duck not minted to correct address");
    }

    // Assert cycle is full
    (,Cycle memory updatedCycle) = diamond.currentCycle();
    assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle not full");

    // Attempt to mint one more duck, should fail
    vm.expectRevert("Cycle is full");
    diamond.mintDuck(cycleId);
}
		function testBasicDuckHatching() public {
			testBasicEggsMint();
			uint256 vrfPrice = diamond.getVrfPrice();
			diamond.openEgg{value: vrfPrice}([duckId]);
			uint256 duckId = 0;
			diamond.claimDuck(duckId, 1, 1);

			DuckInfoDTO memory duckInfo = diamond.getDuckInfo(duckId);
			assertEq(duckInfo.status, DuckStatus.DUCK, "Duck not hatched");
			assertEq(duckInfo.collateralType, 0, "Duck not hatched");
		}
}
