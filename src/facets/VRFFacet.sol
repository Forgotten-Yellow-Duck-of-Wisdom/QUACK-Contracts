// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.21;

// import {DuckStatus} from "../shared/Structs_Ducks.sol";
// import {AccessControl} from "../shared/AccessControl.sol";
// import {LibAppStorage} from "../libs/LibAppStorage.sol";


// contract VrfFacet is AccessControl {
//     event VrfRandomNumber(uint256 indexed tokenId, uint256 randomNumber, uint256 _vrfTimeSet);
//     event OpenPortals(uint256[] _tokenIds);
//     event PortalOpened(uint256 indexed tokenId);

		
//     function linkBalance() external view returns (uint256 linkBalance_) {
//         linkBalance_ = s.link.balanceOf(address(this));
//     }

//     function vrfCoordinator() external view returns (address) {
//         return s.vrfCoordinator;
//     }

//     function link() external view returns (address) {
//         return address(s.link);
//     }

//     function keyHash() external view returns (bytes32) {
//         return s.keyHash;
//     }
//     function openPortals(uint256[] calldata _tokenIds) external {
//         address owner = _msgSender();
//         for (uint256 i; i < _tokenIds.length; i++) {
//             uint256 tokenId = _tokenIds[i];
//             require(s.ducks[tokenId].status == DuckStatus.CLOSED_EGG, "VRFFacet: Portal is not closed");
//             require(owner == s.ducks[tokenId].owner, "VRFFacet: Only duck owner can open a portal");
//             require(s.ducks[tokenId].locked == false, "VRFFacet: Can't open portal when it is locked");
//             drawRandomNumber(tokenId);
// 						// TODO: wip duck marketplace 
//             // LibERC721Marketplace.cancelERC721Listing(address(this), tokenId, owner);
//         }
//         emit OpenPortals(_tokenIds);
//     }

//     function drawRandomNumber(uint256 _tokenId) internal {
//         s.ducks[_tokenId].status = DuckStatus.VRF_PENDING;
//         uint256 fee = s.fee;
//         require(s.link.balanceOf(address(this)) >= fee, "VrfFacet: Not enough LINK");
//         bytes32 l_keyHash = s.keyHash;
//         require(s.link.transferAndCall(s.vrfCoordinator, fee, abi.encode(l_keyHash, 0)), "VrfFacet: link transfer failed");
//         uint256 vrfSeed = uint256(keccak256(abi.encode(l_keyHash, 0, address(this), s.vrfNonces[l_keyHash])));
//         s.vrfNonces[l_keyHash]++;
//         bytes32 requestId = keccak256(abi.encodePacked(l_keyHash, vrfSeed));
//         s.vrfRequestIdToTokenId[requestId] = _tokenId;
//         // for testing
//         tempFulfillRandomness(requestId, uint256(keccak256(abi.encodePacked(block.number, _tokenId))));
//     }

//     // for testing purpose only
//     function tempFulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal {
//         // console.log("bytes");
//         // console.logBytes32(_requestId);
//         //_requestId; // mentioned here to remove unused variable warning

//         uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];

//         // console.log("token id:", tokenId);

//         // require(_msgSender() == im_vrfCoordinator, "Only VRFCoordinator can fulfill");
//         require(s.ducks[tokenId].status == DuckStatus.VRF_PENDING, "VrfFacet: VRF is not pending");
//         s.ducks[tokenId].status = DuckStatus.OPEN_EGG;
//         s.tokenIdToRandomNumber[tokenId] = _randomNumber;

//         emit PortalOpened(tokenId);
//         emit VrfRandomNumber(tokenId, _randomNumber, block.timestamp);
//     }

//     /**
//      * @notice fulfillRandomness handles the VRF response. Your contract must
//      * @notice implement it.
//      *
//      * @dev The VRFCoordinator expects a calling contract to have a method with
//      * @dev this signature, and will trigger it once it has verified the proof
//      * @dev associated with the randomness (It is triggered via a call to
//      * @dev rawFulfillRandomness, below.)
//      *
//      * @param _requestId The Id initially returned by requestRandomness
//      * @param _randomNumber the VRF output
//      */
//     function rawFulfillRandomness(bytes32 _requestId, uint256 _randomNumber) external {
//         uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];

//         require(_msgSender() == s.vrfCoordinator, "Only VRFCoordinator can fulfill");

//         require(s.ducks[tokenId].status == DuckStatus.VRF_PENDING, "VrfFacet: VRF is not pending");
//         s.ducks[tokenId].status = DuckStatus.OPEN_EGG;
//         s.tokenIdToRandomNumber[tokenId] = _randomNumber;

//         emit PortalOpened(tokenId);
//         emit VrfRandomNumber(tokenId, _randomNumber, block.timestamp);
//     }

//     ///@notice Allow the duck diamond owner to change the vrf details
//     //@param _newFee New VRF fee (in LINK)
//     //@param _keyHash New keyhash
//     //@param _vrfCoordinator The new vrf coordinator address
//     //@param _link New LINK token contract address
//     function changeVrf(
//         uint256 _newFee,
//         bytes32 _keyHash,
//         address _vrfCoordinator,
//         address _link
//     ) external onlyOwner {
//         if (_newFee != 0) {
//             s.fee = uint96(_newFee);
//         }
//         if (_keyHash != 0) {
//             s.keyHash = _keyHash;
//         }
//         if (_vrfCoordinator != address(0)) {
//             s.vrfCoordinator = _vrfCoordinator;
//         }
//         if (_link != address(0)) {
//             s.link = ILink(_link);
//         }
//     }

//     // Remove the LINK tokens from this contract that are used to pay for VRF random number fees
//     function removeLinkTokens(address _to, uint256 _value) external onlyOwner {
//         s.link.transfer(_to, _value);
//     }
// }
