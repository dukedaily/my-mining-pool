
import BigNumber from 'bignumber.js';

// export type eNetwork = eEthereumNetwork | ePolygonNetwork | eXDaiNetwork;
export type eNetwork = eEthereumNetwork

export enum eEthereumNetwork {
    buidlerevm = 'buidlerevm',
    kovan = 'kovan',
    kovan_self = 'kovan_self',
    ropsten = 'ropsten',
    main = 'main',
    coverage = 'coverage',
    hardhat = 'hardhat',
    tenderlyMain = 'tenderlyMain',
    localhost = 'localhost',
}

export type tEthereumAddress = string;
export type tStringTokenBigUnits = string; // 1 ETH, or 10e6 USDC or 10e18 DAI
export type tBigNumberTokenBigUnits = BigNumber;
export type tStringTokenSmallUnits = string; // 1 wei, or 1 basic unit of USDC, or 1 basic unit of DAI
export type tBigNumberTokenSmallUnits = BigNumber;

export type iParamsPerNetwork<T> =
    | iEthereumParamsPerNetwork<T>

export interface iEthereumParamsPerNetwork<T> {
    [eEthereumNetwork.kovan]: T;
    [eEthereumNetwork.ropsten]: T;
    [eEthereumNetwork.main]: T;
    [eEthereumNetwork.hardhat]: T;
}

export enum eContractid {
    XToken = 'XToken',
    YouSwapTest='YouSwapTest',
    FactoryV2 = 'FactoryV2',
    FactoryV2Core = 'FactoryV2Core',
    FactoryCreator = 'FactoryCreator',
    InviteV1 = 'InviteV1',
    AToken = 'AToken',
}

export interface ICommonConfiguration {
    MarketId: string;
    ChainlinkAggregator: iParamsPerNetwork<ITokenAddress>;
}

export interface SymbolMap<T> {
    [symbol: string]: T;
}

export interface IRateConfiguration {
    MarketId: string;
    RateConfig: iParamsPerNetwork<ITokenAddress>;
}

export interface IRateModelPara {
    baseRatePerYear: string
    multiplierPerYear: string
    jumpMultiplierPerYear: string
    kink: string
}

export interface IReserveCollateralParams {
    baseLTVAsCollateral: string; //0.75
    liquidationThreshold: string; //0.5
    liquidationBonus: string; //1.08
}

export interface ITokenAddress {
    [token: string]: tEthereumAddress;
}

export interface IInterestRateStrategyParams {
    name: string;
    optimalUtilizationRate: string;
    baseVariableBorrowRate: string;
    variableRateSlope1: string;
    variableRateSlope2: string;
    stableRateSlope1: string;
    stableRateSlope2: string;
}

export interface IReserveBorrowParams {
    // optimalUtilizationRate: string;
    // baseVariableBorrowRate: string;
    // variableRateSlope1: string;
    // variableRateSlope2: string;
    // stableRateSlope1: string;
    // stableRateSlope2: string;
    borrowingEnabled: boolean;
    stableBorrowRateEnabled: boolean;
    reserveDecimals: string;
}
export interface IUnderyingInfo {
    initialAmount: string;
    tokenName: string;
    symbol: string;
    decimalUnits: number;
}

export interface IReserveParams extends IReserveBorrowParams, IReserveCollateralParams {
    //所依赖的资产
    underlying: IUnderyingInfo

    //cToken自身
    aTokenImpl: eContractid;
    reserveFactor: string;
    rateModel: IRateModelPara;
    initialExchangeRateMantissa: string;
    cTokenName: string;
    symbol: string;
    decimals: number;
    becomeImplementationData: string;
}

export enum SupportTokens {
    ETHER = 'ETHER',
    DAI = 'DAI',
    You = 'You',
    AAVE = 'AAVE',
    TUSD = 'TUSD',
    BAT = 'BAT',
    WETH = 'WETH',
    USDC = 'USDC',
    USDT = 'USDT',
    SUSD = 'SUSD',
    ZRX = 'ZRX',
    MKR = 'MKR',
    WBTC = 'WBTC',
    LINK = 'LINK',
    KNC = 'KNC',
    MANA = 'MANA',
    REN = 'REN',
    SNX = 'SNX',
    BUSD = 'BUSD',
    USD = 'USD',
    YFI = 'YFI',
    UNI = 'UNI',
    ENJ = 'ENJ'
}

export enum LoanType {
    NORMAL = 0,
    MARGIN_SWAP_PROTOCOL = 1,
    MINNING_SWAP_PROTOCOL = 2,
    INVALID_PROTOCOL = 3
}
