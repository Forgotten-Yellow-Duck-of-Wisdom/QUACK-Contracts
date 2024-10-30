// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {ItemType, ItemTypeDTO, ItemTypeCategory} from "../shared/Structs_Items.sol";
import {DuckInfo, DuckStatusType, DuckStatisticsType, DuckWearableSlot} from "../shared/Structs_Ducks.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibDuck} from "./LibDuck.sol";
import {LibERC1155} from "./LibERC1155.sol";
import {LibMaths} from "./LibMaths.sol";

library LibItems {
    event EquipWearables(uint64 _duckId, uint16[] _equippedWearables, uint16[] _wearablesToEquip);
    event UseConsumables(uint64 _duckId, uint256[] _itemIds, uint256[] _quantities);

    function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        internal
        view
        returns (ItemTypeDTO[] memory itemBalancesOfTokenWithTypes_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.nftItems[_tokenContract][_tokenId].length;
        itemBalancesOfTokenWithTypes_ = new ItemTypeDTO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.nftItems[_tokenContract][_tokenId][i];
            uint256 bal = s.nftItemBalances[_tokenContract][_tokenId][itemId];
            itemBalancesOfTokenWithTypes_[i].itemId = itemId;
            itemBalancesOfTokenWithTypes_[i].balance = bal;
            itemBalancesOfTokenWithTypes_[i].itemType = s.itemTypes[itemId];
        }
    }

    function addToParent(address _toContract, uint256 _toTokenId, uint256 _id, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nftItemBalances[_toContract][_toTokenId][_id] += _value;
        if (s.nftItemIndexes[_toContract][_toTokenId][_id] == 0) {
            s.nftItems[_toContract][_toTokenId].push(uint16(_id));
            s.nftItemIndexes[_toContract][_toTokenId][_id] = s.nftItems[_toContract][_toTokenId].length;
        }
    }

    function addToOwner(address _to, uint256 _id, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ownerItemBalances[_to][_id] += _value;
        if (s.ownerItemIndexes[_to][_id] == 0) {
            s.ownerItems[_to].push(uint16(_id));
            s.ownerItemIndexes[_to][_id] = s.ownerItems[_to].length;
        }
    }

    function removeFromOwner(address _from, uint256 _id, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.ownerItemBalances[_from][_id];
        require(_value <= bal, "LibItems: Doesn't have that many to transfer");
        bal -= _value;
        s.ownerItemBalances[_from][_id] = bal;
        if (bal == 0) {
            uint256 index = s.ownerItemIndexes[_from][_id] - 1;
            uint256 lastIndex = s.ownerItems[_from].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.ownerItems[_from][lastIndex];
                s.ownerItems[_from][index] = uint16(lastId);
                s.ownerItemIndexes[_from][lastId] = index + 1;
            }
            s.ownerItems[_from].pop();
            delete s.ownerItemIndexes[_from][_id];
        }
    }

    function removeFromParent(address _fromContract, uint256 _fromTokenId, uint256 _id, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.nftItemBalances[_fromContract][_fromTokenId][_id];
        require(_value <= bal, "Items: Doesn't have that many to transfer");
        bal -= _value;
        s.nftItemBalances[_fromContract][_fromTokenId][_id] = bal;
        if (bal == 0) {
            uint256 index = s.nftItemIndexes[_fromContract][_fromTokenId][_id] - 1;
            uint256 lastIndex = s.nftItems[_fromContract][_fromTokenId].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.nftItems[_fromContract][_fromTokenId][lastIndex];
                s.nftItems[_fromContract][_fromTokenId][index] = uint16(lastId);
                s.nftItemIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
            }
            s.nftItems[_fromContract][_fromTokenId].pop();
            delete s.nftItemIndexes[_fromContract][_fromTokenId][_id];
            if (_fromContract == address(this)) {
                checkWearableIsEquipped(uint64(_fromTokenId), _id);
            }
        }
        if (_fromContract == address(this) && bal == 1) {
            DuckInfo storage duck = s.ducks[uint64(_fromTokenId)];
            if (
                duck.equippedWearables[uint16(DuckWearableSlot.HAND_LEFT)] == _id
                    && duck.equippedWearables[uint16(DuckWearableSlot.HAND_RIGHT)] == _id
            ) {
                revert("LibItems: Can't hold 1 item in both hands");
            }
        }
    }

    // @dev old
    // function _equipWearables(
    //     address _owner,
    //     uint256 _tokenId,
    //     uint16[EQUIPPED_WEARABLE_SLOTS] calldata _wearablesToEquip,
    //     uint256[EQUIPPED_WEARABLE_SLOTS] memory _depositIdsToEquip
    // ) internal {
    //     DuckInfo storage duck = s.ducks[_tokenId];

    //     // Get the GotchiEquippedDepositsInfo struct
    //     // GotchiEquippedDepositsInfo storage duckDepositInfo = s.gotchiEquippedDepositsInfo[_tokenId];

    //     // Only valid for claimed ducks
    //     require(duck.status == DuckStatusType.DUCK, "LibDuck: Only valid for Hatched Ducks");
    //     // TODO : wip events
    //     // emit LibItemsEvents.EquipWearables(_tokenId, duck.equippedWearables, _wearablesToEquip);
    //     // emit LibItemsEvents.EquipDelegatedWearables(_tokenId, duckDepositInfo.equippedDepositIds, _depositIdsToEquip);

    //     for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
    //         uint256 toEquipId = _wearablesToEquip[slot];
    //         uint256 existingEquippedWearableId = duck.equippedWearables[slot];

    //         // uint256 depositIdToEquip = _depositIdsToEquip[slot];
    //         // uint256 existingEquippedDepositId = duckDepositInfo.equippedDepositIds[slot];

    //         // // Users might replace Wearables they own with delegated Werables.
    //         // // For this reason, we only skip this slot if both the Wearable tokenId & depositId match
    //         // if (toEquipId == existingEquippedWearableId && existingEquippedDepositId == depositIdToEquip) {
    //         //     continue;
    //         // }

    //         // To prevent the function `removeFromParent` to revert, it's necessary first to unequip this Wearable (delete from storage slot)
    //         // This is an edge case introduced by delegated Wearables, since users can now equip and unequip Wearables of same tokenId (but different depositId)
    //         // This is also necessary regardless of whether the item is transferrable or not. Non-transferrable items can still be equipped/unequipped (they just aren't transferred back to the user's wallet)
    //         delete duck.equippedWearables[slot];

    //         //Handle unequipping wearable case
    //         if (existingEquippedWearableId != 0 && s.itemTypes[existingEquippedWearableId].canBeTransferred) {
    //             //If no deposits have been made to this gotchi for this slot, it's a normal wearable unequipping case.
    //             // if (duckDepositInfo.equippedDepositIds[slot] == 0) {
    //                 // remove wearable from Duck and transfer item to owner
    //                 LibItems.removeFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
    //                 LibItems.addToOwner(_owner, existingEquippedWearableId, 1);
    //                 IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(_owner, address(this), _owner, existingEquippedWearableId, 1);
    //                 emit LibERC1155.TransferFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
    //             // } else {
    //             //     // remove wearable from Duck
    //             //     LibDelegatedWearables.removeDelegatedWearableFromGotchi(slot, _tokenId, existingEquippedWearableId);
    //             // }
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
    //                 require(s.ownerItemBalances[_owner][toEquipId] >= 1, "ItemsFacet: Wearable isn't in inventory");

    //                 //Transfer to Duck
    //                 LibItems.removeFromOwner(_owner, toEquipId, 1);
    //                 LibItems.addToParent(address(this), _tokenId, toEquipId, 1);
    //                 emit LibERC1155.TransferToParent(address(this), _tokenId, toEquipId, 1);
    //                 IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(_owner, _owner, address(this), toEquipId, 1);
    //                 LibERC1155Marketplace.updateERC1155Listing(address(this), toEquipId, _owner);
    //             } else {
    //                 // add wearable to Duck and add delegation
    //                 LibDelegatedWearables.addDelegatedWearableToGotchi(depositIdToEquip, _tokenId, toEquipId);
    //             }
    //         }
    //     }
    //     LibDuck.interact(_tokenId);

    // }
    function _equipWearables(address _owner, uint64 _duckId, uint16[] calldata _wearablesToEquip) internal {
        uint16 wearableSlotsTotal = uint16(type(DuckWearableSlot).max) + 1;
        require(_wearablesToEquip.length == wearableSlotsTotal, "ItemsFacet: Invalid wearables length");
        AppStorage storage s = LibAppStorage.diamondStorage();
        DuckInfo storage duck = s.ducks[_duckId];

        // Only valid for claimed ducks
        require(duck.status == DuckStatusType.DUCK, "LibDuck: Only valid for Hatched Ducks");
        // TODO : wip events
        // emit EquipWearables(_duckId, duck.equippedWearables, _wearablesToEquip);

        for (uint16 slot; slot < wearableSlotsTotal; slot++) {
            uint256 toEquipId = _wearablesToEquip[slot];
            uint256 existingEquippedWearableId = duck.equippedWearables[slot];

            /// TODO : is necessary ?
            // To prevent the function `removeFromParent` to revert, it's necessary first to unequip this Wearable (delete from storage slot)
            // This is an edge case introduced by delegated Wearables, since users can now equip and unequip Wearables of same tokenId (but different depositId)
            // This is also necessary regardless of whether the item is transferrable or not. Non-transferrable items can still be equipped/unequipped (they just aren't transferred back to the user's wallet)
            delete duck.equippedWearables[slot];

            //Handle unequipping wearable case
            if (existingEquippedWearableId != 0 && s.itemTypes[existingEquippedWearableId].canBeTransferred) {
                // remove wearable from Duck and transfer item to owner
                LibItems.removeFromParent(address(this), _duckId, existingEquippedWearableId, 1);
                LibItems.addToOwner(_owner, existingEquippedWearableId, 1);
                // TODO : wip emit event
                // IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(_owner, address(this), _owner, existingEquippedWearableId, 1);
                emit LibERC1155.TransferFromParent(address(this), _duckId, existingEquippedWearableId, 1);
            }

            //Handle equipping wearables case
            if (toEquipId != 0) {
                ItemType storage itemType = s.itemTypes[toEquipId];
                require(duck.level >= itemType.minLevel, "ItemsFacet: Duck level lower than minLevel");
                require(
                    itemType.category == uint8(ItemTypeCategory.WEARABLE), "ItemsFacet: Only wearables can be equippped"
                );
                require(itemType.slotPositions[slot] == true, "ItemsFacet: Wearable can't be equipped in slot");
                {
                    bool canBeEquipped;
                    uint8[] memory allowedCollaterals = itemType.allowedCollaterals;
                    if (allowedCollaterals.length > 0) {
                        uint256 collateralIndex = s.collateralTypeIndexes[duck.collateralType];

                        for (uint256 i; i < allowedCollaterals.length; i++) {
                            if (collateralIndex == allowedCollaterals[i]) {
                                canBeEquipped = true;
                                break;
                            }
                        }
                        require(canBeEquipped, "ItemsFacet: Wearable can't be used for this collateral");
                    }
                }

                // Equips new Wearable
                // Wearable is equipped one by one, even if hands has the same id (but different depositId)
                duck.equippedWearables[slot] = uint16(toEquipId);

                // We need to check if wearable is already in the inventory, if it is, we don't transfer it from the owner
                uint256 maxBalance =
                    slot == uint16(DuckWearableSlot.HAND_LEFT) || slot == uint16(DuckWearableSlot.HAND_RIGHT) ? 2 : 1;
                if (s.nftItemBalances[address(this)][_duckId][toEquipId] >= maxBalance) continue;
                require(s.ownerItemBalances[_owner][toEquipId] >= 1, "ItemsFacet: Wearable isn't in inventory");

                //Transfer to Duck
                LibItems.removeFromOwner(_owner, toEquipId, 1);
                LibItems.addToParent(address(this), _duckId, toEquipId, 1);
                emit LibERC1155.TransferToParent(address(this), _duckId, toEquipId, 1);
                // TODO : wip emit event
                // IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(_owner, _owner, address(this), toEquipId, 1);
                // LibERC1155Marketplace.updateERC1155Listing(address(this), toEquipId, _owner);
            }
        }
        LibDuck.interact(_duckId);
    }

    function checkWearableIsEquipped(uint64 _fromTokenId, uint256 _id) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint16 wearableSlotsTotal = uint16(type(DuckWearableSlot).max) + 1;
        for (uint16 i; i < wearableSlotsTotal; i++) {
            require(
                s.ducks[_fromTokenId].equippedWearables[i] != _id, "Items: Cannot transfer wearable that is equipped"
            );
        }
    }

    ///@notice Allow the owner of an NFT to use multiple consumable items for his duck
    ///@dev Only valid for claimed ducks
    ///@dev Consumables can be used to boost kinship/XP of an duck
    ///@param _duckId Identtifier of duck to use the consumables on
    ///@param _itemIds An array containing the identifiers of the items/consumables to use
    ///@param _quantities An array containing the quantity of each consumable to use
    function _useConsumables(
        address _owner,
        uint64 _duckId,
        uint256[] calldata _itemIds,
        uint256[] calldata _quantities
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_itemIds.length == _quantities.length, "ItemsFacet: _itemIds length != _quantities length");
        require(s.ducks[_duckId].locked == false, "LibAppStorage: Only callable on unlocked Duck");

        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 quantity = _quantities[i];
            ItemType memory itemType = s.itemTypes[itemId];
            require(itemType.category == uint8(ItemTypeCategory.CONSUMABLE), "ItemsFacet: Item isn't consumable");

            LibItems.removeFromOwner(_owner, itemId, quantity);

            //Increase kinship
            if (itemType.kinshipBonus > 0) {
                uint256 kinship =
                    (uint256(int256(itemType.kinshipBonus)) * quantity) + s.ducks[_duckId].interactionCount;
                s.ducks[_duckId].interactionCount = kinship;
            } else if (itemType.kinshipBonus < 0) {
                uint256 kinshipBonus = LibMaths.abs(itemType.kinshipBonus) * quantity;
                if (s.ducks[_duckId].interactionCount > kinshipBonus) {
                    s.ducks[_duckId].interactionCount -= kinshipBonus;
                } else {
                    s.ducks[_duckId].interactionCount = 0;
                }
            }

            /// @dev : old code, need to be refactored
            // {
            //     // prevent stack too deep error with braces here
            //     //Boost traits and reset clock
            //     bool boost = false;
            //     for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
            //         if (itemType.traitModifiers[j] != 0) {
            //             boost = true;
            //             break;
            //         }
            //     }
            //     if (boost) {
            //         s.ducks[_duckId].lastTemporaryBoost = uint40(block.timestamp);
            //         s.ducks[_duckId].temporaryTraitBoosts = itemType.traitModifiers;
            //     }
            // }

            /// @dev : new code, need to be tested
            {
                // prevent stack too deep error with braces here
                //Increase Statistics
                for (uint16 j; j < (uint16(type(DuckStatisticsType).max) + 1); j++) {
                    if (itemType.statisticsModifiers[j] > 0) {
                        s.ducks[_duckId].statistics[j] += uint16(itemType.statisticsModifiers[j]);
                    } else if (itemType.statisticsModifiers[j] < 0) {
                        uint16 absModifier = uint16(LibMaths.abs(int256(itemType.statisticsModifiers[j])));
                        // require(s.ducks[_duckId].statistics[j] >= absModifier, "ItemsFacet: Statistics underflow"); // TODO:  reached 0 ?
                        // s.ducks[_duckId].statistics[j] -= absModifier;
                            // Instead of requiring and reverting, clamp to 0
                        if (s.ducks[_duckId].statistics[j] >= absModifier) {
                            s.ducks[_duckId].statistics[j] -= absModifier;
                        } else {
                            s.ducks[_duckId].statistics[j] = 0;
                        }
                    }
                }
            }

            //Increase experience
            if (itemType.experienceBonus > 0) {
                uint256 experience = (uint256(itemType.experienceBonus) * quantity) + s.ducks[_duckId].experience;
                s.ducks[_duckId].experience = experience;
            }

            itemType.totalQuantity -= quantity;
            LibDuck.interact(_duckId);
            // TODO : wip marketplace
            // LibERC1155Marketplace.updateERC1155Listing(address(this), itemId, _owner);
        }
        emit UseConsumables(_duckId, _itemIds, _quantities);
        // TODO: wip event
        // IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(_owner, _owner, address(0), _itemIds, _quantities);
    }
}
