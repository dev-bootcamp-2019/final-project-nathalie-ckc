AcmeApp = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    return await AcmeApp.initWeb3();
  },

  initWeb3: async function() {
    // Modern dapp browsers...
    if (window.ethereum) {
      AcmeApp.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access");
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      AcmeApp.web3web3Provider = window.web3.currentProvider;
    }
    // if no injected web3 instance is detected, fall back to Ganache
    else {
      AcmeApp.web3web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(AcmeApp.web3Provider);

    return AcmeApp.initContract();
  },

  initContract: function() {
    $.getJSON('AcmeWidgetCo.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var AcmeArtifact = data;
      AcmeApp.contracts.AcmeWidgetCo = TruffleContract(AcmeArtifact);
      // Set the provider for our contract
      AcmeApp.contracts.AcmeWidgetCo.setProvider(AcmeApp.web3Provider);

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        var factoryEvent = acmeInstance.NewFactory();
        var tsEvent = acmeInstance.NewTestSite();
        factoryEvent.watch(function(error, result) {
          if (!error) {
            console.log("Factory added: ", result.args._factoryCount.toNumber(), " ", result.args._factory);
          }
        });
        tsEvent.watch(function(error, result) {
          if (!error) {
            console.log("Test site added: ", result.args._testSiteCount.toNumber(), " ", result.args._testSite);
          }
        });
      }).catch(function(err) {
        console.log(err, message);
      });

      return AcmeApp.displayCurrentAccount();
    });

    return AcmeApp.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.login-btn', AcmeApp.handleLogin);
  },

  //-----------------------------------------------
  // Admin functions
  //-----------------------------------------------
  regUser: function(role) {
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        switch(role) {
          case 1:
            console.log("new-admin:", $('#new-admin').val());
            return acmeInstance.registerAdmin($('#new-admin').val(), {from:accounts[0]});
          case 2:
            console.log("new-tester:", $('#new-tester').val());
            return acmeInstance.registerTester($('#new-tester').val(), {from:accounts[0]});
          case 3:
            console.log("new-salesdist:", $('#new-salesdist').val());
            return acmeInstance.registerSalesDistributor($('#new-salesdist').val(), {from:accounts[0]});
          case 4:
            console.log("new-customer:", $('#new-customer').val());
            return acmeInstance.registerCustomer($('#new-customer').val(), {from:accounts[0]});
          default:
            console.log("Invalid role specified when calling regUser().");
        }
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },

  addLoc: function(locType) {
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        switch(locType) {
          case 1:
            console.log("new-factory:", $('#new-factory').val());
            return acmeInstance.addFactory($('#new-factory').val(), {from:accounts[0]});
          case 2:
            console.log("new-test-site:", $('#new-test-site').val());
            return acmeInstance.addTestSite($('#new-test-site').val(), {from:accounts[0]});
          default:
            console.log("Invalid location type specified when calling addLoc().");
        }
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },

  beginEmerg: function() {
    AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
      console.log("Enabling EMERGENCY state.");
      acmeInstance.beginEmergency();
    }).catch(function(err) {
      console.log(err, message);
    });
  },

  endEmerg: function() {
    AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
      console.log("Disabling EMERGENCY state.");
      acmeInstance.endEmergency();
    }).catch(function(err) {
      console.log(err, message);
    });
  },

  //-----------------------------------------------
  // Tester functions
  //-----------------------------------------------
  recordWidget: function() {
    console.log("Submit was clicked");
    var acmeInstance;
    var factorySelect = $('#factory-select').val();
    var factoryNum;
    var tsSelect = $('#test-site-select').val();
    var tsNum;
    var serial = $('#widget-serial-num').val();
    var testres = $('#widget-test-result').val();
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(instance) {
        acmeInstance = instance;
        return acmeInstance.factoryMapping(web3.sha3(factorySelect));
      }).then(function(result) {
        factoryNum = result.toNumber();
        return acmeInstance.testSiteMapping(web3.sha3(tsSelect));
      }).then(function(result) {
        tsNum = result.toNumber();
        console.log("serial: ", serial);
        console.log("factory-select: ", factorySelect, " factoryNum: ", factoryNum);
        console.log("test-site-select: ", tsSelect, "tsNum: ", tsNum);
        console.log("testres: ", testres);
        return acmeInstance.recordWidgetTests(serial, factoryNum, tsNum, testres, {from:accounts[0]});
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },

  //-----------------------------------------------
  // Sales distributor functions
  //-----------------------------------------------
  updateUPrice: function() {
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        console.log("Updating bin ", $('#new-bin-uprice-bin').val(), "unit price to ", $('#new-bin-uprice').val());
        return acmeInstance.updateUnitPrice($('#new-bin-uprice-bin').val(), $('#new-bin-uprice').val(), {from:accounts[0]});
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },

  updateMask: function() {
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        console.log("Updating bin ", $('#new-bin-mask-bin').val(), "mask to ", $('#new-bin-mask').val());
        return acmeInstance.updateBinMask($('#new-bin-mask-bin').val(), $('#new-bin-mask').val(), {from:accounts[0]});
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },

  //-----------------------------------------------
  // Customer functions
  //-----------------------------------------------
  calculateCost: function() {
    AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
      console.log("In calculateCost. Bin: ", $('#calc-buy-from-bin').val());
      return acmeInstance.binUnitPrice($('#calc-buy-from-bin').val());
    }).then(function(result) {
      var binUPrice = result.toNumber();
      var totalCost = $('#calc-buy-qty').val() * binUPrice;
      $('#calc-total-cost').text(totalCost);
      console.log("Cost for buying ", $('#calc-buy-qty').val(), " widgets from bin ", $('#calc-buy-from-bin').val());
      console.log("is ", totalCost, " wei.");
    }).catch(function(err) {
      console.log(err, message);
    });
  },

  buy: function() {
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(acmeInstance) {
        console.log("Buying from bin ", $('#buy-from-bin').val(), "this many widgets: ", $('#buy-qty').val());
        console.log("Sending payment in wei of: ", $('#send-funds').val());
        return acmeInstance.buyWidgets($('#buy-from-bin').val(), $('#buy-qty').val(), {from:accounts[0], value:$('#send-funds').val()});
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  },


  displayCurrentAccount: function() {
    $('#login-screen').show();
    /*$('#admin-screen').show();
    $('#tester-screen').show();
    $('#salesdist-screen').show();
    $('#customer-screen').show();*/
    $('#admin-screen').hide();
    $('#tester-screen').hide();
    $('#salesdist-screen').hide();
    $('#customer-screen').hide();
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      // [0] is always whatever the active account is in Metamask
      $('.curr-acct-is').text(accounts[0]);
    });
  },

  handleLogin: function(event) {
    event.preventDefault();

    var acmeInstance;
    var role;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      // [0] is always whatever the active account is in Metamask
      var account = accounts[0];

      AcmeApp.contracts.AcmeWidgetCo.deployed().then(function(instance) {
        acmeInstance = instance;
        return acmeInstance.addr2Role(account);
      }).then(function(result) {
        role = result.toNumber();
        console.log("addr2Role(account) ", role);
        $('#login-screen').hide();
        (role == 1) ? $('#admin-screen').show() : $('#admin-screen').hide();
        if (role == 2) {
          acmeInstance.testSiteCount().then(function(tscount) {
            var tsct = tscount.toNumber();
            var tsSelect = $('#test-site-select');
            var tsTemplate = $('#test-site-template');
            console.log("tsct: ", tsct);
            console.log("tsSelect: ", tsSelect);
            console.log("tsTemplate: ", tsTemplate);

            for (i = 0; i < tsct; i ++) {
              acmeInstance.testSiteList(i).then(function(tsname) {
                console.log("tsname: ", tsname);
                tsTemplate.find('.ts-name').text(tsname);
                tsSelect.append(tsTemplate.html());
              });
            }
          });
          acmeInstance.factoryCount().then(function(fcount) {
            var fct = fcount.toNumber();
            var fSelect = $('#factory-select');
            var fTemplate = $('#factory-template');
            console.log("fct: ", fct);
            console.log("fSelect: ", fSelect);
            console.log("fTemplate: ", fTemplate);

            for (j = 0; j < fct; j++) {
              acmeInstance.factoryList(j).then(function(fname) {
                console.log(" fname: ", fname);
                fTemplate.find('.factory-name').text(fname);
                fSelect.append(fTemplate.html());
              });
            }
          });
          $('#tester-screen').show();
        } else {
          $('#tester-screen').hide();
        }
        (role == 3) ? $('#salesdist-screen').show() : $('#salesdist-screen').hide();
        (role == 4) ? $('#customer-screen').show() : $('#customer-screen').hide();
      }).catch(function(err) {
        console.log(err, message);
      });
    });
  }

};

$(function() {
  $(window).load(function() {
    AcmeApp.init();
  });
});
