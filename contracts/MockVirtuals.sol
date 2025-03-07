// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CustomToken.sol"; 
import "./BondingCurve.sol";

contract MockVirtuals is Ownable {
    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol);
    event VirtualsBought(address indexed buyer, uint256 amount);
    event VirtualsSold(address indexed seller, uint256 amount);
    event BondingCurveDeployed(address indexed bondingCurve, address token);

    mapping(address => address) public bondingCurves;

    address public virtualsToken;
    bool public virtualsTokenSet;

    constructor() Ownable(msg.sender) {}

    // Create Virtuals Token (Only Owner, Once Only)
    function createVirtualsToken() external onlyOwner {
        require(!virtualsTokenSet, "Virtuals token already exists.");
        virtualsToken = address(new CustomToken("Virtuals", "VIRT", 1_000_000_000, address(this)));
        virtualsTokenSet = true;
    }

    // Event for debugging
    event Debug(string message, uint256 value);
 
    function createToken(string memory name, string memory symbol, uint256 creatorAmount) external {
        require(virtualsTokenSet, "Virtuals token not set.");
        require(creatorAmount <= 1_000_000_000, "Cannot mint more than 1 billion tokens.");

        // Deploy the token FIRST
        address newToken = address(new CustomToken(name, symbol, 1_000_000_000, address(this)));
        emit TokenCreated(msg.sender, newToken, name, symbol);

        // Now deploy the BondingCurve with the correct token address
        address bondingCurve = address(new BondingCurve(newToken, virtualsToken));
        emit BondingCurveDeployed(bondingCurve, newToken);

        // Transfer all minted tokens to the BondingCurve contract
        IERC20(newToken).transfer(bondingCurve, 1_000_000_000 * 10 ** 18);

        // Register the bonding curve
        bondingCurves[newToken] = bondingCurve;

        // If the creator wants an initial share, calculate the price and transfer tokens
        if (creatorAmount > 0) {
            // Token Creation: Show Cost
            uint256 totalCost = BondingCurve(bondingCurve).getPrice(creatorAmount);
            emit Debug("Total Cost for Creator", totalCost);
            emit Debug("Creator Balance", IERC20(virtualsToken).balanceOf(msg.sender));
            emit Debug("Creator Allowance", IERC20(virtualsToken).allowance(msg.sender, address(this)));
            require(IERC20(virtualsToken).balanceOf(msg.sender) >= totalCost, "Insufficient Virtuals.");
            require(IERC20(virtualsToken).allowance(msg.sender, address(this)) >= totalCost, "Allowance too low.");

            // Transfer Virtuals from creator to BondingCurve
            IERC20(virtualsToken).transferFrom(msg.sender, bondingCurve, totalCost);

            IERC20(virtualsToken).approve(bondingCurve, type(uint256).max);

            // Transfer tokens from the BondingCurve to the creator
            BondingCurve(bondingCurve).buy(creatorAmount, msg.sender);
        }

        emit TokenCreated(msg.sender, newToken, name, symbol);
    }


    // Buy Virtuals with ETH
    function buyVirtuals() external payable {
        require(virtualsTokenSet, "Virtuals token not set.");
        require(msg.value > 0, "Send ETH to buy Virtuals.");

        uint256 virtualsToBuy = msg.value * 10_000_000;
        require(IERC20(virtualsToken).balanceOf(address(this)) >= virtualsToBuy, "Not enough Virtuals.");

        IERC20(virtualsToken).transfer(msg.sender, virtualsToBuy);
        emit VirtualsBought(msg.sender, virtualsToBuy);
    }

    // Sell Virtuals for ETH
    function sellVirtuals(uint256 amount) external {
        require(virtualsTokenSet, "Virtuals token not set.");
        uint256 amountInWei = amount * 1e18;

        uint256 ethToReceive = amountInWei / 10_000_000;
        require(address(this).balance >= ethToReceive, "Not enough ETH.");

        IERC20(virtualsToken).transferFrom(msg.sender, address(this), amountInWei);
        payable(msg.sender).transfer(ethToReceive);

        emit VirtualsSold(msg.sender, amount);
    }
// New functions for proxy interaction

    function buy(uint256 amount, address token) external returns (bool) {
        address bondingCurve = bondingCurves[token];
        require(bondingCurve != address(0), "Bonding curve not found");

        // Buy tokens for msg.sender
        BondingCurve(bondingCurve).buy(amount, msg.sender);
        return true;
    }

    function sell(uint256 amount, address token) external returns (bool) {
        address bondingCurve = bondingCurves[token];
        require(bondingCurve != address(0), "Bonding curve not found");

        // Sell tokens and receive Virtuals
        BondingCurve(bondingCurve).sell(amount, msg.sender);
        return true;
    }

    // Fallback to accept ETH
    receive() external payable {}
}
