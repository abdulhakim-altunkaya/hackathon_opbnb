//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/*Foggy contract is an erc20 token contract. We will use foggy token to reward stakers
and to charge transaction service receivers. People who want to use FoggyBank for anonymous 
transaction will need to pay fees in Foggy token. */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Foggy is Ownable, ERC20Capped {
    event TokenMinted(address minter, uint amount);
    event TokenBurned(address burner, uint amount);

    constructor(uint _cap) ERC20("Foggy", "FOGGY") ERC20Capped(_cap*(10**18)) {
    }

    error StatusError(string message);
    bool public contractStatus = true;
    modifier isEnabled() {
        if(contractStatus == false) {
            revert StatusError("Contract is disabled, contact owner to enable it again");
        }
        _;
    }
    function toggleContractStatus() external onlyOwner {
        contractStatus = !contractStatus;
    }

    //minting function for owner, decimals handled inside the function, 10000 is arbitrary
    function mintOwner(uint _amount) external onlyOwner isEnabled {
        require(_amount > 0 && _amount < 1000000, "mint between 0 and 10000");
        _mint(msg.sender, _amount*(10**18));
        emit TokenMinted(msg.sender, _amount);
    }

    //free minting will be allowed to public for testing the platform, decimals handled, 50 is arbitrary
    function mintGenerals(uint _amount) external isEnabled {
        require(_amount > 0 && _amount < 50, "mint between 0 and 50");
        _mint(msg.sender, _amount*(10**18));
        emit TokenMinted(msg.sender, _amount);
    }

    //burning token function, no need set a higher limit
    function burnToken(uint _amount) external isEnabled {
        require(_amount > 0, "burn amount must be greater than 0");
        _burn(msg.sender, _amount*(10**18));
        emit TokenBurned(msg.sender, _amount);
    }

    //approve FoggyBank contract before sending tokens to it for liquidity
    function approveFoggyBank(address _contractFoggyBank, uint _amount) external isEnabled {
        require(_amount > 0, "approve amount must be greater than 0");
        uint amount = _amount*(10**18);
        _approve(msg.sender, _contractFoggyBank, amount);
    }

    function returnOwner() external view returns(address) {
        return owner();
    }

    function getContractAddress() external view returns(address) {
        return address(this);
    }

    function getYourBalance() external view returns(uint) {
        return balanceOf(msg.sender) / (10**18);
    }

    function getContractBalance() external view returns(uint) {
        return balanceOf(address(this)) / (10**18);
    }

    function getTotalSupply() external view returns(uint) {
        return totalSupply() / (10**18);
    }
}