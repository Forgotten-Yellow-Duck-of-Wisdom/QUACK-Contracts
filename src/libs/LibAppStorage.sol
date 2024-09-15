// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {MetaTxContextStorage, CollateralTypeInfo} from "../shared/Structs.sol";
import {Cycle, DuckInfo} from "../shared/Structs_Ducks.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";

struct AppStorage {
    /////////////////// Global Diamond ///////////////////
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;
    //
    /////////////////// Global Protocol ///////////////////
    //
    address quackTokenAddress;
    address treasuryAddress;
    address farmingAddress;
    address daoAddress;
    // Using 0x000000000000000000000000000000000000dEaD  as burn address.
    //
    /////////////////// Collateral ///////////////////
    //
    // address of ERC20 tokens considered as collateral
    address[] collateralTypes;
    // erc20 address => index in collateralType[]
    mapping(address => uint256) collateralTypeIndexes;
    // erc20 address => collateral info struct
    mapping(address => CollateralTypeInfo) collateralTypeInfo;
    // cycleId => collateral addresses[]
    mapping(uint256 => address[]) cycleCollateralTypes;
    //
    /////////////////// Chainlink-VRF ///////////////////
    //
    /// NEW VRF 2.5
    // @dev: unused atm, vrf used directly in duck struct/character
    // mapping(uint256 => VRFRequest) vrfRequests;
    // uint256[] vrfRequestIds;
    VRFV2PlusWrapperInterface chainlink_vrf_wrapper;
    mapping(uint256 => uint256) vrfRequestIdToTokenId;
    uint32 vrfCallbackGasLimit;
    uint16 vrfRequestConfirmations;
    uint32 vrfNumWords;
    //
    /////////////////// Ducks - Cycles ///////////////////
    //
    uint16 currentCycleId;
    mapping(uint256 => Cycle) cycles;
    //
    /////////////////// Ducks - (ERC721) ///////////////////
    //
    // Ducks XP 
    uint256 MAX_LEVEL;
    uint256 LEVEL_60_XP;
    uint256 LEVEL_100_XP;
    uint256[101] XP_TABLE;
    // global duck collection info
    string name;
    string symbol;
    string description;
    // DB (or/and IPFS ?)
    string baseUri;
    // id equal total Duck supply
    uint32 duckIdCounter;
    uint32[] duckIds;
    mapping(uint256 => uint256) duckIdIndexes;
    // name => current status
    mapping(string => bool) duckNamesUsed;
    mapping(uint32 => uint256) duckRespecCount;
    mapping(uint256 => uint256) eggIdToRandomNumber;
    // token id => Duck Profile struct infos
    mapping(uint256 => DuckInfo) ducks;
    // Mapping owner address => all possessed duck token id
    mapping(address => uint32[]) ownerDuckIds;
    mapping(address => mapping(uint256 => uint256)) ownerDuckIdIndexes;
    mapping(uint256 => address) approved;
    mapping(address => mapping(address => bool)) operators;
    //Pet operators for a token
    mapping(address => mapping(address => bool)) petOperators;
}

/////////////////// Item Factory - (ERC1155) ///////////////////

/////////////////// Composable NFT - (EIP998) ///////////////////

/////////////////// MarketPlace - (ERC721) ///////////////////

/////////////////// MarketPlace - (ERC1155) ///////////////////

/////////////////// MarketPlace - (EIP998) ///////////////////

/*
    NOTE: Once contracts have been deployed you cannot modify the existing entries here. You can only append 
    new entries. Otherwise, any subsequent upgrades you perform will break the memory structure of your 
    deployed contracts.
    */

library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
