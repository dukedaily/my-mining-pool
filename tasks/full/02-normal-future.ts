import { task } from 'hardhat/config'
import BigNumber from 'bignumber.js';
import { oneEther, createBigNumber18, createBigNumber6, createBigNumber8, makePoolId } from '../../helpers/constants'
import {
    getFirstSigner, getXToken, getAccount, getYouSwapFactoryV2, getYouSwapFactoryCreator, getTokenYouTest, getYouSwapInviteV1
} from '../../helpers/contracts-getters'

import Colors = require('colors.ts');
Colors.enable();

task("full:02-normal-future", "01-normal-instance ")
    .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, localDRE) => {
        localDRE.run('set-DRE')

        let YouToken = await getTokenYouTest('You')
        let BUSDToken = await getTokenYouTest("BUSD")
        let UNIToken = await getTokenYouTest("UNI")
        let WBTCToken = await getTokenYouTest("WBTC")

        let account0 = await getAccount(0)
        let account1 = await getAccount(1)
        let account2 = await getAccount(2)
        let account3 = await getAccount(3)
        let account4 = await getAccount(4)

        let factoryCreator = await getYouSwapFactoryCreator()

        //白名单
        await factoryCreator.setWhiteList(account0.address, false)

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

        let powerRatio = 1
        let startTimeDelay = 5
        let priority = 1
        let maxStakeAmount = createBigNumber6(10000000)
        let poolType = 0 //normal
        let lockSeconds = 30000 //60
        let multiple = 10
        let selfReward = 5
        let upper1Reward = 15
        let upper2Reward = 10
        let enableInvite = true
        let stakeToken = YouToken.address
        let commissionToken = YouToken.address

        //整合的参数:  {poolTypeNormal, powerRatio, startTime, priority, maxStakeAmount, lockSeconds, rewardDecRate}
        let poolParams = [
            poolType, powerRatio, startTimeDelay, priority, maxStakeAmount, lockSeconds,
            multiple, selfReward, upper1Reward, upper2Reward
        ]

        let rewardTokens = [YouToken.address]
        let rewardTotals = [createBigNumber6(60)]
        let rewardPerBlocks = [createBigNumber6(1)]

        console.log("当前时间:", (new Date().getTime()) / 1000)
        console.log("startTimeDelay:", startTimeDelay)

        console.log("设置佣金币种, BUSD".yellow);
        await factoryCreator.setSupportCommTokens(BUSDToken.address, createBigNumber18(10), createBigNumber18(10), true)

        //设置手续费
        console.log("设置手续费比例:".yellow, "10%");
        // await factoryCreator.setBenefitRate(1000)  //10%

        console.log('创建：normal-future'.blue.bold);
        await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)
        await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)

        let myFactory = await factoryCreator.getMyFactory(account0.address)
        console.log("myFactory:", myFactory.toString());

        let myFacoryInstance = await getYouSwapFactoryV2(myFactory)
        let poolIds = await myFacoryInstance.poolIds()

        let poolDetail = await myFacoryInstance.getPoolStakeDetail(poolIds[2])
        console.log("pre poolDetail:", poolDetail.toString())

        console.log('poolCount:', poolIds.length);
        console.log('pool ids:', (await myFacoryInstance.poolIds()).toString())

        /*
        console.log("建立邀请关系invite");
        let inviteIns = await getYouSwapInviteV1()
        await inviteIns.connect(account0).acceptInvitation(account1.address)
        await inviteIns.connect(account2).acceptInvitation(account0.address)
        await inviteIns.connect(account3).acceptInvitation(account2.address)

        let inviteUp2 = await inviteIns.inviteUpper2(account2.address)
        console.log("inviteUp2: ".yellow, inviteUp2);

        let inviteLow2 = await inviteIns.inviteLower2(account2.address)
        console.log("inviteLow2: ".yellow, inviteLow2);
        */

        let rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[2])
        console.log('getPoolRewardInfoDetail:'.yellow, rewardDetail.toString());

        console.log("************** account0 操作质押stake!*****************".red);
        await YouToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await UNIToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await BUSDToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await WBTCToken.connect(account0).approve(myFacoryInstance.address, createBigNumber6(100000000))

        await YouToken.connect(account1).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await YouToken.connect(account2).approve(myFacoryInstance.address, createBigNumber18(100000000))

        let pid0 = poolIds[2].toString()
        let pid1 = poolIds[1].toString()

        await myFacoryInstance.stake(pid0, createBigNumber6(10000))
        for (let j = 0; j < 10; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
            console.log(`pid: ${poolIds[2]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
        }

        //增加APR1
        let rewardTokens1 = [UNIToken.address]
        let rewardTotals1 = [createBigNumber18(1000)]
        let rewardPerBlocks1 = [createBigNumber18(100)]

        //增加APR2
        let rewardTokens2 = [UNIToken.address]
        let rewardTotals2 = [createBigNumber18(1)]
        let rewardPerBlocks2 = [createBigNumber18(0.1)]

        //addRewardThroughAPR is here!!
        console.log('call addRewardThroughAPR'.red);
        await myFacoryInstance.addRewardThroughAPR(pid0, rewardTokens1, rewardTotals1, rewardPerBlocks1)
        for (let j = 0; j < 20; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
            console.log(`pid: ${poolIds[2]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true)
        }
        await myFacoryInstance.stake(pid0, createBigNumber6(10000))

        console.log('call addRewardThroughTime'.red);
        await myFacoryInstance.addRewardThroughTime(pid0, rewardTokens2, rewardTotals2)

        //addRewardThroughAPR is here!!
        await myFacoryInstance.addRewardThroughAPR(pid1, rewardTokens2, rewardTotals2, rewardPerBlocks2)

        for (let j = 0; j < 10; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
            console.log(`pid: ${poolIds[2]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true)
        }

        await myFacoryInstance.connect(account0).stake(pid0, createBigNumber6(10000))

        let b = await YouToken.balanceOf(factoryCreator.address)
        console.log("balanceOf You Token : ", b.toString())

        let ids = [poolIds[2].toString(), poolIds[1].toString()];
        console.log("批量解质押：".yellow, ids);
        await myFacoryInstance.unStakes(ids);

        // await myFacoryInstance.unStake(pid0, createBigNumber6(10000));

        for (let j = 0; j < 10; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
            console.log(`pid: ${poolIds[2]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true)
        }

        // await myFacoryInstance.unStake(pid0, createBigNumber6(10000));

        for (let j = 0; j < 10; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
            console.log(`pid: ${poolIds[2]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true)
        }

        console.log("********* reopen ****************".yellow);
        let b1 = await YouToken.balanceOf(account0.address)
        console.log(b1.toString())

        await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
        for (let j = 0; j < 50; j++) {
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
            await BUSDToken.approve(factoryCreator.address, createBigNumber18(100000000))
        }

        //reopen is here!!!
        // await factoryCreator.reopen(poolIds[2], YouToken.address, poolParams, rewardTokens1, rewardTotals1, rewardPerBlocks1)
        await factoryCreator.reopen(poolIds[2], YouToken.address, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)

        let info = await myFacoryInstance.getPoolStakeDetail(10000)
        console.log(`info: ${info}`.yellow);

        console.log("reopen后质押:stake".green)
        //stake is here!!!
        await myFacoryInstance.connect(account0).stake(poolIds[2], createBigNumber6(10000))
        let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[2], account0.address)
        console.log(`刚刚质押后 pid: ${poolIds[2]}, pendingReward: ${pendingReward}`.yellow);
    })