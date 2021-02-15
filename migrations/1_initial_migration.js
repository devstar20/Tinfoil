const Migrations = artifacts.require("Migrations");

module.exports = async function (deployer, network, accounts) {
    console.log("net id: " + await web3.eth.net.getId());
    console.log("balance: " + web3.utils.fromWei(await web3.eth.getBalance(accounts[0])));
    console.log('\n\n\n');
    console.log('----------------------');
    deployer.deploy(Migrations);
};