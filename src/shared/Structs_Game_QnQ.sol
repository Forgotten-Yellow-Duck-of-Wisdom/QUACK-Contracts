// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct VersusGameScore {
    uint256 gameId;
    uint256 tournamentId; // 0 if not a tournament
    uint256[] playersScores; // * Must be same size
    uint256[] playersCharIds; // * Must be same size
    uint256[] winnersCharIds;
    address[] playersAddresses; // * Must be same size
    uint256 timestamp;
}

// each tournament is composed of multiple VersusGame
struct TournamentGameScore {
    uint256 tournamentId;
    address[] playersAddresses;
    // uint256[] playersScores;    ?
    address[] winnersAddresses;
    uint256 timestamp;
}
