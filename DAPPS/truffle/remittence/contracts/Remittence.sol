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

    event LogContractInitialized(address byWhom, uint amountDeposited);
    event LogWithdrawRemittenceAmountInvoked(address from);
    event LogWithdrawRemittenceAmountSuccessed(address from, bytes32 password1, bytes32 password2, uint amountWithdrawan);
    event LogWithDrawUnclaimedAmountCompleted(address byWhom, uint howMuch);
    event LogContractDistruct(address owner);
    
    modifier onlyBy(address _owner) {
        require(_owner == owner);
        _;
    }

    modifier onlyAfter(uint _deadLineLimit){
        require(now > _deadLineLimit);
        _;
    }


    // Alice has deployed the contract with ether in it and puzzle
    constructor (uint  _deadLineLimit, address _CarolAddress) public payable{
        require(msg.value > 0, "ether amount must be greater than 0");

        owner = msg.sender;
        amount = msg.value;
        creationTime = now;
        deadLineLimit = _deadLineLimit;
        Carol = _CarolAddress;

        /**Let the secrert key be part of the contract code. This way, keys won't exposed to the outside
        world through anymeans. Since Alice is deploying this contract, she knows these keys */
        puzzleSecretvalue = keccak256(abi.encodePacked("alice123", "123alice")); 
        emit LogContractInitialized(owner, amount);
    }

    /**This is a public function and hence can be invoked by any person.  */
    function withdrawRemittenceAmount(bytes32 password_bob, bytes32 password_carol) public payable returns(bool) {
        require(msg.sender != address(0), "contract invoking address must not be zero address");
        require(msg.sender == Carol, "Only carol can invoke the Remittemce contract");
        require(amount > 0, "withdrawal amount must be more than 0.");

        emit LogWithdrawRemittenceAmountInvoked(msg.sender);
        bytes32 hashValue = keccak256(abi.encodePacked(password_bob,password_carol));

        if(hashValue == puzzleSecretvalue) { // carol is ready to withdraw the ether
            msg.sender.transfer(amount);
        }
        emit LogWithdrawRemittenceAmountSuccessed(msg.sender,password_bob,password_carol,amount);
        return true;
    }

    function withdrawUnclaimedEther() private onlyBy(owner) onlyAfter(creationTime+deadLineLimit) returns(bool) {
        require(amount > 0, "ether must be there to withdraw");
        emit LogWithDrawUnclaimedAmountCompleted(msg.sender, msg.value);

        msg.sender.transfer(msg.value);
        return true;
    }

    function kill() public onlyBy(owner) returns(bool){
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }

}


