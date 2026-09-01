// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";

contract TokenVestingHandler is Test {
    TokenVesting public immutable TOKEN_VESTING;
    address public immutable OWNER;
    address public beneficiary;
    address[] public beneficiaries;

    uint256 public constant ALLOCATION = 1000e18;
    uint256 public constant START_TIME = 1_000_000;
    uint256 public constant CLIFF_DURATION = 30 days;
    uint256 public constant VESTING_DURATION = 365 days;
    uint160 public beneficiaryCount;
    bool public scheduleRevoked;
    bool public unvestedTokensReclaimed;

    error TokenVestingHandler__AddressCounterOverflow();

    constructor(TokenVesting _tokenVesting, address _owner, address _beneficiary) {
        TOKEN_VESTING = _tokenVesting;
        OWNER = _owner;
        beneficiary = _beneficiary;
    }

    function addBeneficiary() external {
        if (beneficiaryCount == type(uint160).max) {
            revert TokenVestingHandler__AddressCounterOverflow();
        }

        beneficiaryCount += 1;

        beneficiary = address(beneficiaryCount);

        vm.prank(OWNER);

        TOKEN_VESTING.addBeneficiary(beneficiary, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
        beneficiaries.push(beneficiary);
    }

    function claimVestedTokens() external {
        if (beneficiaries.length == 0) return;

        uint256 claimableAmountBeforeWarp = TOKEN_VESTING.getClaimableAmount(beneficiaries[0]);

        vm.warp(block.timestamp + 10 days);

        uint256 claimableAmountAfterWarp = TOKEN_VESTING.getClaimableAmount(beneficiaries[0]);

        if (claimableAmountAfterWarp > claimableAmountBeforeWarp) {
            TOKEN_VESTING.claimVestedTokens(beneficiaries[0]);
        }
    }

    function revokeSchedule() external {
        if (beneficiaries.length == 0 || scheduleRevoked) return;

        scheduleRevoked = true;

        vm.prank(OWNER);
        TOKEN_VESTING.revokeSchedule(beneficiaries[0]);
    }

    function reclaimUnvestedTokens() external {
        if (beneficiaries.length == 0) return;

        if (scheduleRevoked == false) return;

        if (unvestedTokensReclaimed) return;

        vm.prank(OWNER);

        TOKEN_VESTING.reclaimUnvestedTokens(beneficiaries[0]);

        unvestedTokensReclaimed = true;
    }

    function claimRevokedBeneficiary() external {
        if (beneficiaries.length == 0) return;

        if (scheduleRevoked == false) return;

        uint256 claimableAmount = TOKEN_VESTING.getClaimableAmount(beneficiaries[0]);

        if (claimableAmount == 0) return;

        TOKEN_VESTING.claimVestedTokens(beneficiaries[0]);
    }
}

