// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../libs/SafeMath.sol";
import "../interfaces/INFTicket.sol";
import "../interfaces/INFTServiceTypes.sol";
import "./interfaces/INFTicketAvatarService.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/**
 * @title Service contract for the NFTicket avatar
 * @author Harry Behrens | bloXmove
 */

contract NFTicketAvatarService is INFTicketAvatarService, AccessControl, ERC721Enumerable, ERC721URIStorage {
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 public companyDescriptor = NFTAVATAR;
    // NFTicket contract
    INFTicket NFTicketContract;
    address minter;

    // ERC20 token to be distributed to consumers
    IERC20 ERC20Contract;

    // Number of credits on newly minted ticket
    uint256 public numCredits;

    mapping(uint256 => address) public ownership;
    mapping(uint256 => string) public token2uri;
    mapping(uint256 => uint256) public tokenIdMap; // NFTicket ID to local token ID
    mapping(uint256 => uint256) public tokenIdReverseMap; // local token ID to NFTicket ID

    //===================================Initializer===================================//
    constructor (
        address _NFTicketAddress,
        address _ERC20Address,
        address _minter,
        uint256 _numCredits
    ) ERC721("NFTicketAvatar", "BLXA") ERC721URIStorage() {
        NFTicketContract = INFTicket(_NFTicketAddress);
        minter = _minter;
        ERC20Contract = IERC20(_ERC20Address);
        numCredits = _numCredits;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

    }

    function safeMint(address to, uint256 tokenId) public onlyAdmin {
      _safeMint(to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721URIStorage, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
    
    function _update(
      address to,
      uint256 tokenId,
      address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
      return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
      super._increaseBalance(account, value);
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
            IERC721Enumerable(address(NFTicketContract)).ownerOf(_ticketId) ==
                _msgSender(),
            "Only ticket owner can do this"
        );
        _;
    }

    function setMinter(address _minter) 
        public override
        onlyAdmin
    {
        minter = _minter;
    }

    //===================================Public functions===================================//

    /***
     *
     * @notice Mints an NFTicket to sendTo with the metadata given in _URI
     *
     * @param user - address of user wallet
     * @param avatarID - 
     * @param _URI - A URI saved on the ticket; can point to some IPFS resource, for example.
     * @return ticketID - the ERC721 token ID of the NFTicket token/ticket
     *
     * @dev Emits a TicketMinted(uint256 newTicketId, address userAddress) event, both parameters indexed
     *
     ***/
    function createIdentityFor(
        address user, 
        uint avatarID, 
        string calldata _URI
    ) 
        public override 
        onlyMinter
        returns(uint256) 
    {
        Ticket memory ticket = getTicketParams(user, _URI);

        // @dev we store the NFTicket which is created for the avatar within this contract
        Ticket memory newTicket = NFTicketContract.mintNFTicket(address(this), ticket);
        _mint(user, avatarID);
        _setTokenURI(avatarID, _URI);

        ownership[avatarID] = msg.sender; // @notice remember "owner" even when avatar is transferred
		token2uri[avatarID] = _URI;
		tokenIdMap[newTicket.tokenID] = avatarID;
        tokenIdReverseMap[avatarID] = newTicket.tokenID;

        emit TicketMinted(avatarID, user);
        return(newTicket.tokenID); // REAL, i.e. NFTicket::tokenID
    }

    function _safeTransfer_(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'myTransferHelper: TRANSFER_FAILED');
    }

    function _safeTransferFrom_(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'myTransferHelper: TRANSFER_FROM_FAILED');
    }

    /****
    *
    * @notice tokenURI returns the ERC721 tokenURI. When called by NFTicket it performs the necessary token:token mapping
    * 
    * @param tokenID - can be relative to this ERC721 contract or NFTicket
    * @return tokenURI
    *
    ***/
    function tokenURI(uint256 tokenID) 
        public 
        override(ERC721, ERC721URIStorage, INFTicketAvatarService)
        view 
        returns (string memory) 
    {
        if (msg.sender == address(NFTicketContract)) {
            require(tokenIdMap[tokenID] > 0, "URI query for nonexistent token");
            tokenID = tokenIdMap[tokenID];
        }
        return (token2uri[tokenID]);
    }

    function balanceOf(address owner) 
        public 
        override(ERC721, IERC721)
        view 
        returns (uint256) 
    {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) 
        public 
        override(ERC721, IERC721)
        view 
        returns (address) 
    {
        uint256 ticketId = tokenIdReverseMap[tokenId];

        return super.ownerOf(ticketId);
    }

    function totalSupply() 
        public 
        override
        view 
        returns (uint256) 
    {
        return super.totalSupply();
    }

    function tokenByIndex(uint256 index) 
        public 
        override
        view 
        returns (uint256) 
    {
        return super.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) 
        public 
        override
        view 
        returns (uint256) 
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    //===================================Private functions===================================//
    function getTicketParams(
        address _recipient,
        uint256 companyCode,
        string calldata _URI
    ) internal view onlyAdmin returns (Ticket memory ticket) {
        ticket.tokenID = 0; // This Id will be assigned correctly in the NFTicket contract
        ticket.serviceProvider = address(this);
        ticket.serviceDescriptor = IS_TICKET.add(companyCode);
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
    function getTicketParams(
        address _recipient,
        string calldata _URI
    ) internal view returns (Ticket memory ticket) {
        ticket.tokenID = 0; // This Id will be assigned correctly in the NFTicket contract
        ticket.serviceProvider = address(this);
        ticket.serviceDescriptor = IS_TICKET.add(NFTAVATAR); 
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
