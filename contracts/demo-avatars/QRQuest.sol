// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
// import './BloXmoveTestToken.sol';

interface IDemoServiceContract {
	function mintNfticket(address user, string calldata URI) external returns(uint256);
}

error MintingIsPaused();

contract QRQuest is Ownable {

	using Strings for uint256;

	string public baseURI;

	mapping(address => uint256) public ownership;
	mapping(uint256 => address) public token2wallet;
	mapping(uint256 => uint256) public tokenIdMap; // NFTicket ID to local token ID

	mapping(address => mapping(uint256 => bool)) public registry;
	mapping(address => uint256) public registered;

	mapping(address => uint256) public balance;

	IDemoServiceContract public DemoServiceContract;
	// address public erc20_token;

	uint256 constant TOKEN_COUNT = 8;

	event TopUp(address indexed wallet, uint256 amount);
	event Withdraw(address indexed wallet, uint256 amount);

	constructor(
		string memory _initBaseURI,
		IDemoServiceContract demo_contract_addr
	) Ownable() {
		setBaseURI(_initBaseURI);
		DemoServiceContract = demo_contract_addr;
	}

	// public

	function mint() external {

		require(ownership[msg.sender] == 0);

		uint256 rand_local_id = (block.prevrandao % TOKEN_COUNT) + 1; // random token ID in range [1..TOKEN_COUNT]
		string memory uri = string(abi.encodePacked(baseURI, rand_local_id.toString(), '.json'));

        uint256 ticketID = DemoServiceContract.mintNfticket(msg.sender, uri);
		ownership[msg.sender] = ticketID;
		token2wallet[ticketID] = msg.sender;
		tokenIdMap[ticketID] = rand_local_id;

		// BloXmoveTestToken(erc20_token).mint(msg.sender, 100 ether); // mint some test tokens to play with

	}

	function register(uint256 id) external { // register an attendance
		if (!registry[msg.sender][id]) {
			registry[msg.sender][id] = true;
			registered[msg.sender]++;
		}
	}

	function tokenURI(uint256 tokenID) public view virtual returns (string memory) {
		require(tokenIdMap[tokenID] > 0, 'URI query for nonexistent token');
		uint256 local_token_id = tokenIdMap[tokenID];
		uint256 lvl = level(token2wallet[tokenID]);
		string memory level_suffix = '';
		if (lvl > 0) {
			level_suffix = string(abi.encodePacked('-', lvl.toString()));
		}
		return string(abi.encodePacked(baseURI, local_token_id.toString(), level_suffix, '.json'));
	}

	function level(address wallet) public view returns (uint256) {
		uint256 reg_count = registered[wallet];
		if (reg_count < 2) return 0;
		else if (reg_count < 4) return 1;
		else if (reg_count < 6) return 2;
		else return 3;
	}

	/* function topup(uint256 amount) external {
		BloXmoveTestToken(erc20_token).transferFrom(msg.sender, address(this), amount);
		balance[msg.sender] += amount;
		emit TopUp(msg.sender, amount);
	}

	function withdraw(uint256 amount) external {
		transferERC20(msg.sender, amount);
		emit Withdraw(msg.sender, amount);
	}

	function transferERC20(address to, uint256 amount) public {
		require(amount <= balance[msg.sender]);
		balance[msg.sender] -= amount;
		BloXmoveTestToken(erc20_token).transfer(to, amount);
	} */

	// only owner

	/* function setERC20address(address addr) external onlyOwner {
		erc20_token = addr;
	} */

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

}