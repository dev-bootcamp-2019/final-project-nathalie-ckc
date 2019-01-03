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
        assert.equal(isInList, true, 'accounts[0] (deployer) is not an admin');
	  })

});
