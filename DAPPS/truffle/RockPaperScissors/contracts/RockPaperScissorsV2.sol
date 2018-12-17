
pragma solidity ^0.4.25;
import "./Pausable.sol";

/**
*This contract would support multiple games by many players. Each player can decide to either initiate a new game or participant in the on going game.
* Winner would be decided by the contract. In the sepcial case, where in both player has either selected a same move or invalid move, individual bet amount
* can be withdrawan by the each player by calling withdraw().
*
* Special condition - To maintain game sanity and fairness in the game, below are the two rules
* - Any player can initate at most 5 plays. The player must have to complete the running game to initiate a new game.
*
*
* Future enhancement : To resolve unfair practices, any 'pending' game would have a time line for player 1 to respond. If player1 fails to do so
* for what so ever resaon, player2 would be announced the winner by the contract.
*
*
* Game playing instructions
* -------------------------
* Step1 : Any player can start the game by initiateTheGame(uint _bet, bytes32 _secretMove). This player can start 5 such games.
* step2 : Any player can get the list of all such 'Available' games by getAllAvailableGames()
* Step3 : Other player can choose any game from step2 and play his move - otherPlayerMove(bytes32 _gameIdentifier, uint _bet, uint _move)
* step4: First player can get list of all the 'Pending' games by getAllPendingGames(). This list down all the
* games which was initiated by this player and has been played by other player.
* Step5: First player can then choose any pending game and reveal his move by revealTheMove(bytes32 _gameIdentifier, uint _move, bytes32 _secretkey)
* Step6: contract then invokes _decideAndRewardTheWinner(bytes32 _gameIdentifier) to decide the winner and reward it.
*
* Below are other helping APIs availables for smooth run of this contract
* _executeGameAlgo(bytes32 _gameIdentifier) - execute game algorithm
* isGameAvailable(bytes32 gameIdentifier) - check existance of this game
* _resetGame(bytes32 _gameIdentifier) - reset the game
* getBetAmountForThisGame(bytes32 gameIdentifier) - use by any player to get the bet amount for the gameIdentifier
* removeAvailableGame(bytes32 _gameIdentifier) - remove the 'available' game from the list
* removePendingGame(bytes32 _gameIdentifier) - remove the 'pending' game from the list
* withdraw() - invoke by each player to withdraw their balance
* kill() - invoke by contract creator to finally kill this contract
*/


