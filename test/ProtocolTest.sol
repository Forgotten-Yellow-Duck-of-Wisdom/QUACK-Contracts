// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
import {Cycle, DuckStatusType, DuckInfo, DuckInfoDTO, EggDuckTraitsDTO} from "../src/shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../src/shared/Structs.sol";

contract ProtocolTest is TestBaseContract {
    uint256 cycleId;
    Cycle cycle;

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

    function util_addCollateral(uint256 _cycleId, CollateralTypeDTO[] memory _collateralTypes) internal {
        uint256 initialCollateralCount = diamond.getCycleCollateralsAddresses(_cycleId).length;

        diamond.addCollateralTypes(_cycleId, _collateralTypes);

        uint256 updatedCollateralCount = diamond.getCycleCollateralsAddresses(_cycleId).length;
        assertEq(
            updatedCollateralCount,
            initialCollateralCount + _collateralTypes.length,
            "util_addCollateral: Collateral types not added correctly"
        );

        for (uint256 i = 0; i < _collateralTypes.length; i++) {
            CollateralTypeDTO memory addedCollateral =
                diamond.getCycleCollateralInfo(_cycleId, initialCollateralCount + i);
            assertEq(
                addedCollateral.collateralType,
                _collateralTypes[i].collateralType,
                "util_addCollateral: Incorrect collateral address"
            );
            assertEq(
                addedCollateral.delisted,
                _collateralTypes[i].delisted,
                "util_addCollateral: Incorrect collateral delisted status"
            );

            assertEq(
                addedCollateral.primaryColor,
                _collateralTypes[i].primaryColor,
                "util_addCollateral: Incorrect collateral primary color"
            );

            assertEq(
                addedCollateral.secondaryColor,
                _collateralTypes[i].secondaryColor,
                "util_addCollateral: Incorrect collateral secondary color"
            );

            // Verify modifiers
            for (uint256 j = 0; j < _collateralTypes[i].modifiers.length; j++) {
                assertEq(
                    addedCollateral.modifiers[j],
                    _collateralTypes[i].modifiers[j],
                    "util_addCollateral: Incorrect modifier value"
                );
                // assertTrue(
                //     addedCollateral.modifiers[j] == 2 || addedCollateral.modifiers[j] == 1
                //         || addedCollateral.modifiers[j] == -1 || addedCollateral.modifiers[j] == -2,
                //     "Invalid modifier value"
                // );
                assertTrue(addedCollateral.modifiers[j] == _collateralTypes[i].modifiers[j], "Invalid modifier value");
            }
        }
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
        // Define modifiers as int16[]
        int16[] memory modifiers = new int16[](6);
        modifiers[0] = -2;
        modifiers[1] = 1;
        modifiers[2] = 2;
        modifiers[3] = 1;
        modifiers[4] = 0;
        modifiers[5] = -1;

        // Create a dynamic array of CollateralTypeDTO
        CollateralTypeDTO[] memory collateralTypes = new CollateralTypeDTO[](1);
        collateralTypes[0] =
            CollateralTypeDTO(address(quackToken), modifiers, bytes3(0x000000), bytes3(0x000000), false);

        // Add collateral
        util_addCollateral(cycleId, collateralTypes);
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Tests
    ///////////////////////////////////////////////////////////////////////////////////
    function testBasicEggsMint() public {
        uint256 initialBalance = quackToken.balanceOf(account0);
        uint256 mintPrice = cycle.eggsPrice;
        // quackToken.mint(account1, 1000000000000000000);
        // Approve QUACK tokens for spending


        quackToken.approve(address(diamond), mintPrice);

        // Mint a duck
        uint256 duckId = diamond.buyEgg(account0);

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
        diamond.buyEgg(account1);
    }

    function testMintFullEggsSupply() public {
        uint256 cycleMaxSize = cycle.cycleMaxSize;
        uint256 mintPrice = cycle.eggsPrice;

        // Approve QUACK tokens for spending
        quackToken.approve(address(diamond), mintPrice * cycleMaxSize);

        // Mint ducks until the cycle is full
        for (uint256 i = 0; i < cycleMaxSize; i++) {
            uint256 duckId = diamond.buyEgg(account0);
            assertEq(diamond.ownerOf(duckId), account0, "Duck not minted to correct address");
        }

        // Assert cycle is full
        (, Cycle memory updatedCycle) = diamond.currentCycle();
        assertEq(updatedCycle.totalCount, cycleMaxSize, "Cycle not full");

        // Attempt to mint one more duck, should fail
        vm.expectRevert("DuckGameFacet: Exceeded max number of duck for this cycle");
        diamond.buyEgg(account0);
    }

    function testBasicDuckHatching() public {
        testBasicEggsMint();
        uint256 vrfPrice = diamond.getVRFRequestPrice();
    		uint256[] memory ids = new uint256[](1);
    		ids[0] = 0;
        diamond.openEggs{value: vrfPrice}(ids);
        diamond.claimDuck(ids[0], 1, 1);

        DuckInfoDTO memory duckInfo = diamond.getDuckInfo(ids[0]);
        assertEq(uint256(duckInfo.status), uint256(DuckStatusType.DUCK), "Duck not hatched");
        assertEq(duckInfo.collateral, address(quackToken), "Duck not hatched");
    }
}
