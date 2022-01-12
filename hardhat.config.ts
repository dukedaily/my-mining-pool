import path from 'path';
import fs from 'fs';
import "@typechain/hardhat";
// import 'temp-hardhat-etherscan'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-web3'
import "hardhat-contract-sizer";
import "hardhat-gas-reporter"

import { accounts } from './test-wallets.js';
import '@nomiclabs/hardhat-waffle' //内置了hardhat-ethers，依赖，revertWith是它提供的
// import '@nomiclabs/hardhat-ethers'

import { HardhatUserConfig } from 'hardhat/types'
import { NETWORKS_RPC_URL, NETWORKS_DEFAULT_GAS } from './helper-hardhat-config'
import { eNetwork, eEthereumNetwork } from './helpers/types'

require('dotenv').config()

const DEFAULT_BLOCK_GAS_LIMIT = 12450000;
const DEFAULT_GAS_MUL = 5;
const HARDFORK = 'istanbul';
const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY || '';
const INFURA_KEY = process.env.INFURA_KEY || '';
const ALCHEMY_KEY = process.env.ALCHEMY_KEY || '';
const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MAINNET_FORK = process.env.MAINNET_FORK === 'true';
const MNEMONIC = process.env.MNEMONIC || '';
const MNEMONICHardhat = process.env.MNEMONICHardhat || '';
const DEBUG = process.env.DEBUG

console.log('DEBUG:', DEBUG);
console.log("MNEMONIC:", MNEMONIC);
console.log("MNEMONICHardhat:", MNEMONICHardhat);
console.log("ETHERSCAN_KEY:", ETHERSCAN_KEY);
console.log("INFURA_KEY:", INFURA_KEY);
console.log("ALCHEMY_KEY:", ALCHEMY_KEY);

const getCommonNetworkConfig = (networkName: eNetwork, networkId: number) => ({
    url: NETWORKS_RPC_URL[networkName],
    hardfork: HARDFORK,
    blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
    gasMultiplier: DEFAULT_GAS_MUL,
    gasPrice: NETWORKS_DEFAULT_GAS[networkName],
    chainId: networkId,
    accounts: {
        mnemonic: MNEMONIC,
        path: MNEMONIC_PATH,
        initialIndex: 0,
        count: 20,
    },
});

const mainnetFork = MAINNET_FORK
    ? {
        blockNumber: 12012081,
        url: NETWORKS_RPC_URL['main'],
    }
    : undefined;


const SKIP_LOAD = process.env.SKIP_LOAD === 'true';
console.log("SKIP_LOAD:", SKIP_LOAD);

// Prevent to load scripts before compilation and typechain
if (!SKIP_LOAD) {
    ['migrations', 'full', 'misc'].forEach(
        (folder) => {
            const tasksPath = path.join(__dirname, 'tasks', folder);
            fs.readdirSync(tasksPath)
                .filter((pth) => pth.includes('.ts'))
                .forEach((task) => {
                    require(`${tasksPath}/${task}`);
                });
        }
    );
}

const buildConfig: HardhatUserConfig = {
    solidity: {
        version: "0.7.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    typechain: {
        outDir: "typechain",
        target: "ethers-v5",
    },
    etherscan: {
        apiKey: ETHERSCAN_KEY,
    },
    mocha: {
        timeout: 0,
    },
    networks: {
        kovan: getCommonNetworkConfig(eEthereumNetwork.kovan, 42),
        ropsten: getCommonNetworkConfig(eEthereumNetwork.ropsten, 3),
        main: getCommonNetworkConfig(eEthereumNetwork.main, 1),
        hardhat: {
            hardfork: 'istanbul',
            blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
            gas: DEFAULT_BLOCK_GAS_LIMIT,
            gasPrice: 8000000000,
            chainId: 31337,
            throwOnTransactionFailures: true,
            throwOnCallFailures: true,
            accounts: accounts.map(({ secretKey, balance }: { secretKey: string; balance: string }) => ({
                privateKey: secretKey,
                balance,
            })),
            forking: mainnetFork,
        },
    },
    gasReporter: {
        currency: 'CHF',
        gasPrice: 21,
        // enabled: (process.env.REPORT_GAS) ? true : false
      }
}

export default buildConfig
