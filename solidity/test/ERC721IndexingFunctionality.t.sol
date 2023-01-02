// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.11;

import {BaseTest} from "./shared/BaseTest.t.sol";
import "forge-std/Test.sol";
import "solidity/src/ERC721ACore.sol";

contract ERC721IndexingFunctionalityTest is BaseTest {
    uint256 price = 0.2 ether;

    function setUp() public virtual override {
        super.setUp();
        super.init(
            new ERC721ACore("TestContract", "TEST", 3333, 20, 55, price)
        );
        testContract.enablePublicMint(true);
        // Assume we're a given user (non owner)
        vm.startPrank(user0, user0);
    }

    function test_tokenOfOwnerByIndex_noneMintedYet_reverts() public {
        // Expect revert when no tokens have been minted
        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user0, 0);
    }

    function test_tokenOfOwnerByIndex_otherUsersHaveMinted_reverts(uint256 x)
        public
    {
        vm.assume(x > 0);
        vm.assume(x <= testContract.maxMints());

        vm.stopPrank();
        vm.startPrank(user1, user1);

        testContract.publicMint{value: x * price}(x);

        // Expect revert when the user hasn't minted any tokens yet
        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user0, 0);
    }

    function test_tokenOfOwnerByIndex(uint256 x) public {
        vm.assume(x > 0);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);

        // Test that the first token index is correct
        assert(testContract.tokenOfOwnerByIndex(user0, 0) == 0);
        // Test that the last token index is correct
        assert(testContract.tokenOfOwnerByIndex(user0, x - 1) == x - 1);
    }

    function test_tokenOfOwnerByIndex_onlyTokenBurnt_reverts() public {
        testContract.publicMint{value: price}(1);
        testContract.burn(0);

        // Expect revert when the user hasn't minted any tokens yet
        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user0, 0);
    }

    function test_tokenOfOwnerByIndex_firstTokenBurnt(uint256 x) public {
        vm.assume(x > 1);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);
        testContract.burn(0);

        // Test that the burnt token now has the next token's index
        assert(testContract.tokenOfOwnerByIndex(user0, 0) == 1);
        // Test that the last owner token has the original last token's index
        assert(testContract.tokenOfOwnerByIndex(user0, x - 2) == x - 1);
    }

    function test_tokenOfOwnerByIndex_lastTokenBurnt(uint256 x) public {
        vm.assume(x > 1);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);
        testContract.burn(x - 1);

        // Test that the last owned token index is the same
        assert(testContract.tokenOfOwnerByIndex(user0, x - 2) == x - 2);

        // Expect revert when accessing what was previously the final token
        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user0, x - 1);
    }

    function test_tokenOfOwnerByIndex_middleTokenBurnt(
        uint256 x,
        uint256 toBurn
    ) public {
        vm.assume(x > 1);
        vm.assume(toBurn > 0);
        vm.assume(toBurn < x - 1);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);
        testContract.burn(toBurn);

        // Test that the burnt token now has the next tokens ID
        assert(testContract.tokenOfOwnerByIndex(user0, toBurn) == toBurn + 1);
        // Test that the last owner token has the original last token's index
        assert(testContract.tokenOfOwnerByIndex(user0, x - 2) == x - 1);
    }

    function test_tokenOfOwnerByIndex_multiUserBurn() public {
        testContract.publicMint{value: 5 * price}(5);
        testContract.burn(0);
        testContract.burn(4);

        vm.stopPrank();
        vm.startPrank(user1, user1);

        testContract.publicMint{value: 5 * price}(5);
        testContract.burn(6);
        testContract.burn(9);

        // Test that the first token index is correct
        assert(testContract.tokenOfOwnerByIndex(user0, 0) == 1);
        assert(testContract.tokenOfOwnerByIndex(user0, 1) == 2);
        assert(testContract.tokenOfOwnerByIndex(user0, 2) == 3);

        assert(testContract.tokenOfOwnerByIndex(user1, 0) == 5);
        assert(testContract.tokenOfOwnerByIndex(user1, 1) == 7);
        assert(testContract.tokenOfOwnerByIndex(user1, 2) == 8);

        // Expect revert when accessing burnt quantity
        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user0, 4);

        vm.expectRevert(OwnerIndexOutOfBounds.selector);
        testContract.tokenOfOwnerByIndex(user1, 4);
    }

    function test_tokenByIndex_noneMintedYet_reverts() public {
        // Expect revert when no tokens have been minted
        vm.expectRevert(TokenIndexOutOfBounds.selector);
        testContract.tokenByIndex(0);
    }

    function test_tokenByIndex(uint256 amountToMint, uint256 testIndex) public {
        vm.assume(amountToMint > 0);
        vm.assume(amountToMint <= testContract.maxMints());
        vm.assume(testIndex < amountToMint);

        testContract.publicMint{value: amountToMint * price}(amountToMint);

        // Test that indeces line up with tokenIDs when no burning has occured
        assert(testContract.tokenByIndex(testIndex) == testIndex);
    }

    function test_tokenByIndex_onlyTokenBurnt_reverts() public {
        testContract.publicMint{value: price}(1);
        testContract.burn(0);

        // Expect revert when accessing what was previously the only token
        vm.expectRevert(TokenIndexOutOfBounds.selector);
        testContract.tokenByIndex(0);
    }

    function test_tokenByIndex_firstTokenBurnt(uint256 x) public {
        vm.assume(x > 1);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);
        testContract.burn(0);

        // Test that the new first token has the original second token's index
        assert(testContract.tokenByIndex(0) == 1);
    }

    function test_tokenByIndex_lastTokenBurnt_reverts(uint256 x) public {
        vm.assume(x > 1);
        vm.assume(x <= testContract.maxMints());

        testContract.publicMint{value: x * price}(x);

        testContract.burn(x - 1);

        // Test that the previous token's index is unchanged, unless the first token is the one burnt
        assert(testContract.tokenByIndex(x - 2) == x - 2);

        // Expect revert when accessing what was previously the final token
        vm.expectRevert(TokenIndexOutOfBounds.selector);
        testContract.tokenByIndex(x - 1);
    }

    function test_tokenByIndex_middleTokenBurnt(
        uint256 amountToMint0,
        uint256 numToBurn0
    ) public {
        vm.assume(amountToMint0 > 1);
        vm.assume(numToBurn0 > 0);
        vm.assume(numToBurn0 < amountToMint0 - 1);
        vm.assume(amountToMint0 <= testContract.maxMints());

        testContract.publicMint{value: amountToMint0 * 0.2 ether}(
            amountToMint0
        );
        testContract.burn(numToBurn0);

        // Test that the burnt token now has the following token's index
        assert(testContract.tokenByIndex(numToBurn0) == numToBurn0 + 1);
        // Test that the last existing token has the original final index
        assert(
            testContract.tokenByIndex(amountToMint0 - 2) == amountToMint0 - 1
        );
    }

    function test_tokenByIndex_multiUserBurn() public {
        testContract.publicMint{value: 5 * price}(5);
        testContract.burn(0);
        testContract.burn(4);

        vm.stopPrank();
        vm.startPrank(user1, user1);

        testContract.publicMint{value: 5 * price}(5);
        testContract.burn(6);
        testContract.burn(9);

        // Test specific indices to ensure we fully understand how burning affects these functions
        assert(testContract.tokenByIndex(0) == 1);
        assert(testContract.tokenByIndex(1) == 2);
        assert(testContract.tokenByIndex(2) == 3);
        assert(testContract.tokenByIndex(3) == 5);
        assert(testContract.tokenByIndex(4) == 7);
        assert(testContract.tokenByIndex(5) == 8);

        // Expect revert when accessing burnt quantity
        vm.expectRevert(TokenIndexOutOfBounds.selector);
        testContract.tokenByIndex(6);
    }
}
