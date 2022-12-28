// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "solidity/src/ERC721ACore.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.t.sol";

contract BaseTest is Test {
   Utils internal utils;

   address payable[] internal users;
   address internal owner;
   address internal user0;
   address internal user1;
   address internal user2;
   address internal user3;

   // Change this to specific contract type for your ERC721ACore extension
   ERC721ACore testContract;

   function setUp() public virtual {
       utils = new Utils();
       users = utils.createUsers(5);
       owner = users[0];
       vm.label(owner, "Owner");
       user0 = users[1];
       user1 = users[2];
       user2 = users[3];
       user3 = users[4];
   }

   // Change `testContract_` type specific contract type for your ERC721ACore extension
   function init(ERC721ACore testContract_) internal {
       testContract = testContract_;
   }

    function _assumeValidMintAmount(uint256 amount) internal view {
        vm.assume(amount > 0);
        vm.assume(amount <= testContract.maxMints());
    }

    function _assumeValidDevMintAmount(uint256 amount) internal view {
        vm.assume(amount > 0);
        vm.assume(amount <= testContract.totalDevSupply());
    }

    function _assumeUserIsNotOwner(uint256 userIndex) internal view {
        vm.assume(userIndex > 0);
        vm.assume(userIndex < users.length);
    }

    function _startPrankAndExpectOnlyOwnerRevert(uint256 userIndex) internal {
        vm.stopPrank();
        vm.startPrank(users[userIndex], users[userIndex]);
        vm.expectRevert("Ownable: caller is not the owner");
    }
}