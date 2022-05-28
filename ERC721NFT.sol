//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/**
 * @dev String operations.
 */

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract ERC721NFT is ERC721Enumerable, Ownable, ContextMixin{

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 8000;
    uint public constant PRICE = 10000000000000000000;

    string internal baseTokenURI;
    string internal hiddenTokenURI;

    bool public revealed = false;

    event NFTMinted (
        uint256 indexed tokenId,
        address minter
    );

    event donation (
        address donor,
        uint value
    );

    constructor(string memory baseURI,string memory hiddenMetadataUri) ERC721("ERC721NFT", "ERC721NFT") {
        setBaseURI(baseURI);
        sethiddenURI(hiddenMetadataUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function sethiddenURI(string memory _hiddenTokenURI) public onlyOwner {
        hiddenTokenURI = _hiddenTokenURI;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function donate() public payable {
        
        require(msg.value > 0, "Please Donate some ether to fund help me fund my higher education");
        
        emit donation(
            msg.sender,
            msg.value
        );
    }

    function mintNFT() public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(1) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(msg.value >= PRICE, "Not enough ether to purchase NFTs.");

        _mintNFT();

        emit NFTMinted(
            totalMinted,
            msg.sender
        );
        
    }

    function _mintNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenTokenURI;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

}
