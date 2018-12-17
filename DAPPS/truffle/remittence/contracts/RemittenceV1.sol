pragma solidity ^0.4.25;
import "./Pausable.sol";
import "./RemittenceLib.sol";
 
/**  
* @title Remittence
*@dev This contract is deployed by Alice with ether and inbuilt puzzle with two secret keys.
Carol can only invoke Alice contract by submitting both the password. If password are correct then withdraw the
ether.

Rules
    - Alice can submit any no. of remittence
    - amount must be greater than zero
    - Contract onwer can change the address of withdrawal person
    
@ code style - all the private state variables and private internal functions starts with '_'.
**/
contract RemittenceV1 is Pausable{
    address public withdrawalAddress; // by default, configured to Carol Address. This can be change by the contract owner.
    
    // This holds all details about remittence
    struct Remittence {
        bytes32 puzzle;
        uint amount;
        uint deadLine;
    }
    // Allow us to look the remittence details by remittence name
    mapping(bytes => Remittence) public remittenceDetails;

    event LogContractConditionInitialized(address from, string indexed remittenceName, uint amount, uint deadLine);
    event LogWithdrawRemittenceAmountSuccessed(address indexed byWhom, string indexed remittenceName, uint indexed withdrawalAmount);
    event LogWithdrawUnclaimedAmountCompleted(address byWhom, string indexed remittenceName, uint indexed withdrawalAmount);
    event LogContractDistruct(address owner);
    
    
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
    @dev Only nominated person can withdraw the fund
     */
    modifier onlyByAuthorisedPerson() {
        require(msg.sender == withdrawalAddress, "only withdrawalAddress can invoke this function");
        _;
    }
    constructor (address _CarolAddress) public {
        withdrawalAddress = _CarolAddress; // Only Carol is allowed to submit the transaction to withdraw the amount
    }

    /**
     * @dev this function would allow contract owner to change the withdrawal address.  
     */
    function setWithdrawalAddress(address _newAddress)
    public
    onlyWhenNotPaused
    onlyOwner
    returns(bool)
    {
        require(_newAddress != address(0));
        withdrawalAddress = _newAddress;
        return true;
    }

    /**
    @dev This function would set the contract conditions and can be called only by the Alice, who is the contract owner.
    Alice can call this function any number of time to set the contract with the limitation of not reusing the same
    contract name until it is active.
    @param _name array of remittence name. Each remittence is identified by its name
    @param _puzzle hashed puzzle for each remittence. Alice get it through RemittenceLib.getPuzzle(password1, password2)
    @param _amount amount for each remittence
    @param _duration duration after which Alice can withdraw the ether
    @param _CarolAddress Carol address, who in turn would solve the puzzle
    */
    function setRemittenceCondition(bytes _name, bytes32 _puzzle, uint _duration)
    public
    onlyOwner  // only contarct owner can set the remittence.
    onlyWhenNotPaused
    payable
    {
        require(remittenceDetails[_name].amount == 0, "This name is in active state");
        require(msg.value > 0, "Remittence amount must be greater than zero.");
        uint timeLine = now + _duration * 1 seconds;
        remittenceDetails[_name] = Remittence(_puzzle, msg.value, timeLine);   
        emit LogContractConditionInitialized(msg.sender, string(_name),msg.value, timeLine);
    }

    /**
    @dev This function must be invoked by Carol/withdrawal address to solve the puzzle and withdraw the amount.
    @param remittenceName  name of remittence. Carol wants to withdraw amount for this remittence
    @param password_bob Bob's one time password
    @param password_carol Carol's one time password
    @return boolean to indicate the status of this call
    */
    function withdrawRemittenceAmount(string memory remittenceName, bytes32 password_one, bytes32 password_two)
    public
    onlyWhenNotPaused
    onlyByAuthorisedPerson
    onlyOnBeforeDeadLine(remittenceDetails[bytes(remittenceName)].deadLine)
    returns(bool) {
        require(remittenceDetails[bytes(remittenceName)].amount > 0, "Remitttence not found. This remittence is invalid");
        require(remittenceDetails[bytes(remittenceName)].puzzle == RemittenceLib.getPuzzle(password_one,password_two),"password mismatch,can not withdraw the amount");
       
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;
        remittenceDetails[bytes(remittenceName)].amount = 0; // counter reentrant attack
        emit LogWithdrawRemittenceAmountSuccessed(msg.sender, remittenceName, withdrawalAmount);
        msg.sender.transfer(withdrawalAmount);
        return true;
    }
    
    /**
    @dev Alice can claim the unchallenged money after the set deadline
    */
    function withdrawUnclaimedEther(string memory remittenceName)
    public
    onlyWhenNotPaused
    onlyOwner
    onlyAfterDeadLine(remittenceDetails[bytes(remittenceName)].deadLine)
    returns(bool) {
        require(remittenceDetails[bytes(remittenceName)].amount > 0, "puzzle is not set or remittence has been successfully completed");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;
        remittenceDetails[bytes(remittenceName)].amount = 0;
        emit LogWithdrawUnclaimedAmountCompleted(msg.sender, remittenceName, withdrawalAmount);
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