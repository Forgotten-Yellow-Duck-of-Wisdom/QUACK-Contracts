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
 * @title CancelDisplayRental Script
 * @dev This script cancels an active rental for a display slot
 * @notice Run with: forge script script/CancelDisplayRental.s.sol:CancelDisplayRental --broadcast --verify -vvvv
 */
contract CancelDisplayRental is Script {
    IDiamondProxy public diamond;
    
    // Slot ID to cancel rental for
    uint256 public slotId;

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
    }

    function run() public {
        // First, get current rental details to show what we're canceling
        (
            address renter, 
            address contractAddress, 
            uint256 tokenId, 
            bool isRented
        ) = _getRentalDetails(diamond, slotId);
        
        // Check if the slot is actually rented
        require(isRented, "This slot is not currently rented");

        // Cancel the rental
        diamond.cancelRental(slotId);
        
        // Log the result
        console.log("Canceled rental for display slot with ID:", slotId);
        console.log("Rental details that were canceled:");
        console.log("  Renter:", renter);
        console.log("  NFT Contract:", contractAddress);
        console.log("  Token ID:", tokenId);
        
        vm.stopBroadcast();
    }

    function _getRentalDetails(IDiamondProxy diamond, uint256 _slotId) internal view returns (
        address renter,
        address contractAddress,
        uint256 tokenId,
        bool isRented
    ) {
        // Call getSlotDetails and extract rental info
        (
            ,
            DisplayRental memory rental,
            bool rented
        ) = diamond.getSlotDetails(_slotId);
        
        return (rental.renter, rental.contractAddress, rental.tokenId, rented);
    }
}

// Simple struct to match the contract return type
struct DisplayRental {
    address renter;
    address contractAddress;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    bool isActive;
} 