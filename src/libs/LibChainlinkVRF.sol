// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import {DuckStatusType} from "../shared/Structs_Ducks.sol";
import {VRFExtraArgsV1} from "../shared/Structs.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {LibDuck} from "./LibDuck.sol";

library LibChainlinkVRF {
    event RequestSent(uint256 requestId, uint32 numWords);

    // TODO : update requestRandomWords to receive a VRFExtraArgsV1 struct and handle different kind of VRF results
    function requestRandomWords(uint64 _duckId, uint256 _requestPrice) internal returns (uint256 requestId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ducks[_duckId].status = DuckStatusType.VRF_PENDING;
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
        s.vrfRequestIdToDuckId[requestId] = _duckId;

        // START - FOR TESTING PURPOSE ONLY
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1;
        LibDuck.openEggWithVRF(requestId, randomWords);
        // REMOVE FOR DEPLOYMENT - END

        emit RequestSent(requestId, s.vrfNumWords);
        return requestId;
    }

    // TODO : update handleVRFResult to receive different kind of VRF results and assign incoming request to the right action
    function handleVRFResult(uint256 _requestId, uint256[] memory _randomWords, address _sender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_sender == address(s.chainlink_vrf_wrapper), "only VRF V2 Plus wrapper can fulfill");

        // s.vrfRequests[_requestId].fulfilled = true;
        // s.vrfRequests[_requestId].randomWords = _randomWords;
        LibDuck.openEggWithVRF(_requestId, _randomWords);
    }
}
