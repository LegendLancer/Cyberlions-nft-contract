/*
The Phunky Fungi Collection
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MultisigOwnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

// IMPORTANT: _burn() must never be called
contract PhunkyFungi is ERC721A, MultisigOwnable {
    using Strings for uint256;

    bytes32 immutable public presaleMerkleRoot;
    bytes32 immutable public collabMerkleRoot;
    uint immutable public startSaleTimestamp;
    bool public finalized = false;
    bool public airdropped = false;
    bool public revealed = false;

    uint public constant PRESALE_LIMIT = 3;
    uint public constant PUBLIC_LIMIT = 5;
    uint public constant COLLECTION_SIZE = 9200;
    uint public constant PRESALE_PRICE = 0.098 ether;
    uint public constant PUBLIC_PRICE = 0.125 ether;
    uint public constant TEAM_AIRDROP_LIMIT = 100;
    
    address private immutable _revenueRecipient;
    string private _baseURI;
    string private _placeholderURI;

    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    constructor(bytes32 _presaleMerkleRoot, bytes32 _collabMerkleRoot, string memory placeholderURI, address revenueRecipient )
        ERC721A("Phunky Fungi", "PF")
    {
        presaleMerkleRoot = _presaleMerkleRoot;
        collabMerkleRoot = _collabMerkleRoot;
        _placeholderURI = placeholderURI;
        _revenueRecipient = revenueRecipient;
    }

    /// @notice the initial 100 tokens will be minted to the team vault for use in giveaways and collaborations.
    function airdrop(address to, uint quantity) external onlyRealOwner{
        require(airdropped == false, "already airdropped");
        require(quantity <= TEAM_AIRDROP_LIMIT, "Can not airdrop more than publicly disclosed to team.");
        _mint(to, quantity, '', false);
        airdropped = true;
    }


    /// @notice Set sales status
    function setSaleStatus(SaleStatus status) onlyOwner external {
        saleStatus = status;
    }
    
    /// @notice After metadata is revealed and all is in working order, it will be finalized permanently.
    function finalizeMetadata() external onlyRealOwner {
        require(finalized == false, "Metadata is already finalized.");
        finalized = true;
    }
    
    function setMetadataURI(string memory baseURI, string memory placeholderURI, bool reveal) external onlyRealOwner {
        require(finalized == false, "Settings are already finalized.");
        _baseURI = baseURI;
        _placeholderURI = placeholderURI;
        revealed = reveal;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /// @notice Withdraw's contract's balance to the withdrawal address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");

        payable(_revenueRecipient).transfer(balance);
    }

    function toBytes32(address addr) pure internal returns (bytes32){
        return bytes32(uint256(uint160(addr)));
    }
    
    mapping(address=>uint) public claimed;
    mapping(address=>bool) public collabClaimed;
    //mapping(address=>uint) public minted;
    
    /// @notice each address on our collab list may mint 1 fungi at the presale price
    function collabMint(bytes32[] calldata _merkleProof) public payable {
        require(saleStatus == SaleStatus.PRESALE, "Presale is not happening right now");
        require(collabClaimed[msg.sender] == false, "Already claimed");
        require(MerkleProof.verify(_merkleProof, collabMerkleRoot, toBytes32(msg.sender)) == true, "You are not on the collab list");
        require(msg.value >= PRESALE_PRICE, "Amount sent is too low");
        require(totalSupply() < TOKEN_LIMIT, "Token supply limit reached");
        _mint(msg.sender, 1, '', false);
        collabClaimed[msg.sender] = true;
    }
    
    /// @notice each address on our presale list may mint up to 3 fungi at our presale price
    function presaleMint(bytes32[] calldata _merkleProof, uint quantity) public payable {
        require(saleStatus == SaleStatus.PRESALE, "Presale is not happening right now");
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, toBytes32(msg.sender)) == true, "You are not on the presale list");
        require(claimed[msg.sender] + quantity <= PRESALE_LIMIT, "Only up to 3 fungi can be minted per address during presale");
        require(totalSupply() + quantity <= TOKEN_LIMIT, "Token supply limit reached");
        uint cost;
        unchecked {
            cost = quantity * PRESALE_PRICE;
        }
        require(msg.value >= cost, "Amount sent is too low");
        _mint(msg.sender, quantity, '', false);
        claimed[msg.sender] += quantity;
    }

    /// @notice may mint up to 5 fungi per transaction at the public mint price.
    function mint(uint quantity) public payable {
        require(saleStatus == SaleStatus.PUBLIC, "Public sale is not happening right now");
        require(quantity <= PUBLIC_LIMIT, "Only up to 5 fungi can be minted per transaction");
        //require(minted[msg.sender] + quantity <= PUBLIC_LIMIT, "Only up to 5 fungi can be minted at once");
        uint cost;
        unchecked {
            cost = quantity * PUBLIC_PRICE;
        }
        require(msg.value >= cost, "Amount sent is too low");
        require(totalSupply() + quantity <= TOKEN_LIMIT, "Creating this many fungi would exceed the supply limit");
        _mint(msg.sender, quantity, '', false);
        // minted[msg.sender] += quantity;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token ID does not exist");

        return revealed
            ? string(abi.encodePacked(_baseURI(), id.toString(), ".json"))
            : _placeholderURI;
    }
}
