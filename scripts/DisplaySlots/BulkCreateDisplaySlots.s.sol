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
 * @title BulkCreateDisplaySlots Script
 * @dev This script creates multiple display slots at once in the QUACK game
 * @notice Run with: forge script script/BulkCreateDisplaySlots.s.sol:BulkCreateDisplaySlots --broadcast --verify -vvvv
 */
contract BulkCreateDisplaySlots is Script {
    IDiamondProxy public diamond;
    
    // Number of slots to create
    uint256 public slotCount;
    
    // Base price for slots
    uint256 public basePrice;
    
    // Price increment for each subsequent slot
    uint256 public priceIncrement;

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
        slotCount = vm.envOr("SLOT_COUNT", uint256(5));
        basePrice = vm.envOr("BASE_PRICE", uint256(100)); // Default 100 QUACK tokens
        priceIncrement = vm.envOr("PRICE_INCREMENT", uint256(50)); // Default 50 QUACK increment
    }

    function run() public {
        // Array to store created slot IDs
        uint256[] memory createdSlotIds = new uint256[](slotCount);
        
        for (uint256 i = 0; i < slotCount; i++) {
            // Calculate price for this slot
            uint256 slotPrice = basePrice + (i * priceIncrement);
            
            // Create slot with unique name and description
            string memory slotName = string(abi.encodePacked("Display Slot #", _uint2str(i + 1)));
            string memory slotDescription = string(abi.encodePacked("Showcase your NFTs in the QUACK world - Panel #", _uint2str(i + 1)));
            
            // Create the slot
            uint256 slotId = diamond.createDisplaySlot(slotName, slotDescription, slotPrice);
            createdSlotIds[i] = slotId;
            
            // Log each creation (will be in the script output)
            console.log("Created slot #%d with ID: %d and price: %d", i + 1, slotId, slotPrice);
        }
        
        // Log summary
        console.log("--------------------------------------");
        console.log("Created %d display slots", slotCount);
        console.log("Base price: %d QUACK", basePrice);
        console.log("Price increment: %d QUACK", priceIncrement);
        console.log("--------------------------------------");
        
        vm.stopBroadcast();
    }
    
    // Helper function to convert uint to string
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
} 