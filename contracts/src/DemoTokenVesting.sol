// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author 0xshdwfx
 * @title DemoTokenVesting
 * @notice Self-service vesting contract for the public Sepolia demonstration.
 *         Each wallet can create one fixed-size vesting schedule for itself.
 *         This contract has no owner or administrative functions.
 */
contract DemoTokenVesting {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        uint256 totalAllocation;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 amountClaimed;
    }

    IERC20 public immutable DEMO_TOKEN;

    uint256 public constant DEMO_ALLOCATION = 1e18;
    uint256 public constant CLIFF_DURATION = 60 seconds;
    uint256 public constant VESTING_DURATION = 10 minutes;
    uint256 public constant MAX_DEMO_SCHEDULES = 100;
    uint256 public constant MAX_TOTAL_ALLOCATION = DEMO_ALLOCATION * MAX_DEMO_SCHEDULES;

    mapping(address beneficiary => VestingSchedule) public vestingSchedules;

    uint256 public totalSchedules;
    uint256 public totalOutstandingAllocation;

    event DemoScheduleCreated(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );

    event DemoTokensClaimed(address indexed beneficiary, uint256 amountClaimed);

    error DemoTokenVesting__InvalidToken();
    error DemoTokenVesting__ScheduleAlreadyExists(address beneficiary);
    error DemoTokenVesting__MaximumSchedulesReached();
    error DemoTokenVesting__InsufficientFunding();
    error DemoTokenVesting__NoTokensToClaim();

    constructor(address demoToken) {
        if (demoToken == address(0)) {
            revert DemoTokenVesting__InvalidToken();
        }

        DEMO_TOKEN = IERC20(demoToken);
    }

    /**
     * @notice Creates one fixed demo schedule for the connected wallet.
     * @dev The beneficiary is always msg.sender. Visitors cannot choose another
     *      beneficiary, allocation, start time, or duration.
     */
    function createDemoSchedule() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];

        if (schedule.totalAllocation != 0) {
            revert DemoTokenVesting__ScheduleAlreadyExists(msg.sender);
        }

        if (totalSchedules >= MAX_DEMO_SCHEDULES) {
            revert DemoTokenVesting__MaximumSchedulesReached();
        }

        uint256 newOutstandingAllocation = totalOutstandingAllocation + DEMO_ALLOCATION;

        if (DEMO_TOKEN.balanceOf(address(this)) < newOutstandingAllocation) {
            revert DemoTokenVesting__InsufficientFunding();
        }

        uint256 startTime = block.timestamp;

        vestingSchedules[msg.sender] = VestingSchedule({
            totalAllocation: DEMO_ALLOCATION,
            startTime: startTime,
            cliffDuration: CLIFF_DURATION,
            vestingDuration: VESTING_DURATION,
            amountClaimed: 0
        });

        totalSchedules += 1;
        totalOutstandingAllocation = newOutstandingAllocation;

        emit DemoScheduleCreated(msg.sender, DEMO_ALLOCATION, startTime, CLIFF_DURATION, VESTING_DURATION);
    }

    /**
     * @notice Claims vested demo tokens for the connected wallet.
     */
    function claimDemoTokens() external returns (uint256 amountClaimed) {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];

        if (schedule.totalAllocation == 0) {
            revert DemoTokenVesting__NoTokensToClaim();
        }

        uint256 totalVested = _getVestedAmount(schedule);
        amountClaimed = totalVested - schedule.amountClaimed;

        if (amountClaimed == 0) {
            revert DemoTokenVesting__NoTokensToClaim();
        }

        schedule.amountClaimed += amountClaimed;
        totalOutstandingAllocation -= amountClaimed;

        DEMO_TOKEN.safeTransfer(msg.sender, amountClaimed);

        emit DemoTokensClaimed(msg.sender, amountClaimed);
    }

    /**
     * @notice Returns whether a wallet has created a demo schedule.
     */
    function hasDemoSchedule(address beneficiary) external view returns (bool) {
        return vestingSchedules[beneficiary].totalAllocation != 0;
    }

    /**
     * @notice Returns the connected wallet's current claimable amount.
     */
    function getClaimableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        if (schedule.totalAllocation == 0) {
            return 0;
        }

        uint256 totalVested = _getVestedAmount(schedule);

        return totalVested - schedule.amountClaimed;
    }

    /**
     * @notice Returns the vesting schedule for a wallet.
     */
    function getVestingSchedule(address beneficiary) external view returns (VestingSchedule memory) {
        return vestingSchedules[beneficiary];
    }

    function _getVestedAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        uint256 cliffEnd = schedule.startTime + schedule.cliffDuration;

        if (block.timestamp < cliffEnd) {
            return 0;
        }

        uint256 vestingEnd = schedule.startTime + schedule.vestingDuration;

        if (block.timestamp >= vestingEnd) {
            return schedule.totalAllocation;
        }

        return (schedule.totalAllocation * (block.timestamp - schedule.startTime)) / schedule.vestingDuration;
    }
}
