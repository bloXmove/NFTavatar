// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract BLXMAvatarAmulets is UUPSUpgradeable, ERC1155Upgradeable, OwnableUpgradeable {

	constructor() payable {}

	function initialize(
		string memory _uri
	) external initializer {

		__ERC1155_init(_uri);
        __Ownable_init();

	}

	function claim(uint256 _tokenID) external payable {
		// _mint(msg.sender, _tokenID, 1, '');
	}

	// only owner

	function _authorizeUpgrade(address) internal override onlyOwner {}

}