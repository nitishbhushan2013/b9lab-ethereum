pragma solidity ^0.4.25;

/**
*@title Ownable
*@dev This contract maintains and identify the owner of the contract.
* code style - all the state variables and internal functions starts with '_'.
 */
contract Ownable {
    address public _owner; // state variable are declared private. 
                                //use its public getter() to access it. 

    constructor() internal {
        _owner = msg.sender;
    }

    /**
    *@dev this modifier ensures that only owner can can call the function 
     */
    modifier onlyOwner {
        require(_owner == msg.sender, "account must be owner of this contract");
        _;
    }

    /**
    *@return boolean to indicate if the contract invoker is the owner of the 
    contract
     */
    function isOwner() public view returns(bool) {
        return _owner == msg.sender;
    }

    /**
    * @dev This function will returns the owner address
    * @return owner address
     */
    function getOwner() public view returns(address){
        return _owner;
    }



}