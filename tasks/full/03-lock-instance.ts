import { task } from 'hardhat/config'
import BigNumber from 'bignumber.js';
import { oneEther, createBigNumber18, createBigNumber6, createBigNumber8, makePoolId } from '../../helpers/constants'
import {
    getFirstSigner, getXToken, getAccount, getYouSwapFactoryV2, getYouSwapFactoryCreator, getTokenYouTest, getYouSwapInviteV1
} from '../../helpers/contracts-getters'

import Colors = require('colors.ts');
Colors.enable();

task("full:03-lock-instance", "03-lock-instance")
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
        await factoryCreator.setWhiteList(account0.address, true)

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
        let startTimeDelay = 0
        let priority = 1
        let maxInt = new BigNumber('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 16)
        console.log('maxInt:', maxInt.toFixed())
        let maxStakeAmount = maxInt.toFixed()
        let poolType = 2 //lock
        let lockSeconds = 300 //60
        let multiple = 10
        let selfReward = 5
        let upper1Reward = 15
        let upper2Reward = 10
        let enableInvite = false
        let stakeToken = BUSDToken.address
        let commissionToken = YouToken.address
        let withdrawRewardAllowed = 0 //是否允许领取奖励(锁仓期间), 0不允许，1允许

        //整合的参数:  {poolTypeNormal, powerRatio, startTime, priority, maxStakeAmount, lockSeconds, rewardDecRate}
        let poolParams = [
            poolType, powerRatio, startTimeDelay, priority, maxStakeAmount, lockSeconds,
            multiple, selfReward, upper1Reward, upper2Reward, withdrawRewardAllowed
        ]

        let rewardTokens = [YouToken.address]
        let rewardTotals = [createBigNumber6(50000)]
        let rewardPerBlocks = [createBigNumber6(100)]

        console.log("当前时间:", (new Date().getTime()) / 1000)
        console.log("startTimeDelay:", startTimeDelay)

        console.log("设置佣金币种, BUSD".yellow);
        await factoryCreator.setSupportCommTokens(BUSDToken.address, createBigNumber18(10), createBigNumber18(10), true)

        //设置手续费
        console.log("设置新创建矿池手续费比例:".yellow, "10%");
        await factoryCreator.setBenefitRate(1000)  //10%

        console.log('创建：normal-instance'.blue.bold);
        await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)
        await factoryCreator.createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)

        console.log("1111111")

        let myFactory = await factoryCreator.getMyFactory(account0.address)
        console.log("myFactory:", myFactory.toString());

        await factoryCreator.setSupportCommTokens(BUSDToken.address, createBigNumber18(10), createBigNumber18(10), true)
        console.log("佣金币种详情:", (await factoryCreator.getSupportCommTokens()).toString())

        let myFacoryInstance = await getYouSwapFactoryV2(myFactory)
        let poolIds = await myFacoryInstance.poolIds()

        let balanceYouToken = await YouToken.balanceOf((await myFacoryInstance.core()).toString())
        console.log('创建矿池后core balanceYouToken:', balanceYouToken.toString());

        await YouToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000000))

        console.log("设置旧矿池手续费比例:".yellow, "20%");
        await factoryCreator.setBenefitRate(2000)  //10%

        let rewardDetail0 = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail0:'.yellow, rewardDetail0.toString());

        console.log('addRewardThroughAPR'.red);
        // await myFacoryInstance.addRewardThroughAPR(poolIds[0], rewardTokens, rewardTotals, rewardPerBlocks)
        await myFacoryInstance.addRewardThroughTime(poolIds[0], rewardTokens, rewardTotals);

        console.log('benefitRate:', (await factoryCreator.getBenefitRate()).toString())

        balanceYouToken = await YouToken.balanceOf((await myFacoryInstance.core()).toString())
        console.log('增加APR之后，balanceYouToken:', balanceYouToken.toString());

        let rewardDetail1 = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail1:'.yellow, rewardDetail1.toString());

        await factoryCreator.connect(account1).createPool(0, stakeToken, commissionToken, enableInvite, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)
        balanceYouToken = await YouToken.balanceOf((await myFacoryInstance.core()).toString())
        console.log('创建矿池后balanceYouToken:', balanceYouToken.toString());

        let myFactory1 = await factoryCreator.getMyFactory(account1.address)
        console.log("myFactory1:", myFactory.toString());

        let myFacoryInstance1 = await getYouSwapFactoryV2(myFactory1)
        console.log('account1 pool ids:', (await myFacoryInstance1.poolIds()).toString())

        let poolDetail = await myFacoryInstance.getPoolStakeDetail(poolIds[0])
        console.log("pre poolDetail:", poolDetail.toString())

        let newName = "hello world"
        console.log("修改名字为:", newName)
        await factoryCreator.setName(account0.address, poolIds[0], newName)

        poolDetail = await myFacoryInstance.getPoolStakeDetail(poolIds[0])
        console.log("名字改变了-》new poolDetail:", poolDetail.toString())

        console.log('poolCount:', poolIds.length);
        console.log('account0 pool ids:', (await myFacoryInstance.poolIds()).toString())

        console.log("建立邀请关系invite");
        let inviteIns = await getYouSwapInviteV1()
        await inviteIns.connect(account0).acceptInvitation(account1.address)
        await inviteIns.connect(account2).acceptInvitation(account0.address)
        await inviteIns.connect(account3).acceptInvitation(account2.address)

        let inviteUp2 = await inviteIns.inviteUpper2(account2.address)
        console.log("inviteUp2: ".yellow, inviteUp2);

        let inviteLow2 = await inviteIns.inviteLower2(account2.address)
        console.log("inviteLow2: ".yellow, inviteLow2);

        let rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail:'.yellow, rewardDetail.toString());

        console.log("************** account0 操作质押stake!*****************".red);
        await YouToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await UNIToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await BUSDToken.connect(account0).approve(myFacoryInstance.address, createBigNumber18(100000000000000000000000000000000000000000000000000000000000))
        await WBTCToken.connect(account0).approve(myFacoryInstance.address, createBigNumber6(100000000))

        await YouToken.connect(account1).approve(myFacoryInstance.address, createBigNumber18(100000000))
        await YouToken.connect(account2).approve(myFacoryInstance.address, createBigNumber18(100000000))

        let pid0 = poolIds[0].toString()
        await myFacoryInstance.stake(pid0, createBigNumber6(1))
        let pendingReward2 = await myFacoryInstance.pendingRewardV3(pid0, account0.address)
        console.log(`pid: ${poolIds[0]}, pendingRewardV3: ${pendingReward2}`.green);

        console.log("大质押量测试!".yellow);
        let _pid0 = poolIds[0].toString()
        await myFacoryInstance.stake(_pid0, createBigNumber18(100000000000000))
        // await myFacoryInstance.stake(_pid0, createBigNumber18(1))

        //增加APR1
        let rewardTokens1 = [UNIToken.address]
        let rewardTotals1 = [createBigNumber18(100000)]
        let rewardPerBlocks1 = [createBigNumber18(1)]

        //addRewardThroughAPR is here!!
        // console.log('call addRewardThroughAPR'.red);
        // await myFacoryInstance.addRewardThroughAPR(pid0, rewardTokens1, rewardTotals1, rewardPerBlocks1)

        for (let j = 0; j < 20; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
            console.log(`pid: ${poolIds[0]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
        }

        console.log("大量赎回后!".yellow);
        // await myFacoryInstance.unStake(_pid0, createBigNumber18(99999999999999))
        // await myFacoryInstance.unStake(_pid0, createBigNumber18(99999999999999))
        // await myFacoryInstance.unStake(_pid0, createBigNumber18(99999999999999))
        // await myFacoryInstance.unStake(_pid0, createBigNumber18(19999999999999))

        for (let j = 0; j < 20; j++) {
            let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
            console.log(`pid: ${poolIds[0]}, pendingRewardV3: ${pendingReward}`.green);
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
            await myFacoryInstance.setOperateOwner(account0.address, true) //空操作
        }

        // console.log("准备赎回!");
        // await myFacoryInstance.unStakes([pid0])
        // await factoryCreator.setWithdrawAllowed(account0.address, pid0, true) //

        let pendingReward1 = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
        console.log(`withdrawReward前 pid: ${poolIds[0]}, acc0 pendingReward1: ${pendingReward1}`.yellow);
        
        console.log("准备withdrawAll!".yellow);
        // await myFacoryInstance.withdrawReward(pid0)
        await factoryCreator.withdrawAllRewards([myFacoryInstance.address])

        pendingReward1 = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
        console.log(`withdrawReward后 pid: ${poolIds[0]}, acc0 pendingReward1: ${pendingReward1}`.yellow);

        let infoRewardDetail1 = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log(`infoRewardDetail1: ${infoRewardDetail1}`.yellow);

        console.log("********* reopen ****************".yellow);
        let b1 = await YouToken.balanceOf(account0.address)
        console.log(b1.toString())

        await BUSDToken.approve(factoryCreator.address, createBigNumber18(10000000000000))

        //reopen is here!!!
        await factoryCreator.reopen(poolIds[0], YouToken.address, poolParams, rewardTokens, rewardTotals, rewardPerBlocks)

        console.log("reopen后解质押:unstake".green)
        await myFacoryInstance.unStake(pid0, createBigNumber6(10000000000000));

        // console.log("reopen后质押:stake".green)
        // //stake is here!!!
        // await myFacoryInstance.connect(account0).stake(poolIds[0], createBigNumber6(10000))
        let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
        console.log(`解质押后 pid: ${poolIds[0]}, acc0 pendingReward: ${pendingReward}`.yellow);

        let info = await myFacoryInstance.getPoolStakeDetail(10000)
        console.log(`getPoolStakeDetail: ${info}`.yellow);

        let infoRewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log(`infoRewardDetail: ${infoRewardDetail}`.yellow);

        pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[0], account1.address)
        console.log(`解质押后 pid: ${poolIds[0]}, acc1 pendingReward: ${pendingReward}`.yellow);
    })