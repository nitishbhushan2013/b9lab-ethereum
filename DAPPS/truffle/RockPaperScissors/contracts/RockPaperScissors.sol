pragma solidity ^0.5.0;
import "./Pausable.sol";

contract RockPaperScissors is Pausable {
    address payable public Alice; //Alice address
    address payable public Bob; // Bob address 
    address payable private _winner; // winner will decide by the contract
    uint public amount; // represent deposited game amount 
  
    enum  ApproveMoves {Rock, Paper, Scissors} // legal moves for this game
   
    struct Player{       // structure to hold the player game details
        ApproveMoves move;
        uint gameAmount;
        bool hasDepositedAmount;
        bool hasPlayed;
    }
    mapping(address => Player) Players; // mapping of player address with its details
    mapping(uint => bool) movePlayed;   // mapping of the player move in the current game
  
    event LogEnrolCompleted(address from, uint amountDepositedByPlayer);
    event LogPlayCompleted(address from, ApproveMoves playedMove);
    event LogGameAlgoExecuted(ApproveMoves AliceMove, ApproveMoves BobMove, address winnerHasAnnounced);
    event LogPlayeHasRewarded(address winner, uint rewardAmount);
    event LogContractDistruct(address owner);


    /**
    @dev this modifier would ensures that both the player has submitted the amount (possibly zero)
      */  
    modifier whenEnrolStageCompleted {
        require(Players[Alice].hasDepositedAmount == true && Players[Bob].hasDepositedAmount == true, " Alice or Bob need to first deposit the amount.");
        _;
    }

    /**
    @dev this modofier would ensures that both player move must be different for the contract to decide the winner.
     */
    modifier mustNotPlayTheSameMove(uint _num) {
        require(!movePlayed[_num], "player can not play the same move as of other player in the same game.");
        _;
    }

    /**
    @dev This modifier would ensures that both plater has played their chance
     */
    modifier whenPlayStageCompleted {
          require(Players[Alice].hasPlayed == true && Players[Bob].hasPlayed == true, " Alice or Bob need to play their move.");
        _;
    }


    constructor (address payable[2] memory addr) public {
        require(msg.sender == getOwner(), "only owner who deployed Ownable contract can deploy this contract ");
        require(addr[0] != address(0), "addres must not be zero account");
        require(addr[1] != address(0), "addres must not be zero account");
        Alice = addr[0];
        Bob = addr[1];
    }


    /**
    @dev Each player would deposit the ether. In this context, only Alice and Bob are allowed to play the game. 
     */
    function enrol()
     public 
     onlyWhenNotPaused 
     payable 
     returns(bool) {
        require((msg.sender == Alice) || (msg.sender == Bob), "Only Alice and Bob are allowed to play this game"); 
        require(!Players[msg.sender].hasDepositedAmount, "This player has already deposited the amount for this game");
        Players[msg.sender].gameAmount = msg.value;
        Players[msg.sender].hasDepositedAmount = true;
        emit LogEnrolCompleted(msg.sender, msg.value);
        amount += msg.value; // no check on value as it may be 0 
        
        return true;
    }

    /**
    @dev Each player would play their game. Each must not repeat the  other's player move in a single game.
    @param _move player move 
     */
    function play(uint _move)
     public 
     onlyWhenNotPaused
     whenEnrolStageCompleted 
     mustNotPlayTheSameMove(_move)
      returns(bool){
        require(uint(ApproveMoves.Scissors) >= _move, "move must be 0 or 1 or 2");
        require(!Players[msg.sender].hasPlayed, "This palyer has already played for this game");
        Players[msg.sender].move = ApproveMoves(_move);
        Players[msg.sender].hasPlayed = true;
        movePlayed[_move] = true;
        emit LogPlayCompleted(msg.sender, ApproveMoves(_move));

        if(Players[Alice].hasPlayed == true && Players[Bob].hasPlayed == true) //lets see if contract can call
             _decideAndRewardTheWinner(); 
        return true;
    }

    /**
    @dev This function would run the game algorithm to decide the winner and reward it.
    This is a private function and hence can be called only by this contract. 
     */
    function _decideAndRewardTheWinner()
     private
     onlyWhenNotPaused
     whenEnrolStageCompleted 
     whenPlayStageCompleted 
     returns (bool) {
        _executeGameAlgo();
        require(_winner != address(0), "winner must not be addrress zero.");
        emit LogGameAlgoExecuted(Players[Alice].move, Players[Bob].move, _winner);
        
        uint rewardAmount = amount;
     
        //reset the status
        amount = 0;
        Players[Alice].hasDepositedAmount= false;
        Players[Bob].hasDepositedAmount= false;

        Players[Alice].hasPlayed= false;
        Players[Bob].hasPlayed= false;

        movePlayed[uint(ApproveMoves.Rock)] = false;
        movePlayed[uint(ApproveMoves.Paper)] = false;
        movePlayed[uint(ApproveMoves.Scissors)] = false;

        emit LogPlayeHasRewarded(_winner, rewardAmount);
        _winner.transfer(rewardAmount);
        return true;
    }

    /**
    @dev This function would run the game algorithm to decide the winner.
    This is a private function and hence can be called only by this contract. 
     */
    function _executeGameAlgo() 
    private 
    onlyWhenNotPaused
    whenEnrolStageCompleted 
    whenPlayStageCompleted 
    returns(bool) {
        ApproveMoves aliceMove = Players[Alice].move;
        ApproveMoves bobMove= Players[Bob].move;

        if(aliceMove == ApproveMoves.Rock) {
            if(bobMove == ApproveMoves.Paper) {
                _winner = Bob;
            } else if(bobMove == ApproveMoves.Scissors) {
                _winner = Alice;
            }
        } else if(aliceMove == ApproveMoves.Paper) {
            if(bobMove == ApproveMoves.Rock) {
                _winner = Alice;
            } else if(bobMove == ApproveMoves.Scissors) {
                _winner = Bob;
            }
        } else if(aliceMove == ApproveMoves.Scissors) {
            if(bobMove == ApproveMoves.Paper) {
                _winner = Alice;
            } else if(bobMove == ApproveMoves.Rock) {
                _winner = Bob;
            }
        } 
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