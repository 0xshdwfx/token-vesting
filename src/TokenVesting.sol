// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

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
contract TokenVesting is Ownable, Pausable {
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
        bool unvestedTokensReclaimed;
        uint256 amountVestedAtRevocation;
    }

    ////////////////////////
    /// State Variables ///
    //////////////////////

    IERC20 public immutable VESTING_TOKEN;
    mapping(address beneficiary => VestingSchedule) public vestingSchedules;
    address[] public beneficiaries;
    uint256 public totalOutstandingAllocation;

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
    event TokensClaimed(address indexed beneficiary, uint256 tokenAmountClaimed);
    event UnvestedTokensReclaimed(address beneficiary, uint256 amountReclaimed);
    event ExcessTokensWithdrawn(uint256 excessWithdrawn);

    /////////////////
    /// Errors //////
    /////////////////

    error TokenVesting__InvalidToken();
    error TokenVesting__InvalidBeneficiaryAddress();
    error TokenVesting__InvalidAllocationAmount();
    error TokenVesting__InvalidStartTime();
    error TokenVesting__InvalidVestingDuration();
    error TokenVesting__CliffDurationIsGreaterThanVestingDuration();
    error TokenVesting__InsufficientFunding();
    error TokenVesting__BeneficiaryAlreadyExists(address beneficiary);
    error TokenVesting__ScheduleAlreadyRevoked();
    error TokenVesting__BeneficiaryDoesNotExist(address beneficiary);
    error TokenVesting__ZeroTokensToClaim();
    error TokenVesting__UnvestedTokensAlreadyReclaimed();
    error TokenVesting__ScheduleNotRevoked();
    error TokenVesting__NothingToReclaim();
    error TokenVesting__ContractUnderfunded();
    error TokenVesting__NoExcessTokensToWithdraw();

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
     * @custom:error TokenVesting__InsufficientFunding if the contract balance cannot cover all outstanding allocations.
     */
    function addBeneficiary(
        address beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external whenNotPaused onlyOwner {
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

        // validate contract has enough tokens
        uint256 newTotalVestingAllocation = totalOutstandingAllocation + totalAllocation;

        if (VESTING_TOKEN.balanceOf(address(this)) < newTotalVestingAllocation) {
            revert TokenVesting__InsufficientFunding();
        }

        // create VestingSchedule struct and store in mapping
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAllocation: totalAllocation,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            amountClaimed: 0,
            revoked: false,
            unvestedTokensReclaimed: false,
            amountVestedAtRevocation: 0
        });

        // add beneficiary to array for enumeration
        beneficiaries.push(beneficiary);

        // track total allocation across all beneficiaries
        totalOutstandingAllocation += totalAllocation;

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
    function revokeSchedule(address beneficiary) external whenNotPaused onlyOwner {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        if (userVestingSchedule.revoked == true) revert TokenVesting__ScheduleAlreadyRevoked();
        if (userVestingSchedule.totalAllocation == 0) {
            revert TokenVesting__BeneficiaryDoesNotExist(beneficiary);
        }

        userVestingSchedule.amountVestedAtRevocation = getVestedAmount(beneficiary);

        userVestingSchedule.revoked = true;

        emit BeneficiaryVestingScheduleRevoked(beneficiary, userVestingSchedule.amountVestedAtRevocation);
    }

    /**
     * @notice Claims and transfers vested tokens to a beneficiary.
     * @dev Anyone can call this function on behalf of a beneficiary. The claimed
     *      tokens are always transferred directly to the beneficiary address and
     *      cannot be redirected to the caller. Calculates the claimable amount as
     *      the difference between the total vested amount and the amount already
     *      claimed. Uses SafeERC20 for the token transfer and updates the
     *      beneficiary's claimed amount and total outstanding allocation.
     * @param beneficiary Address of the beneficiary whose vested tokens are being
     *        claimed.
     * @return vestedTokensClaimed The amount of vested tokens transferred to the
     *         beneficiary.
     * @custom:error TokenVesting__BeneficiaryDoesNotExist if the beneficiary has no
     *         vesting schedule.
     * @custom:error TokenVesting__ZeroTokensToClaim if no tokens are currently
     *         claimable.
     * @custom:error Pausable.EnforcedPause if the contract is paused.
     */
    function claimVestedTokens(address beneficiary) external whenNotPaused returns (uint256) {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        if (userVestingSchedule.totalAllocation == 0) {
            revert TokenVesting__BeneficiaryDoesNotExist(beneficiary);
        }

        uint256 totalVested =
            userVestingSchedule.revoked ? userVestingSchedule.amountVestedAtRevocation : getVestedAmount(beneficiary);

        uint256 vestedTokensClaimed = totalVested - userVestingSchedule.amountClaimed;

        if (vestedTokensClaimed == 0) revert TokenVesting__ZeroTokensToClaim();

        userVestingSchedule.amountClaimed += vestedTokensClaimed;
        totalOutstandingAllocation -= vestedTokensClaimed;

        VESTING_TOKEN.safeTransfer(beneficiary, vestedTokensClaimed);

        emit TokensClaimed(beneficiary, vestedTokensClaimed);

        return vestedTokensClaimed;
    }

    /**
     * @notice  Recovers unvested tokens from a revoked beneficiary's allocation.
     * @dev     Only the contract owner can call this function. Transfers unvested tokens
     *          (totalAllocation - amountVestedAtRevocation) back to the owner. Validates that
     *          the beneficiary exists, their schedule is revoked, and there are tokens to recover.
     *          Emits UnvestedTokensReclaimed event for transparency.
     * @param   beneficiary Address of the revoked beneficiary whose unvested tokens will be recovered.
     * @custom:error TokenVesting__BeneficiaryDoesNotExist if beneficiary has no vesting schedule.
     * @custom:error TokenVesting__ScheduleNotRevoked if the beneficiary's schedule is not revoked.
     * @custom:error TokenVesting__NothingToReclaim if all tokens were vested before revocation.
     */
    function reclaimUnvestedTokens(address beneficiary) external whenNotPaused onlyOwner {
        VestingSchedule storage userVestingSchedule = vestingSchedules[beneficiary];

        if (userVestingSchedule.totalAllocation == 0) {
            revert TokenVesting__BeneficiaryDoesNotExist(beneficiary);
        }

        if (userVestingSchedule.revoked == false) revert TokenVesting__ScheduleNotRevoked();

        uint256 amountToReclaim = userVestingSchedule.totalAllocation - userVestingSchedule.amountVestedAtRevocation;

        if (amountToReclaim == 0) revert TokenVesting__NothingToReclaim();

        if (userVestingSchedule.unvestedTokensReclaimed) {
            revert TokenVesting__UnvestedTokensAlreadyReclaimed();
        }

        userVestingSchedule.unvestedTokensReclaimed = true;
        totalOutstandingAllocation -= amountToReclaim;

        VESTING_TOKEN.safeTransfer(owner(), amountToReclaim);

        emit UnvestedTokensReclaimed(beneficiary, amountToReclaim);
    }

    /**
     * @notice  Allows the owner to withdraw tokens that exceed the total vesting allocation.
     * @dev     Calculates excess as contract balance minus totalOutstandingAllocation. Validates that
     *          contract holds at least the allocated amount (invariant check). Only unallocated tokens
     *          (accidentally sent or no longer needed) can be withdrawn. Beneficiary allocations are
     *          fully protected. Reverts if contract is underfunded or no excess tokens are available.
     *          Emits ExcessTokensWithdrawn event for transparency.
     * @custom:error TokenVesting__ContractUnderfunded if contract balance is less than totalOutstandingAllocation.
     * @custom:error TokenVesting__NoExcessTokensToWithdraw if contract balance equals totalOutstandingAllocation.
     */
    function withdrawExcessTokens() external onlyOwner {
        uint256 contractBalance = VESTING_TOKEN.balanceOf(address(this));

        if (contractBalance < totalOutstandingAllocation) {
            revert TokenVesting__ContractUnderfunded();
        }

        uint256 excess = contractBalance - totalOutstandingAllocation;

        if (excess == 0) revert TokenVesting__NoExcessTokensToWithdraw();

        VESTING_TOKEN.safeTransfer(owner(), excess);

        emit ExcessTokensWithdrawn(excess);
    }

    /**
     * @notice Pauses contract operations.
     * @dev Only the contract owner can call this function. While paused, functions
     *      protected by the `whenNotPaused` modifier cannot be executed. This
     *      provides an emergency mechanism to temporarily stop sensitive operations.
     * @custom:error OwnableUnauthorizedAccount if the caller is not the owner.
     * @custom:error EnforcedPause if the contract is already paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes contract operations.
     * @dev Only the contract owner can call this function. Functions protected by
     *      the `whenNotPaused` modifier become executable again after the contract
     *      is unpaused.
     * @custom:error OwnableUnauthorizedAccount if the caller is not the owner.
     * @custom:error ExpectedPause if the contract is not currently paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    ////////////////////////////
    ///// Getter Functions /////
    ///////////////////////////

    function getBeneficiariesLength() external view returns (uint256) {
        return beneficiaries.length;
    }

    function getVestingSchedule(address beneficiary) external view returns (VestingSchedule memory) {
        return vestingSchedules[beneficiary];
    }
}
