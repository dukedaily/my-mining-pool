import { IUnderyingInfo, SupportTokens } from '../../helpers/types'
import { PREFIX, DECIMAL6, DECIMAL8, DECIMAL18, INITIALAMOUNT } from '../../helpers/constants'

//hardhat
export const USDTInfo: IUnderyingInfo = {
    initialAmount: INITIALAMOUNT,
    tokenName: PREFIX + SupportTokens.USDT,
    symbol: SupportTokens.USDT,
    decimalUnits: DECIMAL6,
}

export const YouInfo: IUnderyingInfo = {
    initialAmount: INITIALAMOUNT,
    tokenName: PREFIX + SupportTokens.You,
    symbol: SupportTokens.You,
    decimalUnits: DECIMAL6,
}

//kovan测试使用
export const BUSDInfo: IUnderyingInfo = {
    initialAmount: INITIALAMOUNT,
    tokenName: PREFIX + SupportTokens.BUSD,
    symbol: SupportTokens.BUSD,
    decimalUnits: DECIMAL18,
}

export const WBTCInfo: IUnderyingInfo = {
    initialAmount: INITIALAMOUNT,
    tokenName: PREFIX + SupportTokens.WBTC,
    symbol: SupportTokens.WBTC,
    decimalUnits: DECIMAL8,
}

export const UNIInfo: IUnderyingInfo = {
    initialAmount: INITIALAMOUNT,
    tokenName: PREFIX + SupportTokens.UNI,
    symbol: SupportTokens.UNI,
    decimalUnits: DECIMAL18,
}