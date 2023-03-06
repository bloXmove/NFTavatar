// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

error MintingIsPaused();

contract NFTicketAvatar is UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {

	using StringsUpgradeable for uint256;

	string public baseURI;
	string public baseExtension;

	uint256 public cost;
	uint256 public maxMintAmount;
	uint256 constant maxSupply = 1000;

	uint256[maxSupply] private ids;

	bool public paused;

	mapping(address => bool) public whitelisted;

	constructor() payable {}

	function initialize(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI
	) external initializer {

		__ERC721_init(_name, _symbol);
        __Ownable_init();

		setCost(0.05 ether);
		setMaxMintAmount(1);

		setBaseURI(_initBaseURI);
		setBaseExtension('.json');

		pause(false);

    }

	// public

	function mint(address _to, uint256 _mintAmount) external payable {

		if (paused) revert MintingIsPaused();

		require(_mintAmount <= maxMintAmount);

		uint256 supply = totalSupply();
		require(supply + _mintAmount <= maxSupply);

		if (msg.sender != owner()) {
			if (!whitelisted[msg.sender]) {
				require(msg.value >= cost * _mintAmount);
			}
		}

		for (uint256 i; i < _mintAmount; ) {
			_safeMint(_to, pickRandomTokenID());
			unchecked { ++i; }
		}

	}

	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIDs = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIDs;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
		require(_exists(tokenID), 'URI query for nonexistent token');
		return string(abi.encodePacked(baseURI, tokenID.toString(), baseExtension));
	}

	// private

	function pickRandomTokenID() private returns (uint256 id) {
		uint256 len = maxSupply - totalSupply();
		require(len > 0, 'no ids left');
		uint256 randomIndex = block.prevrandao % len;
		id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
		ids[randomIndex] = uint256(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
    	ids[len - 1] = 0;
	}

	// only owner

	function _authorizeUpgrade(address) internal override onlyOwner {}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintAmount = _newMaxMintAmount;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function whitelistUser(address _user) external onlyOwner {
		whitelisted[_user] = true;
	}

	function removeWhitelistUser(address _user) external onlyOwner {
		whitelisted[_user] = false;
	}

	function withdraw() external payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}('');
		require(success);
	}

}