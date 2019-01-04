pragma solidity ^0.4.24;

// Imports go here

contract AcmeWidgetCo {
    // Contract variables
    mapping (address => bool) public adminList;
    mapping (address => bool) public testerList;
    mapping (address => bool) public salesDistributorList;
    mapping (address => bool) public customerList;

    // Stores names of factories and test sites
    string[] public factoryList;
    string[] public testSiteList;

    // Used to ensure we don't add a duplicate factory or test site
    // Uses the keccak256 hash of the string for the lookup
    mapping (bytes32 => bool) public factoryMapping;
    mapping (bytes32 => bool) public testSiteMapping;

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

    // Returns true if the factory was successfully added to the list
    // Won't be added if factory is already in the list, so return false.
    function addFactory(string _factory) public onlyAdmin returns (bool) {
        if (factoryMapping[keccak256(abi.encodePacked(_factory))]) {
            return false;
        } else {
            factoryList.push(_factory);
            return true;
        }
    }

    // Returns true if the test site was successfully added to the list
    // Won't be added if test site is already in the list, so return false.
    function addTestSite(string _testSite) public onlyAdmin returns (bool) {
        if (testSiteMapping[keccak256(abi.encodePacked(_testSite))]) {
            return false;
        } else {
            testSiteList.push(_testSite);
            return true;
        }
    }


    // internal
    // private

}
