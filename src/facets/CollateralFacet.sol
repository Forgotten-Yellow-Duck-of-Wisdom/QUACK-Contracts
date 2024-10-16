// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
// import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC20} from "../libs/LibERC20.sol";
import {LibString} from "../libs/LibString.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {CollateralTypeDTO, CollateralTypeInfo} from "../shared/Structs.sol";

/**
 * @title CollateralFacet
 * @dev Facet of the Diamond contract responsible for managing collateral-related functionalities,
 * including querying collateral information and managing collateral stakes for Ducks.
 * Inherits AccessControl to enforce role-based access restrictions.
 */
contract CollateralFacet is AccessControl {
    /**
     * @dev Emitted when a Duck's collateral stake is increased.
     * @param _tokenId The unique identifier of the Duck NFT.
     * @param _stakeAmount The amount of collateral tokens added to the stake.
     */
    event IncreaseStake(uint256 indexed _tokenId, uint256 _stakeAmount);
    /**
     * @dev Emitted when a Duck's collateral stake is decreased.
     * @param _tokenId The unique identifier of the Duck NFT.
     * @param _reduceAmount The amount of collateral tokens removed from the stake.
     */
    event DecreaseStake(uint256 indexed _tokenId, uint256 _reduceAmount);

    /////////////////////////////////////////////////////////////////////////
    // MARK: READ FUNCTIONS
    /////////////////////////////////////////////////////////////////////////

    /**
     * @notice Retrieves all collateral contract addresses available for a specific cycle.
     * @param _cycleId The identifier of the cycle to query.
     * @return collateralTypes_ An array of addresses representing all collaterals available for the specified cycle.
     *
     * @custom:dev This function accesses the `cycleCollateralTypes` mapping from the AppStorage
     * to fetch all collateral types associated with the given cycle ID.
     */
    function getCycleCollateralsAddresses(uint256 _cycleId) external view returns (address[] memory collateralTypes_) {
        collateralTypes_ = LibAppStorage.diamondStorage().cycleCollateralTypes[_cycleId];
    }

    /**
     * @notice Retrieves detailed information about a specific collateral within a cycle.
     * @param _cycleId The identifier of the cycle containing the collateral.
     * @param _collateralId The index identifier of the collateral within the cycle.
     * @return collateralInfo_ A `CollateralTypeDTO` struct containing comprehensive details about the specified collateral.
     *
     * @custom:dev This function fetches the collateral address from the `cycleCollateralTypes` mapping
     * and populates a `CollateralTypeDTO` struct with modifier values, primary and secondary colors, and delisted status.
     */
    function getCycleCollateralInfo(uint256 _cycleId, uint256 _collateralId)
        external
        view
        returns (CollateralTypeDTO memory collateralInfo_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address collateral = s.cycleCollateralTypes[_cycleId][_collateralId];
        collateralInfo_ = CollateralTypeDTO(
            collateral,
            LibDuck.getModifiersArray(s.collateralTypeInfo[collateral]),
            s.collateralTypeInfo[collateral].primaryColor,
            s.collateralTypeInfo[collateral].secondaryColor,
            s.collateralTypeInfo[collateral].delisted
        );
        return collateralInfo_;
    }

    /**
     * @notice Retrieves detailed information about all collaterals within a specific cycle.
     * @param _cycleId The identifier of the cycle to query.
     * @return collateralInfo_ An array of `CollateralTypeDTO` structs, each containing comprehensive details about a collateral in the cycle.
     *
     * @custom:dev This function iterates through all collateral addresses associated with the given cycle ID
     * and constructs an array of `CollateralTypeDTO` structs with their respective details.
     */
    function getCycleAllCollateralsInfos(uint256 _cycleId)
        external
        view
        returns (CollateralTypeDTO[] memory collateralInfo_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address[] memory collateralTypes = s.cycleCollateralTypes[_cycleId];

        collateralInfo_ = new CollateralTypeDTO[](s.cycleCollateralTypes[_cycleId].length);

        for (uint256 i; i < collateralTypes.length; i++) {
            address collateral = collateralTypes[i];
            collateralInfo_[i].collateralType = collateral;
            collateralInfo_[i].modifiers = LibDuck.getModifiersArray(s.collateralTypeInfo[collateral]);
            collateralInfo_[i].primaryColor = s.collateralTypeInfo[collateral].primaryColor;
            collateralInfo_[i].secondaryColor = s.collateralTypeInfo[collateral].secondaryColor;
            collateralInfo_[i].delisted = s.collateralTypeInfo[collateral].delisted;
        }
    }
    /**
     * @notice Retrieves all collateral contract addresses that are universally available across all cycles.
     * @return An array of addresses, each representing a collateral's contract address.
     *
     * @custom:dev This function accesses the `collateralTypes` array from the AppStorage,
     * providing a list of all collaterals that are available in the protocol regardless of cycle.
     */
    function getAllCyclesCollateralsTypesAddresses() external view returns (address[] memory) {
        return LibAppStorage.diamondStorage().collateralTypes;
    }

    /**
     * @notice Retrieves the collateral details, including the collateral type, escrow contract, and balance for a specific Duck NFT.
     * @dev This function is only valid for Ducks that have been claimed.
     * @param _tokenId The unique identifier of the Duck NFT to query.
     * @return collateralType_ The contract address of the collateral associated with the Duck.
     * @return escrow_ The contract address of the Duck's escrow contract.
     * @return balance_ The current collateral balance of the Duck's escrow contract.
     *
     * @custom:dev This function ensures that the Duck has an associated escrow contract.
     * It then retrieves the collateral type and queries the ERC20 balance of the escrow contract.
     */
    function collateralBalance(uint256 _tokenId)
        external
        view
        returns (address collateralType_, address escrow_, uint256 balance_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        escrow_ = s.ducks[_tokenId].escrow;
        require(escrow_ != address(0), "CollateralFacet: Does not have an escrow");
        collateralType_ = s.ducks[_tokenId].collateralType;
        balance_ = IERC20(collateralType_).balanceOf(escrow_);
    }

    /////////////////////////////////////////////////////////////////////////
    // MARK: WRITE FUNCTIONS
    /////////////////////////////////////////////////////////////////////////

    /**
     * @notice Increases the collateral stake of a specific Duck NFT.
     * @dev Only the owner of the Duck can perform this action. The Duck must be in a claimed state.
     * @param _tokenId The unique identifier of the Duck NFT to increase stake for.
     * @param _stakeAmount The amount of collateral tokens to add to the current stake.
     *
     * @custom:dev This function emits an `IncreaseStake` event upon successful addition of collateral.
     * It transfers the specified collateral tokens from the sender to the Duck's escrow contract.
     */
    function increaseStake(uint256 _tokenId, uint256 _stakeAmount) external isDuckOwner(_tokenId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address escrow = s.ducks[_tokenId].escrow;
        require(escrow != address(0), "CollateralFacet: Does not have an escrow");
        address collateralType = s.ducks[_tokenId].collateralType;
        emit IncreaseStake(_tokenId, _stakeAmount);
        LibERC20.safeTransferFrom(collateralType, _msgSender(), escrow, _stakeAmount);
    }

    /**
     * @notice Decreases the collateral stake of a specific Duck NFT.
     * @dev Only the owner of the Duck can perform this action. The Duck must be unlocked.
     *      The resulting stake must not fall below the minimum required stake.
     * @param _tokenId The unique identifier of the Duck NFT to decrease stake for.
     * @param _reduceAmount The amount of collateral tokens to remove from the current stake.
     *
     * @custom:dev This function emits a `DecreaseStake` event upon successful removal of collateral.
     * It transfers the specified collateral tokens from the Duck's escrow contract back to the sender.
     * Ensures that the remaining stake does not fall below the predefined minimum stake.
     */
    function decreaseStake(uint256 _tokenId, uint256 _reduceAmount)
        external
        onlyUnlocked(_tokenId)
        isDuckOwner(_tokenId)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address escrow = s.ducks[_tokenId].escrow;
        require(escrow != address(0), "CollateralFacet: Does not have an escrow");

        address collateralType = s.ducks[_tokenId].collateralType;
        uint256 currentStake = IERC20(collateralType).balanceOf(escrow);
        uint256 minimumStake = s.ducks[_tokenId].minimumStake;

        require(currentStake - _reduceAmount >= minimumStake, "CollateralFacet: Cannot reduce below minimum stake");
        emit DecreaseStake(_tokenId, _reduceAmount);
        LibERC20.safeTransferFrom(collateralType, escrow, _msgSender(), _reduceAmount);
    }

    // /**
    //  * @notice Destroys a Duck NFT and transfers its experience points to another Duck.
    //  * @dev Only the owner of the Duck can perform this action. The Duck must be unlocked.
    //  *      The function ensures that the Duck being destroyed does not have any equipped items.
    //  * @param _tokenId The unique identifier of the Duck NFT to destroy.
    //  * @param _toId The unique identifier of the Duck NFT to receive the experience points.
    //  *
    //  * @custom:dev This function handles the transfer of experience points from the destroyed Duck to
    //  * another Duck, updates ownership mappings, deletes approvals, and manages collateral transfers.
    //  * It also interacts with the ForgeFacet to mint essence for the owner.
    //  */
    // function decreaseAndDestroy(uint256 _tokenId, uint256 _toId) external onlyUnlocked(_tokenId) isDuckOwner(_tokenId) {
    //         AppStorage storage s = LibAppStorage.diamondStorage();
    // address escrow = s.ducks[_tokenId].escrow;
    //     require(escrow != address(0), "CollateralFacet: Does not have an escrow");

    //     // require(s.nftItems[address(this)][_tokenId].length == 0, "CollateralFacet: Can't burn Duck with items");

    //     //If the toId is different from the tokenId, then perform an experience transfer

    //     if (_tokenId == _toId) revert("CollateralFacet: Cannot send to burned Duck");
    //     else {
    //         uint256 experience = s.ducks[_tokenId].experience;
    //         emit ExperienceTransfer(_tokenId, _toId, experience);
    //         s.ducks[_toId].experience += experience;
    //     }

    //     // remove
    //     s.ducks[_tokenId].owner = address(0);
    //     address owner = _msgSender();
    //     uint256 index = s.ownerTokenIdIndexes[owner][_tokenId];
    //     uint256 lastIndex = s.ownerTokenIds[owner].length - 1;
    //     if (index != lastIndex) {
    //         uint32 lastTokenId = s.ownerTokenIds[owner][lastIndex];
    //         s.ownerTokenIds[owner][index] = lastTokenId;
    //         s.ownerTokenIdIndexes[owner][lastTokenId] = index;
    //     }
    //     s.ownerTokenIds[owner].pop();
    //     delete s.ownerTokenIdIndexes[owner][_tokenId];

    //     // delete token approval if any
    //     if (s.approved[_tokenId] != address(0)) {
    //         delete s.approved[_tokenId];
    //         emit LibERC721.Approval(owner, address(0), _tokenId);
    //     }

    //     emit LibERC721.Transfer(owner, address(0), _tokenId);

    //     // transfer all collateral to _msgSender()
    //     address collateralType = s.ducks[_tokenId].collateralType;
    //     uint256 reduceAmount = IERC20(collateralType).balanceOf(escrow);
    //     emit DecreaseStake(_tokenId, reduceAmount);
    //     LibERC20.transferFrom(collateralType, escrow, owner, reduceAmount);

    //     // delete Duck info
    //     string memory name = s.ducks[_tokenId].name;
    //     if (bytes(name).length > 0) {
    //         delete s.duckNamesUsed[LibString.validateAndLowerName(name)];
    //     }
    //     delete s.ducks[_tokenId];

    //     ForgeFacet forgeFacet = ForgeFacet(s.forgeDiamond);
    //     forgeFacet.mintEssence(owner);
    // }
}
