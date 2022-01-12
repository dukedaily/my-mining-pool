import { task } from 'hardhat/config'
import BigNumber from 'bignumber.js';
import {oneEther, createBigNumber18,createBigNumber8 } from '../../helpers/constants'
import {
    getFirstSigner, getXToken, getAccount, getTokenYouTest
} from '../../helpers/contracts-getters'

import { 
    deployYouSwapInvite, 
    deployYouSwapFactory, 
    deployYouSwapFactoryCore,
    deployYouSwapFactoryCreator,
    deployTokenYouTest
} from '../../helpers/contracts-deployments'

import Colors = require('colors.ts');
Colors.enable();

import { CompoundConfig } from '../../markets/eth';
task("full:initialize", "initialize ")
    // .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, localDRE) => {
        localDRE.run('set-DRE')
        let currNetwork = localDRE.network.name

        let youTokenSymbol = 'You'
        let YouToken = await getTokenYouTest(youTokenSymbol) //10亿：1000000000
        let invite1 = await deployYouSwapInvite()
        let factoryV2 = await deployYouSwapFactory()
        let factoryV2Core = await deployYouSwapFactoryCore()
        let factoryCreator = await deployYouSwapFactoryCreator(
            YouToken.address, 
            invite1.address,
            createBigNumber18(600), 
            createBigNumber18(600))
        await factoryCreator.setPoolFactoryTemplate(factoryV2.address)
        await factoryCreator.setCoreTemplate(factoryV2Core.address)

        console.log("You:", YouToken.address);
        console.log("invite1:", invite1.address);
        console.log("factoryV2模板:", factoryV2.address);
        console.log("factoryV2Core模板:", factoryV2Core.address);
        console.log("factoryCreator:", factoryCreator.address);
    })