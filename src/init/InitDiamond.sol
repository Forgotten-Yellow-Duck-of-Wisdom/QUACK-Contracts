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
        s.LEVEL_50_XP = 42405;
        s.LEVEL_60_XP = 66030;
        s.LEVEL_100_XP = 420000;

        s.XP_TABLE = [
            246,       //1
            517,       //2
            813,       //3
            1133,      //4
            1478,      //5
            1847,      //6
            2240,      //7
            2665,      //8
            3107,      //9
            3573,      //10
            4054,      //11
            4570,      //12
            5104,      //13
            5689,      //14
            6280,      //15
            6894,      //16
            7536,      //17
            8201,      //18
            8889,      //19
            9605,      //20
            10335,     //21
            11083,     //22
            11900,     //23
            12716,     //24
            13545,     //25
            14402,     //26
            15280,     //27
            16178,     //28
            17098,     //29
            18045,     //30
            19022,     //31
            20102,     //32
            21140,     //33
            22182,     //34
            23268,     //35
            24385,     //36
            25467,     //37
            26616,     //38
            27788,     //39
            28998,     //40
            30202,     //41
            31468,     //42
            32798,     //43
            34122,     //44
            35434,     //45
            36839,     //46
            38237,     //47
            39641,     //48
            41023,     //49
            42405,     //50
            44275,     //51
            46298,     //52
            48363,     //53
            50603,     //54
            52931,     //55
            55362,     //56
            57876,     //57
            60490,     //58
            63225,     //59
            66030,     //60
            70019,     //61
            74044,     //62
            78253,     //63
            82650,     //64
            87343,     //65
            92351,     //66
            97596,     //67
            102837,    //68
            108539,    //69
            114309,    //70
            120665,    //71
            126912,    //72
            133606,    //73
            140537,    //74
            147762,    //75
            155475,    //76
            162840,    //77
            170385,    //78
            179071,    //79
            187970,    //80
            195990,    //81
            204710,    //82
            213820,    //83
            223000,    //84
            232680,    //85
            242510,    //86
            252920,    //87
            262700,    //88
            272890,    //89
            283590,    //90
            294800,    //91
            307000,    //92
            318500,    //93
            330000,    //94
            341380,    //95
            354040,    //96
            366880,    //97
            379350,    //98
            392390,    //99
            420000     //100
        ];

        emit InitializeDiamond(msg.sender);
    }

}
