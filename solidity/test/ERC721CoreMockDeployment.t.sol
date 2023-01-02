// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.11;

import {BaseTest} from "./shared/BaseTest.t.sol";
import "forge-std/Test.sol";
import "solidity/src/ERC721ACore.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract ERC721CoreFunctionalityTest is BaseTest {
    uint256 price = 0.2 ether;
    uint256 supply = 3333;
    uint256 maxMints = 20;
    uint256 devSupply = 55;

    string notRevealedUri = "https:www.customUrl.com/pre-reveal.json";
    string baseUri = "https:www.customUrl.com/";
    string baseExt = ".json";

    function setUp() public virtual override {
        super.setUp();

        // Assume we're the owner until otherwise specified
        vm.startPrank(owner, owner);
        super.init(
            new ERC721ACore(
                "TestContract",
                "TEST",
                supply,
                maxMints,
                devSupply,
                price
            )
        );

        testContract.setNotRevealedURI(notRevealedUri);
        vm.stopPrank();
    }

    function test_hacker_steal_contract(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);
        _startPrankAndExpectOnlyOwnerRevert(userIndex);
        testContract.transferOwnership(user3);
    }

    function test_hacker_reveal(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);
        _startPrankAndExpectOnlyOwnerRevert(userIndex);
        testContract.reveal(true);
    }

    function test_hacker_enable_mint(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);
        _startPrankAndExpectOnlyOwnerRevert(userIndex);
        testContract.enablePublicMint(true);
    }

    function test_hacker_withdraw(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);
        _startPrankAndExpectOnlyOwnerRevert(userIndex);
        testContract.withdraw();
    }

    function test_sop(
        uint256 amount0,
        uint256 amount1,
        uint256 amount2
    ) public {
        _assumeValidMintAmount(amount0);
        _assumeValidMintAmount(amount1);
        _assumeValidMintAmount(amount2);

        vm.prank(owner, owner);
        testContract.enablePublicMint(true);

        vm.prank(user0, user0);
        testContract.publicMint{value: amount0 * price}(amount0);

        vm.prank(user1, user1);
        testContract.publicMint{value: amount1 * price}(amount1);

        vm.prank(user2, user2);
        vm.expectRevert("Not enough ETH");
        testContract.publicMint(amount2);

        vm.prank(user2, user2);
        testContract.publicMint{value: amount2 * price}(amount2);

        vm.startPrank(user0, user0);
        testContract.burn(testContract.tokenOfOwnerByIndex(user0, 0));
        vm.stopPrank();

        assert(testContract.balanceOf(user0) == amount0 - 1);

        vm.prank(user1, user1);
        testContract.transferFrom(user1, user2, amount0);

        assert(testContract.balanceOf(user1) == amount1 - 1);
        assert(testContract.balanceOf(user2) == amount2 + 1);

        assert(maxMints == testContract.maxMints());
        vm.startPrank(user0, user0);
        while (testContract.balanceOf(user0) > 0) {
            testContract.burn(testContract.tokenOfOwnerByIndex(user0, 0));
        }

        if (amount0 < testContract.maxMints()) {
            testContract.publicMint{
                value: (testContract.maxMints() - amount0) * price
            }(testContract.maxMints() - amount0);
        }
        vm.stopPrank();

        vm.startPrank(user1, user1);
        while (testContract.balanceOf(user1) > 0) {
            testContract.burn(testContract.tokenOfOwnerByIndex(user1, 0));
        }
        if (amount1 < testContract.maxMints()) {
            testContract.publicMint{
                value: (testContract.maxMints() - amount1) * price
            }(testContract.maxMints() - amount1);
        }
        uint256 balance = user1.balance;
        vm.expectRevert("Cant mint that many");
        testContract.publicMint{value: price}(1);

        assert(
            testContract.balanceOf(user1) == testContract.maxMints() - amount1
        );
        assert(balance == user1.balance);

        uint256 contractBalance = address(testContract).balance;
        uint256 ownerBalance = owner.balance;

        vm.stopPrank();
        vm.startPrank(owner, owner);

        testContract.setBaseURI(baseUri);
        testContract.withdraw();

        assert(address(testContract).balance == 0);
        assert(owner.balance == contractBalance + ownerBalance);

        testContract.reveal(true);

        assertEq(
            testContract.tokenURI(testContract.tokenOfOwnerByIndex(user2, 0)),
            string(
                abi.encodePacked(
                    baseUri,
                    Strings.toString(
                        testContract.tokenOfOwnerByIndex(user2, 0)
                    ),
                    baseExt
                )
            )
        );
    }
}
