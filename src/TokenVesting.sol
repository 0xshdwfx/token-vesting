// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author  0xshdwfx
 * @title   TokenVesting
 * @dev     Manages time-locked token vesting schedules for multiple beneficiaries.
 *          Implements cliff-based and linear vesting mechanics with granular control
 *          over token release. Supports admin revocation with clawback of unvested
 *          allocations. Uses SafeERC20 for safe token transfers and custom errors
 *          for gas-efficient validation.
 * @notice  Beneficiaries can claim vested tokens at any time after cliff expiration.
 *          Contract owner can add beneficiaries with custom vesting schedules and
 *          revoke schedules to recover unvested tokens. All vesting calculations are
 *          linear after the cliff period.
 */
contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;

    ///////////////
    /// Types ////
    //////////////

    struct VestingSchedule {
        uint256 totalAllocation;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 amountClaimed;
        bool revoked;
        uint256 amountVestedAtRevocation;
    }

    ////////////////////////
    /// State Variables ///
    //////////////////////

    IERC20 public immutable VESTING_TOKEN;
    mapping(address beneficiary => VestingSchedule) public vestingSchedules;
    address[] public beneficiaries;
    uint256 public totalVestingAllocation;

    /////////////////
    /// Events //////
    /////////////////

    event BeneficiaryAdded(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );
    event BeneficiaryVestingScheduleRevoked(address indexed beneficiary, uint256 amountVestedAtRevocation);

    /////////////////
    /// Errors //////
    /////////////////

    error TokenVesting__InvalidToken();
    error TokenVesting__InvalidBeneficiaryAddress();
    error TokenVesting__InvalidAllocationAmount();
    error TokenVesting__InvalidStartTime();
    error TokenVesting__InvalidVestingDuration();
    error TokenVesting__CliffDurationIsGreaterThanVestingDuration();
    error TokenVesting__BeneficiaryAlreadyExists(address beneficiary);
    error TokenVesting__ScheduleAlreadyRevoked();
    error TokenVesting__BeneficiaryDoesNotExist(address beneficiary);

    //////////////////////
    //// Constructor ////
    ////////////////////

    /**
     * @notice  Initialises the TokenVesting contract with the vesting token address.
     * @dev     Sets the contract owner to the deployer via Ownable. Validates that the
     *          provided token address is not the zero address to prevent contract bricking.
     *          VESTING_TOKEN is immutable and cannot be changed after deployment, ensuring
     *          security and gas efficiency.
     * @param   _vestingToken Address of the ERC20 token to be vested.
     * @custom:error TokenVesting__InvalidToken if _vestingToken is the zero address.
     */
    constructor(address _vestingToken) Ownable(msg.sender) {
        if (_vestingToken == address(0)) revert TokenVesting__InvalidToken();
        VESTING_TOKEN = IERC20(_vestingToken);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    /**
     * @notice  Adds a new beneficiary with a custom vesting schedule.
     * @dev     Only the contract owner can call this function. Creates a VestingSchedule
     *          struct with the provided parameters and stores it in the vestingSchedules
     *          mapping. Validates all inputs to ensure data integrity. Tracks total
     *          allocation to prevent over-allocation. Emits BeneficiaryAdded event.
     * @param   beneficiary Address of the beneficiary who will receive vested tokens.
     * @param   totalAllocation Total tokens allocated to this beneficiary over the full vesting period.
     * @param   startTime Timestamp when the vesting period begins.
     * @param   cliffDuration Duration in seconds before any tokens unlock.
     * @param   vestingDuration Total duration in seconds from start to 100% vested.
     * @custom:error TokenVesting__InvalidBeneficiaryAddress if beneficiary is zero address.
     * @custom:error TokenVesting__BeneficiaryAlreadyExists if beneficiary already has a vesting schedule.
     * @custom:error TokenVesting__InvalidAllocationAmount if totalAllocation is zero.
     * @custom:error TokenVesting__InvalidStartTime if startTime is zero.
     * @custom:error TokenVesting__InvalidVestingDuration if vestingDuration is zero.
     * @custom:error TokenVesting__CliffDurationIsGreaterThanVestingDuration if cliff >= vesting duration.
     */
    function addBeneficiary(
        address beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyOwner {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        // validate beneficiary address is not zero
        if (beneficiary == address(0)) revert TokenVesting__InvalidBeneficiaryAddress();

        // validate beneficiary doesn't already exist
        if (userVestingSchedule.totalAllocation != 0) {
            revert TokenVesting__BeneficiaryAlreadyExists(beneficiary);
        }

        // validate allocation amount is not zero
        if (totalAllocation == 0) revert TokenVesting__InvalidAllocationAmount();

        // validate start time is not zero
        if (startTime == 0) revert TokenVesting__InvalidStartTime();

        // validate vesting duration is not zero
        if (vestingDuration == 0) revert TokenVesting__InvalidVestingDuration();

        // validate cliff duration is not greater than or equal to vesting duration
        if (cliffDuration >= vestingDuration) {
            revert TokenVesting__CliffDurationIsGreaterThanVestingDuration();
        }

        // create VestingSchedule struct and store in mapping
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAllocation: totalAllocation,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            amountClaimed: 0,
            revoked: false,
            amountVestedAtRevocation: 0
        });

        // add beneficiary to array for enumeration
        beneficiaries.push(beneficiary);

        // track total allocation across all beneficiaries
        totalVestingAllocation += totalAllocation;

        // emit event to log beneficiary addition
        emit BeneficiaryAdded(beneficiary, totalAllocation, startTime, cliffDuration, vestingDuration);
    }

    /**
     * @notice  Calculates the total amount of tokens that have vested for a beneficiary.
     * @dev     Returns zero if the beneficiary does not exist, the schedule is revoked,
     *          or the cliff period has not yet expired. Returns the full totalAllocation
     *          once the entire vesting duration has elapsed. For timestamps between cliff
     *          expiration and vesting period end, calculates a linear vesting amount based
     *          on elapsed time as a fraction of the total vesting duration.
     * @param   beneficiary Address of the beneficiary to query.
     * @return  Total amount of tokens vested at block.timestamp, in wei. Does not account
     *          for tokens already claimed.
     */
    function getVestedAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        // check if beneficiary exists, if totalAllocation is not 0, they have a vesting schedule
        if (userVestingSchedule.totalAllocation == 0) return 0;

        // check if schedule has been revoked
        if (userVestingSchedule.revoked == true) return 0;

        // return 0 if cliff has not expired yet
        uint256 cliffEnd = userVestingSchedule.startTime + userVestingSchedule.cliffDuration;
        if (block.timestamp < cliffEnd) {
            return 0;
        }

        // return totalAllocation if vestingDuration has passed
        uint256 vestingPeriodEnd = userVestingSchedule.startTime + userVestingSchedule.vestingDuration;
        if (block.timestamp > vestingPeriodEnd) return userVestingSchedule.totalAllocation;

        // get fraction of vesting that has occured
        uint256 vestedAmount = (userVestingSchedule.totalAllocation * (block.timestamp - userVestingSchedule.startTime))
            / userVestingSchedule.vestingDuration;

        return vestedAmount;
    }

    /**
     * @notice  Revokes a beneficiary's vesting schedule, preventing future vesting.
     * @dev     Only the contract owner can call this function. Captures the vested amount
     *          at the time of revocation, allowing the beneficiary to claim tokens vested
     *          up to that moment. Future vesting stops immediately upon revocation.
     *          Emits BeneficiaryVestingScheduleRevoked event with the claimable amount.
     * @param   beneficiary Address of the beneficiary whose vesting schedule will be revoked.
     * @custom:error TokenVesting__BeneficiaryDoesNotExist if beneficiary has no vesting schedule.
     * @custom:error TokenVesting__ScheduleAlreadyRevoked if the schedule is already revoked.
     */
    function revokeSchedule(address beneficiary) external onlyOwner {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        if (userVestingSchedule.revoked == true) revert TokenVesting__ScheduleAlreadyRevoked();
        if (userVestingSchedule.totalAllocation == 0) {
            revert TokenVesting__BeneficiaryDoesNotExist(beneficiary);
        }

        userVestingSchedule.revoked = true;

        userVestingSchedule.amountVestedAtRevocation = getVestedAmount(beneficiary);

        emit BeneficiaryVestingScheduleRevoked(beneficiary, userVestingSchedule.amountVestedAtRevocation);
    }

    ////////////////////////////
    ///// Getter Functions /////
    ///////////////////////////

    function getBeneficiariesLength() external view returns (uint256) {
        return beneficiaries.length;
    }

    function getTotalVestingAllocation() external view returns (uint256) {
        return totalVestingAllocation;
    }
}
