import { task } from 'hardhat/config'

// npx hardhat accounts --hello1 "hello duke" --hello2 "hello lily"
task('accounts', "Display all accounts")
    .addOptionalParam('hello1', "hello world1", "hello world1")
    .addOptionalParam('hello2', "hello world2", "hello world2")
    .setAction(async (args, hre) => {
        console.log('args1:', args.hello1);
        console.log('args2:', args.hello2);

        const accounts = await hre.ethers.getSigners();
        for (const account of accounts) {
            console.log(account.address);
        }
    })