// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {NUMERIC_TRAITS_NUM} from "./Structs_Ducks.sol";

struct MetaTxContextStorage {
    address trustedForwarder;
}

struct RevenueSharesDTO {
    address burnAddress;
    address daoAddress;
    address farming;
    address codHash;
}

struct CollateralTypeInfo {
    // treated as an arary of int8
    //Trait modifiers for each collateral. Can be 2, 1, -1, or -2
    int16[NUMERIC_TRAITS_NUM] modifiers;
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    // TODO: add conversion rate / dynamic collateral price
    // //Current conversionRate for the price of this collateral in relation to 1 USD. Can be updated by the DAO
    // uint16 conversionRate;
    bool delisted;
}

// @dev: unused atm, vrf used directly in duck struct/character
// struct VRFRequest {
//     uint256 paid;
//     bool fulfilled;
//     uint256[] randomWords;
// }
