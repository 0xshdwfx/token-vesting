// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";

contract TokenVestingHandler is Test {
    TokenVesting public immutable tokenVesting;
    address public immutable owner;
    address public beneficiary;

    uint256 public constant ALLOCATION = 1000e18;
    uint256 public constant START_TIME = 1_000_000;
    uint256 public constant CLIFF_DURATION = 30 days;
    uint256 public constant VESTING_DURATION = 365 days;
    uint160 public beneficiaryCount;

    error TokenVestingHandler__AddressCounterOverflow();

    constructor(TokenVesting _tokenVesting, address _owner, address _beneficiary) {
        tokenVesting = _tokenVesting;
        owner = _owner;
        beneficiary = _beneficiary;
    }

    function addBeneficiary() external {
        if (beneficiaryCount == type(uint160).max) {
            revert TokenVestingHandler__AddressCounterOverflow();
        }

        beneficiaryCount += 1;

        beneficiary = address(beneficiaryCount);

        vm.prank(owner);

        tokenVesting.addBeneficiary(beneficiary, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }
}

