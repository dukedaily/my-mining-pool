import { task } from 'hardhat/config'
import BigNumber from 'bignumber.js';
import { oneEther, createBigNumber18, createBigNumber8, makePoolId} from '../../helpers/constants'
import {
    getFirstSigner, getXToken, getAccount, getYouSwapFactoryV2, getYouSwapFactoryCreator, getTokenYouTest
} from '../../helpers/contracts-getters'

import Colors = require('colors.ts');
Colors.enable();

task("full:addRewards", "initialize ")
    .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, localDRE) => {
        localDRE.run('set-DRE')
        let currNetwork = localDRE.network.name
        let account0 = await getAccount(0)
        let account1 = await getAccount(1)
        let account2 = await getAccount(2)
        let account3 = await getAccount(3)

        let factoryCreator = await getYouSwapFactoryCreator()
        console.log(await factoryCreator.getAllFactories())
        let myFactory = await factoryCreator.getMyFactory(account0.address)

        let myFacoryInstance = await getYouSwapFactoryV2(myFactory)
        let poolIds = await myFacoryInstance.poolIds()
        console.log("poolIds:", poolIds.toString());

        let YouToken = await getTokenYouTest("You")
        let BUSDToken = await getTokenYouTest("BUSD")
        let UNIToken = await getTokenYouTest("UNI")
        let rewardTokens = [YouToken.address, BUSDToken.address]
        let rewardTotals = [createBigNumber18(10000), createBigNumber18(500)]
        let rewardPerBlocks = [createBigNumber18(1), createBigNumber18(1)]

        for (let i = 0; i < 1; i++) {
            let infos = await myFacoryInstance.getPoolRewardInfo(poolIds[i])
            for (let j = 0; j <infos.length; j++) {
            }
        }

        await BUSDToken.approve(myFacoryInstance.address, createBigNumber18(100000000))
        await UNIToken.approve(myFacoryInstance.address, createBigNumber18(100000000))
        let rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail111:'.yellow, rewardDetail.toString());

        let pendingReward = await myFacoryInstance.pendingRewardV3(poolIds[0], account0.address)
        console.log(`pid: ${poolIds[0]}, pendingRewardV3: ${pendingReward}`.green);

        //addRewardThroughAPR is here!!
        await myFacoryInstance.addRewardThroughAPR(poolIds[0], rewardTokens, rewardTotals, rewardPerBlocks)
        //addRewardThroughAPR is here!!
        await myFacoryInstance.addRewardThroughAPR(poolIds[0], [UNIToken.address], [createBigNumber18(10000)], [createBigNumber18(100)])

        for (let j = 0; j < 10; j++) {
            await myFacoryInstance.setOperateOwner(account0.address, true)
            pendingReward = await myFacoryInstance.connect(account0).pendingRewardV3(poolIds[0], account0.address)
            console.log(`pid: ${poolIds[0]}, pendingRewardV3: ${pendingReward}`.yellow);
        }

        rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail222:'.yellow, rewardDetail.toString());

        console.log("一键领取收益".yellow);
        let b1 = await YouToken.balanceOf(account0.address)
        console.log("一键领取之前：acc0持有you数量:", b1.toString());
        let factoryArr = [myFactory]
        await factoryCreator.withdrawAllRewards(factoryArr)

        rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail333:'.yellow, rewardDetail.toString());
        b1 = await YouToken.balanceOf(account0.address)
        console.log("一键领取之后：acc0持有you数量:", b1.toString());

        let details = await myFacoryInstance.getPoolStakeDetail(poolIds[0])
        console.log(details.toString());

        rewardDetail = await myFacoryInstance.getPoolRewardInfoDetail(poolIds[0])
        console.log('getPoolRewardInfoDetail444:'.yellow, rewardDetail.toString());
    })