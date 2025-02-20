// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockVirtuals.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenCreator is Ownable {
    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol, uint256 price);
    event MockVirtualsSet(address indexed mockVirtualsAddress);
    event VirtualsTokenCreated(address indexed virtualsToken);

    mapping(string => address) public tokens;
    mapping(address => uint256) public tokenPrices;
    address public mockVirtuals;
    bool public mockVirtualsSet;
    bool public virtualsCreated;

    constructor() Ownable(msg.sender) {}

    // Set MockVirtuals (Only Owner Can Set Once)
    function setMockVirtuals(address _mockVirtuals) external onlyOwner {
        require(!mockVirtualsSet, "MockVirtuals already set!");
        mockVirtuals = _mockVirtuals;
        mockVirtualsSet = true;
        MockVirtuals(payable(mockVirtuals)).setTokenCreator(address(this));
        emit MockVirtualsSet(_mockVirtuals);
    }

    // Create Virtuals Token (Only Owner, Once Only)
    function createVirtualsToken() external onlyOwner returns (address) {
        require(!virtualsCreated, "Virtuals token already exists.");

        // Mint the Virtuals token directly to MockVirtuals
        address virtualsToken = address(new CustomToken("Virtuals", "VIRT", 1_000_000_000, mockVirtuals));
        tokens["Virtuals"] = virtualsToken;
        virtualsCreated = true;

        // Register the Virtuals token in MockVirtuals
        MockVirtuals(payable(mockVirtuals)).setVirtualsToken(virtualsToken);
        emit VirtualsTokenCreated(virtualsToken);

        return virtualsToken;
    }


    // Create Agent Tokens (Creator must pay Virtuals for their share)
    function createToken(string memory name, string memory symbol, uint256 creatorAmount) public {
        require(creatorAmount <= 1_000_000_000, "Cannot mint more than 1 billion tokens.");

        // Calculate total Virtuals cost for the creator's share (1 Virtual per token during creation)
        uint256 totalCost = creatorAmount * 1e18;

        //  Pre-Minting Checks: Ensure creator can afford the share
        if (creatorAmount > 0) {
            require(IERC20(tokens["Virtuals"]).balanceOf(msg.sender) >= totalCost, "Insufficient Virtuals for minting.");
            require(IERC20(tokens["Virtuals"]).allowance(msg.sender, address(this)) >= totalCost, "Allowance too low.");
        }

        //  Ensure MockVirtuals can hold the minted tokens
        require(mockVirtuals != address(0), "MockVirtuals not set.");
        
        // Mint all 1B tokens directly to MockVirtuals bank
        address newToken = address(new CustomToken(name, symbol, 1_000_000_000, mockVirtuals));
        tokens[name] = newToken;

        //  Transfer Virtuals from creator to MockVirtuals if requesting a share
        if (creatorAmount > 0) {
            IERC20(tokens["Virtuals"]).transferFrom(msg.sender, mockVirtuals, totalCost);
            IERC20(newToken).transfer(msg.sender, creatorAmount * 10 ** 18);
        }

        // Register token in MockVirtuals and set post-creation price
        uint256 fixedPrice = 2e18;  // 2 Virtuals per Agent token after minting
        MockVirtuals(payable(mockVirtuals)).registerToken(newToken, fixedPrice);

        emit TokenCreated(msg.sender, newToken, name, symbol, fixedPrice);
    }

}

// Custom ERC20 Token Contract
contract CustomToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply, address bank)
        ERC20(name, symbol)
    {
        // Mint all tokens directly to the MockVirtuals bank
        _mint(bank, initialSupply * 10 ** decimals());
    }
}
