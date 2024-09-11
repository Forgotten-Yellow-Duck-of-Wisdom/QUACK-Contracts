// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {IERC20} from "../interfaces/IERC20.sol";

contract CollateralEscrow {
    address internal owner;

    constructor(address _collateralContract) {
        owner = msg.sender;
        approveDuckDiamond(_collateralContract);
    }

    function approveDuckDiamond(address _collateralContract) public {
        require(msg.sender == owner, "CollateralEscrow: Not owner of contract");
        require(
            IERC20(_collateralContract).approve(owner, type(uint256).max),
            "CollateralEscrow: token not approved for transfer"
        );
    }
}
