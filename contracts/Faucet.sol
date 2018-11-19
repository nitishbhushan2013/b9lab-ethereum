pragma solidity ^0.4.22;

contract Faucet {
    address public owner;
    uint public sendAmount;
}

constructor () public payable {
    owner = msg.sender;
    sendAmount = 1 ether;
}

function getWei() public {
    msg.sender.transfer(sendAmount);
}

function sendWei(address whom, uint howMuch) public {
    whom.transfer(howMuch);
}

function getBalance() public pure returns(uint) {
    address(this).balance;
}

function killMe() public returns(bool){
    require(owner == msg.sender);
    selfDestruct(owner);
    return true;
}