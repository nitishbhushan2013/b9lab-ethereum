pragma solidity ^0.5.0;

/**This contract is deployed by Alice with ether and inbuilt puzzle with two secret keys. 
Anyone can solve the puzzle and withdraw the ether */
contract Remittence {
    address public owner;
    uint public amount;
    bytes32 puzzleSecretvalue;
    uint creationTime;
    uint deadLineLimit;

    address public Carol;

    mapping(address => uint) balances;

    event LogContractInitialized(address byWhom, uint amountDeposited);
    event LogWithdrawRemittenceAmountInvoked(address from);
    event LogWithdrawRemittenceAmountSuccessed(address from, bytes32 password1, bytes32 password2, uint amountWithdrawan);
    event LogWithDrawUnclaimedAmountCompleted(address byWhom, uint howMuch);
    event LogContractDistruct(address owner);
    
    modifier onlyByOWner(address _owner) {
        require(_owner == owner, "address must be contract owner");
        _;
    }

    modifier onlyAfter(uint _deadLineLimit){
        require(now > _deadLineLimit,"activity must occur after time line");
        _;
    }
    modifier onlyBefore(uint _deadLineLimit){
        require(now < _deadLineLimit,"activity must occur before time line");
        _;
    }

    // Alice has deployed the contract with ether in it and puzzle
    constructor (uint  _deadLineLimit, address _CarolAddress, bytes32 secretValue) public payable{
        require(msg.value > 0, "ether amount must be greater than 0");

        owner = msg.sender;
        amount = msg.value;
        creationTime = now;
        deadLineLimit = _deadLineLimit;
        Carol = _CarolAddress;
        puzzleSecretvalue = secretValue;
        balances[owner] += msg.value;

        emit LogContractInitialized(owner, amount);
    }

    /**This is a public function and hence can be invoked by any person.  */
    function withdrawRemittenceAmount(bytes32 password_bob, bytes32 password_carol) public 
    onlyBefore(creationTime+deadLineLimit)
    returns(bool) {
        require(msg.sender != address(0), "contract invoking address must not be zero address");
        require(amount > 0, "withdrawal amount must be more than 0.");
        require(puzzleSecretvalue == keccak256(abi.encodePacked(password_bob,password_carol)),"password mismatch,not authorized to withdraw the amount");
        emit LogWithdrawRemittenceAmountInvoked(msg.sender);

        //accounting
        balances[msg.sender] += amount;
        balances[owner] -= amount;
        msg.sender.transfer(amount);
        
        emit LogWithdrawRemittenceAmountSuccessed(msg.sender,password_bob,password_carol,amount);
        return true;
    }

    function withdrawUnclaimedEther() private 
    onlyByOWner(owner) 
    onlyAfter(creationTime+deadLineLimit) 
    returns(bool) {
        require(amount > 0, "ether must be there to withdraw");
        require(msg.sender == Carol, "Only carol can invoke the Remittemce contract");
        emit LogWithDrawUnclaimedAmountCompleted(msg.sender, msg.value);
        balances[owner] -= msg.value;
        msg.sender.transfer(msg.value);
        return true;
    }

    function kill() public onlyByOWner(owner) returns(bool){
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }

}


