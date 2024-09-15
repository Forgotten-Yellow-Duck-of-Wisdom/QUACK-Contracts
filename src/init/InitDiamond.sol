// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";
import {AccessControl} from "../shared/AccessControl.sol";

error DiamondAlreadyInitialized();

contract InitDiamond is AccessControl {
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

        // Initialize XP Table
        initializeXPTable(s);

        emit InitializeDiamond(msg.sender);
    }

    /**
     * @notice Initializes the XP_TABLE in storage based on exponential growth factors.
     * @param s The storage reference from AppStorage.
     */
    function initializeXPTable(AppStorage storage s) internal {
        uint256 MAX_LEVEL = 100;
        uint256 LEVEL_50_XP = 1_000_000;
        uint256 LEVEL_100_XP = 100_000_000;

        s.MAX_LEVEL = MAX_LEVEL;
        s.LEVEL_50_XP = LEVEL_50_XP;
        s.LEVEL_100_XP = LEVEL_100_XP;

        uint256[] memory tempXpTable = new uint256[](MAX_LEVEL + 1);
        tempXpTable[0] = 0;

        // Fixed-point scaling factor (1e18 for precision)
        uint256 SCALE = 1e18;

        // Define base multipliers in fixed-point (e.g., 1.15 = 115 * 1e16)
    uint256 baseMultiplier115 = 115 * 1e16; // Represents 1.15 with 18 decimals
     uint256 baseMultiplier120 = 120 * 1e16; // Represents 1.20 with 18 decimals

        // Calculate XP for levels 1-50 with exponential growth factor 1.15
        for (uint8 level = 1; level <= 50; level++) {
            if (level == 1) {
                tempXpTable[level] = 100;
            } else {
                uint256 previousXp = tempXpTable[level - 1];
                uint256 xp = (previousXp * baseMultiplier115) / SCALE;
                tempXpTable[level] = xp;
            }
        }

        // Calculate XP for levels 51-100 with exponential growth factor 1.20
        for (uint8 level = 51; level <= MAX_LEVEL; level++) {
            if (level == 51) {
                tempXpTable[level] = LEVEL_50_XP;
            } else {
                uint256 previousXp = tempXpTable[level - 1];
                uint256 xp = (previousXp * baseMultiplier120) / SCALE;
                tempXpTable[level] = xp;
            }
        }

        // Compute cumulative XP
        uint256 cumulativeXP = 0;
        for (uint8 level = 1; level <= MAX_LEVEL; level++) {
            cumulativeXP += tempXpTable[level];
            tempXpTable[level] = cumulativeXP;
        }

        // Calculate scaling factor to set level 100 XP to LEVEL_100_XP
        uint256 originalLevel100XP = tempXpTable[MAX_LEVEL];
        uint256 scaleFactor = (LEVEL_100_XP * SCALE) / originalLevel100XP;

        // Apply scaling factor to all levels
        for (uint8 level = 1; level <= MAX_LEVEL; level++) {
            tempXpTable[level] = (tempXpTable[level] * scaleFactor) / SCALE;
        }

        // Assign the calculated XP values to storage XP_TABLE
        for (uint8 level = 1; level <= MAX_LEVEL; level++) {
            s.XP_TABLE[level] = tempXpTable[level];
        }
    }
}
