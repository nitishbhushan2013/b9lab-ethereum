// The miscommunication between call back and Promises
//When these two are mixed in the same code block then it could leads to many inconsistemcies

// The promise chain will, most likely, execute and complete before the callback has returned. 
//And even then, the callback is entered independently from the promise chain. There is:
    //nothing that forces the promise chain to hold before the callback is entered
    // and nothing to tell it to carry on after the callback has been called.
// In case of any assert error or Test failed, the error will not bubble up through the promise chain and it() 
// will fail to pick it up. Although Javascript will report, in text only, that it detected an unhandled error.

const MetaCoin = artifacts.require("./DAPPS/truffle/firstProject/contracts/MetaCoin.sol");
// Mix of callback and Promise 
contract("MetaCoin contract", accounts =>{
    it("balance would be 10000", function(){
        var instance;
        return MetaCoin.deployed()  // Promise 
            .then(_instance => {
                instance = _instance;
                instance.getBalance.call(accounts[0], function(error, balance){  // callback
                    assert.equal(10000, balance, "amount is not equal");
            });
        });
    });

    // converting callback to Promise 
    it("balance would be 10000", done => {
        var instance;
        return MetaCoin.deployed() // Promise 
            .then(_instance => {
                instance = _instance;
                return new Promise((resolve, reject) => {  // Promise wrapper 
                    intance.getBalance.call(accounts[0], function(error, _balance){ // call back 
                        if(error) reject(error);
                        if(_balance) resolve(_balance);
                    });
                });
            }).then(balance => {
                assert.equal(10000, balance, "amount is not equal");
            });
    });



// Pure Promise 
    it("balance would be 10000", done =>{
        var instance;
        return MetaCoin.deployed() // Promise 
            .then(_instance => {
                instance = _instance;
                return instance.getBalance.call(accounts[0]); // Promise 
            }).then(_balance => {
                assert.equal(10000, balance, "amount is not equal");
        });
    });
})



