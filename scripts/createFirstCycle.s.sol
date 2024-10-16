// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/generated/DiamondProxy.sol";
import "../src/generated/IDiamondProxy.sol";
import "../src/shared/Structs.sol";
import "../src/shared/Structs_Ducks.sol";
import "../src/shared/Structs_Items.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract CreateFirstCycle is Script {
    IDiamondProxy public diamond;
    IERC20 public quackToken;

    function setUp() public {
        string memory rpcUrl = vm.envString("BASE_SEPOLIA_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("TEST_ADMIN_PKEY");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
    }

    function run() public {
        address target = 0x7D14D2aB9353e202fa9A8b63Ca2a2148E43E8294; // baseSepolia testnet
        diamond = IDiamondProxy(target);
        uint256 maxCycleDuckQty = 42;
        
        // Create first Item : Body Color
        console.log("Creating first Item : Body Color...");
        ItemType memory bodyColor = ItemType({
            name: "Green",
            description: "Body Color - Green",
            author: msg.sender,
            characteristicsModifiers: new int16[](6),
            statisticsModifiers: new int16[](6),
            slotPositions: new bool[](9),
            allowedCollaterals: new uint8[](1),
            quackPrice: 0,
            maxQuantity: maxCycleDuckQty,
            totalQuantity: 0,
            svgId: 0,
            rarityScoreModifier: 10,
            canPurchaseWithQuack: false,
            minLevel: 0,
            canBeTransferred: true,
            category: 0, // 0 = WEARABLE, 1 = BADGE, 2 = CONSUMABLE, 3 = CURRENCY
            kinshipBonus: 0,
            experienceBonus: 0
        });
        bodyColor.characteristicsModifiers[0] = 0; // STRENGTH
        bodyColor.characteristicsModifiers[1] = 0; // AGILITY
        bodyColor.characteristicsModifiers[2] = 0; // INTELLIGENCE
        bodyColor.characteristicsModifiers[3] = 0; // PERCEPTION
        bodyColor.characteristicsModifiers[4] = 0; // CHARISMA
        bodyColor.characteristicsModifiers[5] = 0; // LUCK

        bodyColor.statisticsModifiers[0] = 0; // HEALTH
        bodyColor.statisticsModifiers[1] = 0; // MANA
        bodyColor.statisticsModifiers[2] = 3; // SPECIAL
        bodyColor.statisticsModifiers[3] = 0; // ENERGY
        bodyColor.statisticsModifiers[4] = 0; // FOOD
        bodyColor.statisticsModifiers[5] = -2; // SANITY

        bodyColor.slotPositions[0] = true; // BODY
        bodyColor.slotPositions[1] = false; // FACE 
        bodyColor.slotPositions[2] = false; // EYES
        bodyColor.slotPositions[3] = false; // HEAD
        bodyColor.slotPositions[4] = false; // MOUTH
        bodyColor.slotPositions[5] = false; // HAND_LEFT
        bodyColor.slotPositions[6] = false; // HAND_RIGHT
        bodyColor.slotPositions[7] = false; // FEET
        bodyColor.slotPositions[8] = false; // SPECIAL

        bodyColor.allowedCollaterals[0] = 0; // QUACK COLLATERAL

        ItemType[] memory items = new ItemType[](1);
        items[0] = bodyColor;
        diamond.addItemTypes(items);
        console.log("First Item : Body Color created");

        console.log("Creating first Duck Cycle...");
        diamond.createCycle(
            uint24(maxCycleDuckQty), // cycle max supply
            1, // eggs price
            0 // item id base color
        );
        console.log("First Duck Cycle created");

        (uint256 cycleId,) = diamond.currentCycle();
        console.log("Cycle ID:", cycleId);

        console.log("Adding QUACK as collateral to first cycle...");
        address quackTokenAddress = diamond.quackAddress();
        int16[] memory quackModifiers = new int16[](6);
        quackModifiers[0] = -2;
        quackModifiers[1] = 1;
        quackModifiers[2] = 2;
        quackModifiers[3] = 1;
        quackModifiers[4] = 0;
        quackModifiers[5] = -1;

        CollateralTypeDTO[] memory collateralTypes = new CollateralTypeDTO[](1);
        collateralTypes[0] = CollateralTypeDTO({
            collateralType: quackTokenAddress,
            modifiers: quackModifiers,
            primaryColor: bytes3(0x000000),
            secondaryColor: bytes3(0x000000),
            delisted: false
        });

        diamond.addCollateralTypes(cycleId, collateralTypes);
        console.log("QUACK added as collateral to first cycle");

        console.log("Post-deployment initialization completed successfully");

        vm.stopBroadcast();
    }
}