import {
    withSaveAndVerify,
    registerContractInJsonDb,
    insertContractAddressInDb,
} from './contracts-helpers'


import { eContractid } from './types'
import {
    Signer,
    utils,
    BigNumberish,
    Contract,
    BytesLike,
    ContractFactory,
    Overrides,
} from "ethers";

import { getFirstSigner } from './contracts-getters';
import {
    // PErc20Delegate__factory,
    // PErc20Delegator__factory,
    // StandardToken__factory,
    YouSwapInviteV1__factory,
    YouSwapFactory__factory,
    YouSwapFactoryCreator__factory,
    YouSwapFactoryCore__factory,
    XToken__factory,
    TokenYouTest__factory,
} from '../typechain'

export const deployXToken = async (marketId: string,
    _initialAmount: BigNumberish,
    _tokenName: string,
    _decimalUnits: BigNumberish,
    _tokenSymbol: string, verify?: boolean) =>
    withSaveAndVerify(
        await new XToken__factory(await getFirstSigner()).deploy(
            _tokenName,
            _tokenSymbol,
            _initialAmount
        ),
        eContractid.XToken,
        [_tokenSymbol],
        verify
    );

export const deployTokenYouTest = async (
    _tokenSymbol: string,
    _name: string,
    _decimals: BigNumberish,
    _amount: BigNumberish,
    verify?: boolean) =>
    withSaveAndVerify(
        await new TokenYouTest__factory(await getFirstSigner()).deploy(_tokenSymbol, _name, _decimals, _amount),
        eContractid.YouSwapTest,
        [_tokenSymbol],
        verify
    );

export const deployYouSwapInvite = async (
        verify?: boolean) =>
        withSaveAndVerify(
            await new YouSwapInviteV1__factory(await getFirstSigner()).deploy(
            ),
            eContractid.InviteV1,
        );
export const deployYouSwapFactory = async (
        verify?: boolean) =>
        withSaveAndVerify(
            await new YouSwapFactory__factory(await getFirstSigner()).deploy(),
            eContractid.FactoryV2,
        );
export const deployYouSwapFactoryCore = async (
        verify?: boolean) =>
        withSaveAndVerify(
            await new YouSwapFactoryCore__factory(await getFirstSigner()).deploy(),
            eContractid.FactoryV2Core,
        );

export const deployYouSwapFactoryCreator = async (
        _you: string, verify?: boolean) =>
        withSaveAndVerify(
            await new YouSwapFactoryCreator__factory(await getFirstSigner()).deploy(
                _you),
            eContractid.FactoryCreator,
            // [_tokenSymbol],
            // verify
        );