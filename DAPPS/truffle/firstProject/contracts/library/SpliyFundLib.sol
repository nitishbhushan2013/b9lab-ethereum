pragma solidity ^0.5.0;

library SplitFundLib {

    struct Fund{
        mapping(address => uint) balance;
    }

    event LogFundSplit(address from, uint amount, address receiver1, address receiver2);
    event LogFundsDeposited(address from, uint amount);

    function splitFund (Fund storage self, address receiver1, address receiver2, uint amount) public returns(bool) {
        require(amount > 0, "amount must be positive number");
        require(receiver1 != address(0), "addres must not be zero account");
        require(receiver2 != address(0), "addres must not be zero account");
        
        if(amount % 2 != 0) { // if its not even, get the even. 1 wei would send back to contract 
            amount = amount - 1;
        }
        uint depositAmount = amount/2;   // amount must be even 
        
        emit LogFundSplit(msg.sender, amount,receiver1, receiver2);
        
        self.balance[receiver1] += depositAmount;
        self.balance[receiver2] += depositAmount;
        
        emit LogFundsDeposited(receiver1,depositAmount);
        emit LogFundsDeposited(receiver2,depositAmount);
        
        return true;
    }


}