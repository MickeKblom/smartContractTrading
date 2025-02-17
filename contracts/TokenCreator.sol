// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockVirtuals.sol";

contract TokenCreator {
    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol, uint256 price);
    event MockVirtualsSet(address indexed mockVirtualsAddress);

    mapping(string => address) public tokens;
    mapping(address => uint256) public tokenPrices;
    address public mockVirtuals; // Store MockVirtuals contract address
    bool public mockVirtualsSet;

    constructor() {}

    function setMockVirtuals(address _mockVirtuals) external {
        require(!mockVirtualsSet, "MockVirtuals already set!");
        mockVirtuals = _mockVirtuals;
        mockVirtualsSet = true;
        emit MockVirtualsSet(_mockVirtuals);
    }

    function createToken(string memory name, string memory symbol, uint256 initialSupply) public {
        address newToken = address(new CustomToken(name, symbol, initialSupply, msg.sender));
        tokens[name] = newToken;

        uint256 price = ((uint256(uint160(newToken)) % 100) + 1) * 10 / 1000;
        tokenPrices[newToken] = price * 1e18; // Scale to avoid integer rounding

        if (mockVirtualsSet) {
            MockVirtuals(mockVirtuals).registerToken(newToken, tokenPrices[newToken]);
        }

        emit TokenCreated(msg.sender, newToken, name, symbol, tokenPrices[newToken]);
    }
}

contract CustomToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply, address creator) 
        ERC20(name, symbol) {
        _mint(creator, initialSupply * 10 ** decimals());
    }
}
