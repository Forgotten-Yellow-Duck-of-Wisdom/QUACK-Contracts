// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract, console2} from "./utils/TestBaseContract.sol";

contract ProtocolTest is TestBaseContract {
    function setUp() public virtual override {
        super.setUp();

        // create First Duck Cycle
        cycleId = diamond.duckGameCreateCycle();
    }

    function testExample() public {
        string memory e = diamond.exampleFunction();
        assertEq(e, "Hello World!", "Invalid example function");
    }
}
