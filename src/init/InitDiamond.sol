// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {console2} from "forge-std/console2.sol";

error DiamondAlreadyInitialized();

contract InitDiamond is AccessControl {
    event InitializeDiamond(address sender);

    function init(
        address _quackTokenAddress,
        address _treasuryAddress,
        address _farmingAddress,
        address _daoAddress,
        address _chainlinkVrfWrapper,
        address _gameQnGAuthorityAddress,
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
        s.gameQnGAuthorityAddress = _gameQnGAuthorityAddress;

        s.chainlink_vrf_wrapper = VRFV2PlusWrapperInterface(_chainlinkVrfWrapper);
        s.vrfCallbackGasLimit = _vrfCallbackGasLimit;
        s.vrfRequestConfirmations = _vrfRequestConfirmations;
        s.vrfNumWords = _vrfNumWords;

        // Initialize XP Table
        // initializeXPTable(s);

        s.MAX_LEVEL = 100;
        s.LEVEL_50_XP = 1800;
        s.LEVEL_100_XP = 170500;

        s.XP_TABLE = [
            100,
            210,
            330,
            460,
            600,
            750,
            910,
            1080,
            1260,
            1450,
            1650,
            1860,
            2080,
            2310,
            2550,
            2800,
            3060,
            3330,
            3610,
            3900,
            4200,
            4510,
            4830,
            5160,
            5500,
            5850,
            6210,
            6580,
            6960,
            7350,
            7750,
            8160,
            8580,
            9010,
            9450,
            9900,
            10360,
            10830,
            11310,
            11800,
            12300,
            12810,
            13330,
            13860,
            14400,
            14950,
            15510,
            16080,
            16660,
            17250,
            18000,
            18800,
            19650,
            20550,
            21500,
            22500,
            23550,
            24650,
            25800,
            27000,
            28500,
            30100,
            31800,
            33600,
            35500,
            37500,
            39600,
            41800,
            44100,
            46500,
            49000,
            51600,
            54300,
            57100,
            60000,
            63000,
            66100,
            69300,
            72600,
            76000,
            79500,
            83100,
            86800,
            90600,
            94500,
            98500,
            102600,
            106800,
            111100,
            115500,
            120000,
            124600,
            129300,
            134100,
            139000,
            144000,
            149100,
            154300,
            159600,
            165000,
            170500
        ];

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
        tempXpTable[1] = 100;

        // Fixed-point scaling factor (1e18 for precision)
        uint256 SCALE = 1e18;

        // Define base multipliers in fixed-point (e.g., 1.15 = 115 * 1e16)
        uint256 baseMultiplier115 = 115 * 1e16; // Represents 1.15 with 18 decimals
        uint256 baseMultiplier120 = 120 * 1e16; // Represents 1.20 with 18 decimals

        // Calculate XP for levels 1-50 with exponential growth factor 1.15
        for (uint8 level = 2; level <= 50; level++) {
            uint256 previousXp = tempXpTable[level - 1];
            console2.log("Previous XP:", previousXp);
            uint256 xp = (previousXp * baseMultiplier115) / SCALE;
            console2.log("XP for level", level, ":", xp);
            tempXpTable[level] = xp;
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
            console2.log("XP for level", level, ":", tempXpTable[level]);
            s.XP_TABLE[level] = tempXpTable[level];
        }
    }
}
