const {expect} = require("chai");
import {describe} from "mocha";
// require("@nomiclabs/hardhat-waffle");
const HRE = require("hardhat");

describe("V2-mining test", function () {
    let owner;
    let addr1;
    let addr2;
    let addrs;

    //部署动作
    it("hello", async function () {
        // 前置部署：initialize相关
        let YouToken = await HRE.ethers.getContractFactory("TokenYouTest");
        [owner, addr1, addr2, ...addrs] = await HRE.ethers.getSigners();

        console.log("owner:", owner.address, 'addr1:', addr1.address)

        let initAmount = 1000
        let tokenName = "YOU Token"
        let symbol = "YOU"
        let decimals = 1

        let YouTokenIns = await YouToken.deploy(symbol, tokenName, decimals, initAmount)
        const ownerBalance = await YouTokenIns.balanceOf(owner.address);
        const totalSupply = await YouTokenIns.totalSupply()
        console.log("ownerBalance:", ownerBalance.toNumber())
        console.log("totalSupply:", totalSupply.toNumber())

        expect(totalSupply.toNumber()).to.equal(ownerBalance.toNumber());
    })
})

