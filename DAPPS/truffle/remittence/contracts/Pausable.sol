pragma solidity ^0.4.25;
import "./Ownable.sol";

/**
*@title Pausable
*@dev This contract contains feture to pause the contract functionlities.
 This inherent can only be invoked by the contract owner
*/
contract Pausable is Ownable {
    bool public _pause;

    event LogPause(address byWhom);
    event LogUnPause(address byWhom);

    /**
     *@dev set the flag to false. This means it would not pause the function. 
     */
    constructor() internal {
        _pause = false;    
    }

    /**
    *@dev this modifier allow to call function ONLY when contract is not paused.
    */
    modifier onlyWhenNotPaused {
        require(!_pause, "flag is already activated");
        _;
    }

    /**
    *@dev this modifier allow to call function ONLY when contract is paused. 
    */
    modifier onlyWhenPaused {
        require(_pause, "flag is not activated");
        _;
    }

    /** 
    * @dev Only when pause flag is mot set, then contract owner can call this 
    *function.  */
    function pause() public onlyOwner onlyWhenNotPaused {
        _pause = true;

        emit LogPause(msg.sender);
    }

    /** 
    * @dev Only when pause flag is set, then contract owner can call this 
    *function  to unset the flag.*/
    function unPause() public onlyOwner onlyWhenPaused {
        _pause = false;

        emit LogUnPause(msg.sender);
    }

}