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

    // TODO: rework enumerable map
    /**
     * @notice Allows the admin to update the collateral modifiers of an existing collateral type.
     * @dev Only callable by an admin. This function updates the modifiers array for the specified collateral type.
     *      Currently commented out pending the rework of the enumerable map structure.
     * @param _collateralType The address of the existing collateral to update.
     * @param _modifiers An array containing the new numeric traits modifiers to be applied to the collateral.
     *
     * @custom:dev This function emits an `UpdateCollateralModifiers` event before updating the modifiers.
     * It ensures that the modifiers array is properly updated in the storage mapping.
     */
    // function updateCollateralModifiers(address _collateralType, int16[NUMERIC_TRAITS_NUM] calldata _modifiers)
    //     external
    //     isAdmin
    // {
    //     emit UpdateCollateralModifiers(s.collateralTypeInfo[_collateralType].modifiers, _modifiers);
    //     s.collateralTypeInfo[_collateralType].modifiers = _modifiers;
    // }

    /**
     * @notice Grants experience points (XP) to multiple Ducks.
     * @dev Only callable by an admin. Each Duck must be a claimed Duck. The XP granted to each Duck cannot exceed 1000 at a time.
     * @param _tokenIds An array of Duck token IDs to which XP will be granted.
     * @param _xpValues An array of XP values corresponding to each Duck in _tokenIds.
     *
     * @custom:dev This function iterates through the provided _tokenIds and _xpValues arrays,
     * ensuring they are of equal length and that each XP value does not exceed the maximum allowed.
     * It then increments the experience points of each specified Duck accordingly.
     * Emits a GrantExperience event for each successful XP grant.
     */
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
