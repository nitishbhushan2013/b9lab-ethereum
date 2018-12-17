pragma solidity ^0.4.25;

library RemittenceLib{
    
    function getPuzzle(bytes32 password1, bytes32 password2) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(password1,password2));
    }
}