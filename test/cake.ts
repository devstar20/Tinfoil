const ReceiptToken = artifacts.require("ReceiptToken");
const RewardToken = artifacts.require('RewardToken');
const FakeToken = artifacts.require('FakeToken');
const Farm = artifacts.require('Farm');
const Farmer = artifacts.require('Farmer');
const truffleAssert = require("truffle-assertions");
const testfile = require("../migrations/deployed.js");
const w3 = require("web3");
const toWei = w3.utils.toWei;
const fromWei = w3.utils.fromWei;

const totalRewardsFor = async (account, geyser) => {
    return (await geyser.updateAccounting.call(account, { from: account }))[4];
}

//timers
const timer = require("./helpers/timer.js");
const helper = require("./helpers/helper.js");
const day = 86400;
const week = 7 * day;


contract('Farmer', function (accounts) {

    it('stake CAKE and earn TIN', async function () {
        const farmer = await Farmer.at(testfile.result.farmer);
        const cakeFarm = await Farm.at(testfile.result.cakeFarm);
        const cakeToken = await FakeToken.at(testfile.result.cakeFakeToken);
        const rewardToken = await RewardToken.at(testfile.result.rewardToken);
        const cakeReceiptToken = await ReceiptToken.at(testfile.result.cakeReceiptToken);



        console.log("\n\n Individual geysers locked amount: ");
        console.log("   * CAKE geyser total locked: " + fromWei(await cakeFarm.totalLocked()));

        console.log("\n\n Receipt token balances for accounts: ");
        console.log("   * Account 1 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[1])));
        console.log("   * Account 2 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[2])));

        cakeToken.mint(accounts[1], toWei("1000"));
        cakeToken.mint(accounts[2], toWei("1000"));
        cakeToken.mint(accounts[3], toWei("1000"));
        cakeToken.mint(accounts[4], toWei("1000"));



        console.log("\n\n Approving tokens... ");
        await cakeToken.approve(cakeFarm.address, toWei("100000"), { from: accounts[1] });
        await cakeToken.approve(cakeFarm.address, toWei("100000"), { from: accounts[2] });
        await cakeToken.approve(cakeFarm.address, toWei("100000"), { from: accounts[3] });
        await cakeToken.approve(cakeFarm.address, toWei("100000"), { from: accounts[4] });

        const batch1Join = [cakeToken.address];
        const amounts = [toWei("100")];
        const amounts2 = [toWei("30")];
        const leaveAmounts = [toWei("100")];
        const leaveAmounts2 = [toWei("30")];

        console.log("\n\n Staking tokens... ");
        await farmer.join(batch1Join, amounts2, { from: accounts[1] });
        await farmer.join(batch1Join, amounts2, { from: accounts[2] });
        await farmer.join(batch1Join, amounts, { from: accounts[3] });

        console.log("\n\n Receipt token balances for accounts after staking: ");
        console.log("   * Account 1 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[1])));
        console.log("   * Account 2 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[2])));
        console.log("   * Account 3 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[3])));


        console.log("\n\n Individual geysers staked amount: ");
        console.log("   * CAKE geyser total staked: " + fromWei(await cakeFarm.totalStaked()));

        console.log("\n\n Reading from the geyser manager. Accounts staked amount: ");
        console.log("       * Accounts[1]: " + fromWei(await farmer.getJoined(cakeToken.address, { from: accounts[1] })));
        console.log("       * Accounts[2]: " + fromWei(await farmer.getJoined(cakeToken.address, { from: accounts[2] })));
        console.log("       * Accounts[3]: " + fromWei(await farmer.getJoined(cakeToken.address, { from: accounts[3] })));

        await helper.advanceTimeAndBlock(day * 1);
        console.log(" getCurrentUserRewards acc[1]: " + JSON.stringify(await farmer.getCurrentUserRewards.call(batch1Join, leaveAmounts2, { from: accounts[1] })));
        await farmer.leave(batch1Join, leaveAmounts2, { from: accounts[1] });


        await helper.advanceTimeAndBlock(day * 2);
        console.log(" getCurrentUserRewards acc[3]: " + JSON.stringify(await farmer.getCurrentUserRewards.call(batch1Join, leaveAmounts, { from: accounts[3] })));
        await farmer.leave(batch1Join, leaveAmounts, { from: accounts[3] });
        await farmer.join(batch1Join, amounts, { from: accounts[4] });


        await helper.advanceTimeAndBlock(week * 2);
        console.log(" getCurrentUserRewards acc[2]: " + JSON.stringify(await farmer.getCurrentUserRewards.call(batch1Join, leaveAmounts2, { from: accounts[2] })));
        console.log(" getCurrentUserRewards acc[4]: " + JSON.stringify(await farmer.getCurrentUserRewards.call(batch1Join, leaveAmounts, { from: accounts[4] })));
        await farmer.leave(batch1Join, amounts2, { from: accounts[2] });
        await farmer.leave(batch1Join, amounts, { from: accounts[4] });
        console.log("\n\n TIN tokens balances after leave: ");
        console.log("   Accounts[1]: " + fromWei(await rewardToken.balanceOf(accounts[1])));
        console.log("   Accounts[2]: " + fromWei(await rewardToken.balanceOf(accounts[2])));
        console.log("   Accounts[3]: " + fromWei(await rewardToken.balanceOf(accounts[3])));
        console.log("   Accounts[4]: " + fromWei(await rewardToken.balanceOf(accounts[4])));
        console.log("   Fees collector: " + fromWei(await rewardToken.balanceOf("0x300DCeB0d83C1C120DDd9008A1D3b966197c7055")));

        console.log("\n\n Receipt token balances for accounts after leave: ");
        console.log("   * Account 1 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[1])));
        console.log("   * Account 2 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[2])));
        console.log("   * Account 3 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[3])));
        console.log("   * Account 4 tCAKE: " + fromWei(await cakeReceiptToken.balanceOf(accounts[4])));

    });
});