// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.4;

import './ERC721ACore.sol';

contract ERC721AWhitelistRelease is ERC721ACore {
    
    bool public whitelistEnabled;
    uint256 public maxMintsWhitelist = 3;
    uint256 public whitelistPrice = 0.07 ether;
    mapping(address => uint256) public whitelist;

    constructor() ERC721ACore(
      "YourPojectTitle",
      "YPT",
      3333,
      20,
      33,
      0.2 ether
    ) {}

    function whitelistMint(uint256 quantity)
        external
        payable
        isWallet
        enoughSupply(quantity)
    {
        require(whitelistEnabled, "Minting not enabled");
        require(quantity <= whitelist[msg.sender], "No whitelist spots");
        require(quantity * whitelistPrice <= msg.value, "Not enough ETH");
        whitelist[msg.sender] = whitelist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * whitelistPrice);
    }

    function setWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            whitelist[addrs[i]] = maxMintsWhitelist;
        }
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    function enableWhitelistMint(bool _enabled) external onlyOwner {
        whitelistEnabled = _enabled;
    }
}