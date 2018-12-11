pragma solidity ^0.4.25;
import "./Pausable.sol";

/**
* @title Remittence
*@dev This contract is deployed by Alice with ether and inbuilt puzzle with two secret keys.
Carol can only invoke Alice contract by submitting both the password. If password are correct then withdraw the
ether.
@ code style - all the private state variables and private internal functions starts with '_'.
**/
contract RemittenceV1 is Pausable{
    address public Carol;
    // This holds all details about remittence
    struct Remittence {
        bytes32 puzzle;
        uint amount;
        uint deadLine;
        bool hasPuzzleSet;
        //uint index;
    }
    // Allow us to look the remittence details by remittence name
    mapping(bytes => Remittence) public remittenceDetails;
   // bytes[] remittenceNameIndex;

    //ensure unique remittence name. 
    mapping(bytes => bool) public inFlightRemittence;

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
    
    constructor () public {
        assert(msg.sender == getOwner(), "only owner who deployed Ownable contract can deploy this contract ");
    }

    
    /**
    @dev This function would set the contract conditions and can be called only by the Alice, who is the contract owner.
    Alice can call this function any number of time to set the contract with the limitation of not reusing the same
    contract name until it is active. 
    @param _name array of remittence name. Each remittence is identified by its name
    @param _puzzle hashed puzzle for each remittence
    @param _amount amount for each remittence
    @param _duration duration after which Alice can withdraw the ether
    @param _CarolAddress Carol address, who in turn would solve the puzzle
    */
    function setRemittenceCondition(bytes _name, bytes32 _puzzle, uint _duration, address _CarolAddress)
    public
    onlyWhenNotPaused
    payable
    {
        require(!inFlightRemittence[_name], "This name is in active state"); 
        Carol = _CarolAddress;
        uint timeLine = now + _duration * 1 seconds;
        Remittence memory newRemittenceRecord = Remittence(_puzzle, msg.value, timeLine, true);    
        remittenceDetails[_name] = newRemittenceRecord;
        inFlightRemittence[_name] = true;
        emit LogContractConditionInitialized(msg.sender, string(_name),msg.value, timeLine);
    }

    /**
    @dev This function must be invoked by Carol to solve the puzzle and withdraw the amount.
    @param remittenceName  name of remittence. Carol wants to withdraw amount for this remittence
    @param password_bob Bob's one time password
    @param password_carol Carol's one time password
    @return boolean to indicate the status of this call
    */
    function withdrawRemittenceAmount(string memory remittenceName, bytes32 password_bob, bytes32 password_carol)
    public
    onlyWhenNotPaused
    onlyOnBeforeDeadLine(remittenceDetails[bytes(remittenceName)].deadLine)
    returns(bool) {
        require(msg.sender == Carol, "only Carol can invoke this function");
        require(remittenceDetails[bytes(remittenceName)].hasPuzzleSet, "puzzle is not set. This remittence is invalid");
        require(remittenceDetails[bytes(remittenceName)].puzzle == keccak256(abi.encodePacked(password_bob,password_carol)),"password mismatch,can not withdraw the amount");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;

        remittenceDetails[bytes(remittenceName)].amount = 0; // counter reentrant attack
        remittenceDetails[bytes(remittenceName)].hasPuzzleSet = false; // allow reusbility of the contract.
        inFlightRemittence[bytes(remittenceName)] = false; // Now Alice can use this name again in future remittence.
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
        require(remittenceDetails[bytes(remittenceName)].hasPuzzleSet, "puzzle is not set or remittence has been successfully used by carol");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceDetails[bytes(remittenceName)].amount;
        remittenceDetails[bytes(remittenceName)].amount = 0;
        remittenceDetails[bytes(remittenceName)].hasPuzzleSet = false;
        inFlightRemittence[bytes(remittenceName)] = false; // Now Alice can use this name again in future remittence.
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