const ReceiptToken = artifacts.require("ReceiptToken");
const RewardToken = artifacts.require("RewardToken");
const MockToken = artifacts.require("MockToken");
const Farmer = artifacts.require("Farmer");
const Farm = artifacts.require("Farm");
const Vault = artifacts.require("Vault");
const deployed = require("./deployed.js");

module.exports = async (deployer, network, accounts) => {
    const minterRole = web3.utils.keccak256("MINTER_ROLE");
    const burnerRole = web3.utils.keccak256("BURNER_ROLE");
    //mainnet addresses
    const feeAddress = "0x300DCeB0d83C1C120DDd9008A1D3b966197c7055";
    let cakeTokenAddress = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"; //not const as we need a fake cake to test everything
    const bakeTokenAddress = "0xe02df9e3e622debdd69fb838bb799e3f168902c5";
    const autoTokenAddress = "0xa184088a740c695e156f91f5cc086a06bb78b827";
    const xvsTokenAddress = "0xcf6bb5389c92bdda8a3747ddb454cb7a64626c63";
    const bunnyTokenAddress = "0xc9849e6fdb743d08faee3e34dd2d1bc69ea11a51";
    const burgerTokenAddress = "0xae9269f27437f0fcbc232d39ec814844a51d6b8f";
    const wSoteTokenAddress = "0x541e619858737031a1244a5d0cd47e5ef480342c";
    const bifiTokenAddress = "0xca3f508b8e4dd382ee878a314789373d80a5190a";

    // deployed contracts
    let result = {};

    console.log("creating TIN token");
    await deployer.deploy(
        RewardToken,
        "TINFOIL Token",
        "TIN",
        web3.utils.toWei("50000")
    );
    const rewardToken = await RewardToken.deployed();
    result.rewardToken = rewardToken.address;
    console.log("reward token: " + rewardToken.address);

    console.log("creating TIN token receipt");
    const rewardReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tTINFOIL Token",
        "tTIN"
    );
    result.rewardReceiptToken = rewardReceiptToken.address;
    console.log("tTIN token: " + rewardReceiptToken.address);

    console.log("creating cake token receipt");
    const cakeReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tPancakeSwap",
        "tCAKE"
    );
    result.cakeReceiptToken = cakeReceiptToken.address;
    console.log("tCAKE token: " + cakeReceiptToken.address);

    console.log("creating bake token receipt");
    const bakeReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tBakeryToken",
        "tBAKE"
    );
    result.bakeReceiptToken = bakeReceiptToken.address;
    console.log("tBAKE token: " + bakeReceiptToken.address);

    console.log("creating auto token receipt");
    const autoReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tAuto",
        "tAUTO"
    );
    result.autoReceiptToken = autoReceiptToken.address;
    console.log("tAUTO token: " + autoReceiptToken.address);


    console.log("creating xvs token receipt");
    const xvsReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tVenus",
        "tXVS"
    );
    result.xvsReceiptToken = xvsReceiptToken.address;
    console.log("tXVS token: " + xvsReceiptToken.address);

    console.log("creating bunny token receipt");
    const bunnyReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tPancake Bunny",
        "tBUNNY"
    );
    result.bunnyReceiptToken = bunnyReceiptToken.address;
    console.log("tBUNNY token: " + bunnyReceiptToken.address);

    console.log("creating burger token receipt");
    const burgerReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tBurger Swap",
        "tBURGER"
    );
    result.burgerReceiptToken = burgerReceiptToken.address;
    console.log("tBURGER token: " + burgerReceiptToken.address);

    console.log("creating wsote token receipt");
    const wSoteReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tSoteria",
        "tWSOTE"
    );
    result.wSoteReceiptToken = wSoteReceiptToken.address;
    console.log("tWSOTE token: " + wSoteReceiptToken.address);

    console.log("creating bifi token receipt");
    const bifiReceiptToken = await deployer.deploy(
        ReceiptToken,
        "tBeefy.Finance",
        "tBIFI"
    );
    result.bifiReceiptToken = bifiReceiptToken.address;
    console.log("tBIFI token: " + bifiReceiptToken.address);


    if (await web3.eth.net.getId() != "1") {
        console.log("deploying fake cake")
        const cakeToken = await deployer.deploy(
            MockToken,
            "Birthday cake token",
            "CAKE"
        );
        result.cakeFakeToken = cakeToken.address;
        cakeTokenAddress = cakeToken.address;
        console.log("minting fake cake")
        await cakeToken.mint(accounts[0], web3.utils.toWei('10000'));
    }



    const maxUnlockSchedules = 40000;
    const initialSharesPerToken = 1;

    const startBonus = 0;
    const bonusDecimals = 3;
    const bonusPeriodInSeconds = 1209600;



    console.log("deploying farmer");
    const farmer = await deployer.deploy(
        Farmer
    );
    result.farmer = farmer.address;



    console.log("deploying cake farm");
    const cakeFarm = await deployer.deploy(
        Farm,
        cakeTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.cakeReceiptToken,
        feeAddress
    );
    result.cakeFarm = cakeFarm.address;
    await cakeReceiptToken.grantRole(minterRole, cakeFarm.address);
    await cakeReceiptToken.grantRole(burnerRole, cakeFarm.address);

    console.log("deploying bake farm");
    const bakeFarm = await deployer.deploy(
        Farm,
        bakeTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.bakeReceiptToken,
        feeAddress
    );
    result.bakeFarm = bakeFarm.address;
    await bakeReceiptToken.grantRole(minterRole, bakeFarm.address);
    await bakeReceiptToken.grantRole(burnerRole, bakeFarm.address);

    console.log("deploying auto farm");
    const autoFarm = await deployer.deploy(
        Farm,
        autoTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.autoReceiptToken,
        feeAddress
    );
    result.autoFarm = autoFarm.address;
    await autoReceiptToken.grantRole(minterRole, autoFarm.address);
    await autoReceiptToken.grantRole(burnerRole, autoFarm.address);

    console.log("deploying xvs farm");
    const xvsFarm = await deployer.deploy(
        Farm,
        xvsTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.xvsReceiptToken,
        feeAddress
    );
    result.xvsFarm = xvsFarm.address;
    await xvsReceiptToken.grantRole(minterRole, xvsFarm.address);
    await xvsReceiptToken.grantRole(burnerRole, xvsFarm.address);

    console.log("deploying bunny farm");
    const bunnyFarm = await deployer.deploy(
        Farm,
        bunnyTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.bunnyReceiptToken,
        feeAddress
    );
    result.bunnyFarm = bunnyFarm.address;
    await bunnyReceiptToken.grantRole(minterRole, bunnyFarm.address);
    await bunnyReceiptToken.grantRole(burnerRole, bunnyFarm.address);

    console.log("deploying burger farm");
    const burgerFarm = await deployer.deploy(
        Farm,
        burgerTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.burgerReceiptToken,
        feeAddress
    );
    result.burgerFarm = burgerFarm.address;
    await burgerReceiptToken.grantRole(minterRole, burgerFarm.address);
    await burgerReceiptToken.grantRole(burnerRole, burgerFarm.address);


    console.log("deploying wsote farm");
    const wSoteFarm = await deployer.deploy(
        Farm,
        wSoteTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.wSoteReceiptToken,
        feeAddress
    );
    result.wSoteFarm = wSoteFarm.address;
    await wSoteReceiptToken.grantRole(minterRole, wSoteFarm.address);
    await wSoteReceiptToken.grantRole(burnerRole, wSoteFarm.address);

    console.log("deploying bifi farm");
    const bifiFarm = await deployer.deploy(
        Farm,
        bifiTokenAddress,
        rewardToken.address,
        maxUnlockSchedules,
        startBonus,
        bonusPeriodInSeconds,
        initialSharesPerToken,
        bonusDecimals,
        result.farmer,
        result.bifiReceiptToken,
        feeAddress
    );
    result.bifiFarm = bifiFarm.address;
    await bifiReceiptToken.grantRole(minterRole, bifiFarm.address);
    await bifiReceiptToken.grantRole(burnerRole, bifiFarm.address);


    // console.log("deploying tin farm");
    // const tinStartBonus = 400;
    // const tinBonusPeriod = 31104000; //1 year

    // const tinFarm = await deployer.deploy(
    //     Farm,
    //     rewardToken.address,
    //     rewardToken.address,
    //     maxUnlockSchedules,
    //     tinStartBonus,
    //     tinBonusPeriod,
    //     initialSharesPerToken,
    //     bonusDecimals,
    //     result.farmer,
    //     result.rewardReceiptToken,
    //     feeAddress
    // );
    // result.tinFarm = tinFarm.address;
    // await tinReceiptToken.grantRole(minterRole, tinFarm.address);
    // await tinReceiptToken.grantRole(burnerRole, tinFarm.address);



    console.log("Adding farms to the farmer");
    console.log("cake farm");
    await farmer.addFarm(cakeTokenAddress, result.cakeFarm);
    console.log("bake farm");
    await farmer.addFarm(bakeTokenAddress, result.bakeFarm);
    console.log("auto farm");
    await farmer.addFarm(autoTokenAddress, result.autoFarm);
    console.log("xvs farm");
    await farmer.addFarm(xvsTokenAddress, result.xvsFarm);
    console.log("bunny farm");
    await farmer.addFarm(bunnyTokenAddress, result.bunnyFarm);
    console.log("burger farm");
    await farmer.addFarm(burgerTokenAddress, result.burgerFarm);
    console.log("wsote farm");
    await farmer.addFarm(wSoteTokenAddress, result.wSoteFarm);
    console.log("bifi farm");
    await farmer.addFarm(bifiTokenAddress, result.bifiFarm);
    // console.log("reward farm");
    // await farmer.addFarm(rewardToken.address, result.tinFarm);


    console.log("Lock rewards into farms");
    const ONE_HOUR = 3600;
    const ONE_DAY = 24 * ONE_HOUR;
    const ONE_WEEK = 7 * ONE_DAY;
    const ONE_MONTH = 30 * ONE_DAY;
    const ONE_YEAR = 365 * ONE_DAY;

    // 7500 to burger, wsote, bunny, xvs, bake and bifi (1250 each)
    // 5000 to cake, auto (2500 each)
    // 5000 to TIN 
    // 7500 to TIN LP
    const baseReward = 1000;
    const bakeReward = 1250; //5%
    const xvsReward = 1250;//5%
    const bunnyReward = 1250;//5%
    const burgerReward = 1250;//5%
    const wsoteReward = 1250;//5%
    const bifiReward = 1250;//5%

    const autoReward = 2500; //10%
    const cakeReward = 1875; //7.5%

    const tCakeReward = 625//2.5%; do not deploy yet
    const tinReward = 5000; //do not deploy yet
    const tinLpReward = 7500; //do not deploy yet

    console.log("cake approve");
    await rewardToken.approve(cakeFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("bake approve");
    await rewardToken.approve(bakeFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("auto approve");
    await rewardToken.approve(autoFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("xvs approve");
    await rewardToken.approve(xvsFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("bunny approve");
    await rewardToken.approve(bunnyFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("burger approve");
    await rewardToken.approve(burgerFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("wsote approve");
    await rewardToken.approve(wSoteFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    console.log("bifi approve");
    await rewardToken.approve(bifiFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });
    // console.log("tin approve");
    // await rewardToken.approve(tinFarm.address, web3.utils.toWei("100000"), { from: accounts[0] });

    console.log("cake lock");
    await cakeFarm.lockTokens(web3.utils.toWei(cakeReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("bake lock");
    await bakeFarm.lockTokens(web3.utils.toWei(bakeReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("auto lock");
    await autoFarm.lockTokens(web3.utils.toWei(autoReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("xvs lock");
    await xvsFarm.lockTokens(web3.utils.toWei(xvsReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("bunny lock");
    await bunnyFarm.lockTokens(web3.utils.toWei(bunnyReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("burger lock");
    await burgerFarm.lockTokens(web3.utils.toWei(burgerReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("wsote lock");
    await wSoteFarm.lockTokens(web3.utils.toWei(wsoteReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    console.log("bifi lock");
    await bifiFarm.lockTokens(web3.utils.toWei(bifiReward.toString()), 2 * ONE_WEEK, { from: accounts[0] })
    // console.log("tin lock");
    // await tinFarm.lockTokens(web3.utils.toWei(tinReward.toString()), 12 * ONE_MONTH, { from: accounts[0] })

    console.log("\n\n\n\n\n deployed below ");
    console.log(result);
    deployed.result = result;


    console.log("\n ending balance: " + web3.utils.fromWei(await web3.eth.getBalance(accounts[0])));



};
