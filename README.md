# b9lab-ethereum

## Project 1
You will create a smart contract named Splitter whereby:

There are three people: Alice, Bob and Carol
we can see the balance of the Splitter contract on the web page
whenever Alice sends ether to the contract, half of it goes to Bob and the other half to Carol
we can see the balances of Alice, Bob and Carol on the web page
we can send ether to it from the web page

#### Stretch goals:
* Make the contract pausible.
* Add a kill switch to the whole contract
* Make the contract a utility that can be used by David, Emma and anybody with an address
* Cover potentially bad input data
* Explicit check on payer for splitting, no one else can call split
* Withdraw pattern for splitted payments
* Free contribution with fallback function also for payer
* Better control over ownership of contract and possible transfer of ownership.
* Manipulate selfdestruct function so that the contract would selfdestruct to another contract that tracks the balances of those using the contract, so people could still withdraw their own funds.
* Allow the user to switch accounts for interaction with the webpage.


## Project 2
You will create a smart contract named Remittance whereby:

There are three people: Alice, Bob & Carol.
Alice wants to send funds to Bob, but she only has ether & Bob wants to be paid in local currency.
luckily, Carol runs an exchange shop that converts ether to local currency.
Therefore, to get the funds to Bob, Alice will allow the funds to be transferred through Carol's exchange shop. Carol will collect the ether from Alice and give the local currency to Bob.

##### The steps involved in the operation are as follows:

* Alice creates a Remittance contract with Ether in it and a puzzle.
* Alice sends a one-time-password to Bob; over SMS, say.
* Alice sends another one-time-password to Carol; over email, say.
* Bob treks to Carol's shop.
* Bob gives Carol his one-time-password.
* Carol submits both passwords to Alice's remittance contract.
* Only when both passwords are correct does the contract yield the Ether to Carol.
* Carol gives the local currency to Bob.
* Bob leaves.
* Alice is notified that the transaction went through.
* Since they each have only half of the puzzle, Bob & Carol need to meet in person so they can supply both passwords to the contract. This is a security measure. It may help to understand this use-case as similar to a 2-factor authentication.

##### Stretch goals:
* Add a deadline, after which Alice can claim back the unchallenged Ether
* Add a limit to how far in the future the deadline can be
* Add a kill switch to the whole contract
* Plug a security hole (which one?) by changing one password to the recipient's address
* Make the contract a utility that can be used by David, Emma and anybody with an address
* Make you, the owner of the contract, take a cut of the Ethers smaller than what it would cost Alice to deploy the same contract herself
did you degrade safety in the name of adding features?



## Project 3

You will create a smart contract named RockPaperScissors whereby:

* Alice and Bob play the classic rock paper scissors game.
* To enrol, each player needs to deposit the right Ether amount, possibly zero.
* To play, each player submits their unique move.
* The contract decides and rewards the winner with all Ether wagered.

##### Stretch goals:
* Make it a utility whereby any 2 people can decide to play against each other.
* Reduce gas costs as much as you can.
* Let players bet their previous winnings.
* How can you entice players to play, knowing that they may have their funding stuck in the contract if they faced an uncooperative player?


## Final Project
We describe the end-goal of a decentralised application for which you describe the problems that it faces and should solve. 
You can also suggest a set of contracts and their function interfaces (functions signatures without bodies, modifiers at your 
discretion) if this is your preferred way of communicating intent.  
The repository for this part is named your_name-essay.

The project represents a regulated system of toll roads. Vehicles pay to drive on them. 
It is regulated in the sense that there is an entity whose role it is to ensure some rules for participants.

##### Participants
This project caters to all of them and they should hold a piece of the checks and balances:

* The regulator
* The road operator(s)
* The toll booth(s)
* The vehicle(s)
* The driver(s)
