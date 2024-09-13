// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
// import {LibERC721} from "../libs/LibERC721.sol";
import {LibERC20} from "../libs/LibERC20.sol";
import {LibString} from "../libs/LibString.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {CollateralTypeDTO} from "../shared/Structs.sol";

contract CollateralFacet is AccessControl {
    event IncreaseStake(uint256 indexed _tokenId, uint256 _stakeAmount);
    event DecreaseStake(uint256 indexed _tokenId, uint256 _reduceAmount);
    /////////////////////////////////////////////////////////////////////////
    // MARK: READ FUNCTIONS
    /////////////////////////////////////////////////////////////////////////

    ///@notice Query addresses about all collaterals available for a particular cycle
    ///@param _cycleId identifier of the cycle to query
    ///@return collateralTypes_ An array containing the addresses of all collaterals available for cycle `_cycleId`
    function getCycleCollateralsAddresses(uint256 _cycleId) external view returns (address[] memory collateralTypes_) {
        collateralTypes_ = s.cycleCollateralTypes[_cycleId];
    }

    ///@notice Query all details about a collateral in a cycle
    ///@param _cycleId The identifier of the cycle to query
    ///@param _collateralId the identifier of the collateral to query
    ///return collateralInfo_ A struct containing extensive details about a collateral of identifier `_collateralId` in cycle `_cycleId`
    function getCycleCollateralInfo(uint256 _cycleId, uint256 _collateralId)
        external
        view
        returns (CollateralTypeDTO memory collateralInfo_)
    {
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

    ///@notice Query all details about all collaterals in a cycle
    ///@param _cycleId The identifier of the cycle to query
    ///return collateralInfo_ An array of structs where each struct contains extensive details about each collateral that is available in cycle `_cycleId`
    function getCycleAllCollateralsInfos(uint256 _cycleId)
        external
        view
        returns (CollateralTypeDTO[] memory collateralInfo_)
    {
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

    ///@notice Query the address of all collaterals that are available universally throughout all cycles
    ///@return An array of addresses,each address representing a collateral's contract address
    function getAllCyclesCollateralsTypesAddresses() external view returns (address[] memory) {
        return s.collateralTypes;
    }

    ///@notice Query the collateral address,balance and escrow contract of an NFT
    ///@dev Only valid for claimed ducks
    ///@param _tokenId the identifier of the NFT to query
    ///@return collateralType_ The contract address of the collateral
    ///@return escrow_ The contract address of the NFT's escrow contract
    ///@return balance_ The collateral balance of the NFT
    function collateralBalance(uint256 _tokenId)
        external
        view
        returns (address collateralType_, address escrow_, uint256 balance_)
    {
        escrow_ = s.ducks[_tokenId].escrow;
        require(escrow_ != address(0), "CollateralFacet: Does not have an escrow");
        collateralType_ = s.ducks[_tokenId].collateralType;
        balance_ = IERC20(collateralType_).balanceOf(escrow_);
    }

    /////////////////////////////////////////////////////////////////////////
    // MARK: WRITE FUNCTIONS
    /////////////////////////////////////////////////////////////////////////

    ///@notice Allow the owner of a claimed Duck to increase its collateral stake
    ///@dev Only valid for claimed ducks
    ///@param _tokenId The identifier of the NFT to increase
    ///@param _stakeAmount The amount of collateral tokens to increase the current collateral by

    function increaseStake(uint256 _tokenId, uint256 _stakeAmount) external onlyDuckOwner(_tokenId) {
        address escrow = s.ducks[_tokenId].escrow;
        require(escrow != address(0), "CollateralFacet: Does not have an escrow");
        address collateralType = s.ducks[_tokenId].collateralType;
        emit IncreaseStake(_tokenId, _stakeAmount);
        LibERC20.safeTransferFrom(collateralType, _msgSender(), escrow, _stakeAmount);
    }

    ///@notice Allow the owner of a claimed Duck to decrease its collateral stake
    ///@dev Only valid for claimed ducks
    ///@dev Will throw if it is reduced less than the minimum stake
    ///@param _tokenId The identifier of the NFT to decrease
    ///@param _reduceAmount The amount of collateral tokens to decrease the current collateral by
    function decreaseStake(uint256 _tokenId, uint256 _reduceAmount)
        external
        onlyUnlocked(_tokenId)
        onlyDuckOwner(_tokenId)
    {
        address escrow = s.ducks[_tokenId].escrow;
        require(escrow != address(0), "CollateralFacet: Does not have an escrow");

        address collateralType = s.ducks[_tokenId].collateralType;
        uint256 currentStake = IERC20(collateralType).balanceOf(escrow);
        uint256 minimumStake = s.ducks[_tokenId].minimumStake;

        require(currentStake - _reduceAmount >= minimumStake, "CollateralFacet: Cannot reduce below minimum stake");
        emit DecreaseStake(_tokenId, _reduceAmount);
        LibERC20.safeTransferFrom(collateralType, escrow, _msgSender(), _reduceAmount);
    }

    // ///@notice Allow the owner of an Duck to destroy his Duck and transfer the XP points to another Duck
    // ///@dev Only valid for claimed ducksi
    // ///@dev Name assigned to destroyed Duck is freed up for use by another aavegotch
    // ///@param _tokenId Identifier of NFT to destroy
    // ///@param _toId Identifier of another claimed Duck where the XP of the sacrificed Duck will be sent

    // function decreaseAndDestroy(uint256 _tokenId, uint256 _toId) external onlyUnlocked(_tokenId) onlyDuckOwner(_tokenId) {
    //     address escrow = s.ducks[_tokenId].escrow;
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
