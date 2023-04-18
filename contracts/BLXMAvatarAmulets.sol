// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract BLXMAvatarAmulets is UUPSUpgradeable, ERC1155Upgradeable, OwnableUpgradeable {

	IERC721 public avatarsContract;

	constructor() payable {}

	function initialize(
		string memory _uri
	) external initializer {

		__ERC1155_init(_uri);
        __Ownable_init();

	}

	function claim(uint256 _tokenID) external payable {
		// @TODO: implement this
		// _mint(msg.sender, _tokenID, 1, '');
	}

	function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
		if (operator == address(avatarsContract)) {
			return true; // trues avatars contract to transfer amulets without prior approval
		}
		return super.isApprovedForAll(account, operator);
    }

	// only owner

	function _authorizeUpgrade(address) internal override onlyOwner {}

	function setAvatarsContractAddress(IERC721 _addr) external onlyOwner {
		avatarsContract = _addr;
	}

}