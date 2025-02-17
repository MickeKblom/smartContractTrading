// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockVirtuals {
    event Buy(address indexed buyer, uint256 amount, address token);
    event Sell(address indexed seller, uint256 amount, address token);
    event Approve(address indexed approver, address token);
    event TokenRegistered(address indexed token, uint256 price);
    event VirtualsTokenSet(address indexed virtualsToken);

    mapping(address => bool) public approvedTokens;
    mapping(address => uint256) public tokenPrices;
    address public virtualsToken;
    address public tokenCreator;
    bool public virtualsTokenSet; // Track if Virtuals Token is set

    constructor(address _tokenCreator) {
        tokenCreator = _tokenCreator;
    }

    // Set Virtuals Token AFTER deployment
    function setVirtualsToken(address _virtualsToken) external {
        require(msg.sender == tokenCreator, "Only TokenCreator can set Virtuals token");
        require(!virtualsTokenSet, "Virtuals token already set");
        virtualsToken = _virtualsToken;
        virtualsTokenSet = true;
        emit VirtualsTokenSet(_virtualsToken);
    }

    function registerToken(address token, uint256 price) external {
        require(msg.sender == tokenCreator, "Only TokenCreator can register tokens");
        tokenPrices[token] = price;
        approvedTokens[token] = true;
        emit TokenRegistered(token, price);
    }

    function buy(address token, uint256 amount) external {
        require(approvedTokens[token], "Token not approved yet.");
        require(IERC20(virtualsToken).balanceOf(msg.sender) >= amount, "Not enough Virtuals tokens");

        uint256 agentTokens = (amount * 10) / tokenPrices[token];
        IERC20(virtualsToken).transferFrom(msg.sender, address(this), amount);
        emit Buy(msg.sender, agentTokens, token);
    }

    function sell(address token, uint256 amount) external {
        require(approvedTokens[token], "Token not approved yet.");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Not enough Agent tokens");

        uint256 virtualsTokens = (amount * tokenPrices[token]) / 10;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Sell(msg.sender, virtualsTokens, token);
    }
}
