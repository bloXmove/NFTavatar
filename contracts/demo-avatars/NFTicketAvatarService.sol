// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libs/SafeMath.sol";
import "../interfaces/INFTicket.sol";
import "../interfaces/INFTServiceTypes.sol";
import "./interfaces/INFTicketAvatarService.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Service contract for the NFTicket avatar
 * @author Harry Behrens | bloXmove
 */
contract NFTicketAvatarService is INFTicketAvatarService, AccessControl {
    using SafeMath for uint256;

    // NFTicket contract
    INFTicket NFTicketContract;
    address minter;

    // ERC20 token to be distributed to consumers
    IERC20 ERC20Contract;

    // Number of credits on newly minted ticket
    uint256 public numCredits;


    //===================================Initializer===================================//
    constructor(
        address _NFTicketAddress,
        address _ERC20Address,
        address _minter,
        uint256 _numCredits
    ) {
        NFTicketContract = INFTicket(_NFTicketAddress);
        minter = _minter;
        ERC20Contract = IERC20(_ERC20Address);
        numCredits = _numCredits;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //===================================Modifiers===================================//
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only admin can do this"
        );
        _;
    }
    modifier onlyMinter() {
        require(msg.sender == minter, "only minter allowed");
        _;
    }

    modifier onlyTicketOwner(uint256 _ticketId) {
        require(
            IERC721(address(NFTicketContract)).ownerOf(_ticketId) ==
                _msgSender(),
            "Only ticket owner can do this"
        );
        _;
    }

    
    //===================================Public functions===================================//
    /**
     * @notice Mints an NFTicket to sendTo with the metadata given in _URI
     *
     * @param _URI - A URI saved on the ticket; can point to some IPFS resource, for example.
     *
     * @dev Emits a TicketMinted(uint256 newTicketId, address userAddress) event, both parameters indexed
     */
    function createIdentityFor(string calldata _URI, address user) 
        public override 
        onlyMinter
        returns(uint256) 
    {

        Ticket memory ticket = getTicketParams(user, _URI);

        Ticket memory newTicket = NFTicketContract.mintNFTicket(user, ticket);

        emit TicketMinted(newTicket.tokenID, user);
        return(newTicket.tokenID);

    }

  
    //===================================Private functions===================================//
    function getTicketParams(address _recipient, uint256 companyCode, string calldata _URI)
        internal
        view
        onlyAdmin
        returns (Ticket memory ticket)
    {
        ticket.tokenID = 0; // This Id will be assigned correctly in the NFTicket contract
        ticket.serviceProvider = address(this);
        ticket.serviceDescriptor = IS_TICKET.add(companyCode) ; 
        ticket.issuedTo = _recipient;
        ticket.certValue = 0;
        ticket.certValidFrom = 0;
        ticket.price = 0;
        ticket.credits = numCredits;
        ticket.pricePerCredit = 0;
        ticket.serviceFee = 900 * 1 ether;
        ticket.resellerFee = 100 * 1 ether;
        ticket.transactionFee = 0 * 1 ether;
        ticket.tokenURI = _URI;
        ticket.erc20Contract = address(ERC20Contract);
        /*
        string memory _msg = string(abi.encodePacked(
            "ticket.serviceDescriptor.1=",
            Strings.toHexString(ticket.serviceDescriptor)));
        require(false, _msg);
        */
    }

    /**
     * @dev The mintNFTicket() function in NFTicket.sol requires two parameters one of which
     * is a Ticket struct. This Ticket struct is assembled here.
     */
    function getTicketParams(address _recipient, string calldata _URI)
        internal
        view
        returns (Ticket memory ticket)
    {
        ticket.tokenID = 0; // This Id will be assigned correctly in the NFTicket contract
        ticket.serviceProvider = address(this);
        ticket.serviceDescriptor = IS_TICKET.add(NFTAVATAR) ; // hb230607 ticketServiceDescriptor;
        ticket.issuedTo = _recipient;
        ticket.certValue = 0;
        ticket.certValidFrom = 0;
        ticket.price = 0;
        ticket.credits = numCredits;
        ticket.pricePerCredit = 0;
        ticket.serviceFee = 900 * 1 ether;
        ticket.resellerFee = 100 * 1 ether;
        ticket.transactionFee = 0 * 1 ether;
        ticket.tokenURI = _URI;
        ticket.erc20Contract = address(ERC20Contract);
    }

}