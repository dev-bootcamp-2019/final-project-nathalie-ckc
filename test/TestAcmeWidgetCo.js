var AcmeWidgetCo = artifacts.require('AcmeWidgetCo');

contract('AcmeWidgetCo', function(accounts) {

    const deployer = accounts[0];
    const admin1 = accounts[1];
    const tester1 = accounts[2];
    const salesdist1 = accounts[3];
    const customer1 = accounts[4];
    const customer2 = accounts[5];


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
    })

});
