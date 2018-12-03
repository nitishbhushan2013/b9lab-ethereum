pragma solidity ^0.5.0;

/**This contract is deployed by Alice with ether and inbuilt puzzle with two secret keys.
Carol can only invoke Alice contract by submitting both the password. If password are correct then withdraw the
 ether. */
contract Remittence {
    address public owner;
    address public Carol;
    uint public amount;
    uint totalWithdrawalAmount;
    uint deadLineLimit;
    bytes32 puzzleSecretvalue;
   
    event LogContractInitialized(address indexed byWhom, uint amountDeposited);
    event LogWithdrawRemittenceAmountInvoked(address from);
    event LogWithdrawRemittenceAmountSuccessed(address indexed from, bytes32 password1, bytes32 password2, uint indexed totalWithdrawalAmount);
    event LogWithdrawUnclaimedAmountCompleted(address byWhom, uint totalWithdrawalAmount);
    event LogContractDistruct(address owner);
    
    modifier onlyByOwner(address _owner) {
        require(_owner == owner, "address must be contract owner");
        _;
    }

    modifier onlyAfterDeadLine {
        require(now > deadLineLimit,"activity must occur after deadline");
        _;
    }
    modifier onlyBeforeDeadLine {
        require(now < deadLineLimit,"activity must occur before deadline");
        _;
    }

    // Alice has deployed the contract with ether in it and puzzle
    constructor (uint  _deadLineLimit, address _CarolAddress, bytes32 secretValue) public payable{
        require(msg.value > 0, "ether amount must be greater than 0");

        owner = msg.sender;
        amount = msg.value; 
        deadLineLimit = now + _deadLineLimit days;
        Carol = _CarolAddress;
        puzzleSecretvalue = secretValue;
      
        emit LogContractInitialized(owner, amount);
    }

    /**
     * As per given specification, only Carol can call this function.
     */
    function withdrawRemittenceAmount(bytes32 password_bob, bytes32 password_carol) public
    onlyBeforeDeadLine
    returns(bool) {
        require(msg.sender == Carol, "only Carol can invoke this function");
        require(amount > 0, "withdrawal amount must be more than 0.");
        require(puzzleSecretvalue == keccak256(abi.encodePacked(password_bob,password_carol)),"password mismatch,not authorized to withdraw the amount");
        emit LogWithdrawRemittenceAmountInvoked(msg.sender);

        //accounting
        totalWithdrawalAmount = amount;
        amount = 0; // counter reentrant attack
        emit LogWithdrawRemittenceAmountSuccessed(msg.sender,password_bob,password_carol,totalWithdrawalAmount);
        msg.sender.transfer(totalWithdrawalAmount);
         
        return true;
    }

    function withdrawUnclaimedEther() public
    onlyByOwner(owner) // only by Alice as she only created and deployed this contract
    onlyAfterDeadLine
    returns(bool) {
        require(amount > 0, "ether must be there to withdraw");
      
        emit LogWithdrawUnclaimedAmountCompleted(msg.sender, amount);
        
        //accounting
        totalWithdrawalAmount = amount; 
        amount = 0;
        msg.sender.transfer(totalWithdrawalAmount);
        return true;
    }

    function kill() public onlyByOwner(owner) returns(bool){
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }

}