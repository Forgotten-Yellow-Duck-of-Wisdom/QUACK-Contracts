# Quack Protocol

baseSepolia testnet
0xa837D2112A4A81baec1715B3a38A60cc93Fca99F


# IMPORTANT
- for mainnet dep, remove test chainlink in VRFLib 

## CMDs

```shell
forge script scripts/createFirstCycle.s.sol:CreateFirstCycle --broadcast -vvvv
```


- [ ] modif - les user peuvent maintenant consume des items meme en oeufs (check potentielles erreurs)
- [ ] modif - items avec maxQty 0 = infinie maintenant (check potentielles erreurs)
- [ ] fix stats - max stats set at eggs buy / egg claim twice
## TODO 
- [ ] add skills (skills level up a l'usage avec des paliers qui peuvent etre augmente en mergeant des skills = level up)
- [ ] add 2 rings slot to wearables
- [ ] Fix characterstics / statistics / traits on item, wearables / consumables etc 
- [ ] Add Respec for Ducks feature
- [~] Add Items feature (set first skin for cycle)
--> is badges part or separate of wearables items ?
--> add pet logic (now separated from wearables)
--> add colorbody id mapping to store onchain duck color as not item ?
- [ ] Add collateral info to Duck Info ?
- [ ] Add extra state //happy, ok, not well, angry, dead
- [ ] Add elo score for ranking games 
- [ ] add random skin per cycle at egg hatch
- [ ] add a mapping itemId => itemManagerAddress, allowing periphery to mint specific items
- [ ] todo calculateMaxStatistics()

## License
MIT - see [LICSENSE.md](LICENSE.md)
