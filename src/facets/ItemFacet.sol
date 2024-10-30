// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
// import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC20} from "../libs/LibERC20.sol";
import {LibERC1155} from "../libs/LibERC1155.sol";
import {LibString} from "../libs/LibString.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {LibItems} from "../libs/LibItems.sol";
import {ItemType, ItemTypeDTO, ItemIdDTO} from "../shared/Structs_Items.sol";
import {DuckInfo, DuckWearableSlot, DuckStatusType} from "../shared/Structs_Ducks.sol";
import {IERC20} from "../interfaces/IERC20.sol";
contract ItemFacet is AccessControl {
    event UseConsumables(uint256 indexed _tokenId, uint256[] _itemIds, uint256[] _quantities);

    ///@notice Returns balance for each item that exists for an account
    ///@param _account Address of the account to query
    ///@return bals_ An array of structs,each struct containing details about each item owned
    function itemBalances(address _account) external view returns (ItemIdDTO[] memory bals_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.ownerItems[_account].length;
        bals_ = new ItemIdDTO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.ownerItems[_account][i];
            bals_[i].balance = s.ownerItemBalances[_account][itemId];
            bals_[i].itemId = itemId;
        }
    }

    ///@notice Returns balance for each item(and their types) that exists for an account
    ///@param _owner Address of the account to query
    ///@return output_ An array of structs containing details about each item owned(including the item types)
    function itemBalancesWithTypes(address _owner) external view returns (ItemTypeDTO[] memory output_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.ownerItems[_owner].length;
        output_ = new ItemTypeDTO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.ownerItems[_owner][i];
            output_[i].balance = s.ownerItemBalances[_owner][itemId];
            output_[i].itemId = itemId;
            output_[i].itemType = s.itemTypes[itemId];
        }
    }

    /**
     * @notice Get the balance of an account's tokens.
     *     @param _owner  The address of the token holder
     *     @param _id     ID of the token
     *     @return bal_    The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
        bal_ = LibAppStorage.diamondStorage().ownerItemBalances[_owner][_id];
    }

    /// @notice Get the balance of a non-fungible parent token
    /// @param _tokenContract The contract tracking the parent token
    /// @param _tokenId The ID of the parent token
    /// @param _id     ID of the token
    /// @return value The balance of the token
    function balanceOfToken(address _tokenContract, uint256 _tokenId, uint256 _id)
        external
        view
        returns (uint256 value)
    {
        value = LibAppStorage.diamondStorage().nftItemBalances[_tokenContract][_tokenId][_id];
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@dev Only valid for claimed ducks
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return bals_ An array of structs containing details about each item owned
    function itemBalancesOfToken(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (ItemIdDTO[] memory bals_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.nftItems[_tokenContract][_tokenId].length;
        bals_ = new ItemIdDTO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.nftItems[_tokenContract][_tokenId][i];
            bals_[i].itemId = itemId;
            bals_[i].balance = s.nftItemBalances[_tokenContract][_tokenId][itemId];
        }
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@dev Only valid for claimed ducks
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return itemBalancesOfTokenWithTypes_ An array of structs containing details about each item owned(including the types)
    function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (ItemTypeDTO[] memory itemBalancesOfTokenWithTypes_)
    {
        itemBalancesOfTokenWithTypes_ = LibItems.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     *     @param _owners The addresses of the token holders
     *     @param _ids    ID of the tokens
     *     @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory bals)
    {
        require(_owners.length == _ids.length, "ItemsFacet: _owners length not same as _ids length");
        AppStorage storage s = LibAppStorage.diamondStorage();
        bals = new uint256[](_owners.length);
        for (uint256 i; i < _owners.length; i++) {
            uint256 id = _ids[i];
            address owner = _owners[i];
            bals[i] = s.ownerItemBalances[owner][id];
        }
    }

    ///@notice Query the current wearables equipped for an NFT
    ///@dev only valid for claimed ducks
    ///@param _duckId Identifier of the NFT to query
    ///@return wearableIds_ An array containing the Identifiers of the wearable items currently equipped for the NFT
    function equippedWearables(uint64 _duckId) external view returns (uint256[] memory wearableIds_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_duckId];
        uint16 wearbleSlotCount = uint16(type(DuckWearableSlot).max) + 1;
        wearableIds_ = new uint256[](wearbleSlotCount);
        for (uint16 i; i < wearbleSlotCount; i++) {
            wearableIds_[i] = duck.equippedWearables[i];
        }
    }

    ///@notice Query the item type of a particular item
    ///@param _itemId Item to query
    ///@return itemType_ A struct containing details about the item type of an item with identifier `_itemId`
    function getItemType(uint256 _itemId) external view returns (ItemType memory itemType_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_itemId < s.itemTypes.length, "ItemsFacet: Item type doesn't exist");
        itemType_ = s.itemTypes[_itemId];
    }

    ///@notice Query the item type of multiple  items
    ///@param _itemIds An array containing the identifiers of items to query
    ///@return itemTypes_ An array of structs,each struct containing details about the item type of the corresponding item
    function getItemTypes(uint256[] calldata _itemIds) external view returns (ItemType[] memory itemTypes_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (_itemIds.length == 0) {
            itemTypes_ = s.itemTypes;
        } else {
            itemTypes_ = new ItemType[](_itemIds.length);
            for (uint256 i; i < _itemIds.length; i++) {
                itemTypes_[i] = s.itemTypes[_itemIds[i]];
            }
        }
    }

    /**
     * @notice Get the URI for a voucher type
     *     @return URI for token type
     */
    function uri(uint256 _id) external view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_id < s.itemTypes.length, "ItemsFacet: Item _id not found");
        return LibString.strWithUint(s.itemsBaseUri, _id);
    }

    /// WRITE FUNCTIONS --------------------------------------------------

    ///@notice Allow the owner of a claimed duck to equip/unequip wearables to his duck
    ///@dev Only valid for claimed ducks
    ///@dev A zero value will unequip that slot and a non-zero value will equip that slot with the wearable whose identifier is provided
    ///@dev A wearable cannot be equipped in the wrong slot
    ///@param _duckId The identifier of the duck to make changes to
    ///@param _wearablesToEquip An array containing the identifiers of the wearables to equip
    function equipWearables(uint64 _duckId, uint16[] calldata _wearablesToEquip)
        external
        isDuckOwner(_duckId)
        onlyUnlocked(_duckId)
    {
        LibItems._equipWearables(_msgSender(), _duckId, _wearablesToEquip);
    }

    ///@notice Allow the owner of an NFT to use multiple consumable items for his duck
    ///@dev Only valid for claimed ducks
    ///@dev Consumables can be used to boost kinship/XP of an duck
    ///@param _duckId Identtifier of duck to use the consumables on
    ///@param _itemIds An array containing the identifiers of the items/consumables to use
    ///@param _quantities An array containing the quantity of each consumable to use
    function useConsumables(uint64 _duckId, uint256[] calldata _itemIds, uint256[] calldata _quantities)
        external
        isDuckOwner(_duckId)
    {
        require(
            LibAppStorage.diamondStorage().ducks[_duckId].status == DuckStatusType.DUCK,
            "ItemFacet: Only valid for Hatched Duck"
        );
        LibItems._useConsumables(_msgSender(), _duckId, _itemIds, _quantities);
    }

    ///@notice Allow an address to purchase multiple items
    ///@dev Buying an item typically mints it, it will throw if an item has reached its maximum quantity
    ///@param _to Address to send the items once purchased
    ///@param _itemIds The identifiers of the items to be purchased
    ///@param _quantities The quantities of each item to be bought
    function purchaseItemsWithQuack(
        address _to,
        uint256[] calldata _itemIds,
        uint256[] calldata _quantities
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address sender = _msgSender();
        require(_itemIds.length == _quantities.length, "ItemFacet: _itemIds not same length as _quantities");
        uint256 totalPrice;
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 quantity = _quantities[i];
            ItemType storage itemType = s.itemTypes[itemId];
            require(itemType.canPurchaseWithQuack, "ItemFacet: Can't purchase item type with Quack");
            uint256 totalQuantity = itemType.totalQuantity + quantity;
            require(totalQuantity <= itemType.maxQuantity, "ItemFacet: Total item type quantity exceeds max quantity");
            itemType.totalQuantity = totalQuantity;
            totalPrice += quantity * itemType.quackPrice;
            LibItems.addToOwner(_to, itemId, quantity);
        }
        uint256 quackBalance = IERC20(s.quackTokenAddress).balanceOf(sender);
        require(quackBalance >= totalPrice, "ItemFacet: Not enough $QUACK!");
        // TODO emit event
        // emit PurchaseItemsWithQuack(sender, _to, _itemIds, _quantities, totalPrice);
        // IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(sender, address(0), _to, _itemIds, _quantities);
        LibDuck.purchase(sender, totalPrice);
        // LibERC1155.onERC1155BatchReceived(sender, address(0), _to, _itemIds, _quantities, "");
    }   

    ///@notice Allow an address to purchase multiple items after they have been minted
    ///@dev Only one item per transaction can be purchased from the Diamond contract
    ///@param _to Address to send the items once purchased
    ///@param _itemIds The identifiers of the items to be purchased
    ///@param _quantities The quantities of each item to be bought

    function purchaseTransferItemsWithQuack(
        address _to,
        uint256[] calldata _itemIds,
        uint256[] calldata _quantities
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_to != address(0), "ItemFacet: Can't transfer to 0 address");
        require(_itemIds.length == _quantities.length, "ItemFacet: ids not same length as values");
        address sender = _msgSender();
        address from = address(this);
        uint256 totalPrice;
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 quantity = _quantities[i];
            require(quantity == 1, "ItemFacet: Can only purchase 1 of an item per transaction");
            ItemType storage itemType = s.itemTypes[itemId];
            require(itemType.canPurchaseWithQuack, "ItemFacet: Can't purchase item type with QUACK");
            totalPrice += quantity * itemType.quackPrice;
            LibItems.removeFromOwner(from, itemId, quantity);
            LibItems.addToOwner(_to, itemId, quantity);
            // LibERC1155Marketplace.updateERC1155Listing(address(this), itemId, from);
        }
        uint256 quackBalance = IERC20(s.quackTokenAddress).balanceOf(sender);
        require(quackBalance >= totalPrice, "ItemFacet: Not enough $QUACK!");
        // TODO emit event
        // IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(sender, from, _to, _itemIds, _quantities);
        // emit PurchaseTransferItemsWithQuack(sender, _to, _itemIds, _quantities, totalPrice);
        LibDuck.purchase(sender, totalPrice);
        LibERC1155.onERC1155BatchReceived(sender, from, _to, _itemIds, _quantities, "");
    }
}
