// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {DuckStatus} from "../shared/Structs_Ducks.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract VrfFacet is AccessControl, VRFV2PlusWrapperConsumerBase {
    event VrfRandomNumber(uint256 indexed tokenId, uint256 randomNumber, uint256 _vrfTimeSet);
    event OpenEggs(uint256[] _tokenIds);
    event EggsOpened(uint256 indexed tokenId);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    address public wrapperAddress;

    constructor(address _wrapperAddress) VRFV2PlusWrapperConsumerBase(_wrapperAddress) {
        wrapperAddress = _wrapperAddress;
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
        
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        );
        
        (requestId,) = requestRandomnessPayInNative(
            callbackGasLimit,
            requestConfirmations,
            numWords,
            extraArgs
        );

        s_requests[requestId] = RequestStatus({
            paid: 0,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        s.vrfRequestIdToTokenId[requestId] = _tokenId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // callback function triggered by the VRF coordinator 
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint256 tokenId = s.vrfRequestIdToTokenId[_requestId];
        require(s.ducks[tokenId].status == DuckStatus.VRF_PENDING, "VrfFacet: VRF is not pending");
        s.ducks[tokenId].status = DuckStatus.OPEN_EGG;
        s.tokenIdToRandomNumber[tokenId] = _randomWords[0];

        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
        emit EggsOpened(tokenId);
        emit VrfRandomNumber(tokenId, _randomWords[0], block.timestamp);
    }

    function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    function changeVrfParameters(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    function withdrawNative(uint256 amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "withdrawNative failed");
    }

    receive() external payable {}
}