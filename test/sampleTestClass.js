const MetaCoin = artifacts.require("./DAPPS/truffle/firstProject/contracts/MetaCoin.sol");

//test class
contract("MetaCoin contract", accounts =>{
    // test case 
    // Style 1 : succint way 
    it("balance must be 10000", function(){ // no call back, 
        // must return the Promise 
        var instance;
        var balance;
        return MetaCoin.deployed()
            .then(_instance => {
                instance = _instance;
                return instance.getBalance.call(accounts[0]);
            }).then(_balance => {
                balance = _balance;
                assert.equal(10000, _balance, "balance is not equal to 10000");
            }); // do ot return any thing for this test to be pass. If it returns then its test failed.
    });
    //style 2
    it("balance must be 10000", done =>{ // function with 'done' callback. done need to be called for success 
    // or failure. If not called, then test will not move to the next one. 
        var instace;
        var balance;
        MetaCoin.deployed()
            .then(_instance => {
                instance = _instance;
                return instance.getBalance.call(accounts[0])
            }).then(_balance => {
                assert.equal(10000, _balance, "balance is not equal to 10000")
                done();  // success criteria
            }).catch(done); // Test failed 
    })

    it("send OPeration is successful", function(){
        var instance;
        var amount = 100;
        var account1_initial_balance;
        var account1_final_balance;
        var account2_initial_balance;
        var account2_final_balance;

        return MetaCoin.deployed()
            .then(_instance => {
                instance = _instance;
                return instance.getBalance.call(accounts[0]);
            }).then(_balance => {
                account1_initial_balance = _balance;
                return instance.getBalance.call(accounts[1]);
            }).then(_balance => {
                account2_initial_balance = _balance;
                return instance.sendCoin(acounts[1], amount, {from : accounts[0]});
            }).then(success => {
                return instance.getBalance.call(accounts[0]);
            }).then(_bal => {
                account1_final_balance = _bal;
                return instance.getBalance.call(accounts[1]);
            }).then(_bal => {
                account2_final_balance = _bal;
                assert.equal(account2_final_balance, account2_initial_balance + amount, "Amount could not correctly received");
                assert.equal(account1_final_balance, account1_initial_balance - amount, "Amount could not correctly sent out");
            });
    });
});