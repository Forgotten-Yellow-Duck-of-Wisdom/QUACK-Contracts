// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import "../interfaces/IERC20.sol";

library LibERC20 {
    function _callOptionalReturn(address token, bytes memory data) private {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        require(size > 0, "LibERC20: call to non-contract");

        (bool success, bytes memory returndata) = token.call(data);
        if (!success) {
            if (returndata.length > 0) {
                // Bubble up the revert reason from the call
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("LibERC20: low-level call failed");
            }
        }
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "LibERC20: operation did not succeed");
        }
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        require(to != address(0), "LibERC20: transfer to the zero address");
        _callOptionalReturn(token, abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    }
}
