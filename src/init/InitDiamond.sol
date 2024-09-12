// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
    event InitializeDiamond(address sender);

    function init() external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.diamondInitialized) {
            revert DiamondAlreadyInitialized();
        }
        s.diamondInitialized = true;

        /*
        TODO: add custom initialization logic here
        */

        s.chainlink_vrf_wrapper = VRFV2PlusWrapperInterface(0x6168499c0cFfCaCD319c818142124B7A15E857ab);
        s.vrfCallbackGasLimit = 100000;
        s.vrfRequestConfirmations = 3;
        s.vrfNumWords = 1;

        emit InitializeDiamond(msg.sender);
    }
}
