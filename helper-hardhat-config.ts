// @ts-ignore
import {
    eEthereumNetwork,
    eNetwork,

} from './helpers/types';

require('dotenv').config();

const INFURA_KEY = process.env.INFURA_KEY || '';
const ALCHEMY_KEY = process.env.ALCHEMY_KEY || '';
const TENDERLY_FORK_ID = process.env.TENDERLY_FORK_ID || '';



const GWEI = 1000 * 1000 * 1000;

export const NETWORKS_RPC_URL = {
    [eEthereumNetwork.kovan]: ALCHEMY_KEY ? `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_KEY}` : `https://kovan.infura.io/v3/${INFURA_KEY}`,
    [eEthereumNetwork.ropsten]: ALCHEMY_KEY ? `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_KEY}` : `https://ropsten.infura.io/v3/${INFURA_KEY}`,
    [eEthereumNetwork.main]: ALCHEMY_KEY ? `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}` : `https://mainnet.infura.io/v3/${INFURA_KEY}`,
    [eEthereumNetwork.hardhat]: 'http://localhost:8545',
};

export const NETWORKS_DEFAULT_GAS = {
    [eEthereumNetwork.kovan]: 65 * GWEI,
    [eEthereumNetwork.ropsten]: 65 * GWEI,
    [eEthereumNetwork.main]: 65 * GWEI,
    [eEthereumNetwork.hardhat]: 65 * GWEI,
};



