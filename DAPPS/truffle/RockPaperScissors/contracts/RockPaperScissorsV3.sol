pragma solidity ^0.4.25;
import "./Pausable.sol";
import "./Utility.sol";

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
* step2 : Any player can get the count of all such 'Available' games by getAllAvailableGamesCount()
* Step3 : Other player can choose any game from step2 and play his move - otherPlayerMove(bytes32 _gameId, uint _bet, uint _move)
* step4: First player can get count of all the 'Pending' games by getPendingGamesCount(). This indicates all the
* games which was initiated by this player and has been played by other player.
* Step5: First player can then choose any pending game and reveal his move by revealTheMove(bytes32 _gameId, uint _move, bytes32 _secretkey)
* Step6: contract then invokes _decideAndRewardTheWinner(bytes32 _gameId) to decide the winner and reward it.
*
* Below are other helping APIs availables for smooth run of this contract
* _executeGameAlgo(bytes32 _gameId) - execute game algorithm
* isGameAvailable(bytes32 gameId) - check existance of this game
* _resetGame(bytes32 _gameId) - reset the game
* getBetAmountForThisGame(bytes32 gameId) - use by any player to get the bet amount for the gameId
* removeAvailableGame(bytes32 _gameId) - remove the 'available' game from the list
* removePendingGame(bytes32 _gameId) - remove the 'pending' game from the list
* withdraw() - invoke by each player to withdraw their balance
* kill() - invoke by contract creator to finally kill this contract
*/


