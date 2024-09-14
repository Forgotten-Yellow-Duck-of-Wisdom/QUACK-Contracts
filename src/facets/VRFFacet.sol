// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {DuckStatusType} from "../shared/Structs_Ducks.sol";
import {VRFExtraArgsV1} from "../shared/Structs.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";

contract VrfFacet is AccessControl {
    event OpenEggs(uint256[] _tokenIds);
    event EggOpened(uint256 indexed tokenId);
    event RequestSent(uint256 requestId, uint32 numWords);

    function getVRFRequestPrice() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit, s.vrfNumWords);
    }

    function openEggs(uint256[] calldata _tokenIds) external payable {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = _msgSender();
        uint256 requestPrice = s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit, s.vrfNumWords);
        require(msg.value >= requestPrice * _tokenIds.length, "VRFFacet: Not enough native funds for chainlink VRF");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(s.ducks[tokenId].status == DuckStatusType.CLOSED_EGGS, "VRFFacet: Eggs is not closed");
            require(owner == s.ducks[tokenId].owner, "VRFFacet: Only duck owner can open an egg");
            require(s.ducks[tokenId].locked == false, "VRFFacet: Can't open eggs when it is locked");
            requestRandomWords(tokenId, requestPrice);
        }
        emit OpenEggs(_tokenIds);
    }

    function requestRandomWords(uint256 _tokenId, uint256 _requestPrice) internal returns (uint256 requestId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ducks[_tokenId].status = DuckStatusType.VRF_PENDING;
        bytes memory extraArgs = abi.encodeWithSelector(bytes4(keccak256("VRF ExtraArgsV1")), VRFExtraArgsV1(true));
        requestId = s.chainlink_vrf_wrapper.requestRandomWordsInNative{value: _requestPrice}(
            s.vrfCallbackGasLimit, s.vrfRequestConfirmations, s.vrfNumWords, extraArgs
        );

        // s.vrfRequests[requestId] = RequestStatus({
        //     paid: requestPrice,
        //     randomWords: new uint256[](0),
        //     fulfilled: false
        // });
        // s.vrfRequestIds.push(requestId);
        s.vrfRequestIdToTokenId[requestId] = _tokenId;
        
        // FOR TESTING PURPOSE ONLY 
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1;
        testCompleteVRF(requestId, randomWords);

        emit RequestSent(requestId, s.vrfNumWords);
        return requestId;
    }

    function testCompleteVRF(uint256 _requestId, uint256[] memory _randomWords) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];
        require(s.ducks[tokenId].status == DuckStatusType.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[tokenId].status = DuckStatusType.OPEN_EGG;
        s.eggIdToRandomNumber[tokenId] = _randomWords[0];

        emit EggOpened(tokenId);
    }

    //   /**
    //    * @notice rawFulfillRandomWords handles the VRF V2 wrapper response.
    //    *
    //    * @param _requestId is the VRF V2 request ID.
    //    * @param _randomWords is the randomness result.
    //    */
    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_msgSender() == address(s.chainlink_vrf_wrapper), "only VRF V2 Plus wrapper can fulfill");
        // s.vrfRequests[_requestId].fulfilled = true;
        // s.vrfRequests[_requestId].randomWords = _randomWords;
        uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];
        require(s.ducks[tokenId].status == DuckStatusType.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[tokenId].status = DuckStatusType.OPEN_EGG;
        s.eggIdToRandomNumber[tokenId] = _randomWords[0];

        emit EggOpened(tokenId);
    }

    receive() external payable {}
}
