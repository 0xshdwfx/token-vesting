// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";
import {VestingToken} from "../../src/VestingToken.sol";

contract TokenVestingTest is Test {
    TokenVesting public tokenVesting;
    VestingToken public vestingToken;

    address public owner = makeAddr("user");
    address public beneficiary1 = makeAddr("beneficiary1");
    address public beneficiary2 = makeAddr("beneficiary2");
    address public beneficiary3 = makeAddr("beneficiary3");

    uint256 public constant ALLOCATION = 1000e18;
    uint256 public constant START_TIME = 1_000_000;
    uint256 public constant CLIFF_DURATION = 30 days;
    uint256 public constant VESTING_DURATION = 365 days;

    error TokenVestingTest__TransferFailed();

    event BeneficiaryAdded(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );

    function setUp() public {
        vm.prank(owner);
        vestingToken = new VestingToken();

        vm.prank(owner);
        tokenVesting = new TokenVesting(address(vestingToken));

        vm.prank(owner);
        if (!vestingToken.transfer(address(tokenVesting), 1_000_000e18)) revert TokenVestingTest__TransferFailed();
    }

    //////////////////////
    /// addBeneficiary ///
    //////////////////////

    function testAddBeneficiaryRevertsIfBeneficiaryIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__InvalidBeneficiaryAddress.selector);
        tokenVesting.addBeneficiary(address(0), ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }
}
