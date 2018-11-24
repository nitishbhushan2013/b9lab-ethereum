pragma solidity ^0.4.25;

contract BankMachine{
 address owner;
 
 mapping(address => uint) balance;
 
 event LogDeposit(address from, uint amount);
 event LogWithdrawal(address from, uint amount);
 
 
 constructor() public {
     owner = msg.sender;
 }
 
 function deposit (uint amount) public payable {
     balance[msg.sender] += amount;
     emit LogDeposit(msg.sender,amount);
 }
 
 function withdrawal(uint amount) public payable returns(bool) {
     require(balance[msg.sender]> amount);
    
     balance[msg.sender] -= amount;
     emit LogWithdrawal(msg.sender,amount);
     
     return true;
 }
}