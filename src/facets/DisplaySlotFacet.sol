// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {DisplaySlot, DisplayRental} from "../shared/Structs_DisplaySlot.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/**
 * @title DisplaySlotFacet
 * @dev Facet of the Diamond contract handling display slot creation, rental, and management
 * Inherits AccessControl to restrict access to admin-only functions.
 */
contract DisplaySlotFacet is AccessControl {
    /**
     * @dev Emitted when a new display slot is created.
     * @param _slotId The unique identifier of the newly created slot.
     * @param _name The name of the slot.
     * @param _description The description of the slot.
     * @param _pricePerWeek The price to rent the slot for one week.
     */
    event SlotCreated(uint256 indexed _slotId, string _name, string _description, uint256 _pricePerWeek);
    
    /**
     * @dev Emitted when a display slot is updated.
     * @param _slotId The unique identifier of the updated slot.
     * @param _name The updated name of the slot.
     * @param _description The updated description of the slot.
     * @param _pricePerWeek The updated price to rent the slot for one week.
     * @param _isActive Whether the slot is active or not.
     */
    event SlotUpdated(uint256 indexed _slotId, string _name, string _description, uint256 _pricePerWeek, bool _isActive);
    
    /**
     * @dev Emitted when a slot is rented.
     * @param _slotId The unique identifier of the rented slot.
     * @param _renter The address of the renter.
     * @param _contractAddress The contract address of the NFT to display.
     * @param _tokenId The token ID of the NFT to display.
     * @param _startTime The start time of the rental.
     * @param _endTime The end time of the rental.
     */
    event SlotRented(
        uint256 indexed _slotId, 
        address indexed _renter, 
        address _contractAddress, 
        uint256 _tokenId, 
        uint256 _startTime, 
        uint256 _endTime
    );
    
    /**
     * @dev Emitted when a rental is canceled.
     * @param _slotId The unique identifier of the slot whose rental is canceled.
     * @param _renter The address of the renter.
     */
    event RentalCanceled(uint256 indexed _slotId, address indexed _renter);
    
    /**
     * @notice Creates a new display slot.
     * @dev Only callable by an admin.
     * @param _name The name of the slot.
     * @param _description The description of the slot.
     * @param _pricePerWeek The price to rent the slot for one week.
     * @return slotId_ The ID of the newly created slot.
     */
    function createDisplaySlot(
        string calldata _name,
        string calldata _description,
        uint256 _pricePerWeek
    ) external isAdmin returns (uint256 slotId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        slotId_ = s.displaySlotCounter++;
        s.displaySlots[slotId_] = DisplaySlot({
            slotId: slotId_,
            name: _name,
            description: _description,
            pricePerWeek: _pricePerWeek,
            isActive: true
        });
        
        s.displaySlotIds.push(slotId_);
        
        emit SlotCreated(slotId_, _name, _description, _pricePerWeek);
    }
    
    /**
     * @notice Updates an existing display slot.
     * @dev Only callable by an admin.
     * @param _slotId The ID of the slot to update.
     * @param _name The updated name of the slot.
     * @param _description The updated description of the slot.
     * @param _pricePerWeek The updated price to rent the slot for one week.
     * @param _isActive Whether the slot should be active or not.
     */
    function updateDisplaySlot(
        uint256 _slotId,
        string calldata _name,
        string calldata _description,
        uint256 _pricePerWeek,
        bool _isActive
    ) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(_slotId < s.displaySlotCounter, "DisplaySlotFacet: Invalid slot ID");
        
        DisplaySlot storage slot = s.displaySlots[_slotId];
        slot.name = _name;
        slot.description = _description;
        slot.pricePerWeek = _pricePerWeek;
        slot.isActive = _isActive;
        
        emit SlotUpdated(_slotId, _name, _description, _pricePerWeek, _isActive);
    }
    
    /**
     * @notice Rents a display slot for one week.
     * @dev Transfers QUACK tokens from the caller to the treasury.
     * @param _slotId The ID of the slot to rent.
     * @param _contractAddress The contract address of the NFT to display.
     * @param _tokenId The token ID of the NFT to display.
     */
    function rentDisplaySlot(
        uint256 _slotId,
        address _contractAddress,
        uint256 _tokenId
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(_slotId < s.displaySlotCounter, "DisplaySlotFacet: Invalid slot ID");
        DisplaySlot storage slot = s.displaySlots[_slotId];
        require(slot.isActive, "DisplaySlotFacet: Slot is not active");
        
        DisplayRental storage rental = s.slotRentals[_slotId];
        require(
            rental.endTime < block.timestamp || !rental.isActive, 
            "DisplaySlotFacet: Slot is already rented"
        );
        
        address sender = _msgSender();
        uint256 price = slot.pricePerWeek;
        
        // Transfer QUACK tokens from sender to treasury
        require(
            IERC20(s.quackTokenAddress).transferFrom(sender, s.treasuryAddress, price),
            "DisplaySlotFacet: QUACK transfer failed"
        );
        
        // Set the rental details
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1 weeks;
        
        rental.renter = sender;
        rental.contractAddress = _contractAddress;
        rental.tokenId = _tokenId;
        rental.startTime = startTime;
        rental.endTime = endTime;
        rental.isActive = true;
        
        // Add to user's rented slots
        uint256[] storage userSlots = s.userRentedSlots[sender];
        uint256 index = userSlots.length;
        userSlots.push(_slotId);
        s.userRentedSlotIndexes[sender][_slotId] = index + 1; // 1-indexed
        
        emit SlotRented(_slotId, sender, _contractAddress, _tokenId, startTime, endTime);
    }
    
    /**
     * @notice Cancels an ongoing rental for a display slot.
     * @dev Only callable by an admin.
     * @param _slotId The ID of the slot whose rental to cancel.
     */
    function cancelRental(uint256 _slotId) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(_slotId < s.displaySlotCounter, "DisplaySlotFacet: Invalid slot ID");
        
        DisplayRental storage rental = s.slotRentals[_slotId];
        require(rental.isActive, "DisplaySlotFacet: No active rental for this slot");
        
        address renter = rental.renter;
        
        // Remove from user's rented slots
        uint256 index = s.userRentedSlotIndexes[renter][_slotId];
        if (index > 0) {
            // 1-indexed, so index 0 means not found
            index--; // Convert to 0-indexed
            uint256[] storage userSlots = s.userRentedSlots[renter];
            uint256 lastIndex = userSlots.length - 1;
            
            if (index != lastIndex) {
                uint256 lastSlotId = userSlots[lastIndex];
                userSlots[index] = lastSlotId;
                s.userRentedSlotIndexes[renter][lastSlotId] = index + 1; // 1-indexed
            }
            
            userSlots.pop();
            s.userRentedSlotIndexes[renter][_slotId] = 0;
        }
        
        rental.isActive = false;
        
        emit RentalCanceled(_slotId, renter);
    }
    
    /**
     * @notice Gets all available display slots.
     * @return slotIds Array of slot IDs.
     * @return slots Array of slot details.
     */
    function getAvailableSlots() external view returns (
        uint256[] memory slotIds,
        DisplaySlot[] memory slots
    ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256 availableCount = 0;
        uint256 totalSlots = s.displaySlotIds.length;
        
        // First, count available slots
        for (uint256 i = 0; i < totalSlots; i++) {
            uint256 slotId = s.displaySlotIds[i];
            DisplaySlot storage slot = s.displaySlots[slotId];
            
            if (slot.isActive) {
                DisplayRental storage rental = s.slotRentals[slotId];
                if (!rental.isActive || rental.endTime < block.timestamp) {
                    availableCount++;
                }
            }
        }
        
        // Initialize return arrays
        slotIds = new uint256[](availableCount);
        slots = new DisplaySlot[](availableCount);
        
        // Fill return arrays
        uint256 index = 0;
        for (uint256 i = 0; i < totalSlots; i++) {
            uint256 slotId = s.displaySlotIds[i];
            DisplaySlot storage slot = s.displaySlots[slotId];
            
            if (slot.isActive) {
                DisplayRental storage rental = s.slotRentals[slotId];
                if (!rental.isActive || rental.endTime < block.timestamp) {
                    slotIds[index] = slotId;
                    slots[index] = slot;
                    index++;
                }
            }
        }
    }
    
    /**
     * @notice Gets all rentals for a specific user.
     * @param _user The address of the user.
     * @return slotIds Array of slot IDs rented by the user.
     * @return rentals Array of rental details.
     */
    function getUserRentals(address _user) external view returns (
        uint256[] memory slotIds,
        DisplayRental[] memory rentals
    ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256[] storage userSlots = s.userRentedSlots[_user];
        uint256 activeCount = 0;
        
        // First, count active rentals
        for (uint256 i = 0; i < userSlots.length; i++) {
            uint256 slotId = userSlots[i];
            DisplayRental storage rental = s.slotRentals[slotId];
            
            if (rental.isActive) {
                activeCount++;
            }
        }
        
        // Initialize return arrays
        slotIds = new uint256[](activeCount);
        rentals = new DisplayRental[](activeCount);
        
        // Fill return arrays
        uint256 index = 0;
        for (uint256 i = 0; i < userSlots.length; i++) {
            uint256 slotId = userSlots[i];
            DisplayRental storage rental = s.slotRentals[slotId];
            
            if (rental.isActive) {
                slotIds[index] = slotId;
                rentals[index] = rental;
                index++;
            }
        }
    }
    
    /**
     * @notice Gets all current active displays.
     * @return slotIds Array of slot IDs with active displays.
     * @return contractAddresses Array of contract addresses for the NFTs being displayed.
     * @return tokenIds Array of token IDs for the NFTs being displayed.
     * @return renters Array of addresses of the renters.
     * @return endTimes Array of end times for the rentals.
     */
    function getCurrentDisplays() external view returns (
        uint256[] memory slotIds,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        address[] memory renters,
        uint256[] memory endTimes
    ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256 totalSlots = s.displaySlotIds.length;
        uint256 activeCount = 0;
        
        // First, count active displays
        for (uint256 i = 0; i < totalSlots; i++) {
            uint256 slotId = s.displaySlotIds[i];
            DisplayRental storage rental = s.slotRentals[slotId];
            
            if (rental.isActive && rental.endTime >= block.timestamp) {
                activeCount++;
            }
        }
        
        // Initialize return arrays
        slotIds = new uint256[](activeCount);
        contractAddresses = new address[](activeCount);
        tokenIds = new uint256[](activeCount);
        renters = new address[](activeCount);
        endTimes = new uint256[](activeCount);
        
        // Fill return arrays
        uint256 index = 0;
        for (uint256 i = 0; i < totalSlots; i++) {
            uint256 slotId = s.displaySlotIds[i];
            DisplayRental storage rental = s.slotRentals[slotId];
            
            if (rental.isActive && rental.endTime >= block.timestamp) {
                slotIds[index] = slotId;
                contractAddresses[index] = rental.contractAddress;
                tokenIds[index] = rental.tokenId;
                renters[index] = rental.renter;
                endTimes[index] = rental.endTime;
                index++;
            }
        }
    }
    
    /**
     * @notice Gets details for a specific display slot.
     * @param _slotId The ID of the slot.
     * @return slot The slot details.
     * @return rental The rental details, if active.
     * @return isRented Whether the slot is currently rented.
     */
    function getSlotDetails(uint256 _slotId) external view returns (
        DisplaySlot memory slot,
        DisplayRental memory rental,
        bool isRented
    ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(_slotId < s.displaySlotCounter, "DisplaySlotFacet: Invalid slot ID");
        
        slot = s.displaySlots[_slotId];
        rental = s.slotRentals[_slotId];
        
        isRented = rental.isActive && rental.endTime >= block.timestamp;
    }
} 