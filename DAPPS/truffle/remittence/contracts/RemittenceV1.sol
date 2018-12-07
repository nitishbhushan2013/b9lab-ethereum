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
        bytes remittenceName; // acts as a unique identifier
        bytes32 puzzle;
        uint amount;
        uint duration;
        bool hasPuzzleSet;
    }

    // Allow us to look the remittence details by remittence name
    mapping(bytes => Remittence) public remittenceMap;

    //ensure unique remittence name
    mapping(bytes => bool) public uniqueNameMap;

    event LogContractConditionInitialized(address from, string indexed remittenceName, uint amount, uint duration);
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
        require(msg.sender == getOwner(), "only owner who deployed Ownable contract can deploy this contract ");
    }
    /**
    @dev This function would set the contract conditions and can be called only by the Alice, who is the contract owner.
    @param _Count total number of remittence submitted by Alice
    @param _nameArray array of remittence name. Each remittence is identified by its name
    @param _puzzleArray array of hashed puzzle for each remittence
    @param _amountArray array of amount for each remittence
    @param _durationArray array of duration after which Alice can withdraw the ether
    @param _CarolAddress Carol address, who in turn would solve the puzzle
    */
    //TODO: check conversion of bytes to string
    function initializeContract(uint8 _Count, bytes[] _nameArray, bytes32[] _puzzleArray, uint[] _amountArray, uint[]  _durationArray, address _CarolAddress) public {
        require(_Count == _nameArray.length, "count must be same");
        require(_Count == _puzzleArray.length, "count must be same");
        require(_Count == _amountArray.length, "count must be same");
        require(_Count == _durationArray.length, "count must be same");

        Carol = _CarolAddress;
        // iterate each record and create the remittence
        for(uint i = 0; i < _Count; i++){  
            require(!uniqueNameMap[_nameArray[i]], "name must be unique"); // This ensures, there won't be any duplicate
            Remittence memory  newRemittenceRecord = Remittence(_nameArray[i], _puzzleArray[i], _amountArray[i], now + _durationArray[i] * 1 seconds, true);    
           // remittenceArray.push(newRemittenceRecord);
            remittenceMap[_nameArray[i]] = newRemittenceRecord;
            emit LogContractConditionInitialized(msg.sender, string(_nameArray[i]), _amountArray[i], _durationArray[i]);
        }
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
    onlyOnBeforeDeadLine(remittenceMap[bytes(remittenceName)].duration)
    returns(bool) {
        require(msg.sender == Carol, "only Carol can invoke this function");
        require(remittenceMap[bytes(remittenceName)].hasPuzzleSet, "puzzle is not set. This remittence is invalid");
        require(remittenceMap[bytes(remittenceName)].amount > 0, "withdrawal amount must be more than 0.");
        require(remittenceMap[bytes(remittenceName)].puzzle == keccak256(abi.encodePacked(password_bob,password_carol)),"password mismatch,can not withdraw the amount");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceMap[bytes(remittenceName)].amount;
        remittenceMap[bytes(remittenceName)].amount = 0; // counter reentrant attack
        remittenceMap[bytes(remittenceName)].hasPuzzleSet = false; // allow reusbility of the contract.
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
    onlyAfterDeadLine(remittenceMap[bytes(remittenceName)].duration)
    returns(bool) {
        require(remittenceMap[bytes(remittenceName)].hasPuzzleSet, "puzzle is not set or remittence has been successfully used by carol");
        require(remittenceMap[bytes(remittenceName)].amount > 0, "ether must be there to withdraw");
        uint withdrawalAmount;
        //accounting
        withdrawalAmount = remittenceMap[bytes(remittenceName)].amount;
        remittenceMap[bytes(remittenceName)].amount = 0;
        remittenceMap[bytes(remittenceName)].hasPuzzleSet = false;
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