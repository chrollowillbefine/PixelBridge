// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BridgePixelToken is ERC20, Ownable, ReentrancyGuard {
    // Address of pixel bridge
    address public pixelBridge;

    /**
     * @dev Initializes the contract by setting a `name`, `symbol` and `pixelBridge`.
     */
    constructor(string memory name, string memory symbol, address _pixelBridge) ERC20(name, symbol) Ownable(msg.sender) {
        pixelBridge = _pixelBridge;
    }

    modifier onlyBridge() {
        require(msg.sender == pixelBridge);
        _;
    }

    function mint(address account, uint256 value) external onlyBridge() nonReentrant {
        // _mint(account, value * 10 ** decimals());
        _mint(account, value);
    }

    function burn(address from, uint256 value) external onlyBridge() nonReentrant() {
        _burn(from, value);
    }
}