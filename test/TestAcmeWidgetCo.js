//const Web3 = require('web3');
var Web3 = require('web3');
var web3 = new Web3('ws://localhost:8546');
var AcmeWidgetCo = artifacts.require('AcmeWidgetCo');

contract('AcmeWidgetCo', function(accounts) {

    const deployer = accounts[0];
    const admin1 = accounts[1];
    const tester1 = accounts[2];
    const salesdist1 = accounts[3];
    const customer1 = accounts[4];
    const customer2 = accounts[5];

/*
    it("accounts[0] (deployer) should be an admin", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const isInList = await acmeWidgetCo.adminList(deployer);
        assert.equal(isInList, true, 'accounts[0] (deployer) is not an admin.');
	  })

    it("Test adding admin, tester, salesdist, customers", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        await acmeWidgetCo.registerAdmin(admin1, {from: deployer});
        const isInList = await acmeWidgetCo.adminList(admin1);
        assert.equal(isInList, true, 'accounts[1] (admin1) is not an admin.');

        const notInList = await acmeWidgetCo.adminList(tester1);
        assert.equal(notInList, false, 'accounts[2] (tester1) should not be an admin, but is.');

        await acmeWidgetCo.registerTester(tester1, {from: admin1});
        const isInList1 = await acmeWidgetCo.testerList(tester1);
        assert.equal(isInList1, true, 'admin1 could not add tester1 to testerList.');

        await acmeWidgetCo.registerSalesDistributor(salesdist1, {from: admin1});
        const isInList2 = await acmeWidgetCo.salesDistributorList(salesdist1);
        assert.equal(isInList2, true, 'admin1 could not add salesdist1 to salesDistributorList.');

        await acmeWidgetCo.registerCustomer(customer1, {from: admin1});
        const isInList3 = await acmeWidgetCo.customerList(customer1);
        assert.equal(isInList3, true, 'admin1 could not add customer1 to customerList.');

        await acmeWidgetCo.registerCustomer(customer2, {from: admin1});
        const isInList4 = await acmeWidgetCo.customerList(customer2);
        assert.equal(isInList4, true, 'admin1 could not add customer2 to customerList.');
    })*/

    it("Test admin populating list of factories and test sites", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        await acmeWidgetCo.addFactory("Factory1 Shanghai", {from: deployer});
        const fact1Position = await acmeWidgetCo.factoryMapping(web3.utils.soliditySha3("Factory1 Shanghai"));
        assert.equal(fact1Position.toNumber(), 0, 'Factory1 Shanghai is not in the list');

        await acmeWidgetCo.addFactory("Factory2 Taipei", {from: deployer});
        const fact2Position = await acmeWidgetCo.factoryMapping(web3.utils.soliditySha3("Factory2 Taipei"));
        assert.equal(fact2Position.toNumber(), 1, 'Factory2 Taipei is not in the list');

        await acmeWidgetCo.addTestSite("TS1 Singapore", {from: deployer});
        const ts1Position = await acmeWidgetCo.testSiteMapping(web3.utils.soliditySha3("TS1 Singapore"));
        assert.equal(ts1Position.toNumber(), 0, 'TS1 Singapore is not in the list');

        await acmeWidgetCo.addTestSite("TS2 Osaka", {from: deployer});
        const ts2Position = await acmeWidgetCo.testSiteMapping(web3.utils.soliditySha3("TS2 Osaka"));
        assert.equal(ts2Position.toNumber(), 1, 'TS2 Osaka is not in the list');
    })
});