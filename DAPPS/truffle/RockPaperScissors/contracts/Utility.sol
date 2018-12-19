pragma solidity ^0.4.25;

library Utility{
    function getSecretMove(address _owner,uint _move, bytes32 _salt) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(_owner, _move, _salt));
    }


}