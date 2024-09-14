// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import {IDiamondCut} from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import {DiamondProxy} from "src/generated/DiamondProxy.sol";
import {IDiamondProxy} from "src/generated/IDiamondProxy.sol";
import {LibDiamondHelper} from "src/generated/LibDiamondHelper.sol";
import {InitDiamond} from "src/init/InitDiamond.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {test_ERC20} from "./test_ERC20.sol";

abstract contract TestBaseContract is Test {
    address public immutable account0 = address(this);
    address public account1;
    address public account2;

    IDiamondProxy public diamond;

    test_ERC20 public quackToken;

    function setUp() public virtual {
        // console2.log("\n -- Test Sepolia --\n");

        // console2.log("Test contract address, aka account0", address(this));
        // console2.log("msg.sender during setup", msg.sender);

        // Test on Sepolia testnet
        string memory sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");

        uint256 testnetFork = vm.createFork(sepoliaRpcUrl);
        vm.selectFork(testnetFork);
        assertEq(vm.activeFork(), testnetFork);
        // console2.log("Tests now running on Sepolia testnet");

        // vm.label(account0, "Account 0");
        account1 = vm.addr(1);
        // vm.label(account1, "Account 1");
        account2 = vm.addr(2);
        // vm.label(account2, "Account 2");

        // quackToken = IERC20(vm.envAddress("QUACK_TOKEN_ADDRESS_SEPOLIA"));
        quackToken = new test_ERC20(account0, 1000000000000000000, 18);


        // console2.log("Deploy diamond");
        diamond = IDiamondProxy(address(new DiamondProxy(account0)));

        // console2.log("Cut and init");
        IDiamondCut.FacetCut[] memory cut = LibDiamondHelper.deployFacetsAndGetCuts(address(diamond));
        InitDiamond init = new InitDiamond();
        diamond.diamondCut(
            cut,
            address(init),
            abi.encodeWithSelector(
                init.init.selector,
                address(quackToken),
                // vm.envAddress("QUACK_TOKEN_ADDRESS_SEPOLIA"),
                vm.envAddress("TEST_TREASURY_WADDRESS"),
                vm.envAddress("TEST_FARMING_WADDRESS"),
                vm.envAddress("TEST_DAO_WADDRESS"),
                vm.envAddress("CHAINLINK_VRF_V2_Wrapper_SEPOLIA"),
                uint32(100000), // vrfCallbackGasLimit
                uint16(3), // vrfRequestConfirmations
                uint32(1) // vrfNumWords
            )
        );

        assertEq(quackToken.balanceOf(account0), 1000000000000000000);
    }
}
