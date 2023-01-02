// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.4;

import './ERC721ACore.sol';

contract ERC721ARelease is ERC721ACore {
    constructor() ERC721ACore(
      "YourPojectTitle",
      "YPT",
      3333,
      20,
      33,
      0.2 ether
    ) {}
}
