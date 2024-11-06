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
        address target = 0x0eEbe5984f388673Ae4c7b14CA91e8F721a2a108; // baseSepolia testnet
        diamond = IDiamondProxy(target);
        uint256 maxCycleDuckQty = 10000;

        /////////////////////////////////////////////////////////////////////
        // Create first Item : Old Bread
        /////////////////////////////////////////////////////////////////////
        console.log("Creating first Item : Old Bread...");
        ItemType memory newItem_oldBread = ItemType({
            name: "Old Bread",
            description: "Give +10 food.",
            author: msg.sender,
            characteristicsModifiers: new int16[](6),
            statisticsModifiers: new int16[](6),
            slotPositions: new bool[](9),
            allowedCollaterals: new uint8[](0),
            quackPrice: 10,
            maxQuantity: 0,
            totalQuantity: 0,
            svgId: 1,
            rarityScoreModifier: 10,
            canPurchaseWithQuack: true,
            minLevel: 0,
            canBeTransferred: true,
            category: 2, // 0 = WEARABLE, 1 = BADGE, 2 = CONSUMABLE, 3 = CURRENCY
            kinshipBonus: 0,
            experienceBonus: 10
        });
        newItem_oldBread.characteristicsModifiers[0] = 0; // STRENGTH
        newItem_oldBread.characteristicsModifiers[1] = 0; // AGILITY
        newItem_oldBread.characteristicsModifiers[2] = 0; // INTELLIGENCE
        newItem_oldBread.characteristicsModifiers[3] = 0; // PERCEPTION
        newItem_oldBread.characteristicsModifiers[4] = 0; // CHARISMA
        newItem_oldBread.characteristicsModifiers[5] = 0; // LUCK

        newItem_oldBread.statisticsModifiers[0] = 0; // HEALTH
        newItem_oldBread.statisticsModifiers[1] = 0; // MANA
        newItem_oldBread.statisticsModifiers[2] = 0; // SPECIAL
        newItem_oldBread.statisticsModifiers[3] = 0; // ENERGY
        newItem_oldBread.statisticsModifiers[4] = 10; // FOOD
        newItem_oldBread.statisticsModifiers[5] = 0; // SANITY

        newItem_oldBread.slotPositions[0] = false; // BODY
        newItem_oldBread.slotPositions[1] = false; // FACE 
        newItem_oldBread.slotPositions[2] = false; // EYES
        newItem_oldBread.slotPositions[3] = false; // HEAD
        newItem_oldBread.slotPositions[4] = false; // MOUTH
        newItem_oldBread.slotPositions[5] = false; // HAND_LEFT
        newItem_oldBread.slotPositions[6] = false; // HAND_RIGHT
        newItem_oldBread.slotPositions[7] = false; // FEET
        newItem_oldBread.slotPositions[8] = false; // SPECIAL

        /////////////////////////////////////////////////////////////////////
        // Create first Item : Glass of Wine
        /////////////////////////////////////////////////////////////////////
        console.log("Creating first Item : Glass of Wine");
        ItemType memory newItem_glassOfWine = ItemType({
            name: "Glass of Wine",
            description: "Give +10 health.",
            author: msg.sender,
            characteristicsModifiers: new int16[](6),
            statisticsModifiers: new int16[](6),
            slotPositions: new bool[](9),
            allowedCollaterals: new uint8[](0),
            quackPrice: 10,
            maxQuantity: 0,
            totalQuantity: 0,
            svgId: 2,
            rarityScoreModifier: 10,
            canPurchaseWithQuack: true,
            minLevel: 0,
            canBeTransferred: true,
            category: 2, // 0 = WEARABLE, 1 = BADGE, 2 = CONSUMABLE, 3 = CURRENCY
            kinshipBonus: 0,
            experienceBonus: 10
        });
        newItem_glassOfWine.characteristicsModifiers[0] = 0; // STRENGTH
        newItem_glassOfWine.characteristicsModifiers[1] = 0; // AGILITY
        newItem_glassOfWine.characteristicsModifiers[2] = 0; // INTELLIGENCE
        newItem_glassOfWine.characteristicsModifiers[3] = 0; // PERCEPTION
        newItem_glassOfWine.characteristicsModifiers[4] = 0; // CHARISMA
        newItem_glassOfWine.characteristicsModifiers[5] = 0; // LUCK

        newItem_glassOfWine.statisticsModifiers[0] = 20; // HEALTH
        newItem_glassOfWine.statisticsModifiers[1] = 0; // MANA
        newItem_glassOfWine.statisticsModifiers[2] = 0; // SPECIAL
        newItem_glassOfWine.statisticsModifiers[3] = 0; // ENERGY
        newItem_glassOfWine.statisticsModifiers[4] = 0; // FOOD
        newItem_glassOfWine.statisticsModifiers[5] = -1; // SANITY

        newItem_glassOfWine.slotPositions[0] = false; // BODY
        newItem_glassOfWine.slotPositions[1] = false; // FACE 
        newItem_glassOfWine.slotPositions[2] = false; // EYES
        newItem_glassOfWine.slotPositions[3] = false; // HEAD
        newItem_glassOfWine.slotPositions[4] = false; // MOUTH
        newItem_glassOfWine.slotPositions[5] = false; // HAND_LEFT
        newItem_glassOfWine.slotPositions[6] = false; // HAND_RIGHT
        newItem_glassOfWine.slotPositions[7] = false; // FEET
        newItem_glassOfWine.slotPositions[8] = false; // SPECIAL

        /////////////////////////////////////////////////////////////////////
        // Create first Item : Glass of Wine
        /////////////////////////////////////////////////////////////////////
        console.log("Creating first Item : XP Boost");
        ItemType memory newItem_xpBoost = ItemType({
            name: "XP Boost",
            description: "No time to waste uh ? +1000xp.",
            author: msg.sender,
            characteristicsModifiers: new int16[](6),
            statisticsModifiers: new int16[](6),
            slotPositions: new bool[](9),
            allowedCollaterals: new uint8[](0),
            quackPrice: 10,
            maxQuantity: 1000000,
            totalQuantity: 0,
            svgId: 3,
            rarityScoreModifier: 10,
            canPurchaseWithQuack: true,
            minLevel: 0,
            canBeTransferred: true,
            category: 2, // 0 = WEARABLE, 1 = BADGE, 2 = CONSUMABLE, 3 = CURRENCY
            kinshipBonus: 0,
            experienceBonus: 1000
        });
        newItem_xpBoost.characteristicsModifiers[0] = 0; // STRENGTH
        newItem_xpBoost.characteristicsModifiers[1] = 0; // AGILITY
        newItem_xpBoost.characteristicsModifiers[2] = 0; // INTELLIGENCE
        newItem_xpBoost.characteristicsModifiers[3] = 0; // PERCEPTION
        newItem_xpBoost.characteristicsModifiers[4] = 0; // CHARISMA
        newItem_xpBoost.characteristicsModifiers[5] = 0; // LUCK

        newItem_xpBoost.statisticsModifiers[0] = 0; // HEALTH
        newItem_xpBoost.statisticsModifiers[1] = 0; // MANA
        newItem_xpBoost.statisticsModifiers[2] = 0; // SPECIAL
        newItem_xpBoost.statisticsModifiers[3] = 0; // ENERGY
        newItem_xpBoost.statisticsModifiers[4] = 0; // FOOD
        newItem_xpBoost.statisticsModifiers[5] = 0; // SANITY

        newItem_xpBoost.slotPositions[0] = false; // BODY
        newItem_xpBoost.slotPositions[1] = false; // FACE 
        newItem_xpBoost.slotPositions[2] = false; // EYES
        newItem_xpBoost.slotPositions[3] = false; // HEAD
        newItem_xpBoost.slotPositions[4] = false; // MOUTH
        newItem_xpBoost.slotPositions[5] = false; // HAND_LEFT
        newItem_xpBoost.slotPositions[6] = false; // HAND_RIGHT
        newItem_xpBoost.slotPositions[7] = false; // FEET
        newItem_xpBoost.slotPositions[8] = false; // SPECIAL

        /////////////////////////////////////////////////////////////////////

        /////////////////////////////////////////////////////////////////////
        // Create first Item : Glass of Wine
        /////////////////////////////////////////////////////////////////////
        console.log("Creating first Item : Wearable Pirate Eye");
        ItemType memory newItem_pirateEye = ItemType({
            name: "Wearable Pirate Eye",
            description: "Cool by design",
            author: msg.sender,
            characteristicsModifiers: new int16[](6),
            statisticsModifiers: new int16[](6),
            slotPositions: new bool[](9),
            allowedCollaterals: new uint8[](1),
            quackPrice: 10,
            maxQuantity: 1000000,
            totalQuantity: 0,
            svgId: 4,
            rarityScoreModifier: 10,
            canPurchaseWithQuack: true,
            minLevel: 1,
            canBeTransferred: true,
            category: 0, // 0 = WEARABLE, 1 = BADGE, 2 = CONSUMABLE, 3 = CURRENCY
            kinshipBonus: 10,
            experienceBonus: 10
        });
        newItem_pirateEye.characteristicsModifiers[0] = 5; // STRENGTH
        newItem_pirateEye.characteristicsModifiers[1] = 2; // AGILITY
        newItem_pirateEye.characteristicsModifiers[2] = -2; // INTELLIGENCE
        newItem_pirateEye.characteristicsModifiers[3] = 1; // PERCEPTION
        newItem_pirateEye.characteristicsModifiers[4] = 5; // CHARISMA
        newItem_pirateEye.characteristicsModifiers[5] = 3; // LUCK

        newItem_pirateEye.statisticsModifiers[0] = 2; // HEALTH
        newItem_pirateEye.statisticsModifiers[1] = 0; // MANA
        newItem_pirateEye.statisticsModifiers[2] = 1; // SPECIAL
        newItem_pirateEye.statisticsModifiers[3] = 1; // ENERGY
        newItem_pirateEye.statisticsModifiers[4] = 0; // FOOD
        newItem_pirateEye.statisticsModifiers[5] = 0; // SANITY

        newItem_pirateEye.slotPositions[0] = false; // BODY
        newItem_pirateEye.slotPositions[1] = false; // FACE 
        newItem_pirateEye.slotPositions[2] = true; // EYES
        newItem_pirateEye.slotPositions[3] = false; // HEAD
        newItem_pirateEye.slotPositions[4] = false; // MOUTH
        newItem_pirateEye.slotPositions[5] = false; // HAND_LEFT
        newItem_pirateEye.slotPositions[6] = false; // HAND_RIGHT
        newItem_pirateEye.slotPositions[7] = false; // FEET
        newItem_pirateEye.slotPositions[8] = false; // SPECIAL

        newItem_pirateEye.allowedCollaterals[0] = 0; // QUACK COLLATERAL
        /////////////////////////////////////////////////////////////////////


        ItemType[] memory items = new ItemType[](4);
        items[0] = newItem_oldBread;
        items[1] = newItem_glassOfWine;
        items[2] = newItem_xpBoost;
        items[3] = newItem_pirateEye;
        diamond.addItemTypes(items);
        console.log("First Item : Body Color created");

        console.log("Creating first Duck Cycle...");
        uint256[] memory bodyIds = new uint256[](6);
        bodyIds[0] = 1;
        bodyIds[1] = 2;
        bodyIds[2] = 3;
        bodyIds[3] = 4;
        bodyIds[4] = 5;
        bodyIds[5] = 6;

        diamond.createCycle(
            uint24(maxCycleDuckQty), // cycle max supply
            1, // eggs price
            bodyIds // item id base color
        );
        console.log("First Duck Cycle created");

        (uint16 cycleId,) = diamond.currentCycle();
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