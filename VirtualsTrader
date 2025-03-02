// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IVirtuals {
    function buy(uint256 amountIn, address tokenAddress) external returns (bool);
    function sell(uint256 amountIn, address tokenAddress) external returns (bool);
}

contract VirtualsTrader {
    address public constant VIRTUALS_CONTRACT = 0xF66DeA7b3e897cD44A5a231c61B6B4423d613259; // Virtuals Protocol contract
    address public constant VIRTUALS_TOKEN = 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b; // Virtuals ERC20 token
    
    IVirtuals public virtualsContract;

    constructor() {
        virtualsContract = IVirtuals(VIRTUALS_CONTRACT);
    }

    /**
     * Approve Virtuals contract to spend Virtuals tokens and Buy Prototype Agent tokens.
     */
    function approveAndBuy(address agentToken, uint256 amount) external {
        IERC20 virtualsToken = IERC20(VIRTUALS_TOKEN);

        // Step 1: Approve Virtuals contract to spend `amount` Virtuals tokens
        require(virtualsToken.approve(VIRTUALS_CONTRACT, amount), "Approval failed");

        // Step 2: Execute buy on Virtuals contract (paying with Virtuals tokens)
        require(virtualsContract.buy(amount, agentToken), "Buy failed");

        // Step 3: Revoke approval after trade (security measure)
        require(virtualsToken.approve(VIRTUALS_CONTRACT, 0), "Revoke approval failed");
    }

    /**
     * Approve Virtuals contract to spend Agent tokens and Sell them for Virtuals tokens.
     */
    function approveAndSell(address agentToken, uint256 amount) external {
        IERC20 agentTokenContract = IERC20(agentToken); // Load Agent (Prototype) ERC20 Token

        // Step 1: Approve Virtuals contract to spend `amount` Agent tokens
        require(agentTokenContract.approve(VIRTUALS_CONTRACT, amount), "Approval failed");

        // Step 2: Execute sell on Virtuals contract (getting Virtuals tokens back)
        require(virtualsContract.sell(amount, agentToken), "Sell failed");

        // Step 3: Revoke approval after trade (security measure)
        require(agentTokenContract.approve(VIRTUALS_CONTRACT, 0), "Revoke approval failed");
    }
}
