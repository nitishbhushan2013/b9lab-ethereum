var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter- Alice deposit scenario', accounts => {
    var contract;
    var OwnerAddres = accounts[0];
    var AliceAddress = accounts[1];
    var BobAddress = accounts[2];
    var carolAddress = accounts[3];

    beforeEach("create a new instance", done => {
        return Splitter.new()
            .then(_instance => {
                contract = _instance;
            })
    });

    it("three address should be populated and balance would be 0", done =>{
        return contract.getBalance.call(OwnerAddres)
        .then(_balance =>{
            assert.equal(_balance, 0, "owner initial balance must be 0");
            return instance.getBalance.call(AliceAddress);
        }).then(_balance => {
            assert.equal(_balance, 0, "Alice initial balance must be 0");
            return instance.getBalance.call(BobAddress);
        }).then(_balance => {
            assert.equal(_balance, 0, "Bob initial balance must be 0");
            return instance.getBalance.call(carolAddress);
        }).then(_balance => {
            assert.equal(_balance, 0, "Carol initial balance must be 0");
        }).catch(done);
    });

    it("should deposit correct amount", done => {
       // var instance;
        var depositAmount = 100;
        var owner_initial_balance;
        var Alice_initial_balance;
        var Bob_initial_balance;
        var Carol_initial_balance;
        var owner_final_balance;
        var Alice_final_balance;
        var Bob_final_balance;
        var Carol_final_balance;

        return contract.getBalance.call(AliceAddress)
            .then(_balance => {
                Alice_initial_balance = _balance;
                return instance.getBalance.call(BobAddress);
            }).then(_balance => {
                Bob_initial_balance = _balance;
                return instance.getBalance.call(OwnerAddres);
            }).then(_balance => {
                owner_initial_balance = _balance;
                return instance.getBalance.call(carolAddress);
            }).then(_balance => {
                Carol_initial_balance = _balance;
                return instance.deposit({from : AliceAddress, value : depositAmount});
            }).then(success => {
                return instance.getBalance.call(AliceAddress);
            }).then(_balance => {
                Alice_final_balance = _balance;
                return instance.getBalance.call(OwnerAddres);
            }).then(_balance => {
                owner_final_balance = _balance;
                return instance.getBalance.call(BobAddress);
            }).then(_balance => {
                Bob_final_balance = _balance;
                return instance.getBalance.call(carolAddress);
            }).then(_balance => {
                Carol_final_balance = _balance;
                assert.equal(Alice_final_balance, Alice_initial_balance, "Incorrect deposit amount");
                assert.equal(Bob_final_balance, Bob_initial_balance + (depositAmount/2), "Incorrect deposit amount");
                assert.equal(Carol_final_balance, Carol_initial_balance + (depositAmount/2), "Incorrect deposit amount");
            }).catch(done);
    })

    it("shoud withdraw correct amount", done => {
        //var instance;
        var withdrawalAmount = 10;
        var bob_current_balance;
        return  instance.withdrawal(withdrawalAmount, {from : BobAddress})
            .then(success => {
                return instance.getBalance.call(BobAddress);
            }).then(_balance => {
                bob_current_balance = _balance;
                assert.equal(bob_current_balance, Bob_final_balance -withdrawalAmount, "withdrawal amount is incorrect");
            })
    })
    
})


contract('Splitter - other than Alice deposit scenario', accounts => {
    var contract;
    var OwnerAddres = accounts[0];
    var AliceAddress = accounts[1];
    var BobAddress = accounts[2];
    var carolAddress = accounts[3];

    beforeEach("new instance is created", done => {
        return Splitter.new()
            .then(_instance => {
                contract = _instance;
            })
    })

    it("should deposit correct amount", done => {
        //var instance;
        var depositAmount = 100;
        var owner_initial_balance;
        var Alice_initial_balance;
        var Bob_initial_balance;
        var Carol_initial_balance;
        var owner_final_balance;
        var Alice_final_balance;
        var Bob_final_balance;
        var Carol_final_balance;

        return contract.getBalance.call(AliceAddress)
        .then(_balance => {
                Alice_initial_balance = _balance;
                return instance.getBalance.call(BobAddress);
            }).then(_balance => {
                Bob_initial_balance = _balance;
                return instance.getBalance.call(OwnerAddres);
            }).then(_balance => {
                owner_initial_balance = _balance;
                return instance.getBalance.call(carolAddress);
            }).then(_balance => {
                Carol_initial_balance = _balance;
                return instance.deposit({from : BobAddress, value : depositAmount});
            }).then(success => {
                return instance.getBalance.call(AliceAddress);
            }).then(_balance => {
                Alice_final_balance = _balance;
                return instance.getBalance.call(OwnerAddres);
            }).then(_balance => {
                owner_final_balance = _balance;
                return instance.getBalance.call(BobAddress);
            }).then(_balance => {
                Bob_final_balance = _balance;
                return instance.getBalance.call(carolAddress);
            }).then(_balance => {
                Carol_final_balance = _balance;
                assert.equal(Alice_final_balance, Alice_initial_balance, "Incorrect deposit amount");
                assert.equal(Bob_final_balance, Bob_initial_balance, "Incorrect deposit amount");
                assert.equal(Carol_final_balance, Carol_initial_balance , "Incorrect deposit amount");
                assert.equal(owner_final_balance, owner_initial_balance + depositAmount, "Incorrect deposit amount");
            }).catch(done);
    })
    
})