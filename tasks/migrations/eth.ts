import { task } from 'hardhat/config'

task("migrations:eth", "Deploy compound protocol on kovan")
    .addFlag('verify', 'Verify contracts at Etherscan')
    .setAction(async ({ verify }, DRE) => {
        console.log("verify:", verify);
        let network = DRE.network.name

        console.log("\n\n === full:deploy-new-assets ===".red.bold);
        await DRE.run("full:deploy-new-assets");

        console.log("\n\n === step 0: run full:initialize ===".red.bold);
        await DRE.run("full:initialize-bsc");

        console.log("\n\n === step 1 run full:01-normal-instance ===".red.bold);
        await DRE.run("full:01-normal-instance", { verify });

        console.log("\n\n === step 2 run full:02-normal-future ===".red.bold);
        await DRE.run("full:02-normal-future", { verify });

        console.log("\n\n === step 3 run full:03-lock-instance ===".red.bold);
        await DRE.run("full:03-lock-instance");

        // console.log("\n\n === step 3 run full:addRewards ===".red.bold);
        // await DRE.run("full:addRewards", { verify });
    })