// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VersusGameScore, TournamentGameScore} from "../shared/Structs_Game_QnQ.sol";
import {LibDuck} from "../libs/LibDuck.sol";

/**
 * Protocol Admin Facet -
 */
contract Game_QnG_Facet is AccessControl {
    function addVersusGameScore(VersusGameScore memory _versusGameScore) external onlyGameQnG {
        require(
            _versusGameScore.playersAddresses.length > 1
                && (
                    _versusGameScore.playersAddresses.length == _versusGameScore.playersCharIds.length
                        && _versusGameScore.playersAddresses.length == _versusGameScore.playersScores.length
                ),
            "Game_QnG_Facet: Players and Ducks addresses length mismatch"
        );
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.versusGameScores[s.versusGameScoresCount] = _versusGameScore;
        s.versusGameScoresIdToIndex[_versusGameScore.gameId] = s.versusGameScoresCount;
        for (uint256 i = 0; i < _versusGameScore.playersAddresses.length; i++) {
            s.playersVersusGameScoreIndexes[_versusGameScore.playersAddresses[i]] = s.versusGameScoresCount;
            s.ducksVersusGameScoreIndexes[_versusGameScore.playersCharIds[i]] = s.versusGameScoresCount;
            if (isWinner(_versusGameScore, _versusGameScore.playersCharIds[i])) {
                LibDuck.addXP(_versusGameScore.playersCharIds[i], 20);
            }
            s.versusGameScoresCount++;
        }
    }

    function isWinner(VersusGameScore memory _versusGameScore, uint256 _charId) internal view returns (bool) {
        for (uint256 i = 0; i < _versusGameScore.winnersCharIds.length; i++) {
            if (_versusGameScore.winnersCharIds[i] == _charId) {
                return true;
            }
        }
        return false;
    }

    function addTournamentGameScore(
        TournamentGameScore memory _tournamentGameScore,
        VersusGameScore[] memory _versusGameScores
    ) external onlyGameQnG {
        AppStorage storage s = LibAppStorage.diamondStorage();
    }
}
