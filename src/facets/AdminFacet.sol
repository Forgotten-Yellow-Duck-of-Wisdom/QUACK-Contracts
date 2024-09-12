// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, DuckInfoMemory} from "../shared/Structs_Ducks.sol";
import {CollateralTypeDTO} from "../shared/Structs.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * Protocol Admin Facet -
 */
contract AdminFacet is AccessControl {
    event CreateCycle(uint256 indexed _cycleId, uint256 _cycleMaxSize, uint256 _eggsPrice, bytes32 _bodyColor);
    event AddCollateralType(CollateralTypeDTO _collateralType);
    event UpdateCollateralModifiers(int16[NUMERIC_TRAITS_NUM] _oldModifiers, int16[NUMERIC_TRAITS_NUM] _newModifiers);

    function changeVrfParameters(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords)
        external
        isAdmin
    {
        s.vrfCallbackGasLimit = _callbackGasLimit;
        s.vrfRequestConfirmations = _requestConfirmations;
        s.vrfNumWords = _numWords;
    }

    ///@notice Allow the Diamond owner or DAO to create a new Cycle
    ///@dev Will throw if the previous cycle is not full yet
    ///@param _cycleMaxSize The maximum number of portals in the new cycle
    ///@param _eggsPrice The base price of portals in the new cycle(in $QUACK)
    ///@param _bodyColor The universal body color applied to NFTs in the new cycle
    function createCycle(uint24 _cycleMaxSize, uint96 _eggsPrice, bytes3 _bodyColor)
        external
        onlyAdmin
        returns (uint256 cycleId_)
    {
        uint256 currentCycleId = s.currentCycleId;
        // require(
        //     s.cycles[currentCycleId].totalCount == s.cycles[currentCycleId].cycleMaxSize,
        //     "AdminFacet: Cycle must be full before creating new"
        // );
        cycleId_ = currentCycleId + 1;
        s.currentCycleId = uint16(cycleId_);
        s.cycles[cycleId_].cycleMaxSize = _cycleMaxSize;
        s.cycles[cycleId_].portalPrice = _eggsPrice;
        s.cycles[cycleId_].bodyColor = _bodyColor;
        emit CreateCycle(cycleId_, _cycleMaxSize, _eggsPrice, _bodyColor);
    }

    ///@notice Allow an admin to add new collateral types to a cycle
    ///@dev If a certain collateral exists already, it will be overwritten
    ///@param _cycleId Identifier for haunt to add the collaterals to
    ///@param _collateralTypes An array of structs where each struct contains details about a particular collateral
    function addCollateralTypes(uint256 _cycleId, CollateralTypeDTO[] calldata _collateralTypes) external onlyAdmin {
        for (uint256 i; i < _collateralTypes.length; i++) {
            address newCollateralType = _collateralTypes[i].collateralType;

            //Overwrite the collateralTypeInfo if it already exists
            s.collateralTypeInfo[newCollateralType] = _collateralTypes[i].collateralTypeInfo;

            //First handle global collateralTypes array
            uint256 index = s.collateralTypeIndexes[newCollateralType];
            bool collateralExists = index > 0 || s.collateralTypes[0] == newCollateralType;

            if (!collateralExists) {
                s.collateralTypes.push(newCollateralType);
                s.collateralTypeIndexes[newCollateralType] = s.collateralTypes.length;
            }

            //Then handle cycleCollateralTypes array
            bool cycleCollateralExists = false;
            for (uint256 hauntIndex = 0; hauntIndex < s.cycleCollateralTypes[_cycleId].length; hauntIndex++) {
                address existingHauntCollateral = s.cycleCollateralTypes[_cycleId][hauntIndex];

                if (existingHauntCollateral == newCollateralType) {
                    cycleCollateralExists = true;
                    break;
                }
            }

            if (!cycleCollateralExists) {
                s.cycleCollateralTypes[_cycleId].push(newCollateralType);
                emit AddCollateralType(_collateralTypes[i]);
            }
        }
    }

    ///@notice Allow the Diamond owner or DAO to update the collateral modifiers of an existing collateral
    ///@param _collateralType The address of the existing collateral to update
    ///@param _modifiers An array containing the new numeric traits modifiers which will be applied to collateral `_collateralType`
    function updateCollateralModifiers(address _collateralType, int16[NUMERIC_TRAITS_NUM] calldata _modifiers)
        external
        onlyAdmin
    {
        emit UpdateCollateralModifiers(s.collateralTypeInfo[_collateralType].modifiers, _modifiers);
        s.collateralTypeInfo[_collateralType].modifiers = _modifiers;
    }
}
