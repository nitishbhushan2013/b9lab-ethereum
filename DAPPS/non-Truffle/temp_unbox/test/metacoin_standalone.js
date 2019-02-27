const Web3 = require('web3');
const web3 = new Web3();

const Ganache = require('ganache-cli');
web3.setProvider(Ganache.provider());

const Promise = require('bluebird');
Promise.promisifyAll(web3.eth, { suffix: "Promise" });
Promise.promisifyAll(web3.version, { suffix: "Promise" });
const assert = require('assert-plus'); 

const truffleContract = require("truffle-contract"); // it returns Promise 


const ConvertLib = truffleContract(require(__dirname + "/../build/contracts/ConvertLib.json"));
ConvertLib.setProvider(web3.currentProvider);
const MetaCoin = truffleContract(require(__dirname + "/../build/contracts/MetaCoin.json"));
MetaCoin.setProvider(web3.currentProvider);

describe("MetaCoin", function() {
    let accounts, networkId, convertLib, metaCoin;

    before("get accounts", function() {
        return web3.eth.getAccountsPromise()
            .then(_accounts => accounts = _accounts)
            .then(() => web3.version.getNetworkPromise())
            .then(_networkId => {
                networkId = _networkId;
                ConvertLib.setNetwork(networkId);
                MetaCoin.setNetwork(networkId);
            });
    });

    before("deploy library", function() {
        return ConvertLib.new({ from: accounts[0], gas: 3000000 })
            .then(_convertLib => convertLib = _convertLib)
            .then(() => MetaCoin.link({ ConvertLib: convertLib.address }));
    });

    beforeEach("deploy a MetaCoin", function() {
        return MetaCoin.new({ from: accounts[0], gas: 3000000 })
            .then(_metaCoin => metaCoin = _metaCoin);
    });

    it("should start with 10000 coins", function() {
        return metaCoin.getBalance.call(accounts[0])
            .then(balance => assert.strictEqual(
                balance.toString(10),
                "10000",
                "should be 10k"));
    });
});