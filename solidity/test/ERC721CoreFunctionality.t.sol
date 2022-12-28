// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

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

    string emptyString = "";
    string testNotRevealedUri = "testNotRevealedUri";
    string testBaseUri = "testBaseUri";
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
    }

    // Initialization

    function test_collectionSize_init() public view {
        assert(testContract.totalCollectionSize() == supply);
    }

    function test_totalSupply_init() public view {
        assert(testContract.totalSupply() == 0);
    }

    function test_publicMintDisabled_init() public view {
        assert(testContract.publicMintEnabled() == false);
    }

    function test_price_init() public view {
        assert(testContract.unitPrice() == price);
    }

    function test_maxMints_init() public view {
        assert(testContract.maxMints() == maxMints);
    }

    function test_devSupply_init() public view {
        assert(testContract.totalDevSupply() == devSupply);
    }

    function test_notRevealedUri_init(uint256 amount) public {
        _assumeValidDevMintAmount(amount);
        testContract.devMint(amount, owner);
        assertEq(testContract.tokenURI(amount - 1), emptyString);
    }

    function test_revealedUri_init(uint256 amount) public {
        _assumeValidDevMintAmount(amount);
        testContract.setNotRevealedURI(testNotRevealedUri);
        testContract.devMint(amount, owner);
        testContract.reveal(true);
        assertEq(
            testContract.tokenURI(amount - 1),
            string(abi.encodePacked(Strings.toString(amount - 1), baseExt))
        );
    }

    // Metadata

    function test_notRevealedUri_displayed_pre_reveal(
        uint256 amount,
        string memory uri
    ) public {
        _assumeValidDevMintAmount(amount);
        testContract.setNotRevealedURI(uri);
        testContract.devMint(amount, owner);
        assertEq(testContract.tokenURI(amount - 1), uri);
    }

    function test_revealedUri_andBaseExtension(
        uint256 amount,
        string memory uri
    ) public {
        _assumeValidDevMintAmount(amount);
        testContract.setBaseURI(uri);
        testContract.devMint(amount, owner);
        testContract.reveal(true);
        assertEq(
            testContract.tokenURI(amount - 1),
            string(abi.encodePacked(uri, Strings.toString(amount - 1), baseExt))
        );
    }

    function test_changeBaseExtension(uint256 amount, string memory ext)
        public
    {
        _assumeValidDevMintAmount(amount);
        testContract.setBaseURI(testBaseUri);
        testContract.setBaseExtension(ext);
        testContract.devMint(amount, owner);
        testContract.reveal(true);
        assertEq(
            testContract.tokenURI(amount - 1),
            string(
                abi.encodePacked(testBaseUri, Strings.toString(amount - 1), ext)
            )
        );
    }

    // Change Price

    function test_changePrice(uint256 newPrice) public {
        vm.assume(newPrice > 0);
        vm.assume(newPrice < 100 ether);
        testContract.setPrice(newPrice);
    }

    // Test withdraw

    function test_withdrawZero() public {
        testContract.withdraw();
    }

    function test_withdrawNonZero(uint256 amount) public {
        uint256 previousOwnerBalance = owner.balance;

        _assumeValidMintAmount(amount);
        testContract.setMintState(1);
        vm.stopPrank();
        vm.startPrank(user0, user0);
        testContract.publicMint{value: amount * price}(amount);

        vm.stopPrank();
        vm.startPrank(owner, owner);

        testContract.withdraw();

        assert(address(testContract).balance == 0);
        assert(owner.balance == previousOwnerBalance + (amount * price));
    }

    // Developer Mint

    function test_devMint_zero_reverts() public {
        vm.expectRevert(IERC721A.MintZeroQuantity.selector);
        testContract.devMint(0, owner);
    }

    function test_devMint_toSelf(uint256 amount) public {
        _assumeValidDevMintAmount(amount);
        testContract.devMint(amount, owner);
    }

    function test_devMint_toOtherUser(uint256 amount) public {
        _assumeValidDevMintAmount(amount);
        testContract.devMint(amount, user1);
    }

    function test_devMint_toMultiUser(uint256 amount) public {
        vm.assume(amount > 1);
        vm.assume(amount <= testContract.totalDevSupply());
        testContract.devMint(amount - 1, user1);
        testContract.devMint(1, user2);
    }

    function test_devMint_maxSupply() public {
        assert(testContract.totalDevSupply() == devSupply);
        testContract.devMint(testContract.totalDevSupply(), owner);
    }

    function test_devMint_maxSupplyPlusOne_reverts() public {
        uint256 devSupplyPlusOne = testContract.totalDevSupply() + 1;
        vm.expectRevert("Not enough dev supply");
        testContract.devMint(devSupplyPlusOne, owner);
    }

    // Mint State

    function test_enableMint() public {
        testContract.setMintState(1);
        assert(testContract.publicMintEnabled() == true);
    }

    function test_disableMint() public {
        testContract.setMintState(1);
        testContract.setMintState(0);
        assert(testContract.publicMintEnabled() == false);
    }

    // Public Mint

    function test_publicMint_mintDisabled_reverts(uint256 amount) public {
        _assumeValidMintAmount(amount);
        vm.expectRevert("Minting not enabled");
        testContract.publicMint{value: amount * price}(amount);
    }

    function test_publicMint(uint256 amount, uint256 userIndex) public {
        _assumeValidMintAmount(amount);
        vm.assume(userIndex > 0);
        vm.assume(userIndex < users.length);

        testContract.setMintState(1);

        vm.stopPrank();
        vm.startPrank(users[userIndex], users[userIndex]);

        testContract.publicMint{value: amount * price}(amount);
        assert(address(testContract).balance == amount * price);
    }

    function test_publicMint_notEnoughEth_reverts(
        uint256 amount,
        uint256 userIndex
    ) public {
        _assumeValidMintAmount(amount);
        vm.assume(userIndex > 0);
        vm.assume(userIndex < users.length);

        testContract.setMintState(1);

        vm.stopPrank();
        vm.startPrank(users[userIndex], users[userIndex]);
        vm.expectRevert("Not enough ETH");
        testContract.publicMint{value: amount * price - 1}(amount);
    }

    function test_publicMint_maxMintsPlusOne_reverts() public {
        uint256 maxPlusOne = testContract.maxMints() + 1;
        testContract.setMintState(1);
        vm.expectRevert("Illegal quantity");
        testContract.publicMint{value: maxPlusOne * price}(maxPlusOne);
    }

    // Burn

    function test_burn_otherPersonsToken_reverts(uint256 amount, uint256 toBurn)
        public
    {
        _assumeValidMintAmount(amount);
        vm.assume(toBurn < amount);
        testContract.setMintState(1);

        vm.stopPrank();
        vm.prank(user0, user0);

        testContract.publicMint{value: amount * price}(amount);

        vm.startPrank(user1, user1);

        vm.expectRevert(IERC721A.TransferCallerNotOwnerNorApproved.selector);
        testContract.burn(toBurn);
    }

    function test_burn_ownerCantBurnOtherPeoplesTokens_reverts(
        uint256 amount,
        uint256 toBurn
    ) public {
        _assumeValidMintAmount(amount);
        vm.assume(toBurn < amount);
        testContract.setMintState(1);

        vm.stopPrank();
        vm.prank(user0, user0);

        testContract.publicMint{value: amount * price}(amount);

        vm.startPrank(owner, owner);

        vm.expectRevert(IERC721A.TransferCallerNotOwnerNorApproved.selector);
        testContract.burn(toBurn);
    }

    function test_burn(
        uint256 amount,
        uint256 burnStart,
        uint256 burnAmount
    ) public {
        _assumeValidMintAmount(amount);

        vm.assume(burnStart < amount);
        vm.assume(burnAmount <= amount - burnStart);

        testContract.setMintState(1);

        vm.stopPrank();
        vm.startPrank(user0, user0);

        testContract.publicMint{value: amount * price}(amount);
        for (uint256 i = burnStart; i < burnStart + burnAmount; i++) {
            testContract.burn(i);
        }

        assert(testContract.balanceOf(user0) == amount - burnAmount);
    }

    /* Test that all onlyOwner functions CANNOT be accesed by a non-owner.
       A lot of these are redundant! Don't remove them! 
       And be sure to add tests for any onlyOwner functions, 
       critical for keeping control of your contract.
    */

    function test_onlyOwner_setMintState(uint256 amount, uint256 userIndex)
        public
    {
        _assumeUserIsNotOwner(userIndex);

        testContract.setMintState(amount);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.setMintState(amount);
    }

    function test_onlyOwner_setPrice(uint256 amount, uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);

        testContract.setPrice(amount);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.setPrice(amount);
    }

    function test_onlyOwner_setNotRevealedUri(
        string memory uri,
        uint256 userIndex
    ) public {
        _assumeUserIsNotOwner(userIndex);

        testContract.setNotRevealedURI(uri);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.setNotRevealedURI(uri);
    }

    function test_onlyOwner_setBaseUri(string memory uri, uint256 userIndex)
        public
    {
        _assumeUserIsNotOwner(userIndex);

        testContract.setBaseURI(uri);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.setBaseURI(uri);
    }

    function test_onlyOwner_setExtension(string memory uri, uint256 userIndex)
        public
    {
        _assumeUserIsNotOwner(userIndex);

        testContract.setBaseExtension(uri);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.setBaseExtension(uri);
    }

    function test_onlyOwner_devMint(uint256 amount, uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);

        _assumeValidMintAmount(amount);

        testContract.devMint(amount, owner);

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.devMint(amount, owner);
    }

    function test_onlyOwner_withdraw(uint256 userIndex) public {
        _assumeUserIsNotOwner(userIndex);

        testContract.withdraw();

        _startPrankAndExpectOnlyOwnerRevert(userIndex);

        testContract.withdraw();
    }
}
