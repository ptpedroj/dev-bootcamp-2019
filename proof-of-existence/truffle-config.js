const HDWalletProvider = require('truffle-hdwallet-provider');
const infuraKey = "5867368ce4df44b8828d71d759fbaeed";
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
      development: {
          host: 'localhost',
          port: 8545,
          network_id: '*'
      },
      rinkeby: {
        provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/5867368ce4df44b8828d71d759fbaeed'),
        network_id: 4,          // Rinkeby's id
        gas: 5500000,        
      }
  }
};