contract RockPaperScissorsV3 is Pausable {
    address private _winner; // winner will decide by the contract
    bool public resetGameFlag = false; // flag to signal the reset game
    uint public maxAllowedGameCount; // maximum no. of allowed games for any player.
    enum ApproveMoves {Rock, Paper, Scissors} // allowed moves for this game.
    /**
    * Available - When Game has been initialized by Player1 and waiting to be played by any other player
    * Pending - Player2 has made their move and now player1 has to decrypt his move. Both these moves will then evaluate by contract to decide the winner
    * Completed - When winner has been announced and paid. This state indicates end of this game. Ideally, this game should be archieved
    */
    enum GameStatus {Available, Pending, Completed}


    /**
    * @dev - this structure will contain player details
    */
    struct PlayerDetail{
        address playerAddress; //unique address
        uint bet; // bet amount
        bytes32 secretMove; //hash of game move
        ApproveMoves move; // game move
    }


    /**
    @dev master structure to contain the game details along side participating player
    */
    struct Game {
        PlayerDetail[2] player;
        GameStatus gameStatus;
        uint availablePointer; // pattern to sync records with availableGamesList
        uint pendingPointer; // pattern to sync records with pendingGamesList
        uint amount; // capture the total bet for this game
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
        uint gameInitiated;
    }
   
    /**
    * @dev this mapping would hold the status count(available, pending) of games for player.
    * */
    mapping(address => GameStatusCount) public playerGameStatusCount;
   
    /**
    @dev When both player play the same move (either valid or invalid), then total bet amount will be divided and store for each player.
    Player can invoke withdrawal () to receive it.
    */
    mapping(address => uint) public playerBlance;
    
    /**
    @dev track the used secretkeys
     */
    mapping(bytes32 => bool) public usedSecrets;
   
   
    event LogGameHasInitiated(address from, bytes32 gameId, uint betAmount, GameStatus gameStatus);
    event LogOtherPlayerPlayed(address from, bytes32 gameId, uint betAmount, ApproveMoves playerMove, GameStatus gameStatus);
    event LogPlayer1MoveRevealed(address from, bytes32 gameId, uint move);
    event LogExecuteGameAlgo(bytes32 gameId, string userMessage);
    event LogGameAlgoExecuted(bytes32 gameId, address winnerHasAnnounced);
    event LogGameResult(bytes32 gameId, string gameStatus_succeeded_withdrawan, uint AliceBalance, uint BobBalance, string userMessage);
    event LogGameReset(bytes32 gameId, string userMessage);
    event LogPlayeHasRewarded(bytes32 gameId, string gameStatus_succeeded_withdrawan, address winner, uint rewardAmount);
    event LogEntryDeletedFromAvailableGamesList(bytes32 gameId);
    event LogEntryDeletedFromPendingGamesList(bytes32 gameId);
    event LogContractDistruct(address owner);

   
    constructor (uint _maxAllowedGame) public {
        maxAllowedGameCount = _maxAllowedGame;
    }

    /**
    @dev this function would allow owner to reset the max alllowed game count.
    */
    function setAllowedGameCount(uint _maxAllowedGame)
    public
    onlyWhenNotPaused
    onlyOwner
    returns(bool) {
        maxAllowedGameCount = _maxAllowedGame;
        return true;
    }

    /**
    * @dev This function will always create a new game and the msg.sender will be first participant.
    * @param _gameId : game Id
    * @param _secretMove : keccak256(msg.sender, gameMove, secretKey)
    *
    * */
    function initiateTheGame(bytes32 _gameId, bytes32 _secretMove)
    public
    onlyWhenNotPaused
    payable
    returns(bool) {
        require( playerGameStatusCount[msg.sender].gameInitiated < maxAllowedGameCount, "you have already initiated maxAllowedGameCount games. Please complete at least one to initiate new game");
        require(!usedSecrets[_secretMove], "you have already used this _secretMove. Please provide different _secretMove");
        require(!isGameAvailable(_gameId), "this game is alraedy active");

        uint _bet = msg.value;
        usedSecrets[_secretMove] = true;

        // set the first player details
        games[_gameId].player[0].playerAddress = msg.sender;
        games[_gameId].player[0].bet = _bet;
        games[_gameId].player[0].secretMove = _secretMove;
        // This status would indicates availability of this game to any other player
        games[_gameId].gameStatus = GameStatus.Available;
        playerGameStatusCount[msg.sender].gameInitiated++; // this will kep track of 'open' games for this player.
        games[_gameId].availablePointer = availableGamesList.push(_gameId) -1;
        games[_gameId].amount += _bet;
        emit LogGameHasInitiated(msg.sender,_gameId, _bet, GameStatus.Available);
        return true;
    }


    /**
    * @dev Other player would pick any game whose gameStatus= 'available' and play their move.
    * other player bet amount must be either equal or more than first player bet.
    *
    * @param _gameId unique game identifier
    * @param _move : second player game move
    */
    function otherPlayerMove(bytes32 _gameId, uint _move)
    public
    onlyWhenNotPaused
    payable
    returns(bool){
        require(_move <= uint(ApproveMoves.Scissors), "player move is not valid");
        require(games[_gameId].gameStatus == GameStatus.Available, "this game is not in the 'Available' state");
        require(msg.value >= games[_gameId].player[0].bet, "bet amount must be equal and more than first player bet amount");

        uint _bet = msg.value;
        // set the second player details
        games[_gameId].player[1].playerAddress = msg.sender;
        games[_gameId].player[1].bet = _bet;
        games[_gameId].player[1].move = ApproveMoves(_move);
        games[_gameId].amount += _bet;
        // This status would hints first player to reveal his move
        games[_gameId].gameStatus = GameStatus.Pending;
        games[_gameId].pendingPointer = pendingGamesList.push(_gameId) -1;
        _removeAvailableGame(_gameId); // this will sync the availableGamesList, which holds all the available games and used by Player2 to get list of these games.
        emit LogOtherPlayerPlayed(msg.sender, _gameId, _bet, ApproveMoves(_move), GameStatus.Pending);

        return true;
    }


    /**
    @dev First player would reveal his move and allow contract to decide the winner.
    @param _move move of the first player
    @param _secretKey key which will decrypt his early submitted _secretMove to verify his move
    */
    function revealTheMove(bytes32 _gameId, uint _move, bytes32 _secretKey)
    public
    onlyWhenNotPaused
    returns(bool) {
        require(msg.sender == games[_gameId].player[0].playerAddress, "only player 1 of this game can invoke this function." );
        require( games[_gameId].gameStatus == GameStatus.Pending, "this game is not available.");
        require(games[_gameId].player[0].secretMove == Utility.getSecretMove(msg.sender, _move, _secretKey), "secret Key is not correct. Pls provide correct secret key.");
       
        if(_move > uint(ApproveMoves.Scissors)) { // wrong move => winner is player2
            _winner = games[_gameId].player[1].playerAddress;
        } else { // correct move, let contract algorithm decides the winner
            games[_gameId].player[0].move = ApproveMoves(_move);
        }

        emit LogPlayer1MoveRevealed(msg.sender, _gameId, _move);
        _decideAndRewardTheWinner(_gameId);
    }


    /**
    @dev This function would run the game algorithm to decide the winner and reward it.
    This is a private function and hence can be called only by this contract.
    @param _gameId game for which to decide the winner
    */
    function _decideAndRewardTheWinner(bytes32 _gameId)
    private
    onlyWhenNotPaused
    returns (bool) {
        _executeGameAlgo(_gameId);
        emit LogGameAlgoExecuted(_gameId, _winner);

        if(_winner == address(0)) { // when both player has submitted same move
            playerBlance[games[_gameId].player[0].playerAddress] = games[_gameId].player[0].bet;
            playerBlance[games[_gameId].player[1].playerAddress] = games[_gameId].player[1].bet;
            
            emit LogGameResult(_gameId, "game withdrawan", playerBlance[games[_gameId].player[0].playerAddress], playerBlance[games[_gameId].player[1].playerAddress], "please withdraw the money");
            
            resetGameFlag = true;
            games[_gameId].gameStatus = GameStatus.Completed;
            _resetGame(_gameId);
            return true;
        }

        uint rewardAmount = games[_gameId].amount;
        games[_gameId].gameStatus = GameStatus.Completed;
        resetGameFlag = true;
        _resetGame(_gameId);
        if(_winner == games[_gameId].player[0].playerAddress){
            playerBlance[games[_gameId].player[0].playerAddress] += rewardAmount;
        } else if(_winner == games[_gameId].player[1].playerAddress){
            playerBlance[games[_gameId].player[1].playerAddress] += rewardAmount;
        }
        emit LogPlayeHasRewarded(_gameId, "game succedded", _winner, rewardAmount);
        return true;
    }


    /**
    @dev This function would run the game algorithm to decide the winner.
    This is a private function and hence can be called only by this contract.
    @param _gameId game for which to decide the winner
    */
    function _executeGameAlgo(bytes32 _gameId)
    private
    onlyWhenNotPaused
    returns(bool) {
        if(_winner != address(0)) { // winner has already being found out
            return true;
        }
        /**
        For the Rock-Paper-Scissor version:
        let d = (3 + a - b) % 3. Then:
        d = 1 => a wins
        d = 2 => b wins
        d = 0 => tie
        */
        uint player1Move = uint(games[_gameId].player[0].move);
        uint player2Move = uint(games[_gameId].player[1].move);
        uint winnerLogic = (3+(player1Move - player2Move)) % 3;

        if(winnerLogic > 0) {
            _winner = games[_gameId].player[winnerLogic].playerAddress;
        }
        //emit event to inform player to withdraw the amount
        if(_winner == address(0))
            emit LogExecuteGameAlgo(_gameId, "Both players have played the same move.");

        return true;
    }

    /**
    * @dev this function will check existance of gameId.
    */
    function isGameAvailable(bytes32 _gameId)
    public
    view
    onlyWhenNotPaused
    returns(bool){
        return ( games[_gameId].player[0].playerAddress != address(0));
    }


    /**
    @dev this function will prepare the play for the next game.
    */
    function _resetGame(bytes32 _gameId)
    private
    onlyWhenNotPaused
    returns(bool) {
        require(!resetGameFlag, "reset flag is not set");
        playerGameStatusCount[msg.sender].gameInitiated --;
        games[_gameId].amount = 0;
        _removeAvailableGame(_gameId);
        _removePendingGame(_gameId);
        resetGameFlag = false;
        emit LogGameReset(_gameId, "Game has reset");
        return true;
    }

    /**
    * @dev this function will return list of all the game
    */
    function getAllAvailableGamesCount()
    public
    view
    onlyWhenNotPaused
    returns (uint){
        return availableGamesList.length;
    }


    /**
    * @dev this function will return list of all the game
    */
    function getAllPendingGamesCount()
    public
    view
    onlyWhenNotPaused
    returns (uint){
        return pendingGamesList.length;
    }

    
    /**
    *dev This function will be use by second player to know the bet amount of this game.
    */
    function getBetAmountForThisGame(bytes32 _gameId)
    public
    view
    onlyWhenNotPaused
    returns(uint) {
        require(isGameAvailable(_gameId), "this game is not active");
        return games[_gameId].player[0].bet;
    }
    /**
    *@dev this function will remove a game identifier from availableGamesList and sync the record with games data structure
    *@param _gameId
    */
    function _removeAvailableGame(bytes32 _gameId)
    private
    onlyWhenNotPaused
    returns(bool) {
        uint rowToDelete = games[_gameId].availablePointer;
        bytes32 keyToMove = availableGamesList[availableGamesList.length -1];
        availableGamesList[rowToDelete] = keyToMove;
        games[_gameId].availablePointer = rowToDelete;
        availableGamesList.length --;
        emit LogEntryDeletedFromAvailableGamesList(_gameId);
        return true;
    }
    /**
    *@dev this function will remove a game identifier from pendingGamesList and sync the record with games data structure
    *@param _gameId
    */
    function _removePendingGame(bytes32 _gameId)
    private
    onlyWhenNotPaused
    returns(bool) {
        uint rowToDelete = games[_gameId].pendingPointer;
        bytes32 keyToMove = pendingGamesList[pendingGamesList.length -1];
        pendingGamesList[rowToDelete] = keyToMove;
        games[_gameId].pendingPointer = rowToDelete;
        pendingGamesList.length --;
        emit LogEntryDeletedFromPendingGamesList(_gameId);
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