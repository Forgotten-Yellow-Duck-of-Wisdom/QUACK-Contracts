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
        address _essencesTokenAddress,
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

        s.name = "Duck Game";
        s.symbol = "DUCK";
        s.description = "Duck Game";
        // TODO: setup base uri for ducks
        s.baseUri = "https://duck.game/ducks/";
        // TODO: setup base uri for items
        s.itemsBaseUri = "https://duck.game/items/";

        s.quackTokenAddress = _quackTokenAddress;
        s.essencesTokenAddress = _essencesTokenAddress;
        s.treasuryAddress = _treasuryAddress;
        s.farmingAddress = _farmingAddress;
        s.daoAddress = _daoAddress;

        s.chainlink_vrf_wrapper = VRFV2PlusWrapperInterface(_chainlinkVrfWrapper);
        s.vrfCallbackGasLimit = _vrfCallbackGasLimit;
        s.vrfRequestConfirmations = _vrfRequestConfirmations;
        s.vrfNumWords = _vrfNumWords;

        // Initialize XP Table

        s.MAX_LEVEL = 100;

        uint16[100] memory XP_TABLE = [
            /// NON CUMULATIVE XP REQUIRED TO REACH LEVEL
            246, //0
            271, //1
            296, //2
            320, //3
            345, //4
            369, //5
            393, //6
            425, //7
            442, //8
            466, //9
            481, //10
            516, //11
            534, //12
            585, //13
            591, //14
            614, //15
            642, //16
            665, //17
            688, //18
            716, //19
            730, //20
            748, //21
            817, //22
            816, //23
            829, //24
            857, //25
            878, //26
            898, //27
            920, //28
            947, //29
            977, //30
            1080, //31
            1038, //32
            1042, //33
            1086, //34
            1117, //35
            1082, //36
            1150, //37
            1172, //38
            1210, //39
            1204, //40
            1266, //41
            1330, //42
            1324, //43
            1312, //44
            1405, //45
            1398, //46
            1404, //47
            1382, //48
            1382, //49
            1870, //50
            2023, //51
            2065, //52
            2240, //53
            2328, //54
            2431, //55
            2514, //56
            2614, //57
            2735, //58
            2805, //59
            3989, //60
            4025, //61
            4209, //62
            4397, //63
            4693, //64
            5008, //65
            5245, //66
            5241, //67
            5702, //68
            5770, //69
            6356, //70
            6247, //71
            6694, //72
            6931, //73
            7225, //74
            7713, //75
            7365, //76
            7545, //77
            8686, //78
            8899, //79
            8020, //80
            8720, //81
            9110, //82
            9180, //83
            9680, //84
            9830, //85
            10410, //86
            9780, //87
            10190, //88
            10700, //89
            11210, //90
            12200, //91
            11500, //92
            11500, //93
            11380, //94
            12660, //95
            12840, //96
            12570, //97
            13040, //98
            27610 //99
            /// CUMULATIVE XP REQUIRED TO REACH LEVEL
            // 246,       //1
            // 517,       //2
            // 813,       //3
            // 1133,      //4
            // 1478,      //5
            // 1847,      //6
            // 2240,      //7
            // 2665,      //8
            // 3107,      //9
            // 3573,      //10
            // 4054,      //11
            // 4570,      //12
            // 5104,      //13
            // 5689,      //14
            // 6280,      //15
            // 6894,      //16
            // 7536,      //17
            // 8201,      //18
            // 8889,      //19
            // 9605,      //20
            // 10335,     //21
            // 11083,     //22
            // 11900,     //23
            // 12716,     //24
            // 13545,     //25
            // 14402,     //26
            // 15280,     //27
            // 16178,     //28
            // 17098,     //29
            // 18045,     //30
            // 19022,     //31
            // 20102,     //32
            // 21140,     //33
            // 22182,     //34
            // 23268,     //35
            // 24385,     //36
            // 25467,     //37
            // 26616,     //38
            // 27788,     //39
            // 28998,     //40
            // 30202,     //41
            // 31468,     //42
            // 32798,     //43
            // 34122,     //44
            // 35434,     //45
            // 36839,     //46
            // 38237,     //47
            // 39641,     //48
            // 41023,     //49
            // 42405,     //50
            // 44275,     //51
            // 46298,     //52
            // 48363,     //53
            // 50603,     //54
            // 52931,     //55
            // 55362,     //56
            // 57876,     //57
            // 60490,     //58
            // 63225,     //59
            // 66030,     //60
            // 70019,     //61
            // 74044,     //62
            // 78253,     //63
            // 82650,     //64
            // 87343,     //65
            // 92351,     //66
            // 97596,     //67
            // 102837,    //68
            // 108539,    //69
            // 114309,    //70
            // 120665,    //71
            // 126912,    //72
            // 133606,    //73
            // 140537,    //74
            // 147762,    //75
            // 155475,    //76
            // 162840,    //77
            // 170385,    //78
            // 179071,    //79
            // 187970,    //80
            // 195990,    //81
            // 204710,    //82
            // 213820,    //83
            // 223000,    //84
            // 232680,    //85
            // 242510,    //86
            // 252920,    //87
            // 262700,    //88
            // 272890,    //89
            // 283590,    //90
            // 294800,    //91
            // 307000,    //92
            // 318500,    //93
            // 330000,    //94
            // 341380,    //95
            // 354040,    //96
            // 366880,    //97
            // 379350,    //98
            // 392390,    //99
            // 420000     //100
        ];

        for (uint16 i = 0; i < s.MAX_LEVEL; i++) {
            s.XP_TABLE[i] = XP_TABLE[i];
        }

        emit InitializeDiamond(msg.sender);
    }
}
