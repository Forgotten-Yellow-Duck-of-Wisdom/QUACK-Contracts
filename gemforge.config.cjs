require('dotenv').config()

const SALT = "0xf8aac9c60a8577e3e439a5639f65f9eca367e2c6de7086f4b4076c0a895d1902"

module.exports = {
  version: 2,
  solc: {
    // SPDX License - to be inserted in all generated .sol files
    license: "MIT",
    // Solidity compiler version - to be inserted in all generated .sol files
    version: "0.8.21",
  },
  // commands to execute
  commands: {
    // the build command
    build: "forge build --names --sizes",
  },
  paths: {
    // contract built artifacts folder
    artifacts: "out",
    // source files
    src: {
      // file patterns to include in facet parsing
      facets: [
        // include all .sol files in the facets directory ending "Facet"
        "src/facets/*Facet.sol",
      ],
    },
    // folders for gemforge-generated files
    generated: {
      // output folder for generated .sol files
      solidity: "src/generated",
      // output folder for support scripts and files
      support: ".gemforge",
      // deployments JSON file
      deployments: "gemforge.deployments.json",
    },
    // library source code
    lib: {
      // diamond library
      diamond: "lib/diamond-2-hardhat",
    },
  },
  // artifacts configuration
  artifacts: {
    // artifact format - "foundry" or "hardhat"
    format: "foundry",
  },
  // generator options
  generator: {
    // proxy interface options
    proxyInterface: {
      // imports to include in the generated IDiamondProxy interface
      imports: ["src/shared/Structs.sol", "src/shared/Structs_Ducks.sol", "src/shared/Structs_Items.sol", "src/shared/Structs_DisplaySlot.sol"],
    },
  },
  // diamond configuration
  diamond: {
    // Whether to include public methods when generating the IDiamondProxy interface. Default is to only include external methods.
    publicMethods: false,
    // The diamond initialization contract - to be called when first deploying the diamond.
    init: {
      // The diamond initialization contract name
      contract: "InitDiamond",
      // The diamond initialization function name
      function: "init",
    },
    // Names of core facet contracts - these will not be modified/removed once deployed and are also reserved names.
    // This default list is taken from the diamond-2-hardhat library.
    // NOTE: we recommend not removing any of these existing names unless you know what you are doing.
    coreFacets: ["OwnershipFacet", "DiamondCutFacet", "DiamondLoupeFacet"],
  },
  // lifecycle hooks
  hooks: {
    // shell command to execute before build
    preBuild: "",
    // shell command to execute after build
    postBuild: "",
    // shell command to execute before deploy
    preDeploy: "",
    // shell command to execute after deploy
    // postDeploy: "scripts/verify.js",
  },
  // Wallets to use for deployment
  wallets: {
    // Wallet named "wallet1"
    wallet1: {
      // Wallet type - mnemonic
      type: "mnemonic",
      // Wallet config
      config: {
        // Mnemonic phrase
        words: "test test test test test test test test test test test junk",
        // 0-based index of the account to use
        index: 0,
      },
    },
    wallet2: {
      // Wallet type - mnemonic
      type: "mnemonic",
      // Wallet config
      config: {
        // Mnemonic phrase
        words: () => process.env.MNEMONIC,
        // 0-based index of the account to use
        index: 0,
      },
    },
    walletTest: {
      // Wallet type - mnemonic
      type: "mnemonic",
      // Wallet config
      config: {
        // Mnemonic phrase
        words: () => process.env.TEST_ADMIN_MNEMO,
        // 0-based index of the account to use
        index: 0,
      },
    },
  },
  // Networks to deploy to
  networks: {
    // Local network
    local: {
      // RPC endpoint URL
      rpcUrl: "http://localhost:8545",
    },
    // Sepolia network
    sepolia: {
      // RPC endpoint URL
      rpcUrl: () => process.env.SEPOLIA_RPC_URL,
    },
    baseSepolia: {
      // RPC endpoint URL
      rpcUrl: () => process.env.BASE_SEPOLIA_RPC_URL,
    },
  },
  // Targets to deploy
  targets: {
    local: {
      // Network to deploy to
      network: "local",
      // Wallet to use for deployment
      wallet: "wallet1",
      // Initialization function arguments
      initArgs: [],
      // CREATE3 salt
      create3Salt: SALT,
    },
    baseSepolia: {
      // Network to deploy to
      network: "baseSepolia",
      // Wallet to use for deployment
      wallet: "walletTest",
      // Initialization function arguments
      initArgs: [
        process.env.QUACK_TOKEN_ADDRESS_SEPOLIA,
        process.env.ESSENCES_TOKEN_ADDRESS_SEPOLIA,
        process.env.TEST_TREASURY_WADDRESS,
        process.env.TEST_FARMING_WADDRESS,
        process.env.TEST_DAO_WADDRESS,
        process.env.CHAINLINK_VRF_V2_Wrapper_SEPOLIA,
        100000, // vrfCallbackGasLimit
        3, // vrfRequestConfirmations
        1 // vrfNumWords
      ],
      // CREATE3 salt
      // create3Salt: SALT,
    },
  },
};
