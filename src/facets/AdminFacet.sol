// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
// import {Cycle} from "../shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../shared/Structs.sol";
import {ItemType} from "../shared/Structs_Items.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {LibItems} from "../libs/LibItems.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC1155} from "../libs/LibERC1155.sol";
// import {LibString} from "../libs/LibString.sol";

/**
 * @title AdminFacet
 * @dev Facet of the Diamond contract handling administrative functions such as managing cycles and collaterals.
 * Inherits AccessControl to restrict access to admin-only functions.
 */
contract AdminFacet is AccessControl {
    /**
     * @dev Emitted when a new cycle is created.
     * @param _cycleId The unique identifier of the newly created cycle.
     * @param _cycleMaxSize The maximum number of portals allowed in the cycle.
     * @param _eggsPrice The base price of portals in the cycle, denominated in $QUACK.
     * @param _bodyColorItemId The item ID representing the body color applied to NFTs in the cycle.
     */
    event CreateCycle(uint256 indexed _cycleId, uint256 _cycleMaxSize, uint256 _eggsPrice, uint256 _bodyColorItemId);
    /**
     * @dev Emitted when a new collateral type is added to a cycle.
     * @param _collateralType The details of the collateral type added.
     */
    event AddCollateralType(CollateralTypeDTO _collateralType);
    /**
     * @dev Emitted when collateral modifiers are updated.
     * @param _oldModifiers The previous set of modifiers.
     * @param _newModifiers The new set of modifiers applied.
     */
    event UpdateCollateralModifiers(int16[] _oldModifiers, int16[] _newModifiers);
    /**
     * @dev Emitted when a game manager is set.
     * @param _gameManager The address of the game manager.
     * @param _allowed The boolean value indicating whether the game manager is allowed.
     */
    event GameManagerSet(address indexed _gameManager, bool _allowed);
    /**
     * @dev Emitted when the VRF parameters are changed.
     * @param _callbackGasLimit The gas limit for the VRF callback function.
     * @param _requestConfirmations The number of block confirmations the VRF request will wait before responding.
     * @param _numWords The number of random words to be returned by the VRF.
     */
    event VrfParametersChanged(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords);
    /**
     * @dev Emitted when a new item type is added.
     * @param _itemType The details of the item type added.
     */
    event AddItemType(ItemType _itemType);
    /**
     * @dev Emitted when the max quantity of an item is updated.
     * @param _itemIds An array of item IDs whose max quantities are updated.
     * @param _maxQuantities An array of new max quantities corresponding to each item in _itemIds.
     */
    event UpdateItemTypeMaxQuantity(uint256[] _itemIds, uint256[] _maxQuantities);
    /**
     * @dev Emitted when the price of an item is updated.
     * @param _itemId The ID of the item whose price is updated.
     * @param _newPrice The new price of the item.
     */
    event UpdateItemPrice(uint256 _itemId, uint256 _newPrice);
    /**
     * @dev Emitted when an item type is updated.
     * @param _itemId The ID of the item whose type is updated.
     * @param _itemType The new type of the item.
     */
    event UpdateItemType(uint256 _itemId, ItemType _itemType);

    /**
     * @notice Sets the allowed status for a game manager.
     * @dev Only callable by an admin.
     * @param _gameManager The address of the game manager to set the allowed status for.
     * @param _allowed The boolean value indicating whether the game manager is allowed.
     */
    function setGameManager(address _gameManager, bool _allowed) external isAdmin {
        LibAppStorage.diamondStorage().allowedGameManager[_gameManager] = _allowed;
        emit GameManagerSet(_gameManager, _allowed);
    }

    /**
     * @notice Updates the parameters for Chainlink VRF (Verifiable Random Function) requests.
     * @dev Only callable by an admin. Updates the callback gas limit, number of request confirmations, and number of random words.
     * @param _callbackGasLimit The gas limit for the VRF callback function.
     * @param _requestConfirmations The number of block confirmations the VRF request will wait before responding.
     * @param _numWords The number of random words to be returned by the VRF.
     */
    function changeVrfParameters(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords)
        external
        isAdmin
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vrfCallbackGasLimit = _callbackGasLimit;
        s.vrfRequestConfirmations = _requestConfirmations;
        s.vrfNumWords = _numWords;
        emit VrfParametersChanged(_callbackGasLimit, _requestConfirmations, _numWords);
    }

    /**
     * @notice Creates a new cycle within the protocol.
     * @dev Only callable by an admin. Ensures the previous cycle is fully occupied before creating a new one.
     * @param _cycleMaxSize The maximum number of eggs allowed in the new cycle.
     * @param _eggsPrice The base price of eggs in the new cycle, denominated in $QUACK.
     * @param _bodyColorItemId The item ID representing the body color applied to NFTs in the new cycle.
     * @return cycleId_ The unique identifier of the newly created cycle.
     *
     * @custom:dev This function initializes a new cycle by incrementing the currentCycleId,
     * setting the cycle's maximum size, eggs price, and body color item ID.
     * It also emits a CreateCycle event upon successful creation.
     */
    function createCycle(uint24 _cycleMaxSize, uint256 _eggsPrice, uint256 _bodyColorItemId)
        external
        isAdmin
        returns (uint256 cycleId_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentCycleId = s.currentCycleId;
        require(
            s.cycles[currentCycleId].totalCount == s.cycles[currentCycleId].cycleMaxSize,
            "AdminFacet: Cycle must be full before creating new"
        );
        cycleId_ = currentCycleId + 1;
        s.currentCycleId = uint16(cycleId_);
        s.cycles[cycleId_].cycleMaxSize = _cycleMaxSize;
        s.cycles[cycleId_].eggsPrice = _eggsPrice;
        // TODO: wip items logic
        s.cycles[cycleId_].bodyColorItemId = _bodyColorItemId;
        emit CreateCycle(cycleId_, _cycleMaxSize, _eggsPrice, _bodyColorItemId);
    }

    /**
     * @notice Adds new collateral types to a specified cycle.
     * @dev Only callable by an admin. If a collateral type already exists, its modifiers will be overwritten.
     * @param _cycleId The identifier of the cycle to which the collateral types will be added.
     * @param _collateralTypes An array of CollateralTypeDTO structs containing details about each collateral type.
     *
     * @custom:dev This function updates the collateralTypeInfo mapping with new or existing collateral types,
     * handles the global collateralTypes array to ensure uniqueness, and updates the cycleCollateralTypes
     * for the specified cycle. Emits an AddCollateralType event for each new collateral type added.
     */
    function addCollateralTypes(uint256 _cycleId, CollateralTypeDTO[] calldata _collateralTypes) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < _collateralTypes.length; i++) {
            address newCollateralTypeAddress = _collateralTypes[i].collateralType;

            // Create or update the collateralTypeInfo directly in storage
            CollateralTypeInfo storage newCollateralTypeInfo = s.collateralTypeInfo[newCollateralTypeAddress];

            // Replace existing modifiers and set new ones
            for (uint16 j; j < _collateralTypes[i].modifiers.length; j++) {
                newCollateralTypeInfo.modifiers[j] = _collateralTypes[i].modifiers[j];
            }

            // Set other properties
            newCollateralTypeInfo.primaryColor = _collateralTypes[i].primaryColor;
            newCollateralTypeInfo.secondaryColor = _collateralTypes[i].secondaryColor;
            newCollateralTypeInfo.delisted = _collateralTypes[i].delisted;

            // Handle global collateralTypes array to ensure uniqueness
            uint256 index = s.collateralTypeIndexes[newCollateralTypeAddress];
            bool collateralExists =
                index > 0 || (s.collateralTypes.length > 0 && s.collateralTypes[0] == newCollateralTypeAddress);

            if (!collateralExists) {
                s.collateralTypes.push(newCollateralTypeAddress);
                s.collateralTypeIndexes[newCollateralTypeAddress] = s.collateralTypes.length;
            }

            // Handle cycleCollateralTypes array
            bool cycleCollateralExists = false;
            for (uint256 cycleIndex = 0; cycleIndex < s.cycleCollateralTypes[_cycleId].length; cycleIndex++) {
                address existingCycleCollateral = s.cycleCollateralTypes[_cycleId][cycleIndex];

                if (existingCycleCollateral == newCollateralTypeAddress) {
                    cycleCollateralExists = true;
                    break;
                }
            }

            if (!cycleCollateralExists) {
                s.cycleCollateralTypes[_cycleId].push(newCollateralTypeAddress);
                emit AddCollateralType(_collateralTypes[i]);
            }
        }
    }

    // /**
    //  * @notice Allows the admin to update the collateral modifiers of an existing collateral type.
    //  * @dev Only callable by an admin. This function updates the modifiers array for the specified collateral type.
    //  *      Currently commented out pending the rework of the enumerable map structure.
    //  * @param _collateralType The address of the existing collateral to update.
    //  * @param _modifiers An array containing the new numeric traits modifiers to be applied to the collateral.
    //  *
    //  * @custom:dev This function emits an `UpdateCollateralModifiers` event before updating the modifiers.
    //  * It ensures that the modifiers array is properly updated in the storage mapping.
    //  */
    // function updateCollateralModifiers(address _collateralType, int16[NUMERIC_TRAITS_NUM] calldata _modifiers)
    //     external
    //     isAdmin
    // {
    //     emit UpdateCollateralModifiers(s.collateralTypeInfo[_collateralType].modifiers, _modifiers);
    //     s.collateralTypeInfo[_collateralType].modifiers = _modifiers;
    // }

    ///@notice Allow an admin to add item types
    ///@param _itemTypes An array of structs where each struct contains details about each item to be added
    function addItemTypes(ItemType[] memory _itemTypes) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 itemTypesLength = s.itemTypes.length;
        for (uint256 i; i < _itemTypes.length; i++) {
            uint256 itemId = itemTypesLength++;
            s.itemTypes.push(_itemTypes[i]);
            emit AddItemType(_itemTypes[i]);
            // TODO: wip event
            // IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(LibMeta.msgSender(), address(0), address(0), itemId, 0);
        }
    }

    /**
     * @notice Set the base url for all items types
     *     @param _value The new base url
     */
    function setBaseURI(string memory _value) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.itemsBaseUri = _value;
        for (uint256 i; i < s.itemTypes.length; i++) {
            // TODO: wip event
            // //delegate event to wearableDiamond
            // IEventHandlerFacet(s.wearableDiamond).emitUriEvent(LibStrings.strWithUint(_value, i), i);
        }
    }

    ///@notice Allow an admin to increase the max quantity of an item
    ///@dev Will throw if the new maxquantity is less than the existing quantity
    ///@param _itemIds An array containing the identifiers of items whose quantites are to be increased
    ///@param _maxQuantities An array containing the new max quantity of each item
    function updateItemTypeMaxQuantity(uint256[] calldata _itemIds, uint256[] calldata _maxQuantities)
        external
        isAdmin
    {
        require(
            _itemIds.length == _maxQuantities.length,
            "AdminFacet: _itemIds length not the same as _newQuantities length"
        );
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 maxQuantity = _maxQuantities[i];
            require(
                maxQuantity >= s.itemTypes[itemId].totalQuantity,
                "AdminFacet: new maxQuantity must be greater than actual quantity"
            );
            s.itemTypes[itemId].maxQuantity = maxQuantity;
        }
        emit UpdateItemTypeMaxQuantity(_itemIds, _maxQuantities);
    }

    // TODO : rework
    // ///@notice Allow an item manager to set the trait and rarity modifiers of an item/wearable
    // ///@dev Only valid for existing wearables
    // ///@param _wearableId The identifier of the wearable to set
    // ///@param _traitModifiers An array containing the new trait modifiers to be applied to a wearable with identifier `_wearableId`
    // ///@param _rarityScoreModifier The new rarityScore modifier of a wearable with identifier `_wearableId`
    // function setItemTraitModifiersAndRarityModifier(
    //     uint256 _wearableId,
    //     int8[6] calldata _traitModifiers,
    //     uint8 _rarityScoreModifier
    // ) external isAdmin {
    //     require(_wearableId < s.itemTypes.length, "Error");
    //     s.itemTypes[_wearableId].traitModifiers = _traitModifiers;
    //     s.itemTypes[_wearableId].rarityScoreModifier = _rarityScoreModifier;
    //     emit ItemModifiersSet(_wearableId, _traitModifiers, _rarityScoreModifier);
    // }

    ///@notice Allow an item manager to set the price of multiple items in GHST
    ///@dev Only valid for existing items that can be purchased with GHST
    ///@param _itemIds The items whose price is to be changed
    ///@param _newPrices The new prices of the items
    function batchUpdateItemsPrice(uint256[] calldata _itemIds, uint256[] calldata _newPrices) public isAdmin {
        require(_itemIds.length == _newPrices.length, "AdminFacet: Items must be the same length as prices");
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            ItemType storage item = s.itemTypes[itemId];
            item.quackPrice = _newPrices[i];
            emit UpdateItemPrice(itemId, _newPrices[i]);
        }
    }

    ///@notice Allow a game manager to mint new ERC1155 items
    ///@dev Will throw if a particular item current supply has reached its maximum supply
    ///@param _to The address to mint the items to
    ///@param _itemIds An array containing the identifiers of the items to mint
    ///@param _quantities An array containing the number of items to mint
    function mintItems(address _to, uint256[] calldata _itemIds, uint256[] calldata _quantities)
        external
        isGameManager
    {
        require(_itemIds.length == _quantities.length, "AdminFacet: Ids and quantities length must match");
        AppStorage storage s = LibAppStorage.diamondStorage();
        address sender = _msgSender();
        uint256 itemTypesLength = s.itemTypes.length;
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];

            require(itemTypesLength > itemId, "AdminFacet: Item type does not exist");

            uint256 quantity = _quantities[i];
            uint256 totalQuantity = s.itemTypes[itemId].totalQuantity + quantity;
            require(
                totalQuantity <= s.itemTypes[itemId].maxQuantity,
                "AdminFacet: Total item type quantity exceeds max quantity"
            );

            LibItems.addToOwner(_to, itemId, quantity);
            s.itemTypes[itemId].totalQuantity = totalQuantity;
        }
        // TODO: wip event
        // IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(sender, address(0), _to, _itemIds, _quantities);
        LibERC1155.onERC1155BatchReceived(sender, address(0), _to, _itemIds, _quantities, "");
    }

    // /**
    //  * @notice Grants experience points (XP) to multiple Ducks.
    //  * @dev Only callable by a game manager. The XP granted to each Duck cannot exceed 1000 at a time.
    //  * @param _duckIds An array of Duck token IDs to which XP will be granted.
    //  * @param _xpValues An array of XP values corresponding to each Duck in _duckIds.
    //  */
    function grantExperience(uint256[] calldata _duckIds, uint256[] calldata _xpValues) external isGameManager {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_duckIds.length == _xpValues.length, "AdminFacet: IDs must match XP array length");
        for (uint256 i; i < _duckIds.length; i++) {
            require(_xpValues[i] <= 1000, "AdminFacet: Cannot grant more than 1000 XP at a time");
            LibDuck.addXP(_duckIds[i], _xpValues[i]);
        }
    }

    // TODO: wip items logic
    function grantItems(uint256[] calldata _duckIds, uint256[] calldata _tokenIds, uint256[] calldata _itemIds)
        external
        isGameManager
    {}
}
