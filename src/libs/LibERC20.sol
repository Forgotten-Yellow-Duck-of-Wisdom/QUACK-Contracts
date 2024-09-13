// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import "../interfaces/IERC20.sol";

library LibERC20 {
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory returndata) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success, "LibERC20: transferFrom failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "LibERC20: transferFrom did not succeed");
        }
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory returndata) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success, "LibERC20: transfer failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "LibERC20: transfer did not succeed");
        }
    }
}
