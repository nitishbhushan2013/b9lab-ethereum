pragma solidity ^0.5.0;

contract Splitter2{

    address public Alice;
    address public Bob;
    address public Carol;
    address owner;
 
    mapping(address => uint) balance;
 
    event LogAddressInitialized(address Alice, address Bob, address Carol);
    event LogDepositMode(bytes32 mode); // split mode or single mode
    event LogFundsDeposited(address indexed from, uint amount);
    event LogFundsWithdrawn(address indexed from, uint amount);
    event LogFundSplit(address indexed from, uint amount, address indexed receiver1, address indexed receiver2);
    event LogContractDistruct(address owner);
    
    constructor(address[3] memory addrs) public{
        require(addrs[0] != address(0), "addres must not be zero account");
        require(addrs[1] != address(0), "addres must not be zero account");
        require(addrs[2] != address(0), "addres must not be zero account");
     
        owner = msg.sender; // this is contract owner who will receive amount if other than Alice send the deposit amount 
   
        Alice = addrs[0];
        Bob = addrs[1];
        Carol = addrs[2];
     
        emit LogAddressInitialized(Alice, Bob, Carol);
    }
  
    function deposit () public payable returns(bool){
        require(msg.value > 0, "deposit amount must be positive number"); 
        
        if(msg.sender == Alice) { // Bob and Carol would recieve equal amount 
            emit LogDepositMode("split mode deposit");
            splitFund(Bob, Carol);
        }
        else { // contract would receive the amount 
            emit LogDepositMode("single deposit");
            balance[msg.sender] += msg.value; 
            emit LogFundsDeposited(msg.sender,msg.value);
        }
        return true;
    }
 
    function withdrawal() public payable returns(bool){
        uint totalAmount = balance[msg.sender];
        require(totalAmount > 0, "must be enough amount");
        
        //withdraw the complete amount of this address
        emit LogFundsWithdrawn(msg.sender,totalAmount);
        balance[msg.sender] = 0;
        msg.sender.transfer(totalAmount);  // rely on pull mechanism to pull the amount. msg.sender is 'trusted' address.
        
        return true;
    }
 
    function splitFund (address receiver1, address receiver2) public payable returns(bool) {
        require(msg.value > 0, "amount must be positive number");
        require(receiver1 != address(0), "addres must not be zero account");
        require(receiver2 != address(0), "addres must not be zero account");
       
        /* no need for this check, as division takes the floor anyway. 
        if(amount % 2 != 0) { // if its not even, get the even. 1 wei would send back to contract 
            amount = amount - 1;
        }*/ 
        uint splitAmount = msg.value/2;  
        
        emit LogFundSplit(msg.sender,splitAmount,receiver1, receiver2);
        
        balance[receiver1] += splitAmount;
        balance[receiver2] += splitAmount;
       
        return true;
    }
 
    function getBalance(address addr) public view  returns(uint){ // this will not change the world state
        return balance[addr];
    }
    
    function kill() public returns(bool) {
        require(owner == msg.sender, "it must be contract owner");
        
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }
}