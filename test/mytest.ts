import { describe } from "mocha";
import rawBRE from 'hardhat';

// We import Chai to use its asserting functions here.
const { use, expect } = require("chai");
const { waffleChai } = require("@ethereum-waffle/chai")
use(waffleChai)

import {
    getFirstSigner, 
    getAccount,
    getAccountSigners, 
    getTokenYouTest,
    getYouSwapFactoryCreator,
    getYouSwapFactoryV2,
    getYouSwapFactoryV2Core
} from '../helpers/contracts-getters'

import { oneEther, 
    createBigNumber18, 
    createBigNumber6, 
    createBigNumber8, 
    makePoolId } from '../helpers/constants'

describe("V2-mining test", function () {
    let YouToken;
    let BUSDToken;
    let UNIToken;
    let WBTCToken;
    let factoryCreator;
    let account0; 
    let account1; 
    let account2; 
    let account3; 
    let account4;
    let args;

    //部署动作
    before(async function () {
        // 前置部署：initialize相关
        rawBRE.run('set-DRE')
        await rawBRE.run("full:deploy-new-assets");

        // 部署creator合约
        rawBRE.run('set-DRE')
        await rawBRE.run("full:initialize");

        YouToken = await getTokenYouTest('You')
        BUSDToken = await getTokenYouTest("BUSD")
        UNIToken = await getTokenYouTest("UNI")
        WBTCToken = await getTokenYouTest("WBTC")

        // [account0, account1, account2, account3, account4, ...args] = await getAccountSigners()
        account0 = await getAccount(0)
        account1 = await getAccount(1)
        account2 = await getAccount(2)
        account3 = await getAccount(3)
        account4 = await getAccount(4)
        factoryCreator = await getYouSwapFactoryCreator()

        YouToken.connect(account0).transfer(account1.address, createBigNumber18(1000000))
        YouToken.connect(account0).transfer(account2.address, createBigNumber18(1000000))
        YouToken.connect(account0).transfer(account3.address, createBigNumber18(1000000))
        YouToken.connect(account0).transfer(account4.address, createBigNumber18(1000000))

        YouToken.connect(account0).approve(factoryCreator.address, createBigNumber18(100000000))
        YouToken.connect(account1).approve(factoryCreator.address, createBigNumber18(100000000))
        YouToken.connect(account2).approve(factoryCreator.address, createBigNumber18(100000000))
        YouToken.connect(account3).approve(factoryCreator.address, createBigNumber18(100000000))
        YouToken.connect(account4).approve(factoryCreator.address, createBigNumber18(100000000))

        UNIToken.connect(account0).approve(factoryCreator.address, createBigNumber18(100000000))
        UNIToken.connect(account1).approve(factoryCreator.address, createBigNumber18(100000000))
    })

    beforeEach(async function () {
        console.log("next!".green)
    })

    describe('normal-instance', function () {
        // 不同场景测试
        it('create pool test', async () => {
            // 单元测试
            let powerRatio = 1
            let startTimeDelay = 0
            let priority = 1
            let maxStakeAmount = createBigNumber18(10000000)
            let poolType = 0 //normal
            let lockSeconds = 30000 //60
            let multiple = 10
            let selfReward = 5
            let upper1Reward = 15
            let upper2Reward = 10
            let withdrawRewardAllowed = 1
            let enableInvite = true
            let stakeToken = YouToken.address
            let commissionToken = YouToken.address
    
            let poolParams = [
                poolType, powerRatio, startTimeDelay, priority, maxStakeAmount, lockSeconds,
                multiple, selfReward, upper1Reward, upper2Reward, withdrawRewardAllowed
            ]
    
            let rewardTokens = [YouToken.address]
            let rewardTotals = [createBigNumber6(60)]
            let rewardPerBlocks = [createBigNumber6(1)]
    
            await factoryCreator.setSupportCommTokens(BUSDToken.address, createBigNumber18(10), createBigNumber18(10), true)
            await factoryCreator.setBenefitRate(1000)  //10%
    
            await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)
            await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)
    
            let myFactory = await factoryCreator.getMyFactory(account0.address)
            let myFacoryInstance = await getYouSwapFactoryV2(myFactory)
            expect((await myFacoryInstance.poolIds()).length).to.equal(2);
        })

        it('stake test', async () => {
            // 单元测试
            let myFactory = await factoryCreator.getMyFactory(account0.address)
            let myFacoryInstance = await getYouSwapFactoryV2(myFactory)
            let poolIds = await myFacoryInstance.poolIds()
            let pid = poolIds[0].toString()
            await expect(
                myFacoryInstance.stake(pid, 0)
            ).to.be.revertedWith("YouSwap:STAKE_AMOUNT_TOO_SMALL_OR_TOO_LARGE");

            await YouToken.approve(myFacoryInstance.address, createBigNumber6(10000))
            let core = (await myFacoryInstance.core()).toString()
            let coreIns = await getYouSwapFactoryV2Core(core)

            await expect(myFacoryInstance.stake(pid, 1)).to.emit(coreIns, 'Stake')
            .withArgs(myFacoryInstance.address, pid, YouToken.address, account0.address, 1);
        })
    })

    describe('lock-instance', function () {
        // 不同场景测试
        it('should1', async () => {
            // 单元测试
        })

        it('should2', async () => {
            // 单元测试
        })
    })
})