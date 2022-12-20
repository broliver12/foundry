// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "solidity/src/ExampleContract.sol";

contract ContractTest is Test {
    ExampleContract foo;
    function setUp() public {
      foo = new ExampleContract();
    }

    function testExample() public {
        assert(foo.exampleFunction());
        assertTrue(true);
    }
}
