// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, DuckInfoDTO} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * @title Duck Facet
 * @dev ERC721 implementation representing user-owned digital ducks.
 *      Handles NFT enumeration, ownership queries, and transfer functionalities.
 */
contract DuckFacet is AccessControl {
    /**
     * @notice Retrieve the total quantity of minted NFTs.
     * @return totalSupply_ The aggregate count of all NFTs ever created.
     *
     * @custom:dev This function accesses the `duckIds` array from the AppStorage
     * to determine the total number of Ducks minted.
     */
    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = LibAppStorage.diamondStorage().duckIds.length;
    }

    /**
     * @notice Enumerate NFTs assigned to a specific owner.
     * @dev Throws an exception if queried for the zero address.
     * @param _owner The address of the NFT holder.
     * @return balance_ The quantity of NFTs owned by the specified address.
     *
     * @custom:dev This function accesses the `ownerDuckIds` mapping from AppStorage
     * to fetch the list of Ducks owned by `_owner`.
     */
    function balanceOf(address _owner) external view returns (uint256 balance_) {
        require(_owner != address(0), "DuckFacet: _owner can't be address(0)");
        balance_ = LibAppStorage.diamondStorage().ownerDuckIds[_owner].length;
    }

    /**
     * @notice Fetch comprehensive information about a specific NFT.
     * @param _duckId The unique identifier of the NFT.
     * @return duckInfo_ A `DuckInfoDTO` struct encapsulating all relevant details of the NFT.
     *
     * @custom:dev This function leverages the `LibDuck` library to retrieve detailed information
     * about the Duck associated with `_duckId`.
     */
    function getDuckInfo(uint64 _duckId) external view returns (DuckInfoDTO memory duckInfo_) {
        duckInfo_ = LibDuck.getDuckInfo(_duckId);
    }

    /**
     * @notice Retrieve the timestamp when an NFT was claimed.
     * @dev Returns zero for unclaimed portals.
     * @param _duckId The unique identifier of the NFT.
     * @return hatchTime_ The Unix timestamp of the NFT's claim.
     *
     * @custom:dev This function accesses the `ducks` mapping from AppStorage to fetch
     * the `hatchTime` of the specified Duck.
     */
    function duckHatchTime(uint64 _duckId) external view returns (uint256 hatchTime_) {
        hatchTime_ = LibAppStorage.diamondStorage().ducks[_duckId].hatchTime;
    }

    /**
     * @notice Enumerate valid NFTs by index.
     * @dev Throws if `_index` is greater than or equal to `totalSupply()`.
     * @param _index A number less than the total supply.
     * @return tokenId_ The unique identifier of the NFT at the specified index.
     *
     * @custom:dev This function accesses the `duckIds` array from AppStorage to fetch
     * the token ID at the given index.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_index < s.duckIds.length, "DuckFacet: index beyond supply");
        tokenId_ = s.duckIds[_index];
    }

    /**
     * @notice List NFTs owned by an address, indexed by position.
     * @dev Throws for invalid indices or zero address queries.
     * @param _owner The address of interest.
     * @param _index A number less than the owner's balance.
     * @return tokenId_ The unique identifier of the NFT at the specified position in the owner's collection.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_index < s.ownerDuckIds[_owner].length, "DuckFacet: index beyond owner balance");
        tokenId_ = s.ownerDuckIds[_owner][_index];
    }

    /**
     * @notice Fetch all NFT identifiers owned by a specific address.
     * @param _owner The address to query.
     * @return tokenIds_ An array of unique identifiers for each owned NFT.
     */
    function tokenIdsOfOwner(address _owner) external view returns (uint64[] memory tokenIds_) {
        tokenIds_ = LibAppStorage.diamondStorage().ownerDuckIds[_owner];
    }

    /**
     * @notice Retrieve detailed information for all NFTs owned by an address.
     * @param _owner The address to query.
     * @return ducksInfos_ An array of `DuckInfoDTO` structs, each containing comprehensive details of an owned NFT.
     *
     * @custom:dev This function iterates through the Ducks owned by `_owner` and utilizes the `LibDuck` library
     * to gather detailed information for each Duck.
     */
    function allDucksInfosOfOwner(address _owner) external view returns (DuckInfoDTO[] memory ducksInfos_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.ownerDuckIds[_owner].length;
        ducksInfos_ = new DuckInfoDTO[](length);
        for (uint256 i; i < length; i++) {
            ducksInfos_[i] = LibDuck.getDuckInfo(s.ownerDuckIds[_owner][i]);
        }
    }

    /**
     * @notice Batch query for NFT ownership
     * @param _tokenIds An array of NFT identifiers to check
     * @return owners_ An array of addresses corresponding to the owners of the queried NFTs
     */
    function batchOwnerOf(uint64[] calldata _tokenIds) external view returns (address[] memory owners_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        owners_ = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owners_[i] = s.ducks[_tokenIds[i]].owner;
            require(owners_[i] != address(0), "DuckFacet: invalid _tokenId");
        }
    }

    /**
     * @notice Determine the owner of a specific NFT
     * @dev Throws for queries about invalid NFTs (those assigned to the zero address)
     * @param _duckId The unique identifier of the NFT
     * @return owner_ The address of the NFT's current owner
     */
    function ownerOf(uint64 _duckId) external view returns (address owner_) {
        owner_ = LibAppStorage.diamondStorage().ducks[_duckId].owner;
        require(owner_ != address(0), "DuckFacet: invalid _duckId");
    }

    /**
     * @notice Fetch the approved address for a single NFT
     * @dev Throws if the NFT doesn't exist
     * @param _duckId The NFT to find the approved address for
     * @return approved_ The currently approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint64 _duckId) external view returns (address approved_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_duckId < s.duckIds.length, "ERC721: tokenId is invalid");
        approved_ = s.approved[_duckId];
    }

    /**
     * @notice Check if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = LibAppStorage.diamondStorage().operators[_owner][_operator];
    }

    // /**
    //  * @notice Verify if an address is authorized to interact with ducks on behalf of another address
    //  * @param _owner The address of the duck owner
    //  * @param _operator The address acting on behalf of the owner
    //  * @return approved_ True if `_operator` is an approved duck interaction operator, false otherwise
    //  */
    // function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_) {
    //     approved_ = LibAppStorage.diamondStorage().petOperators[_owner][_operator];
    // }

    /**
     * @notice Securely transfer ownership of an NFT.
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _duckId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint64 _duckId, bytes calldata _data) external {
        address sender = _msgSender();
        LibDuck.internalTransferFrom(sender, _from, _to, _duckId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _duckId, _data);
    }

    /**
     * @notice Batch transfer multiple NFTs securely.
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for all NFTs.
     * @param _from The current owner of the NFTs.
     * @param _to The new owner.
     * @param _duckIds An array of NFT identifiers to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeBatchTransferFrom(address _from, address _to, uint64[] calldata _duckIds, bytes calldata _data)
        external
    {
        address sender = _msgSender();
        for (uint256 index = 0; index < _duckIds.length; index++) {
            uint64 _tokenId = _duckIds[index];
            LibDuck.internalTransferFrom(sender, _from, _to, _tokenId);
            LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);
        }
    }

    /**
     * @notice Securely transfer ownership of an NFT.
     * @dev Identical to the other function, but without the `_data` parameter (sets data to "").
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _duckId The NFT to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint64 _duckId) external {
        address sender = _msgSender();
        LibDuck.internalTransferFrom(sender, _from, _to, _duckId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _duckId, "");
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _duckId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint64 _duckId) external {
        LibDuck.internalTransferFrom(_msgSender(), _from, _to, _duckId);
    }

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address
     * @param _approved The new approved NFT controller
     * @param _duckId The NFT to approve
     */
    function approve(address _approved, uint64 _duckId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = s.ducks[_duckId].owner;
        require(owner == _msgSender() || s.operators[owner][_msgSender()], "ERC721: Not owner or operator of token.");
        s.approved[_duckId] = _approved;
        emit LibERC721.Approval(owner, _approved, _duckId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        LibAppStorage.diamondStorage().operators[_msgSender()][_operator] = _approved;
        emit LibERC721.ApprovalForAll(_msgSender(), _operator, _approved);
    }

    // function setPetOperatorForAll(address _operator, bool _approved) external {

    /**
     * @notice Get the name of the token collection
     * @return The name of the token collection
     */
    function name() external view returns (string memory) {
        return LibAppStorage.diamondStorage().name;
    }

    /**
     * @notice Get the symbol of the token collection
     * @return The symbol of the token collection
     */
    function symbol() external view returns (string memory) {
        return LibAppStorage.diamondStorage().symbol;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset
     * @dev Throws if `_tokenId` is not a valid NFT
     * @param _tokenId The identifier for an NFT
     * @return The URI string for the given token ID
     */
    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        return LibString.strWithUint("https://app.quack.com/metadata/ducks/", _tokenId);
    }
}
