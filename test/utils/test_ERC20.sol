// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract test_ERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(address to, uint256 amount, uint8 dec) ERC20("TestERC20", "T20") {
        mint(to, amount);
        _decimals = dec;
    }

    // constructor() ERC20("Test Token", "TT") {
    //   // mint(to, amount);
    //   _decimals = 6;
    // }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
