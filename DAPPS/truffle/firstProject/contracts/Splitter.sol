pragma solidity ^0.4.25;

contract Splitter2{

 address public Alice;
 address public Bob;
 address public Carol;
 address owner;
 
 mapping(address => uint) balance;
 
 event LogAddressInitialized(address Alice, address Bob, address Carol);
 event LogDepositMode(bytes32 mode ); // split mode or single mode
 event LogFundsDeposited(address from, uint amount);
 event LogFundsWithdrawn(address from, uint amount);
 event LogFundSplit(address from, uint amount, address receiver1, address receiver2);
 event LogBalance(address addr, uint balance);
 
 constructor(address[] addrs) public{
     owner = msg.sender; // this is contract owner who will receive amount if other than Alice send the deposit amount 
     require(addrs.length == 3); // this is specific contract to accept three address. 
     require(addrs[0] != address(0));
     require(addrs[1] != address(0));
     require(addrs[2] != address(0));
     
     Alice = addrs[0];
     Bob = addrs[1];
     Carol = addrs[2];
     
     emit LogAddressInitialized(Alice, Bob, Carol);
 }
  
 function deposit (uint amount) public payable {
     require(amount >0);
     if(msg.sender == Alice) {
         emit LogDepositMode("split mode deposit");
         multiDeposit(Bob, Carol, amount);
     }
     else {
            LogDepositMode("single deposit");
            balance[owner] += amount;
            emit LogFundsDeposited(owner,amount);
     }
  
 }
 
 function withdrawal(uint amount) public payable {
     require(balance[msg.sender]> amount);
    
     balance[msg.sender] -= amount;
     emit LogFundsWithdrawn(msg.sender,amount);
      
     msg.sender.transfer(amount);  // method call to actually perform the operation
 }
 
 function multiDeposit(address receiver1, address receiver2, uint amount) public payable returns(bool) {
     require(amount >0);
     require(receiver1 != address(0));
     require(receiver2 != address(0));
     
     uint depositAmount = amount/2;   // amount must be even 
     
     balance[receiver1] += depositAmount;
     balance[receiver2] += depositAmount;
     
     LogFundSplit(msg.sender, amount,receiver1, receiver2 );
     emit LogFundsDeposited(receiver1,depositAmount);
     emit LogFundsDeposited(receiver2,depositAmount);
     
     return true;
 }
 
 function getBalance(address addr) view public returns(uint) { // this will not change the world state
        emit LogBalance(addr, balance[addr]);
        return balance[addr];
    }
}