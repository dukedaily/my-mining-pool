import { eContractid, IReserveParams, IUnderyingInfo, SupportTokens } from '../../helpers/types';
import * as cToken from '../../helpers/constants';
import { 
    BUSDInfo, 
    USDTInfo,
    YouInfo,
    UNIInfo,
    WBTCInfo,
 } from './underlyingInfos'

import {
    rateModelBUSD,
    rateModelUSDT,
    rateModelYou,
    rateModelUNI,
    rateModelWBTC,
    rateModelEther,
} from './rateModelConfigs'

export const strategyUSDT: IReserveParams = {
    underlying: USDTInfo,

    rateModel: rateModelUSDT,
    initialExchangeRateMantissa: cToken.INITIALEXCHANGERATEMANTISSA_6,
    cTokenName: cToken.PREFIX + SupportTokens.USDT,
    symbol: cToken.CPREFIX + SupportTokens.USDT,
    decimals: cToken.DECIMAL8,
    becomeImplementationData: cToken.BECOMEIMPLEMENTATIONdATA,

    // strategy: rateStrategyStableOne,
    //来自IReserveCollateralParams
    baseLTVAsCollateral: '0.8',
    liquidationThreshold: '0.5',
    liquidationBonus: '1.08',

    //来自IReserveBorrowParam
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    reserveDecimals: '18',

    aTokenImpl: eContractid.AToken,
    reserveFactor: '1000'
};

export const strategyUNI: IReserveParams = {
    underlying: UNIInfo,

    rateModel: rateModelUNI,
    initialExchangeRateMantissa: cToken.INITIALEXCHANGERATEMANTISSA_18,
    cTokenName: cToken.PREFIX + SupportTokens.UNI,
    symbol: cToken.CPREFIX + SupportTokens.UNI,
    decimals: cToken.DECIMAL8,
    becomeImplementationData: cToken.BECOMEIMPLEMENTATIONdATA,

    // strategy: rateStrategyStableOne,
    //来自IReserveCollateralParams
    baseLTVAsCollateral: '0.8',
    liquidationThreshold: '0.5',
    liquidationBonus: '1.08',

    //来自IReserveBorrowParam
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    reserveDecimals: '18',

    aTokenImpl: eContractid.AToken,
    reserveFactor: '1000'
};

export const strategyBUSD: IReserveParams = {
    underlying: BUSDInfo,

    rateModel: rateModelBUSD,
    initialExchangeRateMantissa: cToken.INITIALEXCHANGERATEMANTISSA_18,
    cTokenName: cToken.PREFIX + SupportTokens.BUSD,
    symbol: cToken.CPREFIX + SupportTokens.BUSD,
    decimals: cToken.DECIMAL8,
    becomeImplementationData: cToken.BECOMEIMPLEMENTATIONdATA,

    // strategy: rateStrategyStableOne,
    //来自IReserveCollateralParams
    baseLTVAsCollateral: '0.8',
    liquidationThreshold: '0.5',
    liquidationBonus: '1.08',

    //来自IReserveBorrowParam
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    reserveDecimals: '18',

    aTokenImpl: eContractid.AToken,
    reserveFactor: '1000'
};

export const strategyWBTC: IReserveParams = {
    underlying: WBTCInfo,

    rateModel: rateModelWBTC,
    initialExchangeRateMantissa: cToken.INITIALEXCHANGERATEMANTISSA_8,
    cTokenName: cToken.PREFIX + SupportTokens.WBTC,
    symbol: cToken.CPREFIX + SupportTokens.WBTC,
    decimals: cToken.DECIMAL8,
    becomeImplementationData: cToken.BECOMEIMPLEMENTATIONdATA,

    // strategy: rateStrategyStableOne,
    //来自IReserveCollateralParams
    baseLTVAsCollateral: '0.8',
    liquidationThreshold: '0.5',
    liquidationBonus: '1.08',

    //来自IReserveBorrowParam
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    reserveDecimals: '18',

    aTokenImpl: eContractid.AToken,
    reserveFactor: '1000'
};

export const strategyYou: IReserveParams = {
    underlying: YouInfo,

    rateModel: rateModelYou,
    initialExchangeRateMantissa: cToken.INITIALEXCHANGERATEMANTISSA_18,
    cTokenName: cToken.PREFIX + SupportTokens.You,
    symbol: cToken.CPREFIX + SupportTokens.You,
    decimals: cToken.DECIMAL8,
    becomeImplementationData: cToken.BECOMEIMPLEMENTATIONdATA,

    // strategy: rateStrategyStableOne,
    //来自IReserveCollateralParams
    baseLTVAsCollateral: '0.8',
    liquidationThreshold: '0.5',
    liquidationBonus: '1.08',

    //来自IReserveBorrowParam
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    reserveDecimals: '18',

    aTokenImpl: eContractid.AToken,
    reserveFactor: '1000'
};
