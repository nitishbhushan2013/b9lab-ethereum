pragma solidity ^0.5.0;
import "./Pausable.sol";

contract RockPaperScissorsV1 is Pausable {
    address payable public Alice; //Alice address
    address payable public Bob; // Bob address 
    address payable private _winner; // winner will decide by the contract
    uint public amount; // represent deposited game amount 
    bool resetGameFlag = false; // flag to signal the reset game
    enum  ApproveMoves {Rock, Paper, Scissors, Invalid} // allowed moves for this game.
   
    struct Player{       // structure to hold the player game details
        ApproveMoves move;
        bytes32 secretMove;
        uint gameAmount;
        bool hasDepositedAmount;
        bool hasPlayed;
        bool hasRevealedTheMove;
    }
    mapping(address => Player) Players; // mapping of player address with its details
    
    // In case of wrong move by both players, game is cancelled.
    //amount of each player will then be maintained in 'playerBlance'. Player can invoke withdrawal () to receive it. 
    mapping(address => uint) playerBlance;  

    event LogEnrolCompleted(address from, uint amountDepositedByPlayer);
    event LogPlayCompleted(address from);
    event LogPlayerMoveRevealed(address from , ApproveMoves playerMove);
    event LogExecuteGameAlgo(string userMessage);
    event LogGameAlgoExecuted(ApproveMoves AliceMove, ApproveMoves BobMove, address winnerHasAnnounced);
    event LogGameResult(string gameStatus_succeeded_withdrawan,  uint AliceBalance, uint BobBalance, string userMessage);
    event LogPlayeHasRewarded(string gameStatus_succeeded_withdrawan, address winner, uint rewardAmount);
    event LogGameReset(string userMessage);
    event LogContractDistruct(address owner);


    /**
    @dev this modifier would ensures that both the player has submitted the amount (possibly zero)
      */  
    modifier whenEnrolStageCompleted {
        require(Players[Alice].hasDepositedAmount == true && Players[Bob].hasDepositedAmount == true, " Alice or Bob need to first deposit the amount.");
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
    @dev Each player would play their game and submit hash value of their move protected by their secret key.
    @param _secretMove //keccak256(msg.sender, gameMove, secretKey)
     */
    function play(bytes32 _secretMove)  
     public 
     onlyWhenNotPaused
     whenEnrolStageCompleted 
      returns(bool){
        require(!Players[msg.sender].hasPlayed, "This player has already played for this game");
        Players[msg.sender].secretMove = _secretMove;
        Players[msg.sender].hasPlayed = true;
      
        emit LogPlayCompleted(msg.sender);
        return true;
    }

    /**
    @dev This function would allow player to pass in needed detail to authenticate their game move.
    @param _move game move suppose to be submitted by this player as encrypted _secretMove
    @param _secretKey key which will decrypt his early submitted _secretMove to verify his move
     */
    function revealTheMove(uint _move, bytes32 _secretkey)
     public
     onlyWhenNotPaused
     whenPlayStageCompleted
     returns(bool) {
          require(!Players[msg.sender].hasRevealedTheMove, "This player has already revealed his move.");
          require(Players[msg.sender].secretMove == keccak256(abi.encodePacked(msg.sender, _move, _secretkey)),
                  "secret Key is not correct. Pls provide correct secret key.");
         
         if(_move > uint(ApproveMoves.Scissors)) {
                _move = 3; //for any invalid entry, set ApproveMoves.Invalid
         }
         Players[msg.sender].move = ApproveMoves(_move);
         Players[msg.sender].hasRevealedTheMove = true;

         emit LogPlayerMoveRevealed(msg.sender, Players[msg.sender].move);

         if(Players[Alice].hasRevealedTheMove == true && Players[Bob].hasRevealedTheMove == true) {
             _decideAndRewardTheWinner(); 
         }
     }

   
    /**
    @dev This function would run the game algorithm to decide the winner and reward it.
    This is a private function and hence can be called only by this contract. 
     */
    function _decideAndRewardTheWinner()
     private
     onlyWhenNotPaused
     whenPlayStageCompleted 
     returns (bool) {
        _executeGameAlgo();
        emit LogGameAlgoExecuted(Players[Alice].move, Players[Bob].move, _winner);
        if(_winner == address(0)) { // when both player has submitted invalid move
            playerBlance[Alice] = Players[Alice].gameAmount;
            playerBlance[Bob] = Players[Bob].gameAmount;
            emit LogGameResult("game withdrawan", playerBlance[Alice], playerBlance[Bob], "please withdraw the money");
            resetGameFlag = true;
            _resetGame();
            return true;
        }
        uint rewardAmount = amount;
        resetGameFlag = true;
        _resetGame();

        emit LogPlayeHasRewarded("game succedded", _winner, rewardAmount);
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
    whenPlayStageCompleted 
    returns(bool) {
        ApproveMoves aliceMove = Players[Alice].move;
        ApproveMoves bobMove= Players[Bob].move;

        if(aliceMove == ApproveMoves.Invalid && bobMove != ApproveMoves.Invalid) 
            _winner = Bob;
        else if(aliceMove != ApproveMoves.Invalid && bobMove == ApproveMoves.Invalid) 
            _winner = Alice;  
        else if(aliceMove == ApproveMoves.Invalid && bobMove == ApproveMoves.Invalid) 
            _winner = address(0);    //special case
        else if(aliceMove == ApproveMoves.Rock) {
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
        //emit event to inform player to withdraw the amount
        if(_winner == address(0))
            emit LogExecuteGameAlgo("Invalid moves, both player submitted INVALID entry.");

        return true;
    }

  /**
  @dev this function will prepare the play for the next game.
   */  
  function _resetGame()
  private
  onlyWhenNotPaused
  whenPlayStageCompleted 
  returns(bool) {
    require(!resetGameFlag, "reset flag is not set");
    //reset the status
    amount = 0;
    Players[Alice].gameAmount = 0;
    Players[Bob].gameAmount = 0;
    Players[Alice].hasDepositedAmount= false;
    Players[Bob].hasDepositedAmount= false;

    Players[Alice].hasPlayed= false;
    Players[Bob].hasPlayed= false;

    Players[Alice].hasRevealedTheMove= false;
    Players[Bob].hasRevealedTheMove= false;
    
    resetGameFlag = false;
    emit LogGameReset("Game has reset");
    return true;
  }


   /**
   @dev this function will allow the individual participating player to withdraw the amount. 
   This is needed only when both player has played the invalid mode and thus game has withdrawan.
    */ 
   function withdraw()
    public
    payable
    returns(bool) {
        uint withdrawalAmount = playerBlance[msg.sender];
        require(withdrawalAmount >0, "withdwaral amount must be greater than zero");
        //accounting
        playerBlance[msg.sender] = 0;
       
        msg.sender.transfer(withdrawalAmount);
        return true;
    }

    /**
    @dev this function will allow contract owner to kill this contract and get back all the contract money. 
     */
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