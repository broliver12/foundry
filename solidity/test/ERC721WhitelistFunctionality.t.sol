// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.11;

import {BaseTest} from "./shared/BaseTest.t.sol";
import "forge-std/Test.sol";
import "solidity/src/ERC721AWhitelistRelease.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract ERC721WhitelistFunctionalityTest is BaseTest {
    ERC721AWhitelistRelease wlContract;

    address[] arr = new address[](3);

    function _assumeValidWhitelistMintAmount(uint256 amount) private view {
        vm.assume(amount <= wlContract.maxMintsWhitelist());
        vm.assume(amount > 0);
    }

    function setUp() public virtual override {
        super.setUp();
        arr[0] = user1;
        arr[1] = user2;
        arr[2] = user3;

        // Assume we're the owner until otherwise specified
        vm.startPrank(owner, owner);
        wlContract = new ERC721AWhitelistRelease();
        super.init(wlContract);
    }

    function test_whitelistMint_init() public view {
        assert(wlContract.whitelistEnabled() == false);
    }

    function test_addMultipleToWhitelist() public {
        wlContract.setWhitelist(arr);
        assert(wlContract.whitelist(user1) == wlContract.maxMintsWhitelist());
        assert(wlContract.whitelist(user2) == wlContract.maxMintsWhitelist());
        assert(wlContract.whitelist(user3) == wlContract.maxMintsWhitelist());
    }

    // Test enable whitelist mint
    function test_enableWhitelistMint() public {
        wlContract.enableWhitelistMint(true);
        assert(wlContract.whitelistEnabled() == true);
    }

    // Test change whitelist price
    function test_setWhitelistPrice() public {
        wlContract.setWhitelistPrice(1 ether);
        assert(wlContract.whitelistPrice() == 1 ether);
    }

    function test_whitelistMint_ownerNotOnWhitelist_reverts(uint256 amount)
        public
    {
        _assumeValidWhitelistMintAmount(amount);
        wlContract.enableWhitelistMint(true);

        // Transfer some eth to owner for this specific test
        vm.stopPrank();
        vm.startPrank(user1, user1);
        (bool sent, ) = payable(owner).call{
            value: amount * wlContract.whitelistPrice()
        }("");
        assert(sent == true);
        vm.stopPrank();

        vm.startPrank(owner, owner);
        wlContract.enableWhitelistMint(true);
        uint256 _value = amount * wlContract.whitelistPrice();
        vm.expectRevert("No whitelist spots");
        wlContract.whitelistMint{value: _value}(amount);
    }

    // Test cant WL mint if not whitelisted
    function test_whitelistMint_userNotOnWhitelist_reverts(uint256 amount)
        public
    {
        _assumeValidWhitelistMintAmount(amount);

        wlContract.setWhitelist(arr);
        wlContract.enableWhitelistMint(true);
        vm.stopPrank();

        vm.startPrank(user0, user0);
        uint256 _value = amount * wlContract.whitelistPrice();
        vm.expectRevert("No whitelist spots");
        wlContract.whitelistMint{value: _value}(amount);
    }

    // Test can WL mint
    function test_whitelistMint(uint256 amount) public {
        _assumeValidWhitelistMintAmount(amount);

        wlContract.setWhitelist(arr);
        wlContract.enableWhitelistMint(true);
        vm.stopPrank();

        vm.startPrank(user1, user1);
        wlContract.whitelistMint{value: amount * wlContract.whitelistPrice()}(
            amount
        );
    }

    // Test can WL mint
    function test_whitelistMint_ifNotEnabled_reverts(uint256 amount) public {
        _assumeValidWhitelistMintAmount(amount);

        uint256 _value = amount * wlContract.whitelistPrice();
        wlContract.setWhitelist(arr);
        vm.stopPrank();

        vm.prank(user1, user1);
        vm.expectRevert("Minting not enabled");
        wlContract.whitelistMint{value: _value}(amount);
    }

    // Test can WL mint
    function test_whitelistMint_notEnoughValue_reverts(uint256 amount) public {
        _assumeValidWhitelistMintAmount(amount);

        uint256 _value = amount * wlContract.whitelistPrice();
        wlContract.setWhitelist(arr);
        wlContract.enableWhitelistMint(true);
        vm.stopPrank();

        vm.prank(user1, user1);
        vm.expectRevert("Not enough ETH");
        wlContract.whitelistMint{value: _value - 1}(amount);
    }

    // Test that refund occurs on WL mint
    function test_whitelistMint_extraValue_refunds(uint256 amount) public {
        _assumeValidWhitelistMintAmount(amount);

        uint256 _value = amount * wlContract.whitelistPrice();
        uint256 _balance = user1.balance;
        wlContract.setWhitelist(arr);
        wlContract.enableWhitelistMint(true);
        vm.stopPrank();

        vm.prank(user1, user1);
        wlContract.whitelistMint{value: _value + 10}(amount);
        assert(user1.balance == _balance - _value);
    }

    function test_onlyOwner_setWhitelistPrice(uint256 amount, uint256 userIndex)
        public
    {
        _assumeUserIsNotOwner(userIndex);

        _assumeValidWhitelistMintAmount(amount);

        wlContract.setWhitelistPrice(amount);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        wlContract.setWhitelistPrice(amount);
    }

    function test_onlyOwner_setWhitelist(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);

        wlContract.setWhitelist(arr);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        wlContract.setWhitelist(arr);
    }

    function test_onlyOwner_enableWhitelist(bool state, uint256 userIndex)
        public
    {
        _assumeUserIsNotOwner(userIndex);

        wlContract.enableWhitelistMint(state);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        wlContract.enableWhitelistMint(state);
    }
}
