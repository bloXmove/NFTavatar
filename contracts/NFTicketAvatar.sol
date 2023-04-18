// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

error MintingIsPaused();

contract NFTicketAvatar is UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IERC1155ReceiverUpgradeable {

	using StringsUpgradeable for uint256;

	string public baseURI;

	uint256 public cost;
	uint256 public maxMintAmount;
	uint256 constant public maxSupply = 1000;

	uint256[maxSupply] private ids;

	bool public paused;

	bool public onlyWhitelisted;
	mapping(address => bool) public whitelisted;
	uint256 public perWhitelistedAddressLimit;

	IERC1155 public amuletsContract;
	mapping(uint256 => uint256) public amulets; // tokenID => amuletID

	constructor() payable {}

	function initialize(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI,
		IERC1155 _amuletsContract
	) external initializer {

		__ERC721_init(_name, _symbol);
        __Ownable_init();

		setBaseURI(_initBaseURI);

		setCost(0.05 ether);
		setMaxMintAmount(1);

		setOnlyWhitelisted(false);
		setPerWhitelistedAddressLimit(3);

		pause(false);

		amuletsContract = _amuletsContract;

    }

	// public

	function mint(address _to, uint256 _mintAmount) external payable {

		if (paused) revert MintingIsPaused();

		require(_mintAmount > 0, 'mint amount is zero');
		require(_mintAmount <= maxMintAmount, 'mint amount exceeds limit');

		uint256 supply = totalSupply();
		require(supply + _mintAmount <= maxSupply, 'max supply is reached');

		if (msg.sender != owner()) {
			if (onlyWhitelisted) {
				require(whitelisted[msg.sender] == true, 'not whitelisted');
				require(balanceOf(msg.sender) + _mintAmount <= perWhitelistedAddressLimit, 'per address limit exceeded');
			}
			require(msg.value >= cost * _mintAmount, 'not enough value sent');
		}

		for (uint256 i; i < _mintAmount; ) {
			_safeMint(_to, pickRandomTokenID());
			unchecked { ++i; }
		}

	}

	function addAmulet(uint256 tokenID, uint256 amuletID) external {
		// require(amuletsContract.balanceOf(msg.sender, amuletID) > 0);
		amuletsContract.safeTransferFrom(msg.sender, address(this), amuletID, 1, '');
		if (amulets[tokenID] > 0) {
			// return existing amulet to the user
			amuletsContract.safeTransferFrom(address(this), msg.sender, amulets[tokenID], 1, '');
		}
		amulets[tokenID] = amuletID;
	}

	function withdrawAmulet(uint256 tokenID) external {
		uint256 amuletID = amulets[tokenID];
		require(amuletID > 0);
		delete amulets[tokenID];
		amuletsContract.safeTransferFrom(address(this), msg.sender, amuletID, 1, '');
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
		string memory amulet = '';
		if (amulets[tokenID] > 0) {
			amulet = string(abi.encodePacked('+', amulets[tokenID].toString()));
		}
		return string(abi.encodePacked(baseURI, tokenID.toString(), amulet, '.json'));
	}

	// private

	function pickRandomTokenID() private returns (uint256 id) {
		uint256 len = maxSupply - totalSupply();
		require(len > 0, 'no ids left');
		uint256 randomIndex = block.prevrandao % len;
		id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
		ids[randomIndex] = uint256(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
    	ids[len - 1] = 0;
		id += 1;
	}

	// only owner

	function _authorizeUpgrade(address) internal override onlyOwner {}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintAmount = _newMaxMintAmount;
	}

	function setPerWhitelistedAddressLimit(uint256 _newPerWhitelistedAddressLimit) public onlyOwner {
		perWhitelistedAddressLimit = _newPerWhitelistedAddressLimit;
	}

	function pause(bool _newState) public onlyOwner {
		paused = _newState;
	}

	function setOnlyWhitelisted(bool _newState) public onlyOwner {
		onlyWhitelisted = _newState;
	}

	function whitelistUser(address _user) external onlyOwner {
		whitelisted[_user] = true;
	}

	function whitelistUsers(address[] calldata _users) external onlyOwner {
		for (uint256 i; i < _users.length; ) {
			whitelisted[_users[i]] = true;
			unchecked { ++i; }
		}
	}

	function removeWhitelistUser(address _user) external onlyOwner {
		whitelisted[_user] = false;
	}

	function withdraw() external payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}('');
		require(success);
	}

	// to receive ERC1155 amulets:

	function onERC1155Received(
        address operator,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external view override returns (bytes4) {
		require(operator == address(this));
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
		// return this.onERC1155BatchReceived.selector;
	}

}