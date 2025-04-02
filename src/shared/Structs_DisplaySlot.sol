// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct DisplaySlot {
    uint256 slotId;
    string name;
    string description;
    uint256 pricePerWeek;
    bool isActive;
}

struct DisplayRental {
    address renter;
    address contractAddress;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    bool isActive;
}
