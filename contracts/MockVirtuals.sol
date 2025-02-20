// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom ERC20 Token Contract
contract CustomToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply, address bank)
        ERC20(name, symbol)
    {
        _mint(bank, initialSupply * 10 ** decimals());
    }
}

// MockVirtuals handles everything: creation, trading, and ETH conversions
contract MockVirtuals is Ownable {
    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol, uint256 price);
    event Buy(address indexed buyer, uint256 amount, address token);
    event Sell(address indexed seller, uint256 amount, address token);
    event VirtualsBought(address indexed buyer, uint256 amount);
    event VirtualsSold(address indexed seller, uint256 amount);

    mapping(address => uint256) public tokenPrices;
    mapping(address => bool) public approvedTokens;
    address public virtualsToken;
    bool public virtualsTokenSet;

    constructor() Ownable(msg.sender) {}

    // Create the Virtuals Token (Only Owner, Once Only)
    function createVirtualsToken() external onlyOwner {
        require(!virtualsTokenSet, "Virtuals token already exists.");
        virtualsToken = address(new CustomToken("Virtuals", "VIRT", 1_000_000_000, address(this)));
        virtualsTokenSet = true;
    }

    // Create Agent Tokens (Creator pays Virtuals for their share)
    function createToken(string memory name, string memory symbol, uint256 creatorAmount) public {
        require(virtualsTokenSet, "Virtuals token not set.");
        require(creatorAmount <= 1_000_000_000, "Cannot mint more than 1 billion tokens.");

        uint256 totalCost = creatorAmount * 1e18; // 1 Virtual per token during creation

        // Ensure the creator has enough Virtuals and allowance
        if (creatorAmount > 0) {
            require(IERC20(virtualsToken).balanceOf(msg.sender) >= totalCost, "Insufficient Virtuals for minting.");
            require(IERC20(virtualsToken).allowance(msg.sender, address(this)) >= totalCost, "Allowance too low.");
        }

        // Mint all tokens to MockVirtuals bank
        address newToken = address(new CustomToken(name, symbol, 1_000_000_000, address(this)));
        approvedTokens[newToken] = true;

        // Transfer Virtuals from creator and mint their share
        if (creatorAmount > 0) {
            IERC20(virtualsToken).transferFrom(msg.sender, address(this), totalCost);
            IERC20(newToken).transfer(msg.sender, creatorAmount * 10 ** 18);
        }

        // Register token and set price to 2 Virtuals per token after creation
        tokenPrices[newToken] = 2e18;
        emit TokenCreated(msg.sender, newToken, name, symbol, 2e18);
    }

    // Buy Agent Tokens with Virtuals
    function buy(address token, uint256 amountInWholeTokens) external {
        require(approvedTokens[token], "Token not approved.");
        uint256 amount = amountInWholeTokens * 10 ** 18;

        uint256 totalCost = (amount * tokenPrices[token]) / 10;
        require(IERC20(virtualsToken).balanceOf(msg.sender) >= totalCost, "Not enough Virtuals.");
        require(IERC20(virtualsToken).allowance(msg.sender, address(this)) >= totalCost, "Allowance too low.");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough tokens in contract.");

        IERC20(virtualsToken).transferFrom(msg.sender, address(this), totalCost);
        IERC20(token).transfer(msg.sender, amount);

        emit Buy(msg.sender, amountInWholeTokens, token);
    }

    // Sell Agent Tokens for Virtuals
    function sell(address token, uint256 amountInWholeTokens) external {
        require(approvedTokens[token], "Token not approved.");
        uint256 amount = amountInWholeTokens * 10 ** 18;

        uint256 virtualsToReceive = (amount * tokenPrices[token]) / 10;
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Not enough Agent tokens.");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Allowance too low.");
        require(IERC20(virtualsToken).balanceOf(address(this)) >= virtualsToReceive, "Not enough Virtuals in contract.");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(virtualsToken).transfer(msg.sender, virtualsToReceive);

        emit Sell(msg.sender, virtualsToReceive, token);
    }

    // Buy Virtuals with ETH
    function buyVirtuals() external payable {
        require(virtualsTokenSet, "Virtuals token not set.");
        require(msg.value > 0, "Send ETH to buy Virtuals.");

        uint256 virtualsToBuy = msg.value * 10_000_000;
        require(IERC20(virtualsToken).balanceOf(address(this)) >= virtualsToBuy, "Not enough Virtuals in contract.");

        IERC20(virtualsToken).transfer(msg.sender, virtualsToBuy);
        emit VirtualsBought(msg.sender, virtualsToBuy);
    }

    // Sell Virtuals for ETH
    function sellVirtuals(uint256 amountInWholeTokens) external {
        require(virtualsTokenSet, "Virtuals token not set.");
        uint256 amount = amountInWholeTokens * 10 ** 18;

        uint256 ethToReceive = amount / 10_000_000;
        require(address(this).balance >= ethToReceive, "Not enough ETH in contract.");

        IERC20(virtualsToken).transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(ethToReceive);

        emit VirtualsSold(msg.sender, amount);
    }

    // Fallback to accept ETH
    receive() external payable {}
}
