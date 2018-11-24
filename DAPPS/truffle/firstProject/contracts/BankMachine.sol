pragma solidity ^0.4.25;

contract BankMachine{

 mapping(address => uint) balance;
 
 event LogFundsDeposited(address from, uint amount);
 event LogFundsWithdrawn(address from, uint amount);
 
 constructor() public{
     
 }
  
 function deposit (uint amount) public payable {
     require(amount >0);
     balance[msg.sender] += amount;
     emit LogFundsDeposited(msg.sender,amount);
 }
 
 function withdrawal(uint amount) public payable {
     require(balance[msg.sender]> amount);
    
     balance[msg.sender] -= amount;
     msg.sender.transfer(amount);
     
     emit LogFundsWithdrawn(msg.sender,amount);
 }
 
 function multiDeposit(address addr1, address addr2, uint amount) public payable returns(bool) {
     require(amount >0);
     
     uint depositAmount = amount/2;
     
     balance[addr1] += depositAmount;
     balance[addr2] += depositAmount;
     
     addr1.transfer(depositAmount);
     emit LogFundsDeposited(addr1,depositAmount);
     addr2.transfer(depositAmount);
     emit LogFundsDeposited(addr2,depositAmount);
     
 }
}