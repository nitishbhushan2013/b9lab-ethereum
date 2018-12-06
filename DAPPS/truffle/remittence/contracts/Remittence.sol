pragma solidity ^0.4.25; 
import "./Pausable.sol";

/**
* @title Remittence
*@dev his contract is deployed by Alice with ether and inbuilt puzzle with two secret keys.
Carol can only invoke Alice contract by submitting both the password. If password are correct then withdraw the
ether. 
@ code style - all the private state variables and private internal functions starts with '_'.
**/
contract Remittence is Pausable{
    address private _owner;
    address private _Carol;
    uint private _amount;
    uint private _durationLimit;
    bytes32 private _puzzleSecretvalue;
    bool private _puzzleSecretValueSet = false;
   
    event LogContractConditionInitialized(address from, uint indexed amount, uint durationLimit, address CarolAddress);
    event LogWithdrawRemittenceAmountSuccessed(address indexed from, uint indexed withdrawalAmount);
    event LogWithdrawUnclaimedAmountCompleted(address byWhom, uint indexed withdrawalAmount);
    event LogContractDistruct(address owner);
  
    /** 
    @dev This modifier would allow function to be called only after certain time line duration
     */
    modifier onlyAfterDeadLine {
        require(now > _durationLimit,"activity must occur after deadline");
        _;
    }

    /** 
    @dev This modifier would allow function to be called only on or before certain time line duration
     */
    modifier onlyOnBeforeDeadLine {
        require(now <= _durationLimit,"activity must occur on or before deadline");
        _;
    }

    constructor () public {
        _owner = msg.sender;
    }
    
     /** 
     @dev This function would set the contract conditions and can be called only by the Alice, who is the contract owner.
     @param secretValue hashed puzzle created by Alice
     @param _timeLimit duration after which Alice can withdraw the ether 
     @param _CarolAddress Carol address, who in turn would solve the puzzle
      */
    function setContractCondition(bytes32 secretValue, uint _timeLimit, address _CarolAddress ) 
    public            
    onlyWhenNotPaused //ensures function is available and can be safely invoked.
    onlyOwner         // ensures only Owner of this contract can call this function.
    payable           // this function can accept amount.
    returns(bool) {
        require(!_puzzleSecretValueSet, "puzzle has been set by the owner");  
         
        _durationLimit = now + _timeLimit * 1 seconds;
        _puzzleSecretvalue = secretValue;
        _amount = msg.value;
        _Carol = _CarolAddress;
        _puzzleSecretValueSet = true;
         
        emit LogContractConditionInitialized(msg.sender, _amount, _durationLimit, _CarolAddress);
    }
     

     /** 
     @dev This function must be invoked by Carol to solve the puzzle and withdraw the amount. 
     @param password_bob Bob's one time password 
     @param password_carol Carol's one time password
     @return boolean to indicate the status of this call
      */
    function withdrawRemittenceAmount(bytes32 password_bob, bytes32 password_carol)
    public
    onlyWhenNotPaused    
    onlyOnBeforeDeadLine
    returns(bool) {
        require(msg.sender == _Carol, "only Carol can invoke this function");
        require(_puzzleSecretValueSet, "puzle is not set");
        require(_amount > 0, "withdrawal amount must be more than 0.");
        require(_puzzleSecretvalue == keccak256(abi.encodePacked(password_bob,password_carol)),"password mismatch,can not withdraw the amount");
      
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = _amount;
        _amount = 0; // counter reentrant attack
        _puzzleSecretValueSet = false; // allow reusbility of the contract.
        
        emit LogWithdrawRemittenceAmountSuccessed(msg.sender,withdrawalAmount);
        msg.sender.transfer(withdrawalAmount);
         
        return true;
    }

    /** 
    @dev Alice can claim the unchallenged money after the set deadline
     */
    function withdrawUnclaimedEther()
    public
    onlyWhenNotPaused
    onlyOwner 
    onlyAfterDeadLine
    returns(bool) {
        
        require(_puzzleSecretValueSet, "puzzle is not set");
        require(_amount > 0, "ether must be there to withdraw");
        
        uint withdrawalAmount;
        
        //accounting
        withdrawalAmount = _amount;
        _amount = 0;
        _puzzleSecretValueSet = false;
         
        emit LogWithdrawUnclaimedAmountCompleted(msg.sender, withdrawalAmount);
         
        msg.sender.transfer(withdrawalAmount);
        return true;
    }

    function getOwner() public view returns(address){
        return _owner;
    }

    function kill()
    public
    onlyWhenPaused  // its safe to kill the contract 
    onlyOwner
    returns(bool){
        emit LogContractDistruct(_owner);
        selfdestruct(_owner);
        return true;
    }


}