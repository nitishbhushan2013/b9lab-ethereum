pragma solidity ^0.5.0;

contract Splitter2{

    address public Alice;
    address public Bob;
    address public Carol;
    address owner;
 
    mapping(address => uint) balance;
 
    event LogAddressInitialized(address Alice, address Bob, address Carol);
    event LogFundsDeposited(address indexed from, uint amount);
    event LogFundsWithdrawn(address indexed from, uint amount);
    event LogFundSplit(address indexed from, uint initialAmount, address indexed receiver1, address indexed receiver2, uint receivedAmount);
    event LogLeftOverFundSent(address indexed to, uint amount);
    event LogContractDistruct(address owner);
   
    
    constructor(address[3] memory addrs) public{
        require(addrs[0] != address(0), "addres must not be zero account");
        require(addrs[1] != address(0), "addres must not be zero account");
        require(addrs[2] != address(0), "addres must not be zero account");
     
        owner = msg.sender; 
   
        Alice = addrs[0];
        Bob = addrs[1];
        Carol = addrs[2];
     
        emit LogAddressInitialized(Alice, Bob, Carol);
    }
  /**
  whenever Alice sends ether to the contract for it to be split, half of it goes to Bob and the other half to Carol.
   */
    function deposit () public payable returns(bool){
        require(msg.value > 0, "deposit amount must be positive number"); 
        require(msg.sender == Alice, "Only Aice can invoke this function"); // this is tight binding with the given specification. 
        
        uint splitAmount = msg.value / 2;  
        uint leftOverAmount = msg.value - (2 * splitAmount);

        emit LogFundSplit(msg.sender, msg.value, Bob, Carol, splitAmount);
   
        balance[Bob] += splitAmount;
        balance[Carol] += splitAmount;
       
        if(leftOverAmount > 0){ // its not wallet and its bad to leave unused amount in the contract. return it back to Alice.
            emit  LogLeftOverFundSent(msg.sender, leftOverAmount);
            msg.sender.transfer(leftOverAmount);
        }
        return true;
    }
 
    function withdrawal() public returns(bool){
        uint totalAmount = balance[msg.sender];
        require(totalAmount > 0, "must be enough amount");
        
        //withdraw the complete amount of this address
        emit LogFundsWithdrawn(msg.sender,totalAmount);
        balance[msg.sender] = 0;
        msg.sender.transfer(totalAmount);  // rely on pull mechanism to pull the amount. msg.sender is 'trusted' address.
        
        return true;
    }
 
    function getBalance(address addr) public view returns(uint){ // this will not change the world state
        return balance[addr];
    }
    
    function kill() public returns(bool) {
        require(owner == msg.sender, "it must be contract owner");
        
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }
}