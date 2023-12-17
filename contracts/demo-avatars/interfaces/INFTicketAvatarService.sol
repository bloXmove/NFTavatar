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

    function createIdentityFor(string calldata URI, address sendTo) external returns(uint256);
}
