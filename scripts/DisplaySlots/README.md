# QUACK Display Slots Scripts

This directory contains scripts for managing display slots in the QUACK game. Display slots allow players to rent space in the game to showcase their NFTs for a specified period.

## Overview

The following scripts are available:

- `CreateDisplaySlot.s.sol` - Creates a single display slot
- `UpdateDisplaySlot.s.sol` - Updates properties of an existing display slot
- `CancelDisplayRental.s.sol` - Cancels an active rental for a display slot
- `BulkCreateDisplaySlots.s.sol` - Creates multiple display slots at once

## Prerequisites

1. Make sure you have Foundry installed (https://book.getfoundry.sh/)
2. Set up your environment variables in a `.env` file:

```
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
TEST_ADMIN_PKEY=your_admin_private_key
```

## Common Parameters

These environment variables can be used to customize the scripts:

| Variable | Description | Default |
|----------|-------------|---------|
| `SLOT_NAME` | Name of the display slot | "Default Display Slot" |
| `SLOT_DESCRIPTION` | Description of the display slot | "A panel to showcase your NFTs" |
| `PRICE_PER_WEEK` | Rental price in QUACK tokens | 100 |
| `SLOT_ID` | ID of an existing slot (for update/cancel) | 0 |
| `SLOT_COUNT` | Number of slots to create in bulk | 5 |
| `BASE_PRICE` | Starting price for bulk slot creation | 100 |
| `PRICE_INCREMENT` | Price increase for each subsequent slot | 50 |
| `IS_ACTIVE` | Whether the slot is active or not | true |

## Usage

### Create a Single Display Slot

```bash
# Source environment variables
source .env

# Run with default parameters
forge script scripts/DisplaySlots/CreateDisplaySlot.s.sol:CreateDisplaySlot --broadcast

# Run with custom parameters
SLOT_NAME="VIP Display" SLOT_DESCRIPTION="Premium slot location" PRICE_PER_WEEK=200 \
forge script scripts/DisplaySlots/CreateDisplaySlot.s.sol:CreateDisplaySlot --broadcast
```

Expected output:
```
Created display slot with ID: 1
Name: VIP Display
Description: Premium slot location
Price per week: 200
```

### Update an Existing Display Slot

```bash
# Source environment variables
source .env

# Run with default parameters (update slot ID 1)
SLOT_ID=1 forge script scripts/DisplaySlots/UpdateDisplaySlot.s.sol:UpdateDisplaySlot --broadcast

# Run with custom parameters
SLOT_ID=1 SLOT_NAME="Updated VIP Display" SLOT_DESCRIPTION="New premium description" PRICE_PER_WEEK=250 IS_ACTIVE=true \
forge script scripts/DisplaySlots/UpdateDisplaySlot.s.sol:UpdateDisplaySlot --broadcast
```

Expected output:
```
Updated display slot with ID: 1
Before update:
  Name: VIP Display
  Description: Premium slot location
  Price per week: 200
  Active: true
After update:
  Name: Updated VIP Display
  Description: New premium description
  Price per week: 250
  Active: true
```

### Cancel a Display Slot Rental

```bash
# Source environment variables
source .env

# Cancel rental for slot ID 1
SLOT_ID=1 forge script scripts/DisplaySlots/CancelDisplayRental.s.sol:CancelDisplayRental --broadcast
```

Expected output:
```
Canceled rental for display slot with ID: 1
Rental details that were canceled:
  Renter: 0x1234...5678
  NFT Contract: 0xabcd...ef01
  Token ID: 42
```

### Create Multiple Display Slots at Once

```bash
# Source environment variables
source .env

# Create 5 slots with default parameters
forge script scripts/DisplaySlots/BulkCreateDisplaySlots.s.sol:BulkCreateDisplaySlots --broadcast

# Create 10 slots with custom pricing
SLOT_COUNT=10 BASE_PRICE=150 PRICE_INCREMENT=25 \
forge script scripts/DisplaySlots/BulkCreateDisplaySlots.s.sol:BulkCreateDisplaySlots --broadcast
```

Expected output:
```
Created slot #1 with ID: 2 and price: 150
Created slot #2 with ID: 3 and price: 175
Created slot #3 with ID: 4 and price: 200
...
Created slot #10 with ID: 11 and price: 375
--------------------------------------
Created 10 display slots
Base price: 150 QUACK
Price increment: 25 QUACK
--------------------------------------
```

## Verifying Transactions

After broadcasting the transactions, you can verify them using the Etherscan API:

```bash
# For Base Sepolia
forge script scripts/DisplaySlots/CreateDisplaySlot.s.sol:CreateDisplaySlot \
  --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY -vvvv
```

## Troubleshooting

- If you encounter "insufficient funds" errors, make sure your admin account has enough ETH for gas and enough QUACK tokens if you're creating/updating slots.
- If scripts fail with "nonce too low" errors, you may need to reset your account's nonce with your RPC provider.
- For transaction errors like "execution reverted", check the contract state to ensure you're not trying to update a non-existent slot or cancel a rental that doesn't exist. 