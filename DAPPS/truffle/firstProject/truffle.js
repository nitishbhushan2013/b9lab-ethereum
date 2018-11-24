const Web3 = require("web3");
const net = require("net");


module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 500000,
      network_id: "*" // Match any network id
    },
    net42: {
      host: "localhost",
      port: 8545,
      gas: 500000,
      network_id: 42 // Match any network id
    },
    ropsten: {
      provider: new Web3.providers.IpcProvider("/Users/nitishbhushan/Library/Ethereum/testnet/geth.ipc", net),
      network_id: 3
    }
  }
};
