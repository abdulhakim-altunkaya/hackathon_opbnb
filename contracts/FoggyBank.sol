//SPDX-License-Identifier: MIT

pragma solidity  >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoggyBank is Ownable {

    //Will be called when people deposit TokenA for anonymous tx
    event Deposit(address indexed depositor, uint amount);
    event Withdraw(address indexed receiver, uint amount);

    //************SETTING POOL TOKEN: TokenA************
    IERC20 public tokenAContract;
    function setTokenA(address _tokenAddress) external {
        tokenAContract = IERC20(_tokenAddress);
    }
    //************SETTING FOGGY TOKEN************
    IERC20 public tokenFoggyContract;
    function setTokenFoggy(address _tokenAddress) external {
        tokenFoggyContract = IERC20(_tokenAddress);
    }

    //************STATE VARIABLES*************
    //each deposit will have a hash and an amount information
    mapping(bytes32 => uint) private balances;
    //these hashes will be saved in an array
    bytes32[] private balanceIds;
    //there will be a fee for calling deposit and withdraw functions to deter scammers
    mapping(address => bool) public feePayers;


    //----------------SECURITY 1: pause contract
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

    //--------------SECURITY 2: checking if new hash already exists
    error Existing(string message, bytes32 hashdata);
    modifier isExisting(bytes32 _hash) {
        for (uint256 i = 0; i < balanceIds.length; i++) {
            if(balanceIds[i] == _hash){
                revert Existing("This hash exists: ", _hash);
            }
        }
        _;
    }

    //---------------SECURITY 3: checking if msg.sender has paid function call fee
    error NotPaid(string message, address caller);
    modifier hasPaid() {
        if (feePayers[msg.sender] == false) {
            revert NotPaid("You need to pay service fee", msg.sender);
        }
        _;
    }

    //**************SETTING FEE********************** 
    //1 is an arbitrary value, ether is for handling decimals. Fee is in Foggy
    //3.PAYMENT OPERATIONS
    uint public fee = 1;
    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }
    function makePayment() external returns(bool) {
        require(balanceOf(msg.sender) >= fee, "you don't have CONTOR");
        require(msg.sender == tx.origin, "contracts cannot withdraw");
        require(msg.sender != address(0), "real addresses can withdraw");
        _transfer(msg.sender, address(this), fee*(10**18));
    }

    //SERVICE FEE
    uint public fee = 1;
    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }
    //owner can collect FOGGY tokens inside the contract
    function collectFees() external onlyOwner {
        uint balanceFoggy = tokenFoggyContract.balanceOf(address(this));
        if (balanceFoggy > 0) {
           tokenFoggyContract._transfer(address(this), msg.sender, balanceFoggy);
        }
    }
    //People must pay service fee for each withdrawal and deposit operation
    function payFee() public {
        require(tokenFoggyContract.balanceOf(msg.sender) >= fee*(10**18), "you don't have FOGGY");
        require(msg.sender == tx.origin, "contracts cannot withdraw");
        require(msg.sender != address(0), "real addresses can withdraw");
        tokenFoggyContract._transfer(msg.sender, address(this), fee*(10**18));
        feePayers[msg.sender] == true;
    }

    // ------------------------------------------------------------------------
    //                          DEPOSIT AND WITHDRAWAL FUNCTIONS
    // ------------------------------------------------------------------------

    //Function to deposit tokens into the contract, decimals handled inside the function
    function deposit(bytes32 _hash, uint _amount) external hasPaid isExisting(_hash) isPaused {
        //input validations
        require(_hash.length == 32, "invalid hash");
        require(_amount >= 1, "_amount must be bigger than 1");
        //general checks
        require(msg.sender == tx.origin, "contracts cannot withdraw");
        require(msg.sender != address(0), "real addresses can withdraw");
        require(tokenAContract.balanceOf(msg.sender) >= 0, "you don't have TokenA");
        //operations
        tokenAContract._transfer(msg.sender, address(this), _amount*(10**18));
        feePayers[msg.sender] = false;
        balanceIds.push(_hash);
        uint amount = _amount*(10**18);
        balances[_hash] = amount;
    }
}
