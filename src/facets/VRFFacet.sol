// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {DuckStatusType} from "../shared/Structs_Ducks.sol";
import {VRFExtraArgsV1} from "../shared/Structs.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";

contract VrfFacet is AccessControl {


    function getVRFRequestPrice() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.chainlink_vrf_wrapper.calculateRequestPriceNative(s.vrfCallbackGasLimit, s.vrfNumWords);
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
