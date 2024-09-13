// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
    event InitializeDiamond(address sender);

    function init(
        address _quackTokenAddress,
        address _treasuryAddress,
        address _farmingAddress,
        address _daoAddress,
        address _chainlinkVrfWrapper,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations,
        uint32 _vrfNumWords
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.diamondInitialized) {
            revert DiamondAlreadyInitialized();
        }
        s.diamondInitialized = true;

        /*
        TODO: add custom initialization logic here
        */

        s.quackTokenAddress = _quackTokenAddress;
        s.treasuryAddress = _treasuryAddress;
        s.farmingAddress = _farmingAddress;
        s.daoAddress = _daoAddress;

        s.chainlink_vrf_wrapper = VRFV2PlusWrapperInterface(_chainlinkVrfWrapper);
        s.vrfCallbackGasLimit = _vrfCallbackGasLimit;
        s.vrfRequestConfirmations = _vrfRequestConfirmations;
        s.vrfNumWords = _vrfNumWords;

        emit InitializeDiamond(msg.sender);
    }
}
