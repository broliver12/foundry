// SPDX-License-Identifier: MIT

// Written by Oliver Straszynski
// https://github.com/broliver12/

pragma solidity ^0.8.11;

import "solidity/src/ERC721ACore.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract BaseTest is Test {
    address payable[] internal users;
    address internal owner;
    address internal user0;
    address internal user1;
    address internal user2;
    address internal user3;

    // Change this to specific contract type for your ERC721ACore extension
    ERC721ACore testContract;

    function setUp() public virtual {
        users = createUsers(5);
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

    // create users with 100 ETH balance each
    function createUsers(uint256 userNum)
        private
        returns (address payable[] memory)
    {
        bytes32 seed = keccak256(abi.encodePacked("seed"));

        address payable[] memory _users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = payable(address(uint160(uint256(seed))));
            seed = keccak256(abi.encodePacked(user));
            vm.deal(user, 100 ether);
            _users[i] = user;
        }

        return _users;
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
