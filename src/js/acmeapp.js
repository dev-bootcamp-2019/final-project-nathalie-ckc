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
      return AcmeApp.displayCurrentAccount();
    })

    return AcmeApp.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.login-btn', AcmeApp.handleLogin);
  },

  displayCurrentAccount: function() {
    $('#login-screen').show();
    $('#admin-screen').hide();
    $('#tester-screen').hide();
    $('#salesdist-screen').hide();
    $('#customer-screen').hide();
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      // [0] is always whatever the active account is in Metamask
      var account = accounts[0];

      var currAccount = $('.curr-acct-is');
      currAccount.text(account);
      //console.log("Account is", account);
    });
  },

  handleLogin: function(event) {
    event.preventDefault();

    var acmeInstance;

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
        var role = result.toNumber();
        console.log("addr2Role(account) ", role);
        $('#login-screen').hide();
        (role == 1) ? $('#admin-screen').show() : $('#admin-screen').hide();
        (role == 2) ? $('#tester-screen').show() : $('#tester-screen').hide();
        (role == 3) ? $('#salesdist-screen').show() : $('#salesdist-screen').hide();
        (role == 3) ? $('#customer-screen').show() : $('#customer-screen').hide();
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
