pragma solidity ^0.4.25;


contract Splitter {
    address owner;  // this is contract owner
    struct Person{   // This stores the users details
        address deployedAddress;
        bytes32 name;
        uint balance;
    }
    mapping (address => Person) balances;
    Person[] persons;
    
    
    event LogTransferAmount(address from, address to, uint amount);
    event LogIdentityCreated(address addr, bytes32 name, uint amount);

    constructor( address[] addr)  public {
        owner = msg.sender;
        Person memory contractOwner = Person({
              deployedAddress : msg.sender,
              name : "contractOwner",
              balance: 1000
            });
        balances[msg.sender] = contractOwner;
    
        if(addr.length == 3){
            constructParticipant(addr);
        }
    }
    
    function constructParticipant(address [] addr) private {   // this must not be called from other public contract. 
        require(owner == msg.sender);
        require(addr.length == 3,"there must be three addresses");
        
        Person memory Alice = Person(addr[0], "Alice", 20);
        Person memory Bob = Person(addr[1], "Bob", 10);
        Person memory Carol = Person(addr[2], "Carol", 10);
        
        persons.push(Alice);                                 // first person pushed  
        emit LogIdentityCreated(addr[0], "Alice", 20);
        
        persons.push(Bob);                                   // second person pushed 
        emit LogIdentityCreated(addr[1], "Bob", 10);
        
        persons.push(Carol);                                 // third person pushed 
        emit LogIdentityCreated(addr[2], "Carol", 10);    
        
        balances[addr[0]] = Alice;
        balances[addr[1]] = Bob;
        balances[addr[2]] = Carol;
    }
    
    function sendAmount(uint amount) public payable { // amount is sent to this contract and so no dedicated 'to' address was passed
        require(balances[msg.sender].balance >= amount); // check enough amount
        
        balances[msg.sender].balance -= amount;
        
        if(balances[msg.sender].name == "Alice"){ // Alice has initiated the transaction, apply business rule 
            Person memory bob = persons[1];
            Person memory carol = persons[2];
            
            balances[bob.deployedAddress].balance += amount/2;
            emit LogTransferAmount(msg.sender,bob.deployedAddress,amount/2);
           
            balances[carol.deployedAddress].balance += amount/2;
            emit LogTransferAmount(msg.sender,carol.deployedAddress,amount/2);
        } 
        else {
            balances[owner].balance +=amount;
            emit LogTransferAmount(msg.sender,owner,amount);
        }
    }
    
    function getBalance(address addr) view public returns(uint) { // this will not change the world state
        return balances[addr].balance;
    }
    
}
