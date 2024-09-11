// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import {NUMERIC_TRAITS_NUM} from "../shared/Structs_Ducks.sol";

library LibMaths {
    //Calculates the base rarity score, including collateral modifier
    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits)
        internal
        pure
        returns (uint256 _rarityScore)
    {
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = _numericTraits[i];
            if (number >= 50) {
                _rarityScore += uint256(number) + 1;
            } else {
                _rarityScore += uint256(int256(100) - number);
            }
        }
    }

    function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _numericTraits)
        internal
        pure
        returns (uint256 multiplier)
    {
        uint256 rarityScore = baseRarityScore(_numericTraits);
        if (rarityScore < 300) return 10;
        else if (rarityScore >= 300 && rarityScore < 450) return 10;
        else if (rarityScore >= 450 && rarityScore <= 525) return 25;
        else if (rarityScore >= 526 && rarityScore <= 580) return 100;
        else if (rarityScore >= 581) return 1000;
    }

    /// @notice Generates numeric traits for a duck based on a random number, modifiers, and cycle ID
    /// @dev Different algorithms are used for Cycle 1 and other cycles to create varied trait distributions
    /// @param _randomNumber A seed used to generate random trait values
    /// @param _modifiers An array of modifiers to adjust the base trait values
    /// @param _cycleId Determines which algorithm to use for trait generation
    /// @return numericTraits_ An array of numeric traits for the duck
    function toNumericTraits(uint256 _randomNumber, int16[NUMERIC_TRAITS_NUM] memory _modifiers, uint256 _cycleId)
        internal
        pure
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_)
    {
        if (_cycleId == 1) {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value /= 2;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        } else {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value = value - 100;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
