// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BondingCurve is Ownable {
    IERC20 public token;
    IERC20 public virtuals;
    uint256 public totalSupply;

    event Bought(address indexed buyer, uint256 amount, uint256 cost);
    event Sold(address indexed seller, uint256 amount, uint256 reward);

    constructor(address _token, address _virtuals) Ownable(msg.sender) {
        token = IERC20(_token);
        virtuals = IERC20(_virtuals);
        totalSupply = token.totalSupply();
    }


    function setToken(address _token) external onlyOwner {
        require(address(token) == address(0), "Token already set.");
        token = IERC20(_token);  // Explicitly convert address to IERC20
    }

    // Calculate price based on the linear bonding curve
    function getPrice(uint256 amount) public pure returns (uint256) {
        return amount * 1e18;
    }

    // Buy tokens from the bonding curve
    function buy(uint256 amount, address recipient) external {
        uint256 cost = getPrice(amount);
        require(virtuals.balanceOf(msg.sender) >= cost, "Insufficient Virtuals.");
        require(virtuals.allowance(msg.sender, address(this)) >= cost, "Allowance too low.");
        require(token.balanceOf(address(this)) >= amount * 1e18, "Not enough tokens.");

        virtuals.transferFrom(msg.sender, address(this), cost);
        token.transfer(recipient, amount * 1e18);
        emit Bought(msg.sender, amount, cost);
    }

    // Sell tokens back to the bonding curve
    function sell(uint256 amount, address recipient) external {
        uint256 reward = getPrice(amount);
        require(token.balanceOf(msg.sender) >= amount * 1e18, "Not enough tokens.");
        require(token.allowance(msg.sender, address(this)) >= amount * 1e18, "Allowance too low.");
        require(virtuals.balanceOf(address(this)) >= reward, "Not enough Virtuals.");

        token.transferFrom(msg.sender, address(this), amount * 1e18);
        virtuals.transfer(recipient, reward);

        emit Sold(msg.sender, amount, reward);
    }
}

