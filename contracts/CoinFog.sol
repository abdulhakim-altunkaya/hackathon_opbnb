//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFog is Ownable {

    //Events are created but NOT emitted to leave less footprints on the blockchain
    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed receiver, uint amount);

    //SETTING TOKEN CONTRACT
    IERC20 public tokenContract;
    function setToken(address tokenAddress) external {
        tokenContract = IERC20(tokenAddress);
    }

    //STATE VARIABLES
    //Each deposit will have a hash and an amount information
    mapping(bytes32 => uint) private balances;
    //Later each new hash will be saved in hash array
    bytes32[] private balanceIds;
    //there will be a fee for depositing and withdrawal to deter scammers
    mapping(address => bool) public feePayers;

    //Security logic: Contract pause
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

    //Security logic: Checking if input hash already exists
    error Existing(string message, bytes32 hashdata);
    modifier isExisting(bytes32 _hash) {
        for(uint i=0; i<balanceIds.length; i++) {
            if(balanceIds[i] == _hash) {
                revert Existing("this hash exists", _hash);
            }
        }
        _;    
    }

    //Security logic: checking if msg.sender has paid function call fee
    error NotPaid(string message, address caller);
    modifier hasPaid() {
        if(feePayers[msg.sender] == false) {
            revert NotPaid("you need to pay withdrawal service fee", msg.sender);
        }
        _;
    }


    //fee setting, payment and collection logic 
    uint public fee = 5 ether;
    function setFee(uint _fee) external onlyOwner {
        fee = _fee * (10**18);
    }
    function collectFees() external onlyOwner {
        uint contractFees = address(this).balance;
        require(contractFees > 1, "No significant fees collected yet");
        (bool success, ) = payable(owner()).call{value: contractFees}("");
        require(success == true, "fee collection failed");
    }
    function payFee() public payable {
        //transaction fee will deter scam calls
        require(msg.value >= fee, "You need to pay withdrawal fee");
        feePayers[msg.sender] = true;
    }

    // ------------------------------------------------------------------------
    //                          DEPOSIT AND WITHDRAWAL FUNCTIONS
    // ------------------------------------------------------------------------

    //Function to deposit tokens into the contract
    //People must also pay for depositing into the contract which is 4 ftm
    //People must also approve contract before sending tokens to this contract
    function deposit(bytes32 _hash, uint _amount) external hasPaid isExisting(_hash) isPaused {

        //input validations
        require(_hash.length == 32, "invalid hash");
        require(_amount >= 1, "_amount must be bigger than 1");

        feePayers[msg.sender] = false;
        balanceIds.push(_hash);
        uint amount = _amount*(10**18);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        balances[_hash] = amount;

    }


    function withdrawPart(string calldata _privateWord, bytes32 _newHash, address receiver, uint _amount) 
        external hasPaid isExisting(_newHash) isPaused
    {
        //input validations
        require(bytes(_privateWord).length > 0, "private word is not enough long");
        require(_newHash.length == 32, "invalid new hash");
        require(receiver != address(0), "invalid receiver address");
        require(bytes20(receiver) == bytes20(address(receiver)), "invalid receiver address");
        require(_amount > 0, "_amount must be bigger than 0");

        //withdrawing the desired amount
        uint amount = _amount * (10**18);
        (uint balanceFinal, bytes32 balanceHash) = getHashAmount(_privateWord);
        require(balanceFinal > amount, "If you want to withdraw all choose withdrawAll function");
        balances[balanceHash] = 0;
        tokenContract.transfer(receiver, amount);
        
        // Resetting function call fee. Each fee is only for 1 function call
        feePayers[msg.sender] = false;
        //redepositing the amount left
        uint amountLeft = balanceFinal - amount;
        require(amountLeft >= 1, "amountLeft must be bigger than 1");
        balanceIds.push(_newHash);
        balances[_newHash] = amountLeft;
    }

    function withdrawAll(string calldata _privateWord, address receiver) 
        external hasPaid isPaused
    {
        //input validations
        require(bytes(_privateWord).length > 0, "private word is not enough long");
        require(receiver != address(0), "invalid receiver address");
        require(bytes20(receiver) == bytes20(address(receiver)), "invalid receiver address");

        // Resetting function call fee. Each fee is only for 1 function call
        feePayers[msg.sender] = false;
        // Get the balance and hash associated with the private word
        (uint balanceFinal, bytes32 balanceHash) = getHashAmount(_privateWord);
        // Ensure the withdrawal amount is greater than 0
        require(balanceFinal > 0, "Withdraw amount must be bigger than 0");
        // Set the balance associated with the hash to 0
        balances[balanceHash] = 0;
        // Transfer the tokens to the receiver's address
        tokenContract.transfer(receiver, balanceFinal);
    }



    // HASH CREATION AND COMPARISON FUNCTIONs
    // Function to create a hash. Users will be advised to use other websites to create their keccak256 hashes.
    // But if they dont, they can use this function.
    function createHash(string calldata _word) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_word));
    }
    
    function getHashAmount(string calldata inputValue) private view returns(uint, bytes32) {
        bytes32 idHash = keccak256(abi.encodePacked(inputValue));
        for(uint i=0; i<balanceIds.length; i++) {
            if(balanceIds[i] == idHash) {
                return (balances[idHash], idHash);
            }
        }
        return (0, idHash);
    }

    function checkHashExist(bytes32 _hash) external view returns(bool) {
        if(balanceIds.length < 1) {
            return false;
        }
        for(uint i = 0; i<balanceIds.length; i++) {
            if(balanceIds[i] == _hash) {
                return true;
            }
        }
        return false;

    }

    function getContractEtherBalance() external view returns(uint) {
        return address(this).balance / (10**18);
    }

    function getContractTokenBalance() external view returns(uint) {
        return tokenContract.balanceOf(address(this)) / (10**18);
    }

}



