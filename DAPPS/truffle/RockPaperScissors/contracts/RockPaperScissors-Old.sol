pragma solidity ^0.5.0;

contract RockPaperScissors {
    address payable public owner; // represent contract owner
    address payable public Alice;
    address payable public Bob;
    address payable public winner; // The address type was split into address and address payable, 
                                            //where only address payable provides the transfer function.
    uint public amount; // represent contract amount 
  
    mapping(address => uint) playerMove;
    mapping(address => bool) playerDepositTheAmount;
    mapping(address => bool) playerPlayedTheirMove;
    bytes32[] approvedMoves;

    bool AlicePlayed = false;
    bool BobPlayed = false;

    enum ApprovedMove {Rock, Paper, Scissors}
    //ApprovedMove aliceMove;
    //ApprovedMove bobMove;


    modifier onlyByOwner(address _owner) {
            require(_owner == owner, "address must be contract owner");
            _;
    }

    constructor (address payable[2] memory addr) public {
        require(addr[0] != address(0), "addres must not be zero account");
        require(addr[1] != address(0), "addres must not be zero account");
       
        owner = msg.sender;
        Alice = addr[0];
        Bob = addr[1];

    }

    /**
    Each participating player would deposit the ether. In this context, only Alice and Bob 
    are allowed to play the game. 
     */
    function startTheGame() public payable returns(bool) {
        require((msg.sender == Alice) || (msg.sender == Bob), "Only Alice and Bob are allowed to play this game"); 
        require(playerDepositTheAmount[msg.sender] != true, "This palyer has already deposited the amount for this game");

        playerDepositTheAmount[msg.sender] = true;
        amount += msg.value; // no check on value as it may be 0 
        
        return true;
    }

    function makeYourMove(uint move) public returns(bool){
        require(playerDepositTheAmount[Alice] == true && playerDepositTheAmount[Bob] == true, " Alice or Bob need to first deposit the amount.");
        require(move < 3, "move must be 0 or 1 or 2");  // imrpovement: pass the bytes32     

        playerMove[msg.sender] = move;
        playerPlayedTheirMove[msg.sender] = true;

        decideTheWinner(); // let it decide to wait for the player 
    }

    function decideTheWinner() public returns (bool) {
        require(playerPlayedTheirMove[Alice] == true && playerPlayedTheirMove[Bob] == true, " Alice or Bob need to play their move");
        require(playerMove[Alice] != playerMove[Bob], "plater move must be different");

       
        if(playerMove[Alice] == 0 ) {
            if(playerMove[Bob] == 1) {
                winner = Bob;
            }else if(playerMove[Bob] == 2){
                winner = Alice;
            }
        } else if(playerMove[Alice] == 1 ) {
            if(playerMove[Bob] == 0) {
                winner = Alice;
            }else if(playerMove[Bob] == 2){
                winner = Bob;
            }
        }else if(playerMove[Alice] == 2 ) {
            if(playerMove[Bob] == 0) {
                winner = Bob;
            }else if(playerMove[Bob] == 1){
                winner = Alice;
            }
        } 
       // reward the winner   
        rewardTheWinner();
    }

    function rewardTheWinner() public returns(bool) {
        require(winner != address(0), "addres must not be zero account");
        uint totalAmount = amount;
        amount = 0;

         //reset the status
         playerDepositTheAmount[Alice] = false;
         playerDepositTheAmount[Bob] = false;
        
         playerPlayedTheirMove[Alice] = false;
         playerPlayedTheirMove[Bob] = false;

        winner.transfer(totalAmount);
       
    }

    function kill() public onlyByOwner(owner) returns(bool){
        emit LogContractDistruct(owner);
        selfdestruct(owner);
        return true;
    }

}