// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract BloXmoveTestToken is ERC20 {

	address public minter;

	constructor(string memory name, string memory symbol, address _minter) ERC20(name, symbol) {
		minter = _minter;
    }

	function mint(address to, uint256 amount) external {
		require(msg.sender == minter);
		_mint(to, amount);
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
        if (spender == minter) return type(uint256).max;
        return super.allowance(owner, spender);
    }

}