contract RockPaperScissorsV2 is Pausable {
    address payable private _winner;                             // winner will decide by the contract
    bool public resetGameFlag = false;                   // flag to signal the reset game
    uint public amount;                                 // total bet for this game
    
    enum  ApproveMoves {Rock, Paper, Scissors, Invalid} // allowed moves for this game.
    
    /**
     * Available - When Game has been initialized by Player1 and waiting to be played by any other player
     * Pending   - Player2 has made their move and now player1 has to decrypt his move. Both these moves  will then evaluate by contract to decide the winner
     * Completed - When winner has been announced and paid. This state indicates end of this game. Ideally, this game should be archieved  
     */
    enum GameStatus {Available, Pending, Completed}
    
    /**
     * @dev - this str ucture will contain player details
     */
    struct PlayerDetail{
        address payable playerAddress;         //unique address
        uint bet;                      // bet amount
        bytes32 secretMove;            //hash of game move
        ApproveMoves move;             // game move
    }
    
    /**
     @dev master structure to contain the game details along side participating player
     */
    struct Game {
        PlayerDetail[2] player;
        GameStatus gameStatus;
        uint availablePointer;  // pattern to sync records with availableGamesList
        uint pendingPointer;    // pattern to sync records with pendingGamesList
    }
    
     /**
     * @dev provide random access based on unique inentifier for individual game,
     * unique identifier : keccak256(msg.sender, secretMove, bet, now)
    */
    mapping (bytes32 => Game) public games;    
    
    /**
     @dev list of all 'Available' games. game successfully played and concluded will remove from this list.
    This will help us to get list of all the available games for player2.     
     */
    bytes32[] public availableGamesList;
    
     /**
     @dev list of all 'Pending' games. game successfully played and concluded will remove from this list.
    This will help us to get list of all the pending games for player1.     
     */
    bytes32[] public pendingGamesList;
    
    
    
    /**
     * @dev this structure would hold the game status count.
     */
    struct GameStatusCount{
        uint availableCount;
       // uint pendingCount;
    }
   
    /**
     * @dev this mapping would hold the status count(available, pending) of games for player.
     * */
    mapping(address => GameStatusCount) public playerGameStatusCount;
    
  
    /**
     * @ help to identify currently running game
     */
    mapping(bytes32 => bool) public availableGames;
    
   
      /**
    @dev When both player play the same move (either valid or invalid), then total bet amount will be divided and store for each player.
        Player can invoke withdrawal () to receive it.
    */
    mapping(address => uint) public playerBlance;  
    
    
    event LogGameHasInitiated(address from, uint betAmount, GameStatus gameStatus);
    event LogOtherPlayerPlayed(address from, uint betAmount, ApproveMoves playerMove, GameStatus gameStatus);
    event LogPlayer1MoveRevealed(address from, ApproveMoves playerMove);
    event LogExecuteGameAlgo(string userMessage);
    event LogGameAlgoExecuted(ApproveMoves firstPlayerMove, ApproveMoves secondPlayerMove, address winnerHasAnnounced);
    event LogGameResult(string gameStatus_succeeded_withdrawan,  uint AliceBalance, uint BobBalance, string userMessage);
    event LogGameReset(string userMessage);
    event LogPlayeHasRewarded(string gameStatus_succeeded_withdrawan, address winner, uint rewardAmount);
    event LogEntryDeletedFromAvailableGamesList( bytes32 gameIdentifier);
    event LogEntryDeletedFromPendingGamesList( bytes32 gameIdentifier);
    event LogContractDistruct(address owner);

    
    constructor () public {
    }
    
    /**
     * @dev This function will always create a new game and the msg.sender will be first participant.
     * @param _bet : bet amount for this game
     * @param _secretMove : keccak256(msg.sender, gameMove, secretKey)
     *
     * */
    function initiateTheGame(uint _bet, bytes32 _secretMove)
    public
    onlyWhenNotPaused
    payable
    returns(bool) {
        bytes32 uniqueGameIdentifier =  keccak256(abi.encodePacked(msg.sender, _secretMove, bet, now));
        require( playerGameStatusCount[msg.sender].availableCount <6, "you have already initiated 5 games. Please complete at least one to initiate new game");
        require(!isGameAvailable(uniqueGameIdentifier), "this game is alraedy active");
        
        // set the first player details
        games[uniqueGameIdentifier].player[0].playerAddress = msg.sender;
        games[uniqueGameIdentifier].player[0].bet = _bet;
        games[uniqueGameIdentifier].player[0].secretMove = _secretMove;
        // This status would indicates availability of this game to any other player
        games[uniqueGameIdentifier].gameStatus = GameStatus.Available;
     
        playerGameStatusCount[msg.sender].availableCount++; // this will kep track of 'open' games for this player. 
        games[uniqueGameIdentifier].availablePointer = availableGamesList.push(uniqueGameIdentifier) -1;
       
        availableGames[uniqueGameIdentifier] = true;
        amount += _bet;
        
        emit LogGameHasInitiated(msg.sender, _bet, GameStatus.Available);
        
        return true;
    }

    /**
     * @dev Other player would pick any game whose gameStatus= 'available'  and play their move.
     * other player bet amount must be either equal or more than first player bet.
     *
     * @param _gameIdentifier unique game identifier
     * @param _bet : bet amount for this game
     * @param _move : second player game move
     */
    function otherPlayerMove(bytes32  _gameIdentifier, uint _bet, uint _move)
    public
    onlyWhenNotPaused
    returns(bool){
        require(isGameAvailable(_gameIdentifier), "this game is not created");
        require(games[_gameIdentifier].gameStatus == GameStatus.Available, "this game is not in the 'Available' state");
        require(_bet >= games[_gameIdentifier].player[0].bet, "bet amount must be equal and more than first player bet amount");
         
        if(_move > uint(ApproveMoves.Scissors)) {
            _move = 3; //for any invalid entry, set ApproveMoves.Invalid
         }
       
        // set the second player details
        games[_gameIdentifier].player[1].playerAddress = msg.sender;
        games[_gameIdentifier].player[1].bet = _bet;
        games[_gameIdentifier].player[1].move = ApproveMoves(_move);
        
        amount += _bet;
         
        // This status would hints first player to reveal his move
        games[_gameIdentifier].gameStatus = GameStatus.Pending;
        
        games[_gameIdentifier].pendingPointer = pendingGamesList.push(_gameIdentifier) -1;
        _removeAvailableGame(_gameIdentifier);
        emit LogOtherPlayerPlayed(msg.sender, _bet, ApproveMoves(_move), GameStatus.Pending);

        return true;
    }
    
    
    /**
    @dev First player would reveal his move and allow contract to decide the winner.
    @param _move move of the first player
    @param _secretKey key which will decrypt his early submitted _secretMove to verify his move
     */
    function revealTheMove(bytes32 _gameIdentifier, uint _move, bytes32 _secretKey)
     public
     onlyWhenNotPaused
     returns(bool) {
        require(msg.sender ==games[_gameIdentifier].player[0].playerAddress, "only player 1 of this game can invoke this function." );
        require( games[_gameIdentifier].gameStatus == GameStatus.Pending, "this game is not available.");
        require(games[_gameIdentifier].player[0].secretMove == keccak256(abi.encodePacked(msg.sender, _move, _secretKey)), "secret Key is not correct. Pls provide correct secret key.");
         
        if(_move > uint(ApproveMoves.Scissors)) {
            _move = 3;
        }
        games[_gameIdentifier].player[0].move = ApproveMoves(_move);
        
        emit LogPlayer1MoveRevealed(msg.sender, ApproveMoves(_move));
        
        _decideAndRewardTheWinner(_gameIdentifier);
    }
      
      
    /**
    @dev This function would run the game algorithm to decide the winner and reward it.
    This is a private function and hence can be called only by this contract.
    @param _gameIdentifier game for which to decide the winner
     */
    function _decideAndRewardTheWinner(bytes32 _gameIdentifier)
     private
     onlyWhenNotPaused
     returns (bool) {
        _executeGameAlgo(_gameIdentifier);
        emit LogGameAlgoExecuted(games[_gameIdentifier].player[0].move, games[_gameIdentifier].player[1].move, _winner);
        
        if(_winner == address(0)) { // when both player has submitted same move
            playerBlance[games[_gameIdentifier].player[0].playerAddress] = games[_gameIdentifier].player[0].bet;
            playerBlance[games[_gameIdentifier].player[1].playerAddress] = games[_gameIdentifier].player[1].bet;
            emit LogGameResult("game withdrawan", playerBlance[games[_gameIdentifier].player[0].playerAddress], playerBlance[games[_gameIdentifier].player[1].playerAddress], "please withdraw the money");
            resetGameFlag = true;
            games[_gameIdentifier].gameStatus = GameStatus.Completed;
            _resetGame(_gameIdentifier);
            return true;
        }
        uint rewardAmount = amount;
        games[_gameIdentifier].gameStatus = GameStatus.Completed;
        resetGameFlag = true;
        _resetGame(_gameIdentifier);
        
        emit LogPlayeHasRewarded("game succedded", _winner, rewardAmount);
        _winner.transfer(rewardAmount);
        return true;
    }  
    
     /**
    @dev This function would run the game algorithm to decide the winner.
    This is a private function and hence can be called only by this contract.
    @param _gameIdentifier game for which to decide the winner
     */
    function _executeGameAlgo(bytes32 _gameIdentifier)
    private
    onlyWhenNotPaused
    returns(bool) {
        ApproveMoves player1Move = games[_gameIdentifier].player[0].move;
        ApproveMoves player2Move = games[_gameIdentifier].player[1].move;
        
        if(player1Move == ApproveMoves.Invalid && player2Move != ApproveMoves.Invalid)
            _winner =games[_gameIdentifier].player[1].playerAddress;
        else if(player1Move != ApproveMoves.Invalid && player2Move == ApproveMoves.Invalid)
            _winner = games[_gameIdentifier].player[0].playerAddress;  
        else if(uint(player1Move) == uint(player2Move))
            _winner = address(0);    //special case when both player play the same move (including invalid move)
        else if(player1Move == ApproveMoves.Rock) {
            if(player2Move == ApproveMoves.Paper) {
                _winner = games[_gameIdentifier].player[1].playerAddress;
            } else if(player2Move == ApproveMoves.Scissors) {
                _winner = games[_gameIdentifier].player[0].playerAddress;
            }
        } else if(player1Move == ApproveMoves.Paper) {
            if(player2Move == ApproveMoves.Rock) {
                _winner = games[_gameIdentifier].player[1].playerAddress;
            } else if(player2Move == ApproveMoves.Scissors) {
                _winner = games[_gameIdentifier].player[1].playerAddress;
            }
        } else if(player1Move == ApproveMoves.Scissors) {
            if(player2Move == ApproveMoves.Paper) {
                _winner = games[_gameIdentifier].player[1].playerAddress;
            } else if(player2Move == ApproveMoves.Rock) {
                _winner = games[_gameIdentifier].player[1].playerAddress;
            }
        }
        //emit event to inform player to withdraw the amount
        if(_winner == address(0))
            emit LogExecuteGameAlgo("Both players have played the same move.");

        return true;
    }
    

    /**
     * @dev this function will check existance of gameIdentifier.
     */
    function isGameAvailable(bytes32 gameIdentifier)
    public
    onlyWhenNotPaused
    returns(bool){
        return availableGames[gameIdentifier];
    }
    
    
     /**
  @dev this function will prepare the play for the next game.
   */  
    function _resetGame(bytes32 _gameIdentifier)
    private
    onlyWhenNotPaused
    returns(bool) {
        require(!resetGameFlag, "reset flag is not set");
   
        amount = 0;
        games[_gameIdentifier].player[0].bet = 0;
        games[_gameIdentifier].player[0].playerAddress = address(0);
        games[_gameIdentifier].player[0].bet = 0;
        
        games[_gameIdentifier].player[1].bet = 0;
        games[_gameIdentifier].player[1].playerAddress = address(0);
        games[_gameIdentifier].player[1].bet = 0;
        
        availableGames[_gameIdentifier] = false;
        
        playerGameStatusCount[msg.sender].availableCount --;
        _removeAvailableGame(_gameIdentifier);
        _removePendingGame(_gameIdentifier);
        resetGameFlag = false;
        emit LogGameReset("Game has reset");
        return true;
    }

     /**
     * @dev this function will return list of all the game
     */
    function getAllAvailableGames()
    public
    view
    onlyWhenNotPaused
    returns (bytes32[] memory){
        return availableGamesList;
    }
    
    
     /**
     * @dev this function will return list of all the game
     */
    function getAllPendingGames()
    public
    view
    onlyWhenNotPaused
    returns (bytes32[] memory){
        return pendingGamesList;
    }
     
   
    
    //ToDO how to return tuple of (game, bet)
    /**
     *dev This function will be use by second player to know the bet amount of this game.
     */
    function getBetAmountForThisGame(bytes32 gameIdentifier)
    public
    view
    onlyWhenNotPaused
    returns(uint) {
        require(isGameAvailable(gameIdentifier), "this game is not active");
        return games[gameIdentifier].player[0].bet;
    }
    
     /**
     *@dev this function will remove a game identifier from availableGamesList and sync the record with games data structure
     *@param _gameIdentifier
     */
    function _removeAvailableGame(bytes32 _gameIdentifier) 
    private 
    onlyWhenNotPaused
    returns(bool) {
        uint rowToDelete = games[_gameIdentifier].availablePointer;
        bytes32 keyToMove = availableGamesList[availableGamesList.length -1];
        
        availableGamesList[rowToDelete] = keyToMove;
        games[_gameIdentifier].availablePointer = rowToDelete;
        availableGamesList.length --;
        
        emit LogEntryDeletedFromAvailableGamesList(_gameIdentifier);
        return true;
    }
    
    
     /**
     *@dev this function will remove a game identifier from pendingGamesList and sync the record with games data structure
     *@param _gameIdentifier
     */
    function _removePendingGame(bytes32 _gameIdentifier)
    private
    onlyWhenNotPaused
    returns(bool) {
        uint rowToDelete = games[_gameIdentifier].pendingPointer;
        bytes32 keyToMove = pendingGamesList[pendingGamesList.length -1];
        
        pendingGamesList[rowToDelete] = keyToMove;
        games[_gameIdentifier].pendingPointer = rowToDelete;
        pendingGamesList.length --;
        
        emit LogEntryDeletedFromPendingGamesList(_gameIdentifier);
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
      