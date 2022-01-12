import { eContractid, IRateModelPara } from '../../helpers/types';
import BigNumber from 'bignumber.js';
import { oneRay,oneEther } from '../../helpers/constants'

export const rateModelUSDT: IRateModelPara = { //真实的
    baseRatePerYear: new BigNumber(0).multipliedBy(oneEther).toFixed(),  //0
    multiplierPerYear: new BigNumber(0.04).multipliedBy(oneEther).toFixed(),//40000000000000000
    jumpMultiplierPerYear: new BigNumber(1.09).multipliedBy(oneEther).toFixed(), //1090000000000000000
    kink: new BigNumber(0.8).multipliedBy(oneEther).toFixed(), //800000000000000000
};

export const rateModelBUSD: IRateModelPara = { //没有这个，模拟的
    baseRatePerYear: new BigNumber(0).multipliedBy(oneEther).toFixed(),  //0
    multiplierPerYear: new BigNumber(0.18).multipliedBy(oneEther).toFixed(),//40000000000000000
    jumpMultiplierPerYear: new BigNumber(1).multipliedBy(oneEther).toFixed(), //1090000000000000000
    kink: new BigNumber(0.8).multipliedBy(oneEther).toFixed(), //800000000000000000
};

export const rateModelWBTC: IRateModelPara = { //真实的
    baseRatePerYear: new BigNumber(0.02).multipliedBy(oneEther).toFixed(),  // 20000000000000000
    multiplierPerYear: new BigNumber(0.18).multipliedBy(oneEther).toFixed(),//180000000000000000
    jumpMultiplierPerYear: new BigNumber(1).multipliedBy(oneEther).toFixed(), //1000000000000000000
    kink: new BigNumber(0.8).multipliedBy(oneEther).toFixed(), //800000000000000000
};

export const rateModelUNI: IRateModelPara = { //真实的
    baseRatePerYear: new BigNumber(0).multipliedBy(oneEther).toFixed(),  //0
    multiplierPerYear: new BigNumber(0.04).multipliedBy(oneEther).toFixed(),//40000000000000000
    jumpMultiplierPerYear: new BigNumber(1.09).multipliedBy(oneEther).toFixed(), //1090000000000000000
    kink: new BigNumber(0.8).multipliedBy(oneEther).toFixed(), //800000000000000000
};

export const rateModelYou: IRateModelPara = { //真实的
    baseRatePerYear: new BigNumber(0).multipliedBy(oneEther).toFixed(),  //0
    multiplierPerYear: new BigNumber(0.04).multipliedBy(oneEther).toFixed(),//40000000000000000
    jumpMultiplierPerYear: new BigNumber(1.09).multipliedBy(oneEther).toFixed(), //1090000000000000000
    kink: new BigNumber(0.8).multipliedBy(oneEther).toFixed(), //800000000000000000
};

export const rateModelEther: IRateModelPara = { //无需支持，废弃
    baseRatePerYear: new BigNumber(0.02).multipliedBy(oneEther).toFixed(),
    multiplierPerYear: new BigNumber(0.2).multipliedBy(oneEther).toFixed(),
    jumpMultiplierPerYear: new BigNumber(2).multipliedBy(oneEther).toFixed(),
    kink: new BigNumber(0.9).multipliedBy(oneEther).toFixed(),
}