//SPDX-License-Identifier: MIT

pragma solidity  >=0.8.7;

contract FoggyBank {
    uint public app = 54545;

    function changeNum(uint _num) public {
        app = _num;
    }
}