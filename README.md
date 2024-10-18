# Quack Protocol

baseSepolia testnet
0xa837D2112A4A81baec1715B3a38A60cc93Fca99F


# IMPORTANT
- for mainnet dep, remove test chainlink in VRFLib 

## CMDs

```shell
forge script scripts/createFirstCycle.s.sol:CreateFirstCycle --broadcast -vvvv
```

## TODO 
- [ ] Fix characterstics / statistics / traits on item, wearables / consumables etc 
- [ ] Add Respec for Ducks feature
- [~] Add Items feature (set first skin for cycle)
--> is badges part or separate of wearables items ?
--> add pet logic (now separated from wearables)
- [ ] Add collateral info to Duck Info ?
- [ ] Add extra state //happy, ok, not well, angry, dead
- [ ] Add elo score for ranking games 
- [ ] add random skin per cycle at egg hatch
- [ ] add a mapping itemId => itemManagerAddress, allowing periphery to mint specific items

## License
MIT - see [LICSENSE.md](LICENSE.md)
