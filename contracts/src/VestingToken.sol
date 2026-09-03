// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author  0xshdwfx
 * @title   VestingToken
 * @dev     Simple ERC20 token for testing TokenVesting contract functionality.
 * @notice  Standard ERC20 token with initial supply minted to deployer.
 */
contract VestingToken is ERC20 {
    constructor() ERC20("Vesting Token", "VST") {
        _mint(msg.sender, 1_000_000e18);
    }
}
