// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {DuckStatus} from "../shared/Structs_Ducks.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";


contract VrfFacet is AccessControl {
    event OpenEggs(uint256[] _tokenIds);
    event EggsOpened(uint256 indexed tokenId);
    event RequestSent(uint256 requestId, uint32 numWords);


    function getVRFRequestPrice() external view returns (uint256) {
        return s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit);
    }

    // TODO : add payment in native token
    function openEggs(uint256[] calldata _tokenIds) external {
        address owner = _msgSender();
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(s.ducks[tokenId].status == DuckStatus.CLOSED_EGG, "VRFFacet: Egg is not closed");
            require(owner == s.ducks[tokenId].owner, "VRFFacet: Only duck owner can egg a portal");
            require(s.ducks[tokenId].locked == false, "VRFFacet: Can't egg portal when it is locked");
            requestRandomWords(tokenId);
        }
        emit OpenEggs(_tokenIds);
    }



    function requestRandomWords(uint256 _tokenId) internal returns (uint256 requestId) {
        s.ducks[_tokenId].status = DuckStatus.VRF_PENDING;
        

        uint256 requestPrice = s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit);
        (requestId,) = s.chainlink_vrf_wrapper.requestRandomWordsInNative{value: requestPrice}(
        s.vrfCallbackGasLimit,
        s.vrfRequestConfirmations,
        s.vrfNumWords
      );


        // s.vrfRequests[requestId] = RequestStatus({
        //     paid: requestPrice, 
        //     randomWords: new uint256[](0),
        //     fulfilled: false
        // });
        // s.vrfRequestIds.push(requestId);
        s.vrfRequestIdToTokenId[requestId] = _tokenId;

        emit RequestSent(requestId, s.vrfNumWords);
        return requestId;
    }

//   /**
//    * @notice rawFulfillRandomWords handles the VRF V2 wrapper response.
//    *
//    * @param _requestId is the VRF V2 request ID.
//    * @param _randomWords is the randomness result.
//    */
  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(_msgSender() == address(s.chainlink_vrf_wrapper), "only VRF V2 Plus wrapper can fulfill");
        // s.vrfRequests[_requestId].fulfilled = true;
        // s.vrfRequests[_requestId].randomWords = _randomWords;

        uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];
        require(s.ducks[tokenId].status == DuckStatus.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[tokenId].status = DuckStatus.OPEN_EGG;
        s.eggIdToRandomNumber[tokenId] = _randomWords[0];

        emit EggsOpened(tokenId);
  }


    receive() external payable {}
}