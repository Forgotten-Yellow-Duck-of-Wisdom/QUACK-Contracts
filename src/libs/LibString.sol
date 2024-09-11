// SPDX-License-Identifier: MIT
// Source: // https://gist.github.com/AlmostEfficient/669ac250214f30347097a1aeedcdfa12
pragma solidity >=0.8.21;

library LibString {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function len(string memory s) internal pure returns (uint256) {
        uint256 length;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (length = 0; i < bytelength; length++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return length;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }

    function validateAndLowerName(string memory _name) internal pure returns (string memory) {
        bytes memory name = abi.encodePacked(_name);
        uint256 len = name.length;
        require(len != 0, "LibString: name can't be 0 chars");
        require(len < 26, "LibString: name can't be greater than 25 characters");
        uint256 char = uint256(uint8(name[0]));
        require(char != 32, "LibString: first char of name can't be a space");
        char = uint256(uint8(name[len - 1]));
        require(char != 32, "LibString: last char of name can't be a space");
        for (uint256 i; i < len; i++) {
            char = uint256(uint8(name[i]));
            require(char > 31 && char < 127, "LibString: invalid character in Duck name.");
            if (char < 91 && char > 64) {
                name[i] = bytes1(uint8(char + 32));
            }
        }
        return string(name);
    }
}
