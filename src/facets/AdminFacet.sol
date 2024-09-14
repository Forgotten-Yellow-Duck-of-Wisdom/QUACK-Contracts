// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle} from "../shared/Structs_Ducks.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../shared/Structs.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * Protocol Admin Facet -
 */
contract AdminFacet is AccessControl {
    event CreateCycle(uint256 indexed _cycleId, uint256 _cycleMaxSize, uint256 _eggsPrice, uint256 _bodyColorItemId);
    event AddCollateralType(CollateralTypeDTO _collateralType);
    event UpdateCollateralModifiers(int16[] _oldModifiers, int16[] _newModifiers);

    function changeVrfParameters(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords)
        external
        isAdmin
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vrfCallbackGasLimit = _callbackGasLimit;
        s.vrfRequestConfirmations = _requestConfirmations;
        s.vrfNumWords = _numWords;
    }

    ///@notice Allow admin to create a new Cycle
    ///@dev Will throw if the previous cycle is not full yet
    ///@param _cycleMaxSize The maximum number of portals in the new cycle
    ///@param _eggsPrice The base price of portals in the new cycle(in $QUACK)
    ///@param _bodyColorItemId The universal itemId of the body color applied to NFTs in the new cycle
    function createCycle(uint24 _cycleMaxSize, uint256 _eggsPrice, uint256 _bodyColorItemId)
        external
        isAdmin
        returns (uint256 cycleId_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentCycleId = s.currentCycleId;
        // require(
        //     s.cycles[currentCycleId].totalCount == s.cycles[currentCycleId].cycleMaxSize,
        //     "AdminFacet: Cycle must be full before creating new"
        // );
        cycleId_ = currentCycleId + 1;
        s.currentCycleId = uint16(cycleId_);
        s.cycles[cycleId_].cycleMaxSize = _cycleMaxSize;
        s.cycles[cycleId_].eggsPrice = _eggsPrice;
        s.cycles[cycleId_].bodyColorItemId = _bodyColorItemId;
        emit CreateCycle(cycleId_, _cycleMaxSize, _eggsPrice, _bodyColorItemId);
    }

    ///@notice Allow an admin to add new collateral types to a cycle
    ///@dev If a certain collateral exists already, it will be overwritten
    ///@param _cycleId Identifier for cycle to add the collaterals to
    ///@param _collateralTypes An array of structs where each struct contains details about a particular collateral
    function addCollateralTypes(uint256 _cycleId, CollateralTypeDTO[] calldata _collateralTypes) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < _collateralTypes.length; i++) {
            address newCollateralTypeAddress = _collateralTypes[i].collateralType;

            // First create or update the collateralTypeInfo directly in storage
            CollateralTypeInfo storage newCollateralTypeInfo = s.collateralTypeInfo[newCollateralTypeAddress];

            // Replace existing(if any) modifiers and set new ones
            for (uint16 j; j < _collateralTypes[i].modifiers.length; j++) {
                newCollateralTypeInfo.modifiers[j] = _collateralTypes[i].modifiers[j];
            }

            // Set other properties
            newCollateralTypeInfo.primaryColor = _collateralTypes[i].primaryColor;
            newCollateralTypeInfo.secondaryColor = _collateralTypes[i].secondaryColor;
            newCollateralTypeInfo.delisted = _collateralTypes[i].delisted;

            //then handle global collateralTypes array
            uint256 index = s.collateralTypeIndexes[newCollateralTypeAddress];
            bool collateralExists = index > 0 || (s.collateralTypes.length > 0 && s.collateralTypes[0] == newCollateralTypeAddress);

            if (!collateralExists) {
                s.collateralTypes.push(newCollateralTypeAddress);
                s.collateralTypeIndexes[newCollateralTypeAddress] = s.collateralTypes.length;
            }

            //Then handle cycleCollateralTypes array
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

    // TODO: rework enumerable map
    // ///@notice Allow the admin to update the collateral modifiers of an existing collateral
    // ///@param _collateralType The address of the existing collateral to update
    // ///@param _modifiers An array containing the new numeric traits modifiers which will be applied to collateral `_collateralType`
    // function updateCollateralModifiers(address _collateralType, int16[NUMERIC_TRAITS_NUM] calldata _modifiers)
    //     external
    //     isAdmin
    // {
    //     emit UpdateCollateralModifiers(s.collateralTypeInfo[_collateralType].modifiers, _modifiers);
    //     s.collateralTypeInfo[_collateralType].modifiers = _modifiers;
    // }

    ///@notice Allow the admin to grant XP(experience points) to multiple Ducks
    ///@dev recipients must be claimed Ducks
    ///@param _tokenIds The identifiers of the Ducks to grant XP to
    ///@param _xpValues The amount XP to grant each Duck
    function grantExperience(uint256[] calldata _tokenIds, uint256[] calldata _xpValues) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_tokenIds.length == _xpValues.length, "AdminFacet: IDs must match XP array length");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 xp = _xpValues[i];
            require(xp <= 1000, "AdminFacet: Cannot grant more than 1000 XP at a time");

            s.ducks[tokenId].experience += xp;
        }
        // TODO: wip events / libXP/drop
        // emit LibXPAllocation.GrantExperience(_tokenIds, _xpValues);
    }
}
