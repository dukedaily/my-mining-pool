import { DRE, getDb } from './misc-utils'
import { Signer } from 'ethers'
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { eContractid, tEthereumAddress } from './types';
import {
    XToken__factory,
    YouSwapInviteV1__factory,
    YouSwapFactory__factory,
    YouSwapFactoryCore__factory,
    YouSwapFactoryCreator__factory,
    TokenYouTest__factory,
} from '../typechain'

export const getFirstSigner = async () => (await DRE.ethers.getSigners())[0]
export const getAccount = async (index: any) => (await DRE.ethers.getSigners())[index]
export const getAccountSigners = async () => await DRE.ethers.getSigners()

export const getXToken = async (symbol: string, address?: tEthereumAddress) =>
    await XToken__factory.connect(
        address || (await getDb().get(`${eContractid.XToken}.${DRE.network.name}`).value())[symbol].address,
        await getFirstSigner()
    )
export const getTokenYouTest = async (symbol: string, address?: tEthereumAddress) =>
    await TokenYouTest__factory.connect(
        address || (await getDb().get(`${eContractid.YouSwapTest}.${DRE.network.name}`).value())[symbol].address,
        await getFirstSigner()
    )
export const getYouSwapInviteV1 = async (address?: tEthereumAddress) =>
    await YouSwapInviteV1__factory.connect(
        address || (await getDb().get(`${eContractid.InviteV1}.${DRE.network.name}`).value()).address,
        await getFirstSigner()
    )
export const getYouSwapFactoryV2 = async (address?: tEthereumAddress) =>
    await YouSwapFactory__factory.connect(
        address || (await getDb().get(`${eContractid.FactoryV2}.${DRE.network.name}`).value()).address,
        await getFirstSigner()
    )
export const getYouSwapFactoryV2Core = async (address?: tEthereumAddress) =>
    await YouSwapFactoryCore__factory.connect(
        address || (await getDb().get(`${eContractid.FactoryV2Core}.${DRE.network.name}`).value()).address,
        await getFirstSigner()
    )
export const getYouSwapFactoryCreator = async (address?: tEthereumAddress) =>
    await YouSwapFactoryCreator__factory.connect(
        address || (await getDb().get(`${eContractid.FactoryCreator}.${DRE.network.name}`).value()).address,
        await getFirstSigner()
    )
