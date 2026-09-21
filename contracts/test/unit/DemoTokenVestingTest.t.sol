// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {DemoTokenVesting} from "../../src/DemoTokenVesting.sol";
import {VestingToken} from "../../src/VestingToken.sol";

contract DemoTokenVestingTest is Test {
    DemoTokenVesting private demoVesting;
    VestingToken private demoToken;

    address private visitor = makeAddr("visitor");
    address private secondVisitor = makeAddr("secondVisitor");

    uint256 private constant INITIAL_FUNDING = 100e18;

    function setUp() external {
        demoToken = new VestingToken();
        demoVesting = new DemoTokenVesting(address(demoToken));

        demoToken.transfer(address(demoVesting), INITIAL_FUNDING);
    }

    function test_CreateDemoScheduleForCaller() external {
        vm.prank(visitor);

        demoVesting.createDemoSchedule();

        (
            uint256 totalAllocation,
            uint256 startTime,
            uint256 cliffDuration,
            uint256 vestingDuration,
            uint256 amountClaimed
        ) = demoVesting.vestingSchedules(visitor);

        assertEq(totalAllocation, demoVesting.DEMO_ALLOCATION());
        assertGt(startTime, 0);
        assertEq(cliffDuration, demoVesting.CLIFF_DURATION());
        assertEq(vestingDuration, demoVesting.VESTING_DURATION());
        assertEq(amountClaimed, 0);
        assertEq(demoVesting.totalSchedules(), 1);
        assertEq(demoVesting.totalOutstandingAllocation(), demoVesting.DEMO_ALLOCATION());
    }

    function test_RevertWhenCallerCreatesSecondSchedule() external {
        vm.startPrank(visitor);

        demoVesting.createDemoSchedule();

        vm.expectRevert(
            abi.encodeWithSelector(DemoTokenVesting.DemoTokenVesting__ScheduleAlreadyExists.selector, visitor)
        );

        demoVesting.createDemoSchedule();

        vm.stopPrank();
    }

    function test_RevertWhenContractIsInsufficientlyFunded() external {
        DemoTokenVesting unfundedDemoVesting = new DemoTokenVesting(address(demoToken));

        vm.expectRevert(DemoTokenVesting.DemoTokenVesting__InsufficientFunding.selector);

        vm.prank(visitor);
        unfundedDemoVesting.createDemoSchedule();
    }

    function test_NoTokensAreClaimableBeforeCliff() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        uint256 claimableAmount = demoVesting.getClaimableAmount(visitor);

        assertEq(claimableAmount, 0);
    }

    function test_ClaimPartialVestedAmountAfterCliff() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        vm.warp(block.timestamp + demoVesting.CLIFF_DURATION());

        uint256 claimableAmount = demoVesting.getClaimableAmount(visitor);

        assertGt(claimableAmount, 0);
        assertLt(claimableAmount, demoVesting.DEMO_ALLOCATION());

        uint256 balanceBefore = demoToken.balanceOf(visitor);

        vm.prank(visitor);
        demoVesting.claimDemoTokens();

        uint256 balanceAfter = demoToken.balanceOf(visitor);

        assertEq(balanceAfter - balanceBefore, claimableAmount);
    }

    function test_ClaimFullAllocationAfterVestingEnds() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        vm.warp(block.timestamp + demoVesting.VESTING_DURATION());

        vm.prank(visitor);
        demoVesting.claimDemoTokens();

        assertEq(demoToken.balanceOf(visitor), demoVesting.DEMO_ALLOCATION());

        assertEq(demoVesting.totalOutstandingAllocation(), 0);
    }

    function test_RevertWhenNothingIsClaimable() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        vm.expectRevert(DemoTokenVesting.DemoTokenVesting__NoTokensToClaim.selector);

        vm.prank(visitor);
        demoVesting.claimDemoTokens();
    }

    function test_ClaimsAlwaysTransferToScheduleBeneficiary() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        vm.warp(block.timestamp + demoVesting.VESTING_DURATION());

        uint256 visitorBalanceBefore = demoToken.balanceOf(visitor);
        uint256 secondVisitorBalanceBefore = demoToken.balanceOf(secondVisitor);

        vm.prank(secondVisitor);

        vm.expectRevert(DemoTokenVesting.DemoTokenVesting__NoTokensToClaim.selector);

        demoVesting.claimDemoTokens();

        vm.prank(visitor);
        demoVesting.claimDemoTokens();

        assertEq(demoToken.balanceOf(visitor) - visitorBalanceBefore, demoVesting.DEMO_ALLOCATION());

        assertEq(demoToken.balanceOf(secondVisitor), secondVisitorBalanceBefore);
    }

    function test_DifferentWalletsReceiveIndependentSchedules() external {
        vm.prank(visitor);
        demoVesting.createDemoSchedule();

        vm.prank(secondVisitor);
        demoVesting.createDemoSchedule();

        assertEq(demoVesting.totalSchedules(), 2);
        assertEq(demoVesting.totalOutstandingAllocation(), demoVesting.DEMO_ALLOCATION() * 2);

        assertTrue(demoVesting.hasDemoSchedule(visitor));
        assertTrue(demoVesting.hasDemoSchedule(secondVisitor));
    }
}
