pragma solidity ^0.4.25;

// Imports go here

contract AcmeWidgetCo {
    // Contract variables
    mapping (address => bool) public adminList;
    mapping (address => bool) public testerList;
    mapping (address => bool) public salesDistributorList;
    mapping (address => bool) public customerList;

    // Modifiers
    modifier onlyAdmin {
        require(
            adminList[msg.sender],
            "Only Admins can run this function."
        );
        _;
    }

    modifier onlyTester {
        require(
            testerList[msg.sender],
            "Only Testers can run this function."
        );
        _;
    }

    modifier onlySalesDistributor {
        require(
            salesDistributorList[msg.sender],
            "Only Sales Distributors can run this function."
        );
        _;
    }

    modifier onlyCustomer {
        require(
            customerList[msg.sender],
            "Only Customers can run this function."
        );
        _;
    }



    // Functions - Within a grouping, place the view and pure functions last
    // constructor
    constructor() public {
        // The first admin is the deployer of the contract
        adminList[msg.sender] = true;
    }



    // fallback function (if exists)
    // external
    // public
    function registerAdmin(address _newAdmin) public onlyAdmin {
        adminList[_newAdmin] = true;
    }

    function registerTester(address _newTester) public onlyAdmin {
        testerList[_newTester] = true;
    }

    function registerSalesDistributor(address _newSalesDistributor) public onlyAdmin {
        salesDistributorList[_newSalesDistributor] = true;
    }

    function registerCustomer(address _newCustomer) public onlyAdmin {
        customerList[_newCustomer] = true;
    }

    // internal
    // private

}
