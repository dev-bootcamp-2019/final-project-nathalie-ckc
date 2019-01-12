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

    // From https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript
    let catchRevert = require("./exceptions.js").catchRevert;

/*
    it("accounts[0] (deployer) should be an admin", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const isInList = await acmeWidgetCo.adminList(deployer);
        assert.equal(isInList, true, 'accounts[0] (deployer) is not an admin.');
	  })
*/


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
    })


    it("Test admin populating list of factories and test sites", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        await acmeWidgetCo.addFactory("Factory1 Shanghai", {from: admin1});
        const fact1Position = await acmeWidgetCo.factoryMapping(web3.utils.soliditySha3("Factory1 Shanghai"));
        assert.equal(fact1Position.toNumber(), 0, 'Factory1 Shanghai is not in the list.');

        await acmeWidgetCo.addFactory("Factory2 Taipei", {from: admin1});
        const fact2Position = await acmeWidgetCo.factoryMapping(web3.utils.soliditySha3("Factory2 Taipei"));
        assert.equal(fact2Position.toNumber(), 1, 'Factory2 Taipei is not in the list.');

        await acmeWidgetCo.addTestSite("TS1 Singapore", {from: admin1});
        const ts1Position = await acmeWidgetCo.testSiteMapping(web3.utils.soliditySha3("TS1 Singapore"));
        assert.equal(ts1Position.toNumber(), 0, 'TS1 Singapore is not in the list.');

        await acmeWidgetCo.addTestSite("TS2 Osaka", {from: admin1});
        const ts2Position = await acmeWidgetCo.testSiteMapping(web3.utils.soliditySha3("TS2 Osaka"));
        assert.equal(ts2Position.toNumber(), 1, 'TS2 Osaka is not in the list.');
    })

    it("Test tester recording widget result", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        await acmeWidgetCo.recordWidgetTests(1234001, 1, 1, 0xFFFFFFFF, {from: tester1});
        const widget1 = await acmeWidgetCo.widgetList(0);
        assert.equal(widget1[0], 1234001, 'Widget1 incorrect serial number.');
        assert.equal(widget1[1], 1, 'Widget1 incorrect factory.');
        assert.equal(widget1[2], 1, 'Widget1 incorrect test site.');
        assert.equal(widget1[3], 0xFFFFFFFF, 'Widget1 incorrect recorded test result.');
    })

    it("Test that additional factory and test sites are usable", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        await acmeWidgetCo.addFactory("Factory3 Delhi", {from: deployer});
        const fact3Position = await acmeWidgetCo.factoryMapping(web3.utils.soliditySha3("Factory3 Delhi"));
        assert.equal(fact3Position.toNumber(), 2, 'Factory3 Delhi is not in the list.');

        await acmeWidgetCo.addTestSite("TS3 Austin", {from: deployer});
        const ts3Position = await acmeWidgetCo.testSiteMapping(web3.utils.soliditySha3("TS3 Austin"));
        assert.equal(ts3Position.toNumber(), 2, 'TS3 is not in the list.');

        await acmeWidgetCo.recordWidgetTests(1234002, 2, 2, 0xFFFF1234, {from: tester1});
        const widget2 = await acmeWidgetCo.widgetList(1);
        assert.equal(widget2[0], 1234002, 'Widget2 incorrect serial number.');
        assert.equal(widget2[1], 2, 'Widget2 incorrect factory.');
        assert.equal(widget2[2], 2, 'Widget2 incorrect test site.');
        assert.equal(widget2[3], 0xFFFF1234, 'Widget2 incorrect recorded test result.');
    })

    it("Test that the recorded widgets in the expected bins", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const b1Count = await acmeWidgetCo.binWidgetCount(1);
        assert.equal(b1Count, 1, 'Bin1 should have 1 widget.');

        const b1W0 = await acmeWidgetCo.bin1Widgets(0);
        const widget1 = await acmeWidgetCo.widgetList(b1W0);
        assert.equal(widget1[0], 1234001, 'Widget1 should be the first in Bin1.');

        const b2Count = await acmeWidgetCo.binWidgetCount(1);
        assert.equal(b2Count, 1, 'Bin2 should have 1 widget.');

        const b2W0 = await acmeWidgetCo.bin2Widgets(0);
        const widget2 = await acmeWidgetCo.widgetList(b2W0);
        assert.equal(widget2[0], 1234002, 'Widget2 should be the first in Bin2.');
    })

    it("Test that sales distributor can update bin unit price.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const b1PriceB4 = await acmeWidgetCo.binUnitPrice(1);
        assert.equal(b1PriceB4, 100000000000000000, 'Bin1 price should be set to 100000000000000000 wei by constructor.');
        await acmeWidgetCo.updateUnitPrice(1, 200000000000000000, {from: salesdist1});
        const b1PriceAfter = await acmeWidgetCo.binUnitPrice(1);
        assert.equal(b1PriceAfter, 200000000000000000, 'Bin1 price should be set to 200000000000000000 wei.');

        const b2PriceB4 = await acmeWidgetCo.binUnitPrice(2);
        assert.equal(b2PriceB4, 50000000000000000, 'Bin2 price should be set to 50000000000000000 wei by constructor.');
        await acmeWidgetCo.updateUnitPrice(2, 60000000000000000, {from: salesdist1});
        const b2PriceAfter = await acmeWidgetCo.binUnitPrice(2);
        assert.equal(b2PriceAfter, 60000000000000000, 'Bin2 price should be set to 60000000000000000 wei.');

        const b3PriceB4 = await acmeWidgetCo.binUnitPrice(3);
        assert.equal(b3PriceB4, 10000000000000000, 'Bin3 price should be set to 10000000000000000 wei by constructor.');
        await acmeWidgetCo.updateUnitPrice(3, 30000000000000000, {from: salesdist1});
        const b3PriceAfter = await acmeWidgetCo.binUnitPrice(3);
        assert.equal(b3PriceAfter, 30000000000000000, 'Bin3 price should be set to 30000000000000000 wei.');
    })

    it("Test that sales distributor can update the bin mask.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const b1MaskB4 = await acmeWidgetCo.binMask(1);
        assert.equal(b1MaskB4, 0xFFFFFFFF, "Bin1 mask should be set to 0xFFFFFFFF by constructor.");
        await acmeWidgetCo.updateBinMask(1, 0xFFFFFFFE, {from: salesdist1});
        const b1MaskAfter = await acmeWidgetCo.binMask(1);
        assert.equal(b1MaskAfter, 0xFFFFFFFE, "Bin1 mask should be set to 0xFFFFFFFE.");

        const b2MaskB4 = await acmeWidgetCo.binMask(2);
        assert.equal(b2MaskB4, 0xFFFF0000, "Bin2 mask should be set to 0xFFFF0000 by constructor.");
        await acmeWidgetCo.updateBinMask(2, 0xFFFE0000, {from: salesdist1});
        const b2MaskAfter = await acmeWidgetCo.binMask(2);
        assert.equal(b2MaskAfter, 0xFFFE0000, "Bin2 mask should be set to 0xFFFE0000.");

        const b3MaskB4 = await acmeWidgetCo.binMask(3);
        assert.equal(b3MaskB4, 0xFF000000, "Bin3 mask should be set to 0xFF000000 by constructor.");
        await acmeWidgetCo.updateBinMask(3, 0xFE000000, {from: salesdist1});
        const b3MaskAfter = await acmeWidgetCo.binMask(3);
        assert.equal(b3MaskAfter, 0xFE000000, "Bin3 mask should be set to 0xFE000000.");
    })

    it("Test that customer can only buy widgets that cost <= their msg.value.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        // Add a bunch of widgets to bin1
        await acmeWidgetCo.recordWidgetTests(1234003, 1, 1, 0xFFFFFFFF, {from: tester1});
        await acmeWidgetCo.recordWidgetTests(1234004, 1, 2, 0xFFFFFFFF, {from: tester1});
        await acmeWidgetCo.recordWidgetTests(1234005, 2, 1, 0xFFFFFFFF, {from: tester1});
        await acmeWidgetCo.recordWidgetTests(1234006, 2, 2, 0xFFFFFFFF, {from: tester1});

        // Should not be able to buy widget
        const lwBin1B4 = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1B4, 0, "Should not have sold any Bin1 widgets yet.");
        await catchRevert(acmeWidgetCo.buyWidgets(1, 2, {from: customer1, value: 100}));
        const lwBin1After = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1After, 0, "Should still not have sold any Bin1 widgets yet.");

    })

    it("Test customer can't buy more widgets than available even with sufficent msg.value.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        // Should not show any widgets as having been bought
        const lwBin1B4 = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1B4, 0, "Should not have sold any Bin1 widgets yet.");
        await catchRevert(acmeWidgetCo.buyWidgets(1, 8, {from: customer1, value: 1700000000000000000}));
        const lwBin1After = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1After, 0, "Should still not have sold any Bin1 widgets yet.");
    })

    it("Test that customer can't buy when circuit breaker stops contract.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const stoppedStateB4 = await acmeWidgetCo.stopContract();
        assert.equal(stoppedStateB4, false, "Contract should not be in stopped state yet.");
        await acmeWidgetCo.beginEmergency({from: admin1});
        await acmeWidgetCo.buyWidgets(1, 3, {from: customer1, value: 600000000000000000});
        const lwBin1After = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert.equal(lwBin1After, 0, "Should not have sold any Bin1 widgets yet.");
        await acmeWidgetCo.endEmergency({from: admin1});
        const stoppedStateAfter = await acmeWidgetCo.stopContract();
        assert.equal(stoppedStateAfter, false, "Contract should not be in stopped state any more.");
    })

    it("Test that customer can buy multiple widgets from same bin in 1 transaction.", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();

        const lwBin1B4 = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1B4, 0, "Should not have sold any Bin1 widgets yet.");
        await acmeWidgetCo.buyWidgets(1, 3, {from: customer1, value: 600000000000000000});
        const lwBin1After = await acmeWidgetCo.lastWidgetSoldInBin(1);
        assert (lwBin1After, 3, "Should have sold widgets 1-3 from Bin1.");
    })

/*
    it("Is unit price what I expected?", async() => {
        const acmeWidgetCo = await AcmeWidgetCo.deployed();
        const bin1up = await acmeWidgetCo.binUnitPrice(1);
        console.log("Bin1 Unit Price: ", bin1up.toNumber());
    })
    */
});
