// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";
import {VestingToken} from "../../src/VestingToken.sol";
import {TokenVestingHandler} from "./TokenVestingHandler.t.sol";

contract TokenVestingInvariantTest is Test {
    TokenVesting public tokenVesting;
    VestingToken public vestingToken;
    TokenVestingHandler public handler;

    address public owner = makeAddr("user");

    // errors
    error TokenVestingTest__TransferFailed();

    // set up
    function setUp() public {
        vm.prank(owner);
        vestingToken = new VestingToken();

        vm.prank(owner);
        tokenVesting = new TokenVesting(address(vestingToken));

        vm.prank(owner);
        if (!vestingToken.transfer(address(tokenVesting), 1_000_000e18)) revert TokenVestingTest__TransferFailed();

        handler = new TokenVestingHandler(tokenVesting, owner, makeAddr("handlerBeneficiary"));
    }
}
