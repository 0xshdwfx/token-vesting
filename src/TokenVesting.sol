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
    }

    ////////////////////////
    /// State Variables ///
    //////////////////////

    IERC20 public immutable VESTING_TOKEN;

    /////////////////
    /// Events //////
    /////////////////

    /////////////////
    /// Errors //////
    /////////////////

    error TokenVesting__InvalidToken();

    //////////////////////
    //// Constructor ////
    ////////////////////

    constructor(address _vestingToken) Ownable(msg.sender) {
        if (_vestingToken == address(0)) revert TokenVesting__InvalidToken();
        VESTING_TOKEN = IERC20(_vestingToken);
    }
}
