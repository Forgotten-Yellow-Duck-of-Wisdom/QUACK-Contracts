// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
enum GameMode { 
    Versus, 
    Tournament 
}

struct VersusPlayerScore {
    address player;
    uint256 characterId;
    uint256 score;
    bool isWinner;
}

struct VersusGame {
    uint256 gameId;
     // 0 if GameMode = Versus (not Tournament or other game mode)
     // else Reference to Tournament.tournamentId or other game mode id
    uint256 modeId;
    uint256 timestamp;
    GameMode gameMode;
    VersusPlayerScore[] players;
}

// each tournament is composed of multiple VersusGame
struct Tournament {
    uint256 tournamentId;
    uint256 timestamp;
    // References to VersusGame.gameId
    uint256[] gameIds; 
    // Top players in the tournament
    address[] winners;  
}
