// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, DuckInfoMemory} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * @title Duck Facet
 * @dev ERC721 implementation representing user-owned digital ducks
 */
contract DuckFacet is AccessControl {
    /**
     * @notice Retrieve the total quantity of minted NFTs
     * @return totalSupply_ The aggregate count of all NFTs ever created
     */
    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = s.duckIds.length;
    }

    /**
     * @notice Enumerate NFTs assigned to a specific owner
     * @dev Throws an exception for queries about the zero address
     * @param _owner The address of the NFT holder
     * @return balance_ The quantity of NFTs owned by the specified address
     */
    function balanceOf(address _owner) external view returns (uint256 balance_) {
        require(_owner != address(0), "DuckFacet: _owner can't be address(0)");
        balance_ = s.ownerDuckIds[_owner].length;
    }

    /**
     * @notice Fetch comprehensive information about a specific NFT
     * @param _tokenId The unique identifier of the NFT
     * @return duckInfo_ A struct encapsulating all relevant details of the NFT
     */
    function getDuckInfo(uint256 _tokenId) external view returns (DuckInfoMemory memory duckInfo_) {
        duckInfo_ = LibDuck.getDuckInfo(_tokenId);
    }

    /**
     * @notice Retrieve the timestamp when an NFT was claimed
     * @dev Returns zero for unclaimed portals
     * @param _tokenId The unique identifier of the NFT
     * @return claimTime_ The Unix timestamp of the NFT's claim
     */
    function duckClaimTime(uint256 _tokenId) external view returns (uint256 claimTime_) {
        claimTime_ = s.ducks[_tokenId].claimTime;
    }

    /**
     * @notice Enumerate valid NFTs by index
     * @dev Throws if `_index` is greater than or equal to `totalSupply()`
     * @param _index A number less than the total supply
     * @return tokenId_ The unique identifier of the NFT at the specified index
     */
    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId_) {
        require(_index < s.duckIds.length, "DuckFacet: index beyond supply");
        tokenId_ = s.duckIds[_index];
    }

    /**
     * @notice List NFTs owned by an address, indexed by position
     * @dev Throws for invalid indices or zero address queries
     * @param _owner The address of interest
     * @param _index A number less than the owner's balance
     * @return tokenId_ The unique identifier of the NFT at the specified position in the owner's collection
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId_) {
        require(_index < s.ownerDuckIds[_owner].length, "DuckFacet: index beyond owner balance");
        tokenId_ = s.ownerDuckIds[_owner][_index];
    }

    /**
     * @notice Fetch all NFT identifiers owned by a specific address
     * @param _owner The address to query
     * @return tokenIds_ An array of unique identifiers for each owned NFT
     */
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_) {
        tokenIds_ = s.ownerDuckIds[_owner];
    }

    /**
     * @notice Retrieve detailed information for all NFTs owned by an address
     * @param _owner The address to query
     * @return ducksInfos_ An array of structs, each containing comprehensive details of an owned NFT
     */
    function allDucksInfosOfOwner(address _owner) external view returns (DuckInfoMemory[] memory ducksInfos_) {
        uint256 length = s.ownerDuckIds[_owner].length;
        ducksInfos_ = new DuckInfoMemory[](length);
        for (uint256 i; i < length; i++) {
            ducksInfos_[i] = LibDuck.getDuckInfo(s.ownerDuckIds[_owner][i]);
        }
    }

    /**
     * @notice Batch query for NFT ownership
     * @param _tokenIds An array of NFT identifiers to check
     * @return owners_ An array of addresses corresponding to the owners of the queried NFTs
     */
    function batchOwnerOf(uint256[] calldata _tokenIds) external view returns (address[] memory owners_) {
        owners_ = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owners_[i] = s.ducks[_tokenIds[i]].owner;
            require(owners_[i] != address(0), "DuckFacet: invalid _tokenId");
        }
    }

    /**
     * @notice Determine the owner of a specific NFT
     * @dev Throws for queries about invalid NFTs (those assigned to the zero address)
     * @param _tokenId The unique identifier of the NFT
     * @return owner_ The address of the NFT's current owner
     */
    function ownerOf(uint256 _tokenId) external view returns (address owner_) {
        owner_ = s.ducks[_tokenId].owner;
        require(owner_ != address(0), "DuckFacet: invalid _tokenId");
    }

    /**
     * @notice Fetch the approved address for a single NFT
     * @dev Throws if the NFT doesn't exist
     * @param _tokenId The NFT to find the approved address for
     * @return approved_ The currently approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address approved_) {
        require(_tokenId < s.duckIds.length, "ERC721: tokenId is invalid");
        approved_ = s.approved[_tokenId];
    }

    /**
     * @notice Check if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = s.operators[_owner][_operator];
    }

    /**
     * @notice Verify if an address is authorized to interact with ducks on behalf of another address
     * @param _owner The address of the duck owner
     * @param _operator The address acting on behalf of the owner
     * @return approved_ True if `_operator` is an approved duck interaction operator, false otherwise
     */
    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = s.petOperators[_owner][_operator];
    }

    /**
     * @notice Securely transfer ownership of an NFT
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        address sender = _msgSender();
        LibDuck.internalTransferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);
    }

    /**
     * @notice Batch transfer multiple NFTs securely
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for all NFTs
     * @param _from The current owner of the NFTs
     * @param _to The new owner
     * @param _tokenIds An array of NFT identifiers to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds, bytes calldata _data)
        external
    {
        address sender = _msgSender();
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 _tokenId = _tokenIds[index];
            LibDuck.internalTransferFrom(sender, _from, _to, _tokenId);
            LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);
        }
    }

    /**
     * @notice Securely transfer ownership of an NFT
     * @dev Identical to the other function, but with no data parameter (sets data to "")
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        address sender = _msgSender();
        LibDuck.internalTransferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, "");
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        LibDuck.internalTransferFrom(_msgSender(), _from, _to, _tokenId);
    }

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external {
        address owner = s.ducks[_tokenId].owner;
        require(owner == _msgSender() || s.operators[owner][_msgSender()], "ERC721: Not owner or operator of token.");
        s.approved[_tokenId] = _approved;
        emit LibERC721.Approval(owner, _approved, _tokenId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        s.operators[_msgSender()][_operator] = _approved;
        emit LibERC721.ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
     * @notice Get the name of the token collection
     * @return The name of the token collection
     */
    function name() external view returns (string memory) {
        return s.name;
    }

    /**
     * @notice Get the symbol of the token collection
     * @return The symbol of the token collection
     */
    function symbol() external view returns (string memory) {
        return s.symbol;
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
