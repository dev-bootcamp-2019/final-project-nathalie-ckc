pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './SafeMath32.sol';

contract AcmeWidgetCo {
    using SafeMath for uint256;
    using SafeMath32 for uint32;

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
    // Bin0 is unsellable widgets, so not all 0 indices are populated b/c N/A
    // Bin1 has most functionality, Bin2 a bit less, Bin3 even less
    WidgetData[] public widgetList;
    mapping (uint32 => uint32) public widgetSerialMapping;
    uint32 public widgetCount;
    uint32[4] public binMask;  // What tests must pass to be in each bin.
    uint256[4] public binUnitPrice; // in wei
    uint32[] public bin1Widgets; // Array of indices into widgetList
    uint32[] public bin2Widgets;
    uint32[] public bin3Widgets;
    uint32[4] public binWidgetCount;
    uint32[4] public lastWidgetSoldInBin; // Start selling from 0, index of last sold in bin1
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
    event NewTestedWidget(uint32 indexed _serial, uint8 indexed _factory, uint8 _testSite, uint32 _results, uint32 widgetCount, uint8 indexed bin, uint32 binCount);
    event NewUnitPrice(uint8 indexed _bin, uint256 _newPrice, address indexed _salesDistributor);
    event NewBinMask(uint8 indexed _bin, uint32 _newBinMask, address indexed _salesDistributor);

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
        binUnitPrice[1] = 0.1 ether;
        binUnitPrice[2] = 0.05 ether;
        binUnitPrice[3] = 0.01 ether;
        binMask[1] = 0xFFFFFFFF;
        binMask[2] = 0xFFFF0000;
        binMask[3] = 0xFF000000;
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
        uint8 bin;
        WidgetData memory w;
        w.serialNumber = _serial;
        w.factoryMadeAt = _factory;
        w.siteTestedAt = _testSite;
        w.testResults = _results;
        widgetList.push(w);
        widgetSerialMapping[_serial] = widgetCount; // Save index for serial #

        // HACK: Generalize to N bins if time allows
        // HACK: Figure out 2-D arrays if time allows
        if ((_results & binMask[1]) == binMask[1]) {
            bin1Widgets.push(widgetCount);
            bin = 1;
        } else if ((_results & binMask[2]) == binMask[2]) {
            bin2Widgets.push(widgetCount);
            bin = 2;
        } else if ((_results & binMask[3]) == binMask[3]) {
            bin3Widgets.push(widgetCount);
            bin = 3;
        } else {  // Widgets that don't match a bin are too low quality to sell
            bin = 0;
        }
        binWidgetCount[bin]++;
        widgetCount++;
        emit NewTestedWidget(_serial, _factory, _testSite, _results, widgetCount, bin, binWidgetCount[bin]);
        return widgetCount;
    }

    //-------------------------
    // Sales distributor functions
    //-------------------------
    // HACK: Later generalize to N bins, if time allows
    // Allow sales distributor to update the unit price of any of the bins
    function updateUnitPrice(uint8 _bin, uint256 _newPrice) public onlySalesDistributor {
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        binUnitPrice[_bin] = _newPrice;
        emit NewUnitPrice(_bin, _newPrice, msg.sender);
    }

    function updateBinMask(uint8 _bin, uint32 _newMask) public onlySalesDistributor {
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        binMask[_bin] = _newMask;
        emit NewBinMask(_bin, _newMask, msg.sender);
    }

    //-------------------------
    // Customer functions
    //-------------------------
    // HACK: Generalize to N widgets if time allows
    function buyWidgets(uint8 _bin, uint32 _quantity) payable public onlyCustomer {
        require(_quantity > 0, "Must purchase >0 widgets.");
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        uint32 wCount = binWidgetCount[_bin];
        uint32 lastSold = lastWidgetSoldInBin[_bin];
        uint256 uPrice = binUnitPrice[_bin];
        uint32 stock = wCount.sub(lastSold).sub(1);
        require((_quantity <= stock), "Insufficient stock.");
        require((uint256(_quantity).mul(uPrice) <= msg.value), "Insufficient funds.");

        // HACK: Currently doesn't refund any excess if customer overpaid
        WidgetOrderFill memory w;
        w.bin = _bin;
        w.firstIndex = lastSold + 1;
        w.lastIndex = lastSold + _quantity;

        // LEFT OFF HERE: Need to update lastBinXWidgetSold

        customerWidgetMapping[msg.sender].push(w);

        // TODO: Need to emit event about the sale
    }


    // internal
    // private

}
