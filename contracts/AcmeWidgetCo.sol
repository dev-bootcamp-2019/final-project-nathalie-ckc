pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './SafeMath32.sol';

/// @title Contract to manage and sell widgets for Acme Widget Company
/// @author Nathalie C. Chan King Choy
contract AcmeWidgetCo {
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    //===========================================
    // Struct definitions
    //===========================================
    // The information about a single widget
    struct WidgetData {
      uint32 serialNumber;
      uint8 factoryMadeAt;
      uint8 siteTestedAt;
      uint32 testResults;  // bit == 1 => that test passed, 0 => test failed
      // e.g. testResults == 0xFFFFFFFF means all 32 tests passed
      // e.g. testResults == 0xFFFF0000 means only the first 16 tests passed
    }

    // Assumption: Customer will buy >1 widget in an order.
    // The information for an order of widgets from a particular bin.
    // Widgets are sold in array index order
    // e.g. Customer buys 5 widgets. If [1] was the last widget sold in that
    //      bin, then firstIndex is [2], lastIndex is [6] for this order.
    struct WidgetOrderFill {
      uint8 bin;
      // Indices into corresponding bin of widgets
      uint32 firstIndex;
      uint32 lastIndex;
    }

    //===========================================
    // Contract variables
    //===========================================
    // Circuit breaker
    bool public stopContract;

    // Lists of users by role
    mapping (address => uint8) public addr2Role;
    // Enum may seem appropriate, but you have to document the decoding anyway
    // because the enum isn't accessible in JavaScript, so skip using enum.
    // This is how to decode:
    // Admin = 1
    // Tester = 2
    // Sales Distributor = 3
    // Customer = 4


    // Assumption: During the life of this contract Acme won't ever reach >256 sites
    // Stores names of factories and test sites
    string[] public factoryList;
    string[] public testSiteList;
    uint8 public factoryCount;
    uint8 public testSiteCount;


    // Used to ensure we don't add a duplicate factory or test site
    // Uses the keccak256 hash of the string for the lookup
    // Store the index into the string array for that name
    mapping (bytes32 => uint8) public factoryMapping;
    mapping (bytes32 => uint8) public testSiteMapping;


    // Track the widgets. Map the serial number to position in widgetList
    // Assumption: We won't have more than 4 billion widgets
    // Bin0 is unsellable widgets (i.e. did not have the correct sets of
    //   passing test results. So, not all 0 indices are populated b/c N/A.
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
    // HACK: Because using uint instead of int, widget[0] never really gets sold
    // TODO: Deal with that later if time allows
    uint32[4] public lastWidgetSoldInBin; // Index of last sold in that bin
    mapping (address => WidgetOrderFill[]) public customerWidgetMapping; // Who owns each widget in widgetList


    //===========================================
    // Events
    //===========================================
    event NewAdmin(address indexed _newAdminRegistered);
    event NewTester(address indexed _newTesterRegistered);
    event NewSalesDistributor(address indexed _newSalesDistributorRegistered);
    event NewCustomer(address indexed _newCustomerRegistered);
    event NewFactory(uint8 indexed _factoryCount, string _factory);
    event NewTestSite(uint8 indexed _testSiteCount, string _testSite);
    event NewTestedWidget(uint32 indexed _serial, uint8 indexed _factory, uint8 _testSite, uint32 _results, uint32 _widgetCount, uint8 indexed _bin, uint32 _binCount);
    event NewUnitPrice(uint8 indexed _bin, uint256 _newPrice, address indexed _salesDistributor);
    event NewBinMask(uint8 indexed _bin, uint32 _newBinMask, address indexed _salesDistributor);
    event WidgetSale(uint8 indexed _bin, uint32 _quantity, address indexed _customer, uint256 _totalAmtPaid);


    //===========================================
    // Modifiers
    //===========================================
    modifier onlyAdmin {
        require(
            (addr2Role[msg.sender] == 1),
            "Only Admins can run this function."
        );
        _;
    }

    modifier onlyTester {
        require(
            (addr2Role[msg.sender] == 2),
            "Only Testers can run this function."
        );
        _;
    }

    modifier onlySalesDistributor {
        require(
            (addr2Role[msg.sender] == 3),
            "Only Sales Distributors can run this function."
        );
        _;
    }

    modifier onlyCustomer {
        require(
            (addr2Role[msg.sender] == 4),
            "Only Customers can run this function."
        );
        _;
    }

    // Circuit breaker
    modifier stopInEmergency {
        if (!stopContract) _;
    }

    modifier onlyInEmergency {
        if (stopContract) _;
    }


    //===========================================
    // constructor
    //===========================================
    /// @notice Set up initial conditions for the contract, on deployment
    constructor() public {
        // Circuit breaker
        stopContract = false;

        // The first admin is the deployer of the contract
        addr2Role[msg.sender] = 1;

        // These values can only be changed by Sales Distributors
        binUnitPrice[1] = 0.1 ether;
        binUnitPrice[2] = 0.05 ether;
        binUnitPrice[3] = 0.01 ether;
        binMask[1] = 0xFFFFFFFF;
        binMask[2] = 0xFFFF0000;
        binMask[3] = 0xFF000000;
    }

    // fallback function (if exists)

    //===========================================
    // public
    //===========================================

    //-------------------------
    // Admin functions
    //-------------------------

    /// @notice Circuit breaker enable - start emergency mode
    function beginEmergency() public onlyAdmin {
        stopContract = true;
    }

    /// @notice Circuit breaker disable - end emergency mode
    function endEmergency() public onlyAdmin {
        stopContract = false;
    }

    // Functions to add to user lists

    /// @notice Admin can add another admin
    /// @dev Admin has privileges for adding users, sites, or stopping contract
    /// @param _newAdmin is Ethereum address of the new admin
    function registerAdmin(address _newAdmin) public onlyAdmin {
        require(addr2Role[_newAdmin] == 0);
        addr2Role[_newAdmin] = 1;
        emit NewAdmin(_newAdmin);
    }

    /// @notice Admin can add another tester
    /// @dev Tester has privileges to record test results for widgets
    /// @param _newTester is Ethereum address of the new tester
    function registerTester(address _newTester) public onlyAdmin {
        require(addr2Role[_newTester] == 0);
        addr2Role[_newTester] = 2;
        emit NewTester(_newTester);
    }

    /// @notice Admin can add another sales distributor
    /// @dev Sales dist. has privileges to update bin masks and unit prices
    /// @param _newSalesDistributor is Ethereum address of the new sales dist.
    function registerSalesDistributor(address _newSalesDistributor) public onlyAdmin {
        require(addr2Role[_newSalesDistributor] == 0);
        addr2Role[_newSalesDistributor] = 3;
        emit NewSalesDistributor(_newSalesDistributor);
    }

    /// @notice Admin can add another customer
    /// @dev Customer has privileges to buy widgets
    /// @param _newCustomer is Ethereum address of the new customer
    function registerCustomer(address _newCustomer) public onlyAdmin {
        require(addr2Role[_newCustomer] == 0);
        addr2Role[_newCustomer] = 4;
        emit NewCustomer(_newCustomer);
    }

    /// @notice Admin can add another factory for tester to choose from
    /// @dev Won't be added if _factory is already in the list
    /// @param _factory is the name of the new factory.
    function addFactory(string _factory) public onlyAdmin {
        require(factoryCount < 255);  // Prevent overflow
        require(factoryMapping[keccak256(abi.encodePacked(_factory))] == 0);

        factoryList.push(_factory);
        factoryMapping[keccak256(abi.encodePacked(_factory))] = factoryCount;
        factoryCount++;

        emit NewFactory(factoryCount, _factory);
    }

    /// @notice Admin can add another test site for tester to choose from
    /// @dev Won't be added if _testSite is already in the list
    /// @param _testSite is the name of the new test site.
    function addTestSite(string _testSite) public onlyAdmin {
        require(testSiteCount < 255);  // Prevent overflow
        require(testSiteMapping[keccak256(abi.encodePacked(_testSite))] == 0);

        testSiteList.push(_testSite);
        testSiteMapping[keccak256(abi.encodePacked(_testSite))] = testSiteCount;
        testSiteCount++;

        emit NewTestSite(testSiteCount, _testSite);
    }


    //-------------------------
    // Tester functions
    //-------------------------

    /// @notice Tester records the factory where the widget was made, the site
    ///   where it was tested, and the test results for a given widget serial #
    /// @dev Won't be added if serial # is already in the list
    /// @dev TODO: Generalize to N bins if time allows
    /// @dev TODO: Figure out 2-D arrays if time allows
    /// @param _serial is the serial number for the widget under test
    /// @param _factory is the factory where the widget was made
    /// @param _testSite is the site where the widget was tested
    /// @param _results is the bit mapping of what tests passed or failed
    ///   bit == 1 => that test passed, 0 => test failed
    ///   e.g. testResults == 0xFFFFFFFF means all 32 tests passed
    ///   e.g. testResults == 0xFFFF0000 means only the first 16 tests passed
    function recordWidgetTests(uint32 _serial, uint8 _factory, uint8 _testSite, uint32 _results)
        public
        onlyTester
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
    }

    //-------------------------
    // Sales distributor functions
    //-------------------------

    /// @notice Sales distributor can update the unit price of any of the bins
    /// @dev TODO: Later generalize to N bins, if time allows
    /// @param _bin is the bin whose price is getting updated
    /// @param _newPrice is the new price in wei
    function updateUnitPrice(uint8 _bin, uint256 _newPrice) public onlySalesDistributor {
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        binUnitPrice[_bin] = _newPrice;
        emit NewUnitPrice(_bin, _newPrice, msg.sender);
    }

    /// @notice Sales distributor can update the mask of any of the bins
    /// @dev TODO: Later generalize to N bins, if time allows
    /// @dev Mask is how we know what bin a widget belongs in.  Widget must have
    ///   a 1 in its test result in all positions where mask is 1 to get into
    ///   that particular bin
    /// @param _bin is the bin whose mask is getting updated
    /// @param _newMask is the new mask value (e.g. 0xFFFFFF00)
    function updateBinMask(uint8 _bin, uint32 _newMask) public onlySalesDistributor {
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        binMask[_bin] = _newMask;
        emit NewBinMask(_bin, _newMask, msg.sender);
    }


    //-------------------------
    // Customer functions
    //-------------------------

    /// @notice Function for customer to buy widgets from a specific bin
    /// @dev This function is stopped by the circuit breaker
    /// @dev TODO: Later generalize to N bins, if time allows
    /// @dev TODO: Currently doesn't refund any excess if customer overpaid
    /// @dev TODO: Currently only way to withdraw funds is when killing the contract.
    /// @param _bin is the bin from which the customer wants to buy widgets
    /// @param _quantity is the number of widgets to buy
    function buyWidgets(uint8 _bin, uint32 _quantity) payable public onlyCustomer stopInEmergency {
        require(_quantity > 0, "Must purchase >0 widgets.");
        require((_bin > 0) && (_bin <=3), "Bin must be between 1 to 3, inclusive");
        uint32 wCount = binWidgetCount[_bin];
        uint32 lastSold = lastWidgetSoldInBin[_bin];
        uint256 uPrice = binUnitPrice[_bin];
        uint32 stock = wCount.sub(lastSold).sub(1);
        require((_quantity <= stock), "Insufficient stock. NOTE: widget[0] in each bin is not for sale.");
        require((uint256(_quantity).mul(uPrice) <= msg.value), "Insufficient funds.");

        WidgetOrderFill memory w;
        w.bin = _bin;
        w.firstIndex = lastSold.add(1);
        w.lastIndex = lastSold.add(_quantity);

        customerWidgetMapping[msg.sender].push(w);
        lastWidgetSoldInBin[_bin] = w.lastIndex;

        emit WidgetSale(_bin, _quantity, msg.sender, msg.value);
    }

}
