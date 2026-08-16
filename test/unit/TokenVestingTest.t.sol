// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
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

    // events
    event BeneficiaryAdded(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );

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
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    function test_Constructor_Reverts_WhenVestingTokenAddressIsZero() public {
        vm.expectRevert(TokenVesting.TokenVesting__InvalidToken.selector);
        new TokenVesting(address(0));
    }

    //////////////////////
    /// addBeneficiary ///
    //////////////////////

    function test_AddBeneficiary_Reverts_WhenBeneficiaryIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__InvalidBeneficiaryAddress.selector);
        tokenVesting.addBeneficiary(address(0), ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }

    function test_AddBeneficiary_Reverts_WhenBeneficiaryAlreadyExists() public {
        vm.startPrank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.expectRevert(
            abi.encodeWithSelector(TokenVesting.TokenVesting__BeneficiaryAlreadyExists.selector, beneficiary1)
        );
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.stopPrank();
    }

    function test_AddBeneficiary_Reverts_WhenAllocationIsZero() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__InvalidAllocationAmount.selector);
        tokenVesting.addBeneficiary(beneficiary1, 0, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }

    function test_AddBeneficiary_Reverts_WhenStartTimeIsZero() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__InvalidStartTime.selector);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, 0, CLIFF_DURATION, VESTING_DURATION);
    }

    function test_AddBeneficiary_Reverts_WhenVestingDurationIsZero() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__InvalidVestingDuration.selector);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, 0);
    }

    function test_AddBeneficiary_Reverts_WhenCliffDurationIsGreaterThanVestingDuration() public {
        vm.prank(owner);
        vm.expectRevert(TokenVesting.TokenVesting__CliffDurationIsGreaterThanVestingDuration.selector);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, 10 days);
    }

    function test_AddBeneficiary_StoresBeneficiary_WhenValid() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
        assertEq(tokenVesting.beneficiaries(0), beneficiary1, "First beneficiary at index 0");
        assertEq(tokenVesting.getBeneficiariesLength(), 1, "Total length is 1");
    }

    function test_AddBeneficiary_StoresMultipleBeneficiaries_WhenMultipleAdded() public {
        vm.startPrank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
        tokenVesting.addBeneficiary(beneficiary2, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
        tokenVesting.addBeneficiary(beneficiary3, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.stopPrank();

        assertEq(tokenVesting.beneficiaries(0), beneficiary1, "First beneficiary at index 0");
        assertEq(tokenVesting.beneficiaries(1), beneficiary2, "Second beneficiary at index 1");
        assertEq(tokenVesting.beneficiaries(2), beneficiary3, "Third beneficiary at index 2");
        assertEq(tokenVesting.getBeneficiariesLength(), 3, "Total length is 3");
    }

    function test_AddBeneficiary_IncreasesTotalVestingAllocation_WhenBeneficiaryAdded() public {
        vm.startPrank(owner);

        uint256 totalVestingAllocationBeforeBeneficiaryAdded = tokenVesting.getTotalVestingAllocation();

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 totalVestingAllocationAfterBeneficiaryAdded = tokenVesting.getTotalVestingAllocation();

        vm.stopPrank();

        assertEq(
            totalVestingAllocationAfterBeneficiaryAdded,
            totalVestingAllocationBeforeBeneficiaryAdded + ALLOCATION,
            "totalVestingAllocation should increase by exactly ALLOCATION"
        );
    }

    function test_AddBeneficiary_EmitsBeneficiaryAddedEvent_WhenValidBeneficiaryAdded() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true, address(tokenVesting));
        emit BeneficiaryAdded(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }

    ////////////////////////
    /// getVestedAmount ///
    //////////////////////

    function test_GetVestedAmount_ReturnsZero_WhenBeneficiaryDoesNotExist() public view {
        uint256 vestedAmount = tokenVesting.getVestedAmount(beneficiary1);
        assertEq(vestedAmount, 0, "getVestedAmount should return 0 when does not exist");
    }

    function test_GetVestedAmount_ReturnsZero_WhenBeneficiaryVestingScheduleHasBeenRevoked() public {
        vm.startPrank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        tokenVesting.revokeSchedule(beneficiary1);

        vm.stopPrank();

        uint256 vestedAmount = tokenVesting.getVestedAmount(beneficiary1);
        assertEq(vestedAmount, 0, "getVestedAmount should return 0 when schedule has been revoked");
    }

    function test_GetVestedAmount_ReturnsZero_WhenCliffHasNotExpired() public {
        vm.prank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 cliffEnd = START_TIME + CLIFF_DURATION;
        vm.warp(cliffEnd - 1);

        uint256 vestedAmount = tokenVesting.getVestedAmount(beneficiary1);
        assertEq(vestedAmount, 0, "getVestedAmount should return 0 when cliff has not expired");
    }

    function test_GetVestedAmount_ReturnsTotalAllocation_WhenVestingDurationHasPassed() public {
        vm.prank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 vestingPeriodEnd = START_TIME + VESTING_DURATION;
        vm.warp(vestingPeriodEnd + 1);

        uint256 vestedAmount = tokenVesting.getVestedAmount(beneficiary1);
        assertEq(
            vestedAmount, ALLOCATION, "getVestedAmount should return total allocation when vesting duration has passed"
        );
    }

    function test_GetVestedAmount_ReturnsLinearVestedAmount_WhenBetweenCliffAndEnd() public {
        vm.prank(owner);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        // calculate a time between after cliff and before vesting end
        uint256 midVestingTime = START_TIME + CLIFF_DURATION + (VESTING_DURATION / 2);

        vm.warp(midVestingTime);

        uint256 fractionOfVested = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        uint256 vestedAmount = tokenVesting.getVestedAmount(beneficiary1);
        assertEq(vestedAmount, fractionOfVested, "getVestedAmount should return the amount vested at this time");
    }

    ///////////////////////
    /// revokeSchedule ///
    /////////////////////

    function test_RevokeSchedule_Reverts_WhenBeneficiaryIsAlreadyRevoked() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        // initial revoke state = false
        // first call changes revoke state = true
        tokenVesting.revokeSchedule(beneficiary1);

        vm.expectRevert(TokenVesting.TokenVesting__ScheduleAlreadyRevoked.selector);

        // second call tests revert if revoke stake = true
        tokenVesting.revokeSchedule(beneficiary1);

        vm.stopPrank();
    }
}

