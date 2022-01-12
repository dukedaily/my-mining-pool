import { task } from 'hardhat/config'

import { deployStandardToken } from '../../helpers/contracts-deployments'
import {
    getUnitroller,
    getFirstSigner,
    getComptroller,
} from '../../helpers/contracts-getters'

task("verify:verify", "Deploy unitroller")
    .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, localDRE) => {
        localDRE.run('set-DRE')
        let owner = await getFirstSigner()

        address: "0x0D0D1FBA787D1dc4d6fDE380F62235785f9BE5b4",
        constructorArguments: [
            50,
            "a string argument",
            {
                x: 10,
                y: 5,
            },
            "0xabcdef",
        ],
    })