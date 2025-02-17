// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMockVirtuals {
    function buy(address token, uint256 amount) external;
    function sell(address token, uint256 amount) external;
}

contract AutoTrader {
    address public owner;
    IMockVirtuals public virtualsContract;

    constructor(address _virtualsContract) {
        owner = msg.sender;
        virtualsContract = IMockVirtuals(_virtualsContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function approveAndTrade(
        address token, 
        uint256 amount, 
        bool isBuy
    ) external onlyOwner {
        IERC20 tokenContract = IERC20(token);

        // Approve the Virtuals contract to spend this token
        tokenContract.approve(address(virtualsContract), type(uint256).max);

        // Execute Buy or Sell
        if (isBuy) {
            virtualsContract.buy(token, amount);
        } else {
            virtualsContract.sell(token, amount);
        }
    }
}
