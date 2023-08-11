//SPDX-License-Identifier: MIT

pragma solidity  >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoggyBank is Ownable {

    //Will be called when people deposit TokenA for anonymous tx
    event Deposit(address indexed depositor, uint amount);
    event Withdraw(address indexed receiver, uint amount);

    //SETTING POOL TOKEN: TokenA
    IERC20 public tokenContract;
    function setToken(address tokenAddress) external {
        tokenContract = IERC20(tokenAddress);
    }

    //STATE VARIABLES
    //each deposit will have a hash and an amount information
    mapping(bytes32 => uint) private balances;
    //these hashes will be saved in an array
    bytes32[] private balanceIds;
    //there will be a fee for calling deposit and withdraw functions to deter scammers
    mapping(address => bool) public feePayers;

    //SECURITY 1: pause contract
    bool public status;
    error Stopped(string message, address owner);
    modifier isPaused() {
        if(status == true) {
            revert Stopped("contract has been paused, contact owner", owner());
        }
        _;
    }
    function togglePause() external onlyOwner {
        status = !status;
    }

    //SECURITY 2: checking if new hash already exists
    error Existing(string message, bytes32 hashdata);
    modifier isExisting(bytes32 _hash) {
        for (uint256 i = 0; i < balanceIds.length; i++) {
            if(balanceIds[i] == _hash){
                revert Existing("This hash exists: ", _hash);
            }
        }
        _;
    }

    //SECURITY 3: checking if msg.sender has paid function call fee
    error NotPaid(string message, address caller);
    modifier hasPaid() {
        if (feePayers[msg.sender] == false) {
            revert NotPaid("You need to pay service fee", msg.sender);
        }
        _;
    }

}
