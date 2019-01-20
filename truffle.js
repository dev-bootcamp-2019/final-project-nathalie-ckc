const HDWalletProvider = require("truffle-hdwallet-provider");

// dotenv refers to .env, which is in .gitignore
// That's where to keep variables that shouldn't go on Github
require('dotenv').config()  

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(process.env.MNEMONIC, "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY, 0, 10);
      },
      network_id: 4
    }
  }
};
