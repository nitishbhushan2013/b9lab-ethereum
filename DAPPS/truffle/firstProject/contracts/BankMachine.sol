pragma solidity ^0.4.25;

contract BankMachine{

 mapping(address => uint) balance;
 
 event sender(address from, uint amount);
 event receiver(address from, uint amount);
 
 constructor() public {
 }
 
 function deposit (uint amount) public payable {
     require(amount >0);
     balance[msg.sender] += amount;
     emit sender(msg.sender,amount);
 }
 
 function withdrawal(uint amount) public payable {
     require(balance[msg.sender]> amount);
    
     balance[msg.sender] -= amount;
     msg.sender.transfer(amount);
     
     emit receiver(msg.sender,amount);
 }
}