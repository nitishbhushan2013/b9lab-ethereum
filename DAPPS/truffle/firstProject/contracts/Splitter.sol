pragma solidity ^0.5.0;

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
    event LogContractDistruct(address owner);
    
    constructor(address[] memory addrs) public{
        require(addrs.length == 3, "There must be three address"); // this is specific contract to accept three address. 
        require(addrs[0] != address(0), "addres must not be zero account");
        require(addrs[1] != address(0), "addres must not be zero account");
        require(addrs[2] != address(0), "addres must not be zero account");
     
        owner = msg.sender; // this is contract owner who will receive amount if other than Alice send the deposit amount 
   
        Alice = addrs[0];
        Bob = addrs[1];
        Carol = addrs[2];
     
        emit LogAddressInitialized(Alice, Bob, Carol);
    }
  
    function deposit (uint amount) public payable returns(bool){
        require(msg.value > 0, "deposit amount must be positive number"); 
        
        if(msg.sender == Alice) {
            emit LogDepositMode("split mode deposit");
            splitFund(Bob, Carol, msg.value);
        }
        else {
            emit LogDepositMode("single deposit");
            balance[owner] += msg.value;
            emit LogFundsDeposited(owner,msg.value);
        }
        return true;
    }
 
    function withdrawal(uint amount) public payable returns(bool){
        require(balance[msg.sender] > amount, "must be enough amount");
        
        balance[msg.sender] -= amount;
        emit LogFundsWithdrawn(msg.sender,amount);
        
        msg.sender.transfer(amount);  // rely on pull mechanism to pull the amount. msg.sender is 'trusted' address.
        
        return true;
    }
 
    function splitFund (address receiver1, address receiver2, uint amount) public payable returns(bool) {
        require(amount > 0, "amount must be positive number");
        require(receiver1 != address(0), "addres must not be zero account");
        require(receiver2 != address(0), "addres must not be zero account");
        
        if(amount % 2 != 0) { // if its not even, get the even. 1 wei would send back to contract 
            amount = amount - 1;
        }
        uint depositAmount = amount/2;   // amount must be even 
        
        emit LogFundSplit(msg.sender, amount,receiver1, receiver2);
        
        balance[receiver1] += depositAmount;
        balance[receiver2] += depositAmount;
        
        emit LogFundsDeposited(receiver1,depositAmount);
        emit LogFundsDeposited(receiver2,depositAmount);
        
        return true;
    }
 
    function getBalance(address addr) public view  returns(uint){ // this will not change the world state
        emit LogBalance(addr, balance[addr]);
        return balance[addr];
    }
    
    function kill() public returns(bool) {
        require(owner == msg.sender, "it must be contract owner");
        
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }
     
    function () external payable {  // fallback function : allow to send ether back to contract.
        
    }
}