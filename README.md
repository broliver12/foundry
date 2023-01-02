## ERC721 Project Template

NFT project template.

Contains various template implementations of `ERC721A`, alongside a complete suite of unit tests.

Depends on:

- [foundry](https://github.com/foundry-rs/foundry)

- [ERC721A](https://github.com/erc721a/)

- [openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)


## Setup

1. Install `foundry`

2. Executing `forge -V` should output something like `forge 0.2.0 (6ad60c8 2022-12-20T00:04:58.584892Z)`

## Usage

1. Clone this repository

2. Extend `ERC721ACore`, or modify `ERC721ARelease` or `ERC721AWhitelistRelease` and implement your custom functionality.

## Testing

1. Update `/solidity/test/shared/BaseTest.t.sol` to test your custom implementation.

2. Add new tests that extend `BaseTest` to leverage existing functionality.

3. Execute `forge test` to run all tests in `/solidity/test`, or `forge test --match-path <testFilePath>` to run a specific file

**Note:** Extending ERC721ACore will allow you to run your code againt basic functionality tests. Complete test coverage is the ONLY way to be confident in your smart contract's functionality.

## Todo

1. Add deploy script
2. Add documentation for tests & deployer

## License

[MIT](https://github.com/broliver12/foundry_erc721/blob/master/LICENSE.txt)