// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
// import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC20} from "../libs/LibERC20.sol";
import {LibString} from "../libs/LibString.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {LibItems} from "../libs/LibItems.sol";
import {ItemType, ItemTypeDTO, ItemIdDTO} from "../shared/Structs_Items.sol";

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
    ///@param _tokenId Identifier of the NFT to query
    ///@return wearableIds_ An array containing the Identifiers of the wearable items currently equipped for the NFT
    function equippedWearables(uint256 _tokenId) external view returns (uint256[] memory wearableIds_) {
        wearableIds_ = LibAppStorage.diamondStorage().ducks[_tokenId].equippedWearables;
    }

    ///@notice Query the item type of a particular item
    ///@param _itemId Item to query
    ///@return itemType_ A struct containing details about the item type of an item with identifier `_itemId`
    function getItemType(uint256 _itemId) public view returns (ItemType memory itemType_) {
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

    // ///@notice Allow the owner of a claimed aavegotchi to equip/unequip wearables to his aavegotchi
    // ///@dev Only valid for claimed ducks
    // ///@dev A zero value will unequip that slot and a non-zero value will equip that slot with the wearable whose identifier is provided
    // ///@dev A wearable cannot be equipped in the wrong slot
    // ///@param _tokenId The identifier of the aavegotchi to make changes to
    // ///@param _wearablesToEquip An array containing the identifiers of the wearables to equip
    // function equipWearables(
    //     uint256 _tokenId,
    //     uint16[EQUIPPED_WEARABLE_SLOTS] calldata _wearablesToEquip
    // ) isDuckOwner(_tokenId) onlyUnlocked(_tokenId) external {
    //     uint256[EQUIPPED_WEARABLE_SLOTS] memory _depositIds;
    //     _equipWearables(_tokenId, _wearablesToEquip, _depositIds);
    // }

    // function _equipWearables(
    //     uint256 _tokenId,
    //     uint16[EQUIPPED_WEARABLE_SLOTS] calldata _wearablesToEquip,
    //     uint256[EQUIPPED_WEARABLE_SLOTS] memory _depositIdsToEquip
    // ) internal {
    //     DuckInfo storage duck = s.ducks[_tokenId];

    //     // Get the GotchiEquippedDepositsInfo struct
    //     GotchiEquippedDepositsInfo storage duckDepositInfo = s.gotchiEquippedDepositsInfo[_tokenId];

    //     // Only valid for claimed ducks
    //     require(duck.status == DuckStatusType.DUCK, "LibDuck: Only valid for Hatched Ducks");
    //     emit LibItemsEvents.EquipWearables(_tokenId, duck.equippedWearables, _wearablesToEquip);
    //     emit LibItemsEvents.EquipDelegatedWearables(_tokenId, duckDepositInfo.equippedDepositIds, _depositIdsToEquip);

    //     address sender = LibMeta.msgSender();

    //     for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
    //         uint256 toEquipId = _wearablesToEquip[slot];
    //         uint256 existingEquippedWearableId = duck.equippedWearables[slot];

    //         uint256 depositIdToEquip = _depositIdsToEquip[slot];
    //         uint256 existingEquippedDepositId = duckDepositInfo.equippedDepositIds[slot];

    //         // Users might replace Wearables they own with delegated Werables.
    //         // For this reason, we only skip this slot if both the Wearable tokenId & depositId match
    //         if (toEquipId == existingEquippedWearableId && existingEquippedDepositId == depositIdToEquip) {
    //             continue;
    //         }

    //         // To prevent the function `removeFromParent` to revert, it's necessary first to unequip this Wearable (delete from storage slot)
    //         // This is an edge case introduced by delegated Wearables, since users can now equip and unequip Wearables of same tokenId (but different depositId)
    //         // This is also necessary regardless of whether the item is transferrable or not. Non-transferrable items can still be equipped/unequipped (they just aren't transferred back to the user's wallet)
    //         delete duck.equippedWearables[slot];

    //         //Handle unequipping wearable case
    //         if (existingEquippedWearableId != 0 && s.itemTypes[existingEquippedWearableId].canBeTransferred) {
    //             //If no deposits have been made to this gotchi for this slot, it's a normal wearable unequipping case.
    //             if (duckDepositInfo.equippedDepositIds[slot] == 0) {
    //                 // remove wearable from Duck and transfer item to owner
    //                 LibItems.removeFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
    //                 LibItems.addToOwner(sender, existingEquippedWearableId, 1);
    //                 IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(sender, address(this), sender, existingEquippedWearableId, 1);
    //                 emit LibERC1155.TransferFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
    //             } else {
    //                 // remove wearable from Duck
    //                 LibDelegatedWearables.removeDelegatedWearableFromGotchi(slot, _tokenId, existingEquippedWearableId);
    //             }
    //         }

    //         //Handle equipping wearables case
    //         if (toEquipId != 0) {
    //             ItemType storage itemType = s.itemTypes[toEquipId];
    //             require(duck.level >= itemType.minLevel, "ItemsFacet: Duck level lower than minLevel");
    //             require(itemType.category == LibItems.ITEM_CATEGORY_WEARABLE, "ItemsFacet: Only wearables can be equippped");
    //             require(itemType.slotPositions[slot] == true, "ItemsFacet: Wearable can't be equipped in slot");
    //             {
    //                 bool canBeEquipped;
    //                 uint8[] memory allowedCollaterals = itemType.allowedCollaterals;
    //                 if (allowedCollaterals.length > 0) {
    //                     uint256 collateralIndex = s.collateralTypeIndexes[duck.collateralType];

    //                     for (uint256 i; i < allowedCollaterals.length; i++) {
    //                         if (collateralIndex == allowedCollaterals[i]) {
    //                             canBeEquipped = true;
    //                             break;
    //                         }
    //                     }
    //                     require(canBeEquipped, "ItemsFacet: Wearable can't be used for this collateral");
    //                 }
    //             }

    //             // Equips new Wearable
    //             // Wearable is equipped one by one, even if hands has the same id (but different depositId)
    //             duck.equippedWearables[slot] = uint16(toEquipId);
    //             duckDepositInfo.equippedDepositIds[slot] = depositIdToEquip;

    //             // If no deposits have been made to this gotchi for this slot, it's a normal wearable equipping case.
    //             if (depositIdToEquip == 0) {
    //                 // We need to check if wearable is already in the inventory, if it is, we don't transfer it from the owner
    //                 uint256 maxBalance = slot == LibItems.WEARABLE_SLOT_HAND_LEFT || slot == LibItems.WEARABLE_SLOT_HAND_RIGHT ? 2 : 1;
    //                 if(s.nftItemBalances[address(this)][_tokenId][toEquipId] >= maxBalance) continue;
    //                 require(s.ownerItemBalances[sender][toEquipId] >= 1, "ItemsFacet: Wearable isn't in inventory");

    //                 //Transfer to Duck
    //                 LibItems.removeFromOwner(sender, toEquipId, 1);
    //                 LibItems.addToParent(address(this), _tokenId, toEquipId, 1);
    //                 emit LibERC1155.TransferToParent(address(this), _tokenId, toEquipId, 1);
    //                 IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(sender, sender, address(this), toEquipId, 1);
    //                 LibERC1155Marketplace.updateERC1155Listing(address(this), toEquipId, sender);
    //             } else {
    //                 // add wearable to Duck and add delegation
    //                 LibDelegatedWearables.addDelegatedWearableToGotchi(depositIdToEquip, _tokenId, toEquipId);
    //             }
    //         }
    //     }
    //     LibDuck.interact(_tokenId);

    // }

    // ///@notice Allow the owner of an NFT to use multiple consumable items for his duck
    // ///@dev Only valid for claimed ducks
    // ///@dev Consumables can be used to boost kinship/XP of an duck
    // ///@param _tokenId Identtifier of duck to use the consumables on
    // ///@param _itemIds An array containing the identifiers of the items/consumables to use
    // ///@param _quantities An array containing the quantity of each consumable to use
    // function useConsumables(
    //     uint256 _tokenId,
    //     uint256[] calldata _itemIds,
    //     uint256[] calldata _quantities
    // ) external onlyUnlocked(_tokenId) isDuckOwner(_tokenId) {
    //     require(_itemIds.length == _quantities.length, "ItemsFacet: _itemIds length != _quantities length");
    //     require(s.ducks[_tokenId].status == DuckStatusType.DUCK, "LibDuck: Only valid for Hatched Duck");

    //     address sender = LibMeta.msgSender();
    //     for (uint256 i; i < _itemIds.length; i++) {
    //         uint256 itemId = _itemIds[i];
    //         uint256 quantity = _quantities[i];
    //         ItemType memory itemType = s.itemTypes[itemId];
    //         require(itemType.category == LibItems.ITEM_CATEGORY_CONSUMABLE, "ItemsFacet: Item isn't consumable");

    //         LibItems.removeFromOwner(sender, itemId, quantity);

    //         //Increase kinship
    //         if (itemType.kinshipBonus > 0) {
    //             uint256 kinship = (uint256(int256(itemType.kinshipBonus)) * quantity) + s.ducks[_tokenId].interactionCount;
    //             s.ducks[_tokenId].interactionCount = kinship;
    //         } else if (itemType.kinshipBonus < 0) {
    //             uint256 kinshipBonus = LibAppStorage.abs(itemType.kinshipBonus) * quantity;
    //             if (s.ducks[_tokenId].interactionCount > kinshipBonus) {
    //                 s.ducks[_tokenId].interactionCount -= kinshipBonus;
    //             } else {
    //                 s.ducks[_tokenId].interactionCount = 0;
    //             }
    //         }

    //         {
    //             // prevent stack too deep error with braces here
    //             //Boost traits and reset clock
    //             bool boost = false;
    //             for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
    //                 if (itemType.traitModifiers[j] != 0) {
    //                     boost = true;
    //                     break;
    //                 }
    //             }
    //             if (boost) {
    //                 s.ducks[_tokenId].lastTemporaryBoost = uint40(block.timestamp);
    //                 s.ducks[_tokenId].temporaryTraitBoosts = itemType.traitModifiers;
    //             }
    //         }

    //         //Increase experience
    //         if (itemType.experienceBonus > 0) {
    //             uint256 experience = (uint256(itemType.experienceBonus) * quantity) + s.ducks[_tokenId].experience;
    //             s.ducks[_tokenId].experience = experience;
    //         }

    //         itemType.totalQuantity -= quantity;
    //         LibDuck.interact(_tokenId);
    //         LibERC1155Marketplace.updateERC1155Listing(address(this), itemId, sender);
    //     }
    //     emit UseConsumables(_tokenId, _itemIds, _quantities);
    // 		// TODO: wip event
    //     // IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(sender, sender, address(0), _itemIds, _quantities);
    // }
}
