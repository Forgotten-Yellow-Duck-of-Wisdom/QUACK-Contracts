// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {Cycle, DuckInfoMemory} from "../shared/Structs_Ducks.sol";
import {LibDuck} from "../libs/LibDuck.sol";
import {IDuckFacet} from "../interfaces/IDuckFacet.sol";
import {AccessControl} from "../shared/AccessControl.sol";
import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {LibERC721} from "../libs/LibERC721.sol";
import {LibString} from "../libs/LibString.sol";

/**
 * Protocol Admin Facet - 
 */
contract AdminFacet is AccessControl {

}
