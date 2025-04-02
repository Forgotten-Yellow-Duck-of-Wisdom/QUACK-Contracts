// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";
import {DisplaySlot, DisplayRental} from "../src/shared/Structs_DisplaySlot.sol";

contract TestDisplaySlot is TestBaseContract {
    uint256 slotId;
    uint256 testSlotPrice = 100;
    string testSlotName = "Test Display Panel";
    string testSlotDescription = "A panel to showcase your NFTs";
    address testContractAddress;
    uint256 testTokenId = 123;
    address treasuryAddress;

    ///////////////////////////////////////////////////////////////////////////////////
    // Setup
    ///////////////////////////////////////////////////////////////////////////////////
    function setUp() public virtual override {
        super.setUp();
        
        // Set testContractAddress to a mock NFT contract address
        testContractAddress = address(0x123456789);
        
        // Get treasury address from the diamond
        treasuryAddress = diamond.getTreasuryAddress();
        
        // Create test display slot
        slotId = diamond.createDisplaySlot(testSlotName, testSlotDescription, testSlotPrice);
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Utils
    ///////////////////////////////////////////////////////////////////////////////////
    function util_createDisplaySlot(string memory _name, string memory _description, uint256 _price) internal returns (uint256) {
        uint256 newSlotId = diamond.createDisplaySlot(_name, _description, _price);
        
        // Get the created slot to verify
        (DisplaySlot memory slot, , ) = diamond.getSlotDetails(newSlotId);
        
        // Verify slot properties
        assertEq(slot.slotId, newSlotId, "Incorrect slot ID");
        assertEq(slot.name, _name, "Incorrect slot name");
        assertEq(slot.description, _description, "Incorrect slot description");
        assertEq(slot.pricePerWeek, _price, "Incorrect slot price");
        assertEq(slot.isActive, true, "Slot should be active");
        
        return newSlotId;
    }
    
    function util_rentDisplaySlot(uint256 _slotId, address _renter, address _contractAddress, uint256 _tokenId) internal {
        // Get slot price
        (DisplaySlot memory slot, , ) = diamond.getSlotDetails(_slotId);
        uint256 price = slot.pricePerWeek;
        
        // Switch to renter account
        vm.startPrank(_renter);
        
        // Approve QUACK tokens for spending
        quackToken.approve(address(diamond), price);
        
        // Rent the slot
        diamond.rentDisplaySlot(_slotId, _contractAddress, _tokenId);
        
        // Stop impersonating
        vm.stopPrank();
        
        // Verify rental
        (,DisplayRental memory rental, bool isRented) = diamond.getSlotDetails(_slotId);
        
        assertEq(isRented, true, "Slot should be rented");
        assertEq(rental.renter, _renter, "Incorrect renter");
        assertEq(rental.contractAddress, _contractAddress, "Incorrect contract address");
        assertEq(rental.tokenId, _tokenId, "Incorrect token ID");
        assertEq(rental.isActive, true, "Rental should be active");
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Tests Display Slots
    ///////////////////////////////////////////////////////////////////////////////////
    function test_createDisplaySlot() public {
        // Test slot creation with different parameters
        string memory name = "Premium Display";
        string memory description = "A premium slot for high-value NFTs";
        uint256 price = 200;
        
        uint256 newSlotId = util_createDisplaySlot(name, description, price);
        
        // Ensure ID increments properly
        assertEq(newSlotId, slotId + 1, "Slot ID should increment");
    }
    
    function test_updateDisplaySlot() public {
        // Get initial slot details
        (DisplaySlot memory initialSlot, , ) = diamond.getSlotDetails(slotId);
        
        // Define updated values
        string memory updatedName = "Updated Display Panel";
        string memory updatedDescription = "Updated description for the panel";
        uint256 updatedPrice = 150;
        bool updatedActive = true;
        
        // Update the slot
        diamond.updateDisplaySlot(slotId, updatedName, updatedDescription, updatedPrice, updatedActive);
        
        // Get updated slot details
        (DisplaySlot memory updatedSlot, , ) = diamond.getSlotDetails(slotId);
        
        // Verify updates
        assertEq(updatedSlot.slotId, initialSlot.slotId, "Slot ID should not change");
        assertEq(updatedSlot.name, updatedName, "Name should be updated");
        assertEq(updatedSlot.description, updatedDescription, "Description should be updated");
        assertEq(updatedSlot.pricePerWeek, updatedPrice, "Price should be updated");
        assertEq(updatedSlot.isActive, updatedActive, "Active status should be updated");
    }
    
    function test_deactivateDisplaySlot() public {
        // Update the slot to deactivate it
        diamond.updateDisplaySlot(slotId, testSlotName, testSlotDescription, testSlotPrice, false);
        
        // Get updated slot details
        (DisplaySlot memory updatedSlot, , ) = diamond.getSlotDetails(slotId);
        
        // Verify it's deactivated
        assertEq(updatedSlot.isActive, false, "Slot should be deactivated");
        
        // Try to rent the deactivated slot
        vm.startPrank(account1);
        quackToken.approve(address(diamond), testSlotPrice);
        vm.expectRevert("DisplaySlotFacet: Slot is not active");
        diamond.rentDisplaySlot(slotId, testContractAddress, testTokenId);
        vm.stopPrank();
    }
    
    function test_rentDisplaySlot() public {
        // Initial state check
        (,, bool initialRented) = diamond.getSlotDetails(slotId);
        assertEq(initialRented, false, "Slot should not be rented initially");
        
        // Give account1 some QUACK tokens
        quackToken.mint(account1, 1000);
        
        // Initial treasury balance
        uint256 initialTreasuryBalance = quackToken.balanceOf(treasuryAddress);
        
        // Rent the slot from account1
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Verify treasury received payment
        assertEq(
            quackToken.balanceOf(treasuryAddress), 
            initialTreasuryBalance + testSlotPrice, 
            "Treasury should receive payment"
        );
        
        // Check user rentals
        (uint256[] memory slotIds, DisplayRental[] memory rentals) = diamond.getUserRentals(account1);
        
        assertEq(slotIds.length, 1, "User should have 1 rented slot");
        assertEq(slotIds[0], slotId, "Incorrect slot ID in user rentals");
        assertEq(rentals[0].renter, account1, "Incorrect renter in user rentals");
        assertEq(rentals[0].contractAddress, testContractAddress, "Incorrect contract address in user rentals");
        assertEq(rentals[0].tokenId, testTokenId, "Incorrect token ID in user rentals");
    }
    
    function test_cannotRentAlreadyRentedSlot() public {
        // First, rent the slot
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Try to rent the same slot again
        quackToken.mint(account2, 1000);
        vm.startPrank(account2);
        quackToken.approve(address(diamond), testSlotPrice);
        vm.expectRevert("DisplaySlotFacet: Slot is already rented");
        diamond.rentDisplaySlot(slotId, address(0x456), 456);
        vm.stopPrank();
    }
    
    function test_rentalExpiration() public {
        // First, rent the slot
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Fast forward time to after rental expires (1 week + 1 second)
        vm.warp(block.timestamp + 1 weeks + 1 seconds);
        
        // Check slot is no longer rented
        (,, bool isRented) = diamond.getSlotDetails(slotId);
        assertEq(isRented, false, "Slot should not be rented after expiration");
        
        // Rent it again with a different account
        quackToken.mint(account2, 1000);
        util_rentDisplaySlot(slotId, account2, address(0x456), 456);
    }
    
    function test_cancelRental() public {
        // First, rent the slot
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Cancel the rental as admin
        diamond.cancelRental(slotId);
        
        // Verify rental is canceled
        (,DisplayRental memory rental, bool isRented) = diamond.getSlotDetails(slotId);
        assertEq(isRented, false, "Slot should not be rented after cancellation");
        assertEq(rental.isActive, false, "Rental should be inactive");
        
        // Check user rentals
        (uint256[] memory slotIds, ) = diamond.getUserRentals(account1);
        assertEq(slotIds.length, 0, "User should have no rented slots after cancellation");
    }
    
    function test_nonAdminCannotCancelRental() public {
        // First, rent the slot
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Try to cancel the rental as non-admin
        vm.startPrank(account1);
        vm.expectRevert();
        diamond.cancelRental(slotId);
        vm.stopPrank();
    }
    
    function test_getAvailableSlots() public {
        // Create multiple slots
        uint256 slot2 = util_createDisplaySlot("Slot 2", "Second test slot", 200);
        uint256 slot3 = util_createDisplaySlot("Slot 3", "Third test slot", 300);
        
        // Rent one slot
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        
        // Deactivate another slot
        diamond.updateDisplaySlot(slot2, "Slot 2", "Second test slot", 200, false);
        
        // Get available slots
        (uint256[] memory availableSlotIds, DisplaySlot[] memory availableSlots) = diamond.getAvailableSlots();
        
        // Only slot3 should be available
        assertEq(availableSlotIds.length, 1, "Should have 1 available slot");
        assertEq(availableSlotIds[0], slot3, "Available slot should be slot3");
        assertEq(availableSlots[0].slotId, slot3, "Available slot details mismatch");
    }
    
    function test_getCurrentDisplays() public {
        // Create multiple slots
        uint256 slot2 = util_createDisplaySlot("Slot 2", "Second test slot", 200);
        
        // Rent both slots with different NFTs
        quackToken.mint(account1, 2000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        util_rentDisplaySlot(slot2, account1, address(0x456), 456);
        
        // Get current displays
        (
            uint256[] memory displaySlotIds,
            address[] memory contractAddresses,
            uint256[] memory tokenIds,
            address[] memory renters,
            uint256[] memory endTimes
        ) = diamond.getCurrentDisplays();
        
        // Verify we have 2 displays
        assertEq(displaySlotIds.length, 2, "Should have 2 displays");
        
        // Verify first display
        bool foundSlot1 = false;
        bool foundSlot2 = false;
        
        for (uint256 i = 0; i < displaySlotIds.length; i++) {
            if (displaySlotIds[i] == slotId) {
                foundSlot1 = true;
                assertEq(contractAddresses[i], testContractAddress, "Incorrect contract address for slot 1");
                assertEq(tokenIds[i], testTokenId, "Incorrect token ID for slot 1");
                assertEq(renters[i], account1, "Incorrect renter for slot 1");
            } else if (displaySlotIds[i] == slot2) {
                foundSlot2 = true;
                assertEq(contractAddresses[i], address(0x456), "Incorrect contract address for slot 2");
                assertEq(tokenIds[i], 456, "Incorrect token ID for slot 2");
                assertEq(renters[i], account1, "Incorrect renter for slot 2");
            }
        }
        
        assertTrue(foundSlot1, "Didn't find slot 1 in current displays");
        assertTrue(foundSlot2, "Didn't find slot 2 in current displays");
    }
    
    function test_multipleRentalsForSameUser() public {
        // Create multiple slots
        uint256 slot2 = util_createDisplaySlot("Slot 2", "Second test slot", 200);
        uint256 slot3 = util_createDisplaySlot("Slot 3", "Third test slot", 300);
        
        // Rent all slots with the same account
        quackToken.mint(account1, 1000);
        util_rentDisplaySlot(slotId, account1, testContractAddress, testTokenId);
        util_rentDisplaySlot(slot2, account1, address(0x456), 456);
        util_rentDisplaySlot(slot3, account1, address(0x789), 789);
        
        // Check user rentals
        (uint256[] memory slotIds, DisplayRental[] memory rentals) = diamond.getUserRentals(account1);
        
        assertEq(slotIds.length, 3, "User should have 3 rented slots");
        
        // Verify the user has all three slots
        bool hasSlot1 = false;
        bool hasSlot2 = false;
        bool hasSlot3 = false;
        
        for (uint256 i = 0; i < slotIds.length; i++) {
            if (slotIds[i] == slotId) {
                hasSlot1 = true;
                assertEq(rentals[i].tokenId, testTokenId, "Incorrect token ID for slot 1");
            } else if (slotIds[i] == slot2) {
                hasSlot2 = true;
                assertEq(rentals[i].tokenId, 456, "Incorrect token ID for slot 2");
            } else if (slotIds[i] == slot3) {
                hasSlot3 = true;
                assertEq(rentals[i].tokenId, 789, "Incorrect token ID for slot 3");
            }
        }
        
        assertTrue(hasSlot1 && hasSlot2 && hasSlot3, "User should have all three slots");
    }
    
    function test_insufficientAllowance() public {
        // Give account1 QUACK tokens but don't approve
        quackToken.mint(account1, 1000);
        
        // Try to rent without approving
        vm.startPrank(account1);
        vm.expectRevert("ERC20: insufficient allowance");
        diamond.rentDisplaySlot(slotId, testContractAddress, testTokenId);
        vm.stopPrank();
    }
}