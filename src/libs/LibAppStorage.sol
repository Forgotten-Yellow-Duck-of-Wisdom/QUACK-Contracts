// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {MetaTxContextStorage, CollateralTypeInfo} from "../shared/Structs.sol";
import {Cycle, DuckInfo} from "../shared/Structs_Ducks.sol";
import {VRFV2PlusWrapperInterface} from "../interfaces/IVRFV2PlusWrapperInterface.sol";
import {ItemType} from "../shared/Structs_Items.sol";

struct AppStorage {
    /////////////////// Global Diamond ///////////////////
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;
    //
    /////////////////// Global Protocol ///////////////////
    //
    address quackTokenAddress;
    address essencesTokenAddress;
    address treasuryAddress;
    address farmingAddress;
    address daoAddress;
    mapping(address => bool) allowedGameManager;
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
    uint16 MAX_LEVEL;
    mapping(uint16 => uint256) XP_TABLE;
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
    //Pet operators for a Duck
    mapping(address => mapping(address => bool)) petOperators;
    /////////////////// Item Factory - (ERC1155) ///////////////////
    string itemsBaseUri;
    ItemType[] itemTypes;
    mapping(uint256 => address) itemTypeToTokenAddress;
    // ---- OWNER ITEMS BALANCES ----
    // owner => itemId => balance
    mapping(address => mapping(uint256 => uint256)) ownerItemBalances;
    // owner => itemIds array
    mapping(address => uint256[]) ownerItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => uint256)) ownerItemIndexes;
    // ---- NFT ITEMS BALANCES ----
    // nftAddress => nftId => tokenId => balance
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemBalances;
    // nftAddress => nftId => tokenIds array
    mapping(address => mapping(uint256 => uint256[])) nftItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemIndexes;
}

// ??

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
