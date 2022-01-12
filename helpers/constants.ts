import BigNumber from 'bignumber.js';

// ----------------
// MATH
// ----------------

export const PERCENTAGE_FACTOR = '10000';
export const HALF_PERCENTAGE = '5000';
export const WAD = Math.pow(10, 18).toString();
export const HALF_WAD = new BigNumber(WAD).multipliedBy(0.5).toString();
export const RAY = new BigNumber(10).exponentiatedBy(27).toFixed();
export const HALF_RAY = new BigNumber(RAY).multipliedBy(0.5).toFixed();
export const WAD_RAY_RATIO = Math.pow(10, 9).toString();
export const oneEther = new BigNumber(Math.pow(10, 18));
export const decimal6Price = new BigNumber(Math.pow(10, 30));
export const decimal8Price = new BigNumber(Math.pow(10, 28));
export const decimal18Price = new BigNumber(Math.pow(10, 18));
export const decimal8 = new BigNumber(Math.pow(10, 8));
export const decimal6 = new BigNumber(Math.pow(10, 6));
export const oneRay = new BigNumber(Math.pow(10, 27));
export const MAX_UINT_AMOUNT =
    '115792089237316195423570985008687907853269984665640564039457584007913129639935';
export const ONE_YEAR = '31536000';
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const ONE_ADDRESS = '0x0000000000000000000000000000000000000001';
// ----------------
// PROTOCOL GLOBAL PARAMS
// ----------------
export const OPTIMAL_UTILIZATION_RATE = new BigNumber(0.8).times(RAY);
export const EXCESS_UTILIZATION_RATE = new BigNumber(0.2).times(RAY);
export const APPROVAL_AMOUNT_LENDING_POOL = '1000000000000000000000000000';
export const TOKEN_DISTRIBUTOR_PERCENTAGE_BASE = '10000';
export const MOCK_USD_PRICE_IN_WEI = '5848466240000000';
export const USD_ADDRESS = '0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96';
export const AAVE_REFERRAL = '0';

export const PREFIX = 'Publ '
export const CPREFIX = 'p'
export const DECIMAL18 = 18
export const DECIMAL8 = 8
export const DECIMAL6 = 6
export const INITIALEXCHANGERATEMANTISSA_6 = '200000000000000' //USDT, USDC
export const INITIALEXCHANGERATEMANTISSA_8 = '20000000000000000' //WBTC
export const INITIALEXCHANGERATEMANTISSA_18 = '200000000000000000000000000' //WETH, SUSHI, 1INCH, BNT, DAI
export const BECOMEIMPLEMENTATIONdATA = '0x00'

export const baseRatePerYear= new BigNumber(0.02).multipliedBy(oneEther).toFixed()

export const kink_ =new BigNumber(0.85).multipliedBy(oneEther).toFixed() 
export const supplyBaseSpeed_= new BigNumber(1).multipliedBy(oneEther).toFixed()
export const supplyG0_= new BigNumber(0).multipliedBy(oneEther).toFixed()
export const supplyG1_= new BigNumber(0.04).multipliedBy(oneEther).toFixed()
export const supplyG2_= new BigNumber(0.75).multipliedBy(oneEther).toFixed()
export const borrowBaseSpeed_= new BigNumber(1).multipliedBy(oneEther).toFixed()
export const borrowG0_= new BigNumber(0.5).multipliedBy(oneEther).toFixed()
export const borrowG1_= new BigNumber(0.3).multipliedBy(oneEther).toFixed()
export const borrowG2_= new BigNumber(1.2).multipliedBy(oneEther).toFixed()

export const createBigNumber18 = (v:any) => {
    return new BigNumber(v).multipliedBy(oneEther).toFixed()
}

let poolIdBase = 10000
// let poolIdBase = 1
export const makePoolId = (v:any) => {
    return poolIdBase + v
}

export const trunkMatissa18 = (v:any) => {
    return new BigNumber(v).dividedBy(oneEther).toFixed()
}

export const createBigNumber8 = (v:any) => {
    return new BigNumber(v).multipliedBy(decimal8).toFixed()
}

export const trunkMatissa8 = (v:any) => {
    return new BigNumber(v).dividedBy(decimal8).toFixed()
}

export const createBigNumber6 = (v:any) => {
    return new BigNumber(v).multipliedBy(decimal6).toFixed()
}

export const trunkMatissa6 = (v:any) => {
    return new BigNumber(v).dividedBy(decimal6).toFixed()
}

export const INITIALAMOUNT = createBigNumber18(100000000000000000000000000000000000000000000000000000000000).toString() 

export const MOCK_CHAINLINK_AGGREGATORS_PRICES = {
    AAVE: oneEther.multipliedBy('0.003620948469').toFixed(),
    BAT: oneEther.multipliedBy('0.00137893825230').toFixed(),
    BUSD: oneEther.multipliedBy('0.00736484').toFixed(),
    DAI: oneEther.multipliedBy('0.00369068412860').toFixed(),
    ENJ: oneEther.multipliedBy('0.00029560').toFixed(),
    KNC: oneEther.multipliedBy('0.001072').toFixed(),
    LINK: oneEther.multipliedBy('0.009955').toFixed(),
    MANA: oneEther.multipliedBy('0.000158').toFixed(),
    MKR: oneEther.multipliedBy('2.508581').toFixed(),
    REN: oneEther.multipliedBy('0.00065133').toFixed(),
    SNX: oneEther.multipliedBy('0.00442616').toFixed(),
    SUSD: oneEther.multipliedBy('0.00364714136416').toFixed(),
    TUSD: oneEther.multipliedBy('0.00364714136416').toFixed(),
    UNI: oneEther.multipliedBy('0.00536479').toFixed(),
    USDC: oneEther.multipliedBy('0.00367714136416').toFixed(),
    USDT: oneEther.multipliedBy('0.00369068412860').toFixed(),
    WETH: oneEther.toFixed(),
    WBTC: oneEther.multipliedBy('47.332685').toFixed(),
    YFI: oneEther.multipliedBy('22.407436').toFixed(),
    ZRX: oneEther.multipliedBy('0.001151').toFixed(),
    UniDAIWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniWBTCWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniAAVEWETH: oneEther.multipliedBy('0.003620948469').toFixed(),
    UniBATWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniDAIUSDC: oneEther.multipliedBy('22.407436').toFixed(),
    UniCRVWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniLINKWETH: oneEther.multipliedBy('0.009955').toFixed(),
    UniMKRWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniRENWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniSNXWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniUNIWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniUSDCWETH: oneEther.multipliedBy('22.407436').toFixed(),
    UniWBTCUSDC: oneEther.multipliedBy('22.407436').toFixed(),
    UniYFIWETH: oneEther.multipliedBy('22.407436').toFixed(),
    BptWBTCWETH: oneEther.multipliedBy('22.407436').toFixed(),
    BptBALWETH: oneEther.multipliedBy('22.407436').toFixed(),
    WMATIC: oneEther.multipliedBy('0.003620948469').toFixed(),
    STAKE: oneEther.multipliedBy('0.003620948469').toFixed(),
    xSUSHI: oneEther.multipliedBy('0.00913428586').toFixed(),
    USD: '5848466240000000',
};
