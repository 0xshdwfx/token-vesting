// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";

contract TokenVestingHandler {
    TokenVesting public immutable tokenVesting;

    constructor(TokenVesting _tokenVesting) {
        tokenVesting = _tokenVesting;
    }
}
