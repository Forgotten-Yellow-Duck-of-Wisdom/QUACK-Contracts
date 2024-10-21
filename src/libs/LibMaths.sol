// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

import {DuckCharacteristicsType, DuckStatisticsType} from "../shared/Structs_Ducks.sol";
import {CollateralTypeInfo} from "../shared/Structs.sol";
import {console2} from "forge-std/console2.sol";

library LibMaths {
    /// @notice Generates numeric traits for a duck based on a random number, modifiers, and cycle ID
    /// @dev Different algorithms are used for Cycle 1 and other cycles to create varied trait distributions
    /// @param _randomNumber A seed used to generate random trait values
    /// @param _collateralType The collateral struct with a mapping of modifiers to adjust the base trait values
    /// @param _cycleId Determines which algorithm to use for trait generation
    /// @return characteristics_ A uint uint mapping of numeric traits for the duck
    function calculateCharacteristics(
        uint256 _randomNumber,
        CollateralTypeInfo storage _collateralType,
        uint256 _cycleId
    ) internal view returns (int16[] memory characteristics_) {
        uint256 characteristicsCount = uint256(type(DuckCharacteristicsType).max) + 1;
        // Initialize the array with the required length
        characteristics_ = new int16[](characteristicsCount);
        if (_cycleId == 1) {
            for (uint256 i; i < characteristicsCount; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value /= 2;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                characteristics_[i] = int16(int256(value)) + _collateralType.modifiers[uint16(i)];
            }
        } else {
            for (uint256 i; i < characteristicsCount; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value = value - 100;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                characteristics_[i] = int16(int256(value)) + _collateralType.modifiers[uint16(i)];
            }
        }
        return characteristics_;
    }

    function calculateMaxStatistics(uint256 _randomNumber, CollateralTypeInfo storage _collateralType, int16[] memory _characteristics, uint16[] memory _charactisticsBoosts) internal view returns (uint16[] memory statistics_) {
        uint256 statisticsCount = uint256(type(DuckStatisticsType).max) + 1;
        statistics_ = new uint16[](statisticsCount);
        for (uint256 i; i < statisticsCount; i++) {
            // uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
            // if (value > 99) {
            //     value /= 2;
            //     if (value > 99) {
            //         value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
            //     }
            // }
            // statistics_[i] = int16(int256(value)) + _collateralType.modifiers[uint16(i)] + _charactisticsBoosts[i];
            statistics_[i] = 100;
        }
        return statistics_;
    }

    //Calculates the base rarity score, including collateral modifier
    function baseRarityScore(int16[] memory _characteristics) internal pure returns (uint256 rarityScore_) {
        for (uint256 i; i < _characteristics.length; i++) {
            int256 number = _characteristics[i];
            if (number >= 50) {
                rarityScore_ += uint256(number) + 1;
            } else {
                rarityScore_ += uint256(int256(100) - number);
            }
        }
    }

    function rarityMultiplier(int16[] memory _characteristics) internal pure returns (uint256 multiplier_) {
        uint256 rarityScore = baseRarityScore(_characteristics);
        if (rarityScore < 300) return 10;
        else if (rarityScore >= 300 && rarityScore < 450) return 10;
        else if (rarityScore >= 450 && rarityScore <= 525) return 25;
        else if (rarityScore >= 526 && rarityScore <= 580) return 100;
        else if (rarityScore >= 581) return 1000;
    }

    // // old version xp calculation
    // function sqrt(uint256 x) internal pure returns (uint256 y) {
    //     uint256 z = (x + 1) / 2;
    //     y = x;
    //     while (z < y) {
    //         y = z;
    //         z = (x / z + z) / 2;
    //     }
    // }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
