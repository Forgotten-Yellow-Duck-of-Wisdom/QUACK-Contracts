// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {MetaTxContextStorage, CollateralTypeInfo} from "../shared/Structs.sol";
import {Cycle, DuckInfo} from "../shared/Structs_Ducks.sol";
import {ILink} from "../interfaces/ILink.sol";

uint8 constant STATUS_CLOSED_EGG = 0;
uint8 constant STATUS_VRF_PENDING = 1;
uint8 constant STATUS_OPEN_EGG = 2;
uint8 constant STATUS_DUCK = 3;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant EGG_DUCKS_NUM = 10;


struct AppStorage {
    /////////////////// Global Diamond ///////////////////
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;
    /////////////////// Global Protocol ///////////////////
    address treasuryAddress;
    address quackTokenAddress;
    /////////////////// Collateral ///////////////////
    // // address of ERC20 tokens considered as collateral
    // address[] collateralTypes;
    // // erc20 address => index in collateralType[]
    // mapping(address => uint256) collateralTypeIndexes;
    // // erc20 address => collateral info struct
    // mapping(address => CollateralTypeInfo) collateralTypeInfo;
    // // cycleId => collateral addresses[]
    // mapping(uint256 => address[]) cycleCollateralTypes;

    /////////////////// Chainlink-VRF ///////////////////
    mapping(bytes32 => uint256) vrfRequestIdToTokenId;
    mapping(bytes32 => uint256) vrfNonces;
    bytes32 keyHash;
    uint144 fee;
    address vrfCoordinator;
    ILink link;
    /////////////////// Ducks - Cycles ///////////////////
    uint16 currentCycleId;
    mapping(uint256 => Cycle) cycles;
    /////////////////// Ducks - (ERC721) ///////////////////
    // global duck collection info
    string name;
    string symbol;
    string description;
    // DB (or/and IPFS ?)
    string baseUri;
    // id equal total Duck supply
    uint256 duckIdCounter;
    uint32[] ducksIds;
    // name => current status
    mapping(string => bool) duckNamesUsed;
    mapping(uint32 => uint256) ducksRespecCount;
    mapping(uint256 => uint256) eggIdToRandomNumber;
    // token id to Duck Profile infos
    mapping(uint256 tokenId => DuckInfo) ducks;
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
