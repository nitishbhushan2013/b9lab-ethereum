pragma solidity ^0.4.25;
import "./Pausable.sol";
import "./RemittenceLib.sol";
 
/**  
* @title Remittence

*@dev This is am utility contract. It allows any one to submit amount with a puzzle and an ether in it.
Any one can solve the puzzle (requires two passwords) and withdrwaw the amount with in set timeline and attenpts. After this time line, submitter can withdraw the unclaim amount.  

Rules
    - Any one can submit any number of remittemce
    - Each remittence request would contain amount, puzzle, duration 
    - amount must be greater than zero
    - Any one can try to solve the puzzle and get the amount with in set time line.
    - Each account will have five chances to solve the puzzle. ( This can se seen as a way to avoid brute force)
    
@ code style - all the private state variables and private internal functions starts with '_'.
**/
contract RemittenceV1 is Pausable{
    uint maxCount;
    // This holds all details about remittence
    struct Remittence {
        address creator;
        bytes32 puzzle;
        uint amount;
        uint deadLine;
        mapping(address => uint) userAttempt;
    }
    // Allow us to look the remittence details by remittence name
    mapping(bytes => Remittence) public remittenceDetails;

    // maintains the balance of each participant. withdraw() can be used to withdraw the amount.
    mapping(address => uint) public accountBalance;
   
    // maintain the list of used puzzle. user must not allow to reuse the puzzle.
    mapping(bytes32 => bool) public usedSecrets;

    event LogContractConditionInitialized(address from, string indexed remittenceName, uint amount, uint deadLine);
    event LogWithdrawRemittenceAmountSuccessed(address indexed byWhom, string indexed remittenceName, uint indexed withdrawalAmount);
    event LogAttemptFailed(address indexed byWhom, uint failedAttempt);
    event LogWithdrawUnclaimedAmountCompleted(address byWhom, string indexed remittenceName, uint indexed withdrawalAmount);
    event LogAmountWithdrawan(address byWhom, uint withdrawalAmount);
    event LogContractDistruct(address owner);
    
    //Set the maximum allowed try to solve the puzzle. 
    constructor(uint _maxCount) public {
        maxCount = _maxCount;
    }

    /**
    @dev allow the contract creator to change the maxAllowed count. 
     */
    function setMaxCount(uint _newCount)
     public 
     onlyWhenNotPaused
     onlyOwner
     returns(uint) {
        require(_newCount > 0, "new count must be greater than zero.");
        maxCount = _newCount;

        return maxCount;
    }


    /**
    @dev This modifier would allow function to be called only after certain time line duration
    */
    modifier onlyAfterDeadLine(uint _timeLine) {
        require(now > _timeLine,"activity must occur after deadline");
        _;
    }
    
    /**
    @dev This modifier would allow function to be called only on or before certain time line duration
    */
    modifier onlyOnBeforeDeadLine(uint _timeLine) {
        require(now <= _timeLine,"activity must occur on or before deadline");
        _;
    }
    
     /**
    @dev This modifier would allow function to be called only by the creator of this remittence
    */
    modifier onlyCreator(string memory _remittenceName) {
        require(msg.sender == remittenceDetails[bytes(_remittenceName)].creator, "only craetor of this remittence can invoke the function.");
        _;
    }

    /**
    @dev This function would set the contract conditions and can be called any nmuber of times with the limitation of not reusing the same contract name until it is active.
   
    @param _name array of remittence name. Each remittence is identified by its name
    @param _puzzle hashed puzzle for each remittence. Alice get it through RemittenceLib.getPuzzle(password1, password2)
    @param _duration duration after which Alice can withdraw the ether
    */
    function setRemittenceCondition(bytes _name, bytes32 _puzzle, uint _duration)
    public
    onlyWhenNotPaused
    payable
    {
        require(remittenceDetails[_name].amount == 0, "This name is in active state");
        require(!usedSecrets[_puzzle], "you have already used this _puzzle. Please provide different _puzzle");
        require(msg.value > 0, "Remittence amount must be greater than zero.");

        usedSecrets[_puzzle] = true;
        uint timeLine = now + _duration * 1 seconds;
        remittenceDetails[_name] = Remittence(msg.sender, _puzzle, msg.value, timeLine);   

        emit LogContractConditionInitialized(msg.sender, string(_name), msg.value, timeLine);
    }

    /**
    @dev Any one can call this function to solve the puzzle and withdraw the amount.
    @param remittenceName  name of remittence. 
    @param password_one first password
    @param password_two second password
    @return boolean to indicate the status of this call
    */
    function withdrawRemittenceAmount(string memory remittenceName, bytes32 password_one, bytes32 password_two)
    public
    onlyWhenNotPaused
    onlyOnBeforeDeadLine(remittenceDetails[bytes(remittenceName)].deadLine)
    returns(bool) {
        require(remittenceDetails[bytes(remittenceName)].amount > 0, "Remitttence not found. This remittence is invalid");
        require(remittenceDetails[bytes(remittenceName)].userAttempt[msg.sender] <= maxCount, "maximum attempt reached."); // userAttempt
       
        //accounting
        if(remittenceDetails[bytes(remittenceName)].puzzle != RemittenceLib.getPuzzle(password_one,password_two)) {
             remittenceDetails[bytes(remittenceName)].userAttempt[msg.sender]++;
             emit LogAttemptFailed(msg.sender, remittenceDetails[bytes(remittenceName)].userAttempt[msg.sender]-1);
             revert("password mismatch, please provides the correct passwords.");
        }
       
        uint withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;
        accountBalance[msg.sender]++ = withdrawalAmount;
        remittenceDetails[bytes(remittenceName)].amount = 0; // counter reentrant attack

        emit LogWithdrawRemittenceAmountSuccessed(msg.sender, remittenceName, withdrawalAmount);
        return true;
    }
    
    /**
    @dev Remittence creator can claim the unchallenged money after the set deadline
    */
    function withdrawUnclaimedEther(string memory remittenceName)
    public
    onlyWhenNotPaused
    onlyCreator(remittenceName)
    onlyAfterDeadLine(remittenceDetails[bytes(remittenceName)].deadLine)
    returns(bool) {
        require(remittenceDetails[bytes(remittenceName)].amount > 0, "puzzle is not set or remittence has been successfully completed");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;
        accountBalance[msg.sender] += withdrawalAmount;
        remittenceDetails[bytes(remittenceName)].amount = 0;
        emit LogWithdrawUnclaimedAmountCompleted(msg.sender, remittenceName, withdrawalAmount);
        return true;
    }

    /**
    @dev this function will allow the individual participating player to withdraw the amount.
    This is needed only when both player has played the invalid mode and thus game has withdrawan.
    */
    function withdraw()
    public
    onlyWhenNotPaused
    payable
    returns(bool) {
        uint withdrawalAmount = accountBalance[msg.sender];
        require(withdrawalAmount >0, "withdwaral amount must be greater than zero");
        //accounting
        accountBalance[msg.sender] = 0;

        emit LogAmountWithdrawan(msg.sender, withdrawalAmount);
        msg.sender.transfer(withdrawalAmount);
        return true;
    }
    
    function kill()
    public
    onlyWhenPaused // its safe to kill the contract
    onlyOwner
    returns(bool){
        emit LogContractDistruct(msg.sender);
        selfdestruct(msg.sender);
        return true;
    }

}