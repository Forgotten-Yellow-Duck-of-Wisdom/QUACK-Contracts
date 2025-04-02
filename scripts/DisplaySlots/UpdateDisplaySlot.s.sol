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
 * @title UpdateDisplaySlot Script
 * @dev This script updates an existing display slot in the QUACK game
 * @notice Run with: forge script script/UpdateDisplaySlot.s.sol:UpdateDisplaySlot --broadcast --verify -vvvv
 */
contract UpdateDisplaySlot is Script {
    IDiamondProxy public diamond;
    
    // Slot details
    uint256 public slotId;
    string public slotName;
    string public slotDescription;
    uint256 public pricePerWeek;
    bool public isActive;

    function setUp() public {
        // Setup fork
        string memory rpcUrl = vm.envString("BASE_SEPOLIA_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("TEST_ADMIN_PKEY");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set diamond address for baseSepolia testnet
        address target = 0xBaf52B4B45A28293ACE0116918a9fFD31D57334D;
        diamond = IDiamondProxy(target);

        // Get the required slot ID
        slotId = vm.envOr("SLOT_ID", uint256(0));
        
        // Set slot details from environment variables
        slotName = vm.envOr("SLOT_NAME", string("Updated Display Slot"));
        slotDescription = vm.envOr("SLOT_DESCRIPTION", string("Updated description for the display slot"));
        pricePerWeek = vm.envOr("PRICE_PER_WEEK", uint256(100));
        isActive = vm.envOr("IS_ACTIVE", true);
    }

    function run() public {
        // First, get current slot details to show before update
        (
            string memory currentName, 
            string memory currentDescription, 
            uint256 currentPrice, 
            bool currentActive
        ) = _getSlotDetails(diamond, slotId);

        // Update the slot
        diamond.updateDisplaySlot(slotId, slotName, slotDescription, pricePerWeek, isActive);
        
        // Log the result
        console.log("Updated display slot with ID:", slotId);
        console.log("Before update:");
        console.log("  Name:", currentName);
        console.log("  Description:", currentDescription);
        console.log("  Price per week:", currentPrice);
        console.log("  Active:", currentActive);
        console.log("After update:");
        console.log("  Name:", slotName);
        console.log("  Description:", slotDescription);
        console.log("  Price per week:", pricePerWeek);
        console.log("  Active:", isActive);
        
        vm.stopBroadcast();
    }

    function _getSlotDetails(IDiamondProxy diamond, uint256 _slotId) internal view returns (
        string memory name,
        string memory description,
        uint256 price,
        bool active
    ) {
        // Call getSlotDetails and extract basic slot info
        (
            DisplaySlot memory slot,
            ,
        ) = diamond.getSlotDetails(_slotId);
        
        return (slot.name, slot.description, slot.pricePerWeek, slot.isActive);
    }
}

// Simple struct to match the contract return type
struct DisplaySlot {
    uint256 slotId;
    string name;
    string description;
    uint256 pricePerWeek;
    bool isActive;
} 