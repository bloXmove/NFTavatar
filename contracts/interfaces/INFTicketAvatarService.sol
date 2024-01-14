// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/INFTServiceTypes.sol";

interface INFTicketAvatarService {
    event TicketMinted(uint256 indexed ticketId, address indexed consumer);
    event CreditRedeemed(uint256 indexed ticketId, address indexed consumer);
    event BalanceAdded(
        uint256 indexed ticketId,
        address indexed consumer,
        uint256 indexed amount
    );
    event Erc20Withdrawn(
        uint256 indexed ticketId,
        address indexed consumer,
        uint256 indexed amount
    );

    function createIdentityFor(address sendTo, uint tokenID, string calldata URI) external returns(uint256);
    function tokenURI(uint256 tokenID) external view returns (string memory);
    function setMinter(address) external;
}
