pragma solidity ^0.4.24;

// Imports go here

contract AcmeWidgetCo {
    //===========================================
    // Struct definitions
    //===========================================
    struct WidgetData {
      uint32 serialNumber;
      uint8 factoryMadeAt;
      uint8 siteTestedAt;
      uint32 testResults;  // bit == 1 => that test passed, 0 => test failed
    }

    // Assumption: Customers don't buy 1 widget from a given bin, they buy lots
    struct WidgetOrderFill {
      uint8 bin;
      // Indices into corresponding bin of widgets
      uint32 firstIndex;
      uint32 lastIndex;
    }

    //===========================================
    // Contract variables
    //===========================================

    // Lists of users by role
    mapping (address => bool) public adminList;
    mapping (address => bool) public testerList;
    mapping (address => bool) public salesDistributorList;
    mapping (address => bool) public customerList;

    // Stores names of factories and test sites
    // During the life of this contract Acme won't ever reach >256 sites
    string[] public factoryList;
    string[] public testSiteList;
    uint8 factoryCount;
    uint8 testSiteCount;

    // Used to ensure we don't add a duplicate factory or test site
    // Uses the keccak256 hash of the string for the lookup
    // Store the index into the string array for that name
    mapping (bytes32 => uint8) public factoryMapping;
    mapping (bytes32 => uint8) public testSiteMapping;

    // Track the widgets. Map the serial number to position in widgetList
    // Assumption: We won't have more than 4 billion widgets
    WidgetData[] public widgetList;
    mapping (uint32 => uint32) public widgetSerialMapping;
    uint32 public widgetCount;
    uint32 public bin1Mask;  // What tests must pass to be in bin1 (most functionality)
    uint32 public bin2Mask;  // What tests must pass to be in bin2
    uint32 public bin3Mask;  // What tests must pass to be in bin3, else unsellable
    uint256 public bin1UnitPrice; // in wei
    uint256 public bin2UnitPrice;
    uint256 public bin3UnitPrice;
    uint32[] public bin1Widgets; // Array of indices into widgetList
    uint32[] public bin2Widgets;
    uint32[] public bin3Widgets;
    uint32 public bin1WidgetCount;
    uint32 public bin2WidgetCount;
    uint32 public bin3WidgetCount;
    uint32 public lastBin1WidgetSold; // Start selling from 0, index of last sold in bin1
    uint32 public lastBin2WidgetSold;
    uint32 public lastBin3WidgetSold;
    mapping (address => WidgetOrderFill[]) public customerWidgetMapping; // Who owns each widget in widgetList

    //===========================================
    // Events
    //===========================================
    event NewAdmin(address indexed _newAdminRegistered);
    event NewTester(address indexed _newTesterRegistered);
    event NewSalesDistributor(address indexed _newSalesDistributorRegistered);
    event NewCustomer(address indexed _newCustomerRegistered);
    event NewFactory(uint8 indexed factoryCount, string _factory);
    event NewTestSite(uint8 indexed testSiteCount, string _testSite);
    event NewTestedWidget(uint32 indexed _serial, uint8 indexed _factory, uint8 _testSite, uint32 indexed _results, uint32 widgetCount);
    event NewUnitPrice(uint8 indexed _bin, uint256 _newPrice);

    //===========================================
    // Modifiers
    //===========================================
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

    //===========================================
    // constructor
    //===========================================
    constructor() public {
        // The first admin is the deployer of the contract
        adminList[msg.sender] = true;

        // These values can only be changed by Sales Distributors
        bin1UnitPrice = 0.1 ether;
        bin2UnitPrice = 0.05 ether;
        bin3UnitPrice = 0.01 ether;
        bin1Mask = 0xFFFFFFFF;
        bin2Mask = 0xFFFF0000;
        bin3Mask = 0xFF000000;
    }

    // fallback function (if exists)
    // external

    //===========================================
    // public
    //===========================================

    //-------------------------
    // Admin functions
    //-------------------------
    function registerAdmin(address _newAdmin) public onlyAdmin {
        adminList[_newAdmin] = true;
        emit NewAdmin(_newAdmin);
    }

    function registerTester(address _newTester) public onlyAdmin {
        testerList[_newTester] = true;
        emit NewTester(_newTester);
    }

    function registerSalesDistributor(address _newSalesDistributor) public onlyAdmin {
        salesDistributorList[_newSalesDistributor] = true;
        emit NewSalesDistributor(_newSalesDistributor);
    }

    function registerCustomer(address _newCustomer) public onlyAdmin {
        customerList[_newCustomer] = true;
        emit NewCustomer(_newCustomer);
    }

    // Returns factoryCount if the factory was successfully added to the list
    // Won't be added if factory is already in the list, so return 0.
    function addFactory(string _factory) public onlyAdmin returns (uint8) {
        require(factoryCount < 255);  // Prevent overflow
        if (factoryMapping[keccak256(abi.encodePacked(_factory))] != 0) {
            return 0;
        } else {
            factoryList.push(_factory);
            factoryMapping[keccak256(abi.encodePacked(_factory))] = factoryCount;
            factoryCount++;
            emit NewFactory(factoryCount, _factory);
            return factoryCount;
        }
    }

    // Returns testSiteCount if the test site was successfully added to the list
    // Won't be added if test site is already in the list, so return 0.
    function addTestSite(string _testSite) public onlyAdmin returns (uint8) {
        require(testSiteCount < 255);  // Prevent overflow
        if (testSiteMapping[keccak256(abi.encodePacked(_testSite))] != 0) {
            return 0;
        } else {
            testSiteList.push(_testSite);
            testSiteMapping[keccak256(abi.encodePacked(_testSite))] = testSiteCount;
            testSiteCount++;
            emit NewTestSite(testSiteCount, _testSite);
            return testSiteCount;
        }
    }

    //-------------------------
    // Tester functions
    //-------------------------
    // Returns the widgetID (i.e. the index into the widgetList for this widget)
    function recordWidgetTests(uint32 _serial, uint8 _factory, uint8 _testSite, uint32 _results)
        public
        onlyTester
        returns (uint32)
    {
        require(_factory < factoryCount);           // Valid factory
        require(_testSite < testSiteCount);         // Valid test site
        require(widgetSerialMapping[_serial] == 0); // Widget not already recorded
        WidgetData memory w;
        w.serialNumber = _serial;
        w.factoryMadeAt = _factory;
        w.siteTestedAt = _testSite;
        w.testResults = _results;
        widgetList.push(w);
        widgetSerialMapping[_serial] = widgetCount; // Save index for serial #
        widgetCount++;
        emit NewTestedWidget(_serial, _factory, _testSite, _results, widgetCount);
        return widgetCount;
    }

    //-------------------------
    // Sales distributor functions
    //-------------------------
    // HACK: Later generalize to N bins, if time allows
    function updateUnitPrice(uint8 _bin, uint256 _newPrice) public onlySalesDistributor {
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        if (_bin == 1) {
            bin1UnitPrice = _newPrice;
        } else if (_bin == 2) {
            bin2UnitPrice = _newPrice;
        } else if (_bin == 3) {
            bin3UnitPrice = _newPrice;
        } else {
            revert(); // Should never get here
        }
        emit NewUnitPrice(_bin, _newPrice);
    }


    // internal
    // private

}
