import { task } from 'hardhat/config'
import { deployXToken, deployTokenYouTest} from '../../helpers/contracts-deployments'
import {
    getFirstSigner,
} from '../../helpers/contracts-getters'
import { CompoundConfig } from '../../markets/eth';
import { SupportTokens } from '../../helpers/types'

task("full:deploy-new-assets", "Deploy unitroller")
    .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, localDRE) => {
        localDRE.run('set-DRE')

        let owner = await getFirstSigner()
        // const reserves = Object.entries(CompoundConfig.ReservesConfig)

        const reserves = Object.entries(CompoundConfig.ReservesConfig).filter(
            ([symbol, _]) => symbol !== SupportTokens.ETHER
        )

        for (let [_, stragety] of reserves) {
            let { initialAmount, tokenName, symbol, decimalUnits } = stragety.underlying
            console.log(initialAmount, tokenName,symbol,decimalUnits)
            // let token = await deployXToken("etherid", initialAmount, tokenName, decimalUnits, symbol)
            // console.log(`deploy ${symbol} new address: ${token.address}`);

            let token = await deployTokenYouTest(symbol, tokenName, decimalUnits, initialAmount)
            console.log(`deploy ${symbol} new address: ${token.address}`);
        }
    })