// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/generated/DiamondProxy.sol";
import "../../src/generated/IDiamondProxy.sol";
import "../../src/shared/Structs.sol";
import "../../src/shared/Structs_Ducks.sol";
import "../../src/shared/Structs_Items.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

/**
 * @title CreateDisplaySlot Script
 * @dev This script creates a new display slot in the QUACK game
 * @notice Run with: forge script script/CreateDisplaySlot.s.sol:CreateDisplaySlot --broadcast --verify -vvvv
 */
contract CreateDisplaySlot is Script {
    IDiamondProxy public diamond;
    
    // Slot details
    string public slotName;
    string public slotDescription;
    uint256 public pricePerWeek;

    function setUp() public {
        // Setup fork
        string memory rpcUrl = vm.envString("BASE_SEPOLIA_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("TEST_ADMIN_PKEY");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set diamond address for baseSepolia testnet
        address target = 0xBaf52B4B45A28293ACE0116918a9fFD31D57334D;
        diamond = IDiamondProxy(target);

        // Set slot details from environment variables or use defaults
        slotName = vm.envOr("SLOT_NAME", string("Default Display Slot"));
        slotDescription = vm.envOr("SLOT_DESCRIPTION", string("A panel to showcase your NFTs"));
        pricePerWeek = vm.envOr("PRICE_PER_WEEK", uint256(100)); // Default 100 QUACK tokens
    }

    function run() public {
        // Create the display slot
        uint256 slotId = diamond.createDisplaySlot(slotName, slotDescription, pricePerWeek);
        
        // Log the result
        console.log("Created display slot with ID:", slotId);
        console.log("Name:", slotName);
        console.log("Description:", slotDescription);
        console.log("Price per week:", pricePerWeek);
        
        vm.stopBroadcast();
    }
} 