// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import {AccessControl} from "../shared/AccessControl.sol";
import {AppStorage, LibAppStorage} from "../libs/LibAppStorage.sol";
import {VersusGameScore, TournamentGameScore} from "../shared/Structs_Game_QnQ.sol";
import {LibDuck} from "../libs/LibDuck.sol";

/**
 * @title Game_QnG_Facet
 * @dev Manages game scores for versus games and tournaments in the Quack and Gather (QnG) game system.
 * This facet handles the addition of scores for individual games and tournaments, as well as
 * updating player statistics and duck experience points.
 */
contract Game_QnG_Facet is AccessControl {
    event VersusGameScoreAdded(uint256 indexed gameId, uint256 indexed tournamentId, uint256 versusGameScoresCount);
    event TournamentGameScoreAdded(uint256 indexed tournamentId, uint256 versusGameScoresCount);

    function addVersusGameScore(
    uint256 _gameId,
    uint256 _tournamentId,
    VersusPlayerScore[] calldata _playerScores
) external onlyGameQnG {
    require(_playerScores.length > 1, "At least two players required");
    
    AppStorage storage s = LibAppStorage.diamondStorage();

    // Initialize VersusGame
    VersusGame storage game = s.versusGames[_gameId];
    game.gameId = _gameId;
    game.tournamentId = _tournamentId;
    game.timestamp = block.timestamp;

    for (uint256 i = 0; i < _playerScores.length; i++) {
        VersusPlayerScore memory pScore = _playerScores[i];
        require(pScore.player != address(0), "Invalid player address");
        
        game.players.push(pScore);

        // Link players to games
        s.playerVersusGameIds[pScore.player].push(_gameId);

        // Link characters to games
        s.duckVersusGameIds[pScore.characterId].push(_gameId);

        // check if the player is a winner
        if (isWinner(pScore, pScore.characterId)) {
            LibDuck.addXP(pScore.characterId, 20);
        }
    }

    s.versusGameCount++;

    emit VersusGameScoreAdded(_gameId, _tournamentId, _playerScores.length);
}

    // /**
    //  * @notice Adds a new versus game score to the system
    //  * @dev This function can only be called by an address with the GameQnG role
    //  * @param _versusGameScore A struct containing all the details of the versus game score
    //  * @custom:throws Game_QnG_Facet: Players and Ducks addresses length mismatch
    //  * @custom:throws Game_QnG_Facet: Game ID already exists
    //  */
    // function addVersusGameScore(VersusGameScore memory _versusGameScore) external onlyGameQnG {
    //     _addVersusGameScore(_versusGameScore);
    // }

    // /**
    //  * @notice Internal function to add a versus game score and update related data
    //  * @dev This function updates various mappings and awards XP to winning ducks
    //  * @param _versusGameScore A struct containing all the details of the versus game score
    //  * @custom:throws Game_QnG_Facet: Players and Ducks addresses length mismatch
    //  * @custom:throws Game_QnG_Facet: Game ID already exists
    //  */
    // function _addVersusGameScore(VersusGameScore memory _versusGameScore) internal {
    //     require(
    //         _versusGameScore.playersAddresses.length > 1
    //             && (
    //                 _versusGameScore.playersAddresses.length == _versusGameScore.playersCharIds.length
    //                     && _versusGameScore.playersAddresses.length == _versusGameScore.playersScores.length
    //             ),
    //         "Game_QnG_Facet: Players and Ducks addresses length mismatch"
    //     );
    //     AppStorage storage s = LibAppStorage.diamondStorage();
    //     require(s.versusGameScoresIdToIndex[_versusGameScore.gameId] == 0, "Game_QnG_Facet: Game ID already exists");
    //     s.versusGameScoresCount++;
    //     uint256 currentIndex = s.versusGameScoresCount;

    //     s.versusGameScores[currentIndex] = _versusGameScore;
    //     s.versusGameScoresIdToIndex[_versusGameScore.gameId] = currentIndex;
    //     for (uint256 i = 0; i < _versusGameScore.playersAddresses.length; i++) {
    //         s.playersVersusGameScoreIndexes[_versusGameScore.playersAddresses[i]] = currentIndex;
    //         s.ducksVersusGameScoreIndexes[_versusGameScore.playersCharIds[i]] = currentIndex;
    //         if (isWinner(_versusGameScore, _versusGameScore.playersCharIds[i])) {
    //             LibDuck.addXP(_versusGameScore.playersCharIds[i], 20);
    //         }
    //     }
    //     emit VersusGameScoreAdded(_versusGameScore.gameId, _versusGameScore.tournamentId, currentIndex);
    // }

    /**
     * @notice Determines if a given character ID is a winner in a versus game
     * @dev This function iterates through the winners array to check for a match
     * @param _versusGameScore The versus game score containing the winners information
     * @param _charId The character ID to check for winner status
     * @return bool True if the character is a winner, false otherwise
     */
    function isWinner(VersusGameScore memory _versusGameScore, uint256 _charId) internal view returns (bool) {
        for (uint256 i = 0; i < _versusGameScore.winnersCharIds.length; i++) {
            if (_versusGameScore.winnersCharIds[i] == _charId) {
                return true;
            }
        }
        return false;
    }

    // /**
    //  * @notice Adds a new tournament game score and its associated versus game scores
    //  * @dev This function can only be called by an address with the GameQnG role. It adds the tournament
    //  *      score and then calls _addVersusGameScore for each associated versus game.
    //  * @param _tournamentGameScore A struct containing the tournament game score details
    //  * @param _versusGameScores An array of VersusGameScore structs associated with this tournament
    //  * @custom:throws Game_QnG_Facet: No versus game scores provided
    //  * @custom:throws Game_QnG_Facet: Tournament ID already exists
    //  * @custom:throws Game_QnG_Facet: Versus game score does not match tournament ID
    //  */
    // function addTournamentGameScore(
    //     TournamentGameScore memory _tournamentGameScore,
    //     VersusGameScore[] memory _versusGameScores
    // ) external onlyGameQnG {
    //     AppStorage storage s = LibAppStorage.diamondStorage();
    //     require(_versusGameScores.length > 0, "Game_QnG_Facet: No versus game scores provided");
    //     require(
    //         s.tournamentGameScoresIdToIndex[_tournamentGameScore.tournamentId] == 0,
    //         "Game_QnG_Facet: Tournament ID already exists"
    //     );

    //     // Add the tournament game score
    //     s.tournamentGameScoresCount++;
    //     s.tournamentGameScores[s.tournamentGameScoresCount] = _tournamentGameScore;
    //     s.tournamentGameScoresIdToIndex[_tournamentGameScore.tournamentId] = s.tournamentGameScoresCount;

    //     // Add all versus game scores associated with this tournament
    //     for (uint256 i = 0; i < _versusGameScores.length; i++) {
    //         require(
    //             _versusGameScores[i].tournamentId == _tournamentGameScore.tournamentId,
    //             "Game_QnG_Facet: Versus game score does not match tournament ID"
    //         );
    //         _addVersusGameScore(_versusGameScores[i]);
    //     }
    //     emit TournamentGameScoreAdded(_tournamentGameScore.tournamentId, _versusGameScores.length);
    // }


function addTournament(
    uint256 _tournamentId,
    VersusGame[] calldata _versusGames,
    address[] calldata _winners
) external onlyGameQnG {
    require(_versusGames.length == 8, "Tournament requires 8 Versus games");
    require(_winners.length > 0, "At least one winner required");

    AppStorage storage s = LibAppStorage.diamondStorage();

    Tournament storage tournament = s.tournaments[_tournamentId];
    tournament.tournamentId = _tournamentId;
    tournament.timestamp = block.timestamp;

    for (uint256 i = 0; i < _versusGames.length; i++) {
        uint256 gameId = _versusGames[i].gameId;
        tournament.gameIds.push(gameId);
    }

    for (uint256 i = 0; i < _winners.length; i++) {
        tournament.winners.push(_winners[i]);

        // Link players to tournaments
        s.playerTournamentIds[_winners[i]].push(_tournamentId);
    }

    s.tournamentCount++;

    emit TournamentAdded(_tournamentId, _versusGames.length, _winners.length);
}
    ///////////////////////////////////////////////////////////
    // Read functions
    ///////////////////////////////////////////////////////////
/**
 * @notice Retrieves a versus game score by its game ID
 * @param _gameId The ID of the game to retrieve
 * @return VersusGameScore The versus game score struct
 * @custom:throws Game_QnG_Facet: Game ID does not exist
 */
function getVersusGameScoreById(uint256 _gameId) external view returns (VersusGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 index = s.versusGameScoresIdToIndex[_gameId];
    require(index != 0, "Game_QnG_Facet: Game ID does not exist");
    return s.versusGameScores[index];
}

/**
 * @notice Retrieves a versus game score by its index
 * @param _index The index of the versus game score to retrieve
 * @return VersusGameScore The versus game score struct
 * @custom:throws Game_QnG_Facet: Index out of bounds
 */
function getVersusGameScoreByIndex(uint256 _index) external view returns (VersusGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(_index > 0 && _index <= s.versusGameScoresCount, "Game_QnG_Facet: Index out of bounds");
    return s.versusGameScores[_index];
}

/**
 * @notice Retrieves a tournament game score by its tournament ID
 * @param _tournamentId The ID of the tournament to retrieve
 * @return TournamentGameScore The tournament game score struct
 * @custom:throws Game_QnG_Facet: Tournament ID does not exist
 */
function getTournamentGameScoreById(uint256 _tournamentId) external view returns (TournamentGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 index = s.tournamentGameScoresIdToIndex[_tournamentId];
    require(index != 0, "Game_QnG_Facet: Tournament ID does not exist");
    return s.tournamentGameScores[index];
}

/**
 * @notice Retrieves a tournament game score by its index
 * @param _index The index of the tournament game score to retrieve
 * @return TournamentGameScore The tournament game score struct
 * @custom:throws Game_QnG_Facet: Index out of bounds
 */
function getTournamentGameScoreByIndex(uint256 _index) external view returns (TournamentGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(_index > 0 && _index <= s.tournamentGameScoresCount, "Game_QnG_Facet: Index out of bounds");
    return s.tournamentGameScores[_index];
}

/**
 * @notice Retrieves the latest versus game score for a player
 * @param _playerAddress The address of the player
 * @return VersusGameScore The latest versus game score struct for the player
 * @custom:throws Game_QnG_Facet: No game score found for player
 */
function getPlayerLatestVersusGameScore(address _playerAddress) external view returns (VersusGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 index = s.playersVersusGameScoreIndexes[_playerAddress];
    require(index != 0, "Game_QnG_Facet: No game score found for player");
    return s.versusGameScores[index];
}

/**
 * @notice Retrieves all versus game scores for a player
 * @param _playerAddress The address of the player
 * @return VersusGameScore[] An array of versus game score structs for the player
 */
function getPlayerAllVersusGameScores(address _playerAddress) external view returns (VersusGameScore[] memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = 0;
    for (uint256 i = 1; i <= s.versusGameScoresCount; i++) {
        if (isPlayerInVersusGame(s.versusGameScores[i], _playerAddress)) {
            count++;
        }
    }
    
    VersusGameScore[] memory playerScores = new VersusGameScore[](count);
    uint256 index = 0;
    for (uint256 i = 1; i <= s.versusGameScoresCount; i++) {
        if (isPlayerInVersusGame(s.versusGameScores[i], _playerAddress)) {
            playerScores[index] = s.versusGameScores[i];
            index++;
        }
    }
    return playerScores;
}

/**
 * @notice Retrieves the latest versus game score for a duck
 * @param _duckId The ID of the duck
 * @return VersusGameScore The latest versus game score struct for the duck
 * @custom:throws Game_QnG_Facet: No game score found for duck
 */
function getDuckLatestVersusGameScore(uint256 _duckId) external view returns (VersusGameScore memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 index = s.ducksVersusGameScoreIndexes[_duckId];
    require(index != 0, "Game_QnG_Facet: No game score found for duck");
    return s.versusGameScores[index];
}

/**
 * @notice Retrieves all versus game scores for a duck
 * @param _duckId The ID of the duck
 * @return VersusGameScore[] An array of versus game score structs for the duck
 */
function getDuckAllVersusGameScores(uint256 _duckId) external view returns (VersusGameScore[] memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = 0;
    for (uint256 i = 1; i <= s.versusGameScoresCount; i++) {
        if (isDuckInVersusGame(s.versusGameScores[i], _duckId)) {
            count++;
        }
    }
    
    VersusGameScore[] memory duckScores = new VersusGameScore[](count);
    uint256 index = 0;
    for (uint256 i = 1; i <= s.versusGameScoresCount; i++) {
        if (isDuckInVersusGame(s.versusGameScores[i], _duckId)) {
            duckScores[index] = s.versusGameScores[i];
            index++;
        }
    }
    return duckScores;
}


/**
 * @notice Retrieves all tournament game scores for a player
 * @param _playerAddress The address of the player
 * @return TournamentGameScore[] An array of tournament game score structs for the player
 */
function getPlayerAllTournamentGameScores(address _playerAddress) external view returns (TournamentGameScore[] memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = 0;
    for (uint256 i = 1; i <= s.tournamentGameScoresCount; i++) {
        if (isPlayerInTournament(s.tournamentGameScores[i], _playerAddress)) {
            count++;
        }
    }
    
    TournamentGameScore[] memory playerTournaments = new TournamentGameScore[](count);
    uint256 index = 0;
    for (uint256 i = 1; i <= s.tournamentGameScoresCount; i++) {
        if (isPlayerInTournament(s.tournamentGameScores[i], _playerAddress)) {
            playerTournaments[index] = s.tournamentGameScores[i];
            index++;
        }
    }
    return playerTournaments;
}

/**
 * @notice Retrieves all tournament game scores for a duck
 * @param _duckId The ID of the duck
 * @return TournamentGameScore[] An array of tournament game score structs for the duck
 */
function getDuckAllTournamentGameScores(uint256 _duckId) external view returns (TournamentGameScore[] memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = 0;
    for (uint256 i = 1; i <= s.tournamentGameScoresCount; i++) {
        if (isDuckInTournament(s.tournamentGameScores[i], _duckId)) {
            count++;
        }
    }
    
    TournamentGameScore[] memory duckTournaments = new TournamentGameScore[](count);
    uint256 index = 0;
    for (uint256 i = 1; i <= s.tournamentGameScoresCount; i++) {
        if (isDuckInTournament(s.tournamentGameScores[i], _duckId)) {
            duckTournaments[index] = s.tournamentGameScores[i];
            index++;
        }
    }
    return duckTournaments;
}
/**
 * @notice Retrieves the total number of versus games played
 * @return uint256 The total number of versus games
 */
function getTotalCountVersusGames() external view returns (uint256) {
    return LibAppStorage.diamondStorage().versusGameScoresCount;
}

/**
 * @notice Retrieves the total number of tournaments played
 * @return uint256 The total number of tournaments
 */
function getTotalCountTournaments() external view returns (uint256) {
    return LibAppStorage.diamondStorage().tournamentGameScoresCount;
}

///////////////////////////////////////////////////////////
// Helpers
///////////////////////////////////////////////////////////
// Helper functions

function isPlayerInVersusGame(VersusGameScore memory _game, address _playerAddress) internal pure returns (bool) {
    for (uint256 i = 0; i < _game.playersAddresses.length; i++) {
        if (_game.playersAddresses[i] == _playerAddress) {
            return true;
        }
    }
    return false;
}

function isDuckInVersusGame(VersusGameScore memory _game, uint256 _duckId) internal pure returns (bool) {
    for (uint256 i = 0; i < _game.playersCharIds.length; i++) {
        if (_game.playersCharIds[i] == _duckId) {
            return true;
        }
    }
    return false;
}

function isPlayerInTournament(TournamentGameScore memory _tournament, address _playerAddress) internal pure returns (bool) {
    for (uint256 i = 0; i < _tournament.playersAddresses.length; i++) {
        if (_tournament.playersAddresses[i] == _playerAddress) {
            return true;
        }
    }
    return false;
}

function isDuckInTournament(TournamentGameScore memory _tournament, uint256 _duckId) internal pure returns (bool) {
    // Assuming TournamentGameScore has a playersCharIds array. If not, you might need to adjust this function.
    for (uint256 i = 0; i < _tournament.playersCharIds.length; i++) {
        if (_tournament.playersCharIds[i] == _duckId) {
            return true;
        }
    }
    return false;
}

}

