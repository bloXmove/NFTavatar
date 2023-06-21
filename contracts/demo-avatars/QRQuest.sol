// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

interface IDemoServiceContract {
	function mintNfticket(string calldata URI, address user) external returns(uint256);
}

contract QRQuest is Ownable {

	using Strings for uint256;

	string public baseURI;

	uint256 constant TOKEN_COUNT = 8;
    uint256 constant LEADERBOARD_SIZE = 10;

	mapping(address => uint256) public ownership;
	mapping(uint256 => address) public token2wallet;
	mapping(uint256 => uint256) public tokenIdMap; // NFTicket ID to local token ID

	mapping(address => mapping(uint256 => bool)) public isRegistered;
	mapping(address => uint256[]) public regs;

    struct LeaderboardEntry {
        address wallet;
        uint256 score;
    }

    mapping(uint256 => LeaderboardEntry) leaderboard;

	IDemoServiceContract public DemoServiceContract;

	constructor(
		string memory _initBaseURI,
		IDemoServiceContract demo_contract_addr
	) Ownable() {
		setBaseURI(_initBaseURI);
		setDemoServiceContractAddr(demo_contract_addr);
	}


	// public

	function mint() external {

		require(ownership[msg.sender] == 0, 'already minted');

		uint256 rand_local_id = (block.prevrandao % TOKEN_COUNT) + 1; // random token ID in range [1..TOKEN_COUNT]
		string memory uri = string(abi.encodePacked(baseURI, rand_local_id.toString(), '.json'));

		uint256 ticketID = DemoServiceContract.mintNfticket(uri, msg.sender);
		ownership[msg.sender] = ticketID;
		token2wallet[ticketID] = msg.sender;
		tokenIdMap[ticketID] = rand_local_id;

	}

	function register(uint256 id) external { // register an attendance
		require(id > 0);
		require(!isRegistered[msg.sender][id], 'already registered');
		isRegistered[msg.sender][id] = true;
		regs[msg.sender].push(id);
        addToLeaderboard(msg.sender);
	}

	function getAllRegs(address wallet) external view returns (uint256[] memory) {
		return regs[wallet];
	}

    function getLeaderboard() external view returns (LeaderboardEntry[LEADERBOARD_SIZE] memory ret) {
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            ret[i] = leaderboard[i];
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
		uint256 reg_count = regs[wallet].length;
		if (reg_count < 3) return 1;
		else if (reg_count < 6) return 2;
		else return 3;
	}


    // private

    function addToLeaderboard(address wallet) private {

        uint256 score = regs[wallet].length;

        if (leaderboard[LEADERBOARD_SIZE - 1].score >= score) return;

        // first pass: remove the wallet from the leaderboard to eliminate dups
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            if (leaderboard[i].wallet == wallet) {

                // shift leaderboard up
                for (uint256 j = i; j < LEADERBOARD_SIZE; j++) {
                    leaderboard[j] = leaderboard[j+1];
                }

                break;

            }
        }

        // second pass: add the wallet to the leaderboard
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            if (leaderboard[i].score < score) {

                // shift leaderboard down
                LeaderboardEntry memory curr = leaderboard[i];
                for (uint256 j = i; j < LEADERBOARD_SIZE; j++) {
                    LeaderboardEntry memory next = leaderboard[j+1];
                    leaderboard[j+1] = curr;
                    curr = next;
                }

                leaderboard[i] = LeaderboardEntry(wallet, score);
                delete leaderboard[LEADERBOARD_SIZE];

                break;

            }
        }

    }


	// only owner

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setDemoServiceContractAddr(IDemoServiceContract addr) public onlyOwner {
		DemoServiceContract = addr;
	}

}