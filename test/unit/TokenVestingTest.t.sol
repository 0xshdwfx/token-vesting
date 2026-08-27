// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";
import {VestingToken} from "../../src/VestingToken.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVestingTest is Test {
    TokenVesting public tokenVesting;
    VestingToken public vestingToken;

    address public owner = makeAddr("user");
    address public beneficiary1 = makeAddr("beneficiary1");
    address public beneficiary2 = makeAddr("beneficiary2");
    address public beneficiary3 = makeAddr("beneficiary3");
    address public nonOwner = makeAddr("nonOwner");

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
    event BeneficiaryVestingScheduleRevoked(address indexed beneficiary, uint256 amountVestedAtRevocation);
    event TokensClaimed(address indexed beneficiary, uint256 tokenAmountClaimed);
    event UnvestedTokensReclaimed(address beneficiary, uint256 amountReclaimed);
    event ExcessTokensWithdrawn(uint256 excessWithdrawn);

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

    function test_AddBeneficiary_Reverts_WhenContractBalanceIsLessThanNewTotalOutstandingAllocation() public {
        vm.startPrank(owner);

        vm.expectRevert(TokenVesting.TokenVesting__InsufficientFunding.selector);

        tokenVesting.addBeneficiary(beneficiary1, 1_000_001e18, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.stopPrank();
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

    function test_AddBeneficiary_IncreasesTotalOutstandingAllocation_WhenBeneficiaryAdded() public {
        vm.startPrank(owner);

        uint256 totalOutstandingAllocationBeforeBeneficiaryAdded = tokenVesting.totalOutstandingAllocation();

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 totalOutstandingAllocationAfterBeneficiaryAdded = tokenVesting.totalOutstandingAllocation();

        vm.stopPrank();

        assertEq(
            totalOutstandingAllocationAfterBeneficiaryAdded,
            totalOutstandingAllocationBeforeBeneficiaryAdded + ALLOCATION,
            "totalOutstandingAllocation should increase by exactly ALLOCATION"
        );
    }

    function test_AddBeneficiary_EmitsBeneficiaryAddedEvent_WhenValidBeneficiaryAdded() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true, address(tokenVesting));
        emit BeneficiaryAdded(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }

    function test_AddBeneficiary_Reverts_WhenPaused() public {
        vm.prank(owner);
        tokenVesting.pause();

        vm.prank(owner);

        vm.expectRevert(Pausable.EnforcedPause.selector);

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);
    }

    function test_AddBeneficiary_Works_WhenUnpaused() public {
        vm.startPrank(owner);
        tokenVesting.pause();

        tokenVesting.unpause();

        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.stopPrank();

        assertEq(
            tokenVesting.getVestingSchedule(beneficiary1).totalAllocation,
            ALLOCATION,
            "beneficiary schedule should be created after unpausing"
        );
    }

    ////////////////////////
    /// getVestedAmount ///
    //////////////////////

    function test_GetVestedAmount_ReturnsZero_WhenBeneficiaryDoesNotExist() public {
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
        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
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

    function test_RevokeSchedule_Reverts_WhenBeneficiaryDoesNotExist() public {
        vm.prank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(TokenVesting.TokenVesting__BeneficiaryDoesNotExist.selector, beneficiary1)
        );

        tokenVesting.revokeSchedule(beneficiary1);
    }

    function test_RevokeSchedule_EmitsBeneficiaryVestingScheduleRevokedEvent_WhenScheduleRevoked() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 expectedAmountVestedAtRevocation = tokenVesting.getVestedAmount(beneficiary1);

        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit BeneficiaryVestingScheduleRevoked(beneficiary1, expectedAmountVestedAtRevocation);

        tokenVesting.revokeSchedule(beneficiary1);

        vm.stopPrank();
    }

    function test_RevokeSchedule_Reverts_WhenPaused() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        tokenVesting.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);

        tokenVesting.revokeSchedule(beneficiary1);

        vm.stopPrank();
    }

    //////////////////////////
    /// claimVestedTokens ///
    ////////////////////////

    function test_ClaimVestedTokens_Reverts_WhenBeneficiaryDoesNotExist() public {
        vm.expectRevert(
            abi.encodeWithSelector(TokenVesting.TokenVesting__BeneficiaryDoesNotExist.selector, beneficiary1)
        );

        tokenVesting.claimVestedTokens(beneficiary1);
    }

    function test_ClaimVestedTokens_AllowsRevokedBeneficiary_ToClaimVestedAtRevocationAmount() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.revokeSchedule(beneficiary1);

        uint256 vestingTokenBalanceBeforeTransfer = vestingToken.balanceOf(address(tokenVesting));
        uint256 revokedBeneficiaryBalanceBeforeTransfer = vestingToken.balanceOf(address(beneficiary1));

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 vestingTokenBalanceAfterTransfer = vestingToken.balanceOf(address(tokenVesting));
        uint256 revokedBeneficiaryBalanceAfterTransfer = vestingToken.balanceOf(address(beneficiary1));

        uint256 amountClaimed = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        vm.stopPrank();

        assertEq(
            vestingTokenBalanceAfterTransfer,
            vestingTokenBalanceBeforeTransfer - amountClaimed,
            "contract vestingToken balance should decrease by amount claimed"
        );
        assertEq(
            revokedBeneficiaryBalanceAfterTransfer,
            revokedBeneficiaryBalanceBeforeTransfer + amountClaimed,
            "revoked beneficiary balance should increase by amount claimed"
        );
    }

    function test_ClaimVestedTokens_ReturnsCorrectAmount_WhenMidVesting() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 fractionOfVested = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        uint256 vestedAmountClaimed = tokenVesting.claimVestedTokens(beneficiary1);

        assertEq(fractionOfVested, vestedAmountClaimed, "claimVestedTokens should return correct vested fraction");
    }

    function test_ClaimVestedTokens_Reverts_WhenVestedTokensClaimedEqualsZero() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        // attempting to claim before cliff expires - getVestedAmount() returns 0
        // already claimed is 0, so difference is 0
        uint256 cliffEnd = START_TIME + CLIFF_DURATION;
        vm.warp(cliffEnd - 1);

        vm.expectRevert(TokenVesting.TokenVesting__ZeroTokensToClaim.selector);

        tokenVesting.claimVestedTokens(beneficiary1);
    }

    function test_ClaimVestedTokens_UpdatesTotalOutstandingAllocation_WhenClaiming() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 totalOutstandingAllocationBeforeClaiming = tokenVesting.totalOutstandingAllocation();

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 totalOutstandingAllocationAfterClaiming = tokenVesting.totalOutstandingAllocation();

        uint256 amountClaimed = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        vm.stopPrank();

        assertEq(
            totalOutstandingAllocationAfterClaiming,
            totalOutstandingAllocationBeforeClaiming - amountClaimed,
            "total outstanding allocation should decrease by amount claimed"
        );
    }

    function test_ClaimVestedTokens_TransfersTokensToBeneficiary_WhenClaimingMidVesting() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 vestingTokenBalanceBeforeTransfer = vestingToken.balanceOf(address(tokenVesting));
        uint256 beneficiaryBalanceBeforeTransfer = vestingToken.balanceOf(address(beneficiary1));

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 vestingTokenBalanceAfterTransfer = vestingToken.balanceOf(address(tokenVesting));
        uint256 beneficiaryBalanceAfterTransfer = vestingToken.balanceOf(address(beneficiary1));

        uint256 amountClaimed = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        vm.stopPrank();

        assertEq(
            vestingTokenBalanceAfterTransfer,
            vestingTokenBalanceBeforeTransfer - amountClaimed,
            "contract vestingToken balance should decrease by amount claimed"
        );
        assertEq(
            beneficiaryBalanceAfterTransfer,
            beneficiaryBalanceBeforeTransfer + amountClaimed,
            "beneficiary balance should increase by amount claimed"
        );
    }

    function test_ClaimVestedTokens_UpdatesAmountClaimed_WhenClaimingAtMidVesting() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 totalAmountClaimedBeforeBeneficiaryClaimed = tokenVesting.getVestingSchedule(beneficiary1).amountClaimed;

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 totalAmountClaimedAfterBeneficiaryClaimed = tokenVesting.getVestingSchedule(beneficiary1).amountClaimed;

        uint256 expectedClaimed = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        vm.stopPrank();

        assertEq(
            totalAmountClaimedAfterBeneficiaryClaimed,
            totalAmountClaimedBeforeBeneficiaryClaimed + expectedClaimed,
            "amountClaimed should increase by claimed amount"
        );
    }

    function test_ClaimVestedTokens_EmitsTokensClaimedEvent_WhenVestedTokensClaimed() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 amountClaimed = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit TokensClaimed(beneficiary1, amountClaimed);

        tokenVesting.claimVestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ClaimVestedTokens_Reverts_WhenPaused() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);

        tokenVesting.claimVestedTokens(beneficiary1);

        vm.stopPrank();
    }

    //////////////////////////////
    /// reclaimUnvestedTokens ///
    ////////////////////////////

    function test_ReclaimUnvestedTokens_Reverts_WhenBeneficiaryDoesNotExist() public {
        vm.startPrank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(TokenVesting.TokenVesting__BeneficiaryDoesNotExist.selector, beneficiary1)
        );

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ReclaimUnvestedTokens_Reverts_WhenScheduleIsNotRevoked() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.expectRevert(TokenVesting.TokenVesting__ScheduleNotRevoked.selector);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ReclaimUnvestedTokens_TransfersCorrectAmount_WhenRevokedAtMidVesting() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.revokeSchedule(beneficiary1);

        uint256 expectedReclaimableAmount = tokenVesting.getVestingSchedule(beneficiary1).totalAllocation
            - tokenVesting.getVestingSchedule(beneficiary1).amountVestedAtRevocation;

        uint256 ownerTokenBalanceBeforeReclaim = vestingToken.balanceOf(address(owner));

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        uint256 ownerTokenBalanceAfterReclaim = vestingToken.balanceOf(address(owner));

        vm.stopPrank();

        assertEq(
            ownerTokenBalanceAfterReclaim,
            ownerTokenBalanceBeforeReclaim + expectedReclaimableAmount,
            "owner's token balance should increase by the expected reclaimable amount"
        );
    }

    function test_ReclaimUnvestedTokens_Reverts_WhenAmountToReclaimIsZero() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        // warp to 100% vested
        uint256 vestingPeriodEnd = START_TIME + VESTING_DURATION;
        vm.warp(vestingPeriodEnd);

        tokenVesting.revokeSchedule(beneficiary1);

        vm.expectRevert(TokenVesting.TokenVesting__NothingToReclaim.selector);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ReclaimUnvestedTokens_Reverts_WhenUnvestedTokensAlreadyClaimed() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.revokeSchedule(beneficiary1);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.expectRevert(TokenVesting.TokenVesting__UnvestedTokensAlreadyReclaimed.selector);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ReclaimUnvestedTokens_EmitsUnvestedTokensReclaimedEvent_WhenReclaimingAtMidVesting() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.revokeSchedule(beneficiary1);

        uint256 amountToReclaim = tokenVesting.getVestingSchedule(beneficiary1).totalAllocation
            - tokenVesting.getVestingSchedule(beneficiary1).amountVestedAtRevocation;

        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit UnvestedTokensReclaimed(beneficiary1, amountToReclaim);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    function test_ReclaimUnvestedTokens_Reverts_WhenPaused() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        tokenVesting.revokeSchedule(beneficiary1);

        tokenVesting.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);

        tokenVesting.reclaimUnvestedTokens(beneficiary1);

        vm.stopPrank();
    }

    /////////////////////////////
    /// withdrawExcessTokens ///
    ///////////////////////////

    function test_WithdrawExcessTokens_Reverts_WhenContractBalanceIsLessThanTotalOutstandingAllocation() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 fundedAmount = 999e18;

        deal(address(vestingToken), address(tokenVesting), fundedAmount);

        vm.prank(owner);

        vm.expectRevert(TokenVesting.TokenVesting__ContractUnderfunded.selector);

        tokenVesting.withdrawExcessTokens();
    }

    function test_WithdrawExcessTokens_Reverts_WhenThereAreNoExcessTokensToWithdraw() public {
        uint256 exactAllocation = 1_000_000e18;

        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, exactAllocation, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        assertEq(
            vestingToken.balanceOf(address(tokenVesting)),
            exactAllocation,
            "tokenVesting balance should equal the exact allocation"
        );

        assertEq(
            tokenVesting.totalOutstandingAllocation(),
            exactAllocation,
            "total outstanding allocation should equal the exact allocation"
        );

        vm.prank(owner);

        vm.expectRevert(TokenVesting.TokenVesting__NoExcessTokensToWithdraw.selector);

        tokenVesting.withdrawExcessTokens();
    }

    function test_WithdrawExcessTokens_TransfersExcessToOwner_WhenExcessExists() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 contractBalanceBeforeWithdrawal = vestingToken.balanceOf(address(tokenVesting));

        uint256 outstandingAllocation = tokenVesting.totalOutstandingAllocation();

        uint256 excess = contractBalanceBeforeWithdrawal - outstandingAllocation;

        assertGt(excess, 0, "excess should be greater than zero");

        uint256 ownerBalanceBeforeWithdrawal = vestingToken.balanceOf(owner);

        vm.prank(owner);
        tokenVesting.withdrawExcessTokens();

        uint256 ownerBalanceAfterWithdrawal = vestingToken.balanceOf(owner);

        uint256 contractBalanceAfterWithdrawal = vestingToken.balanceOf(address(tokenVesting));

        assertEq(
            ownerBalanceAfterWithdrawal,
            ownerBalanceBeforeWithdrawal + excess,
            "owner balance should increase by excess amount"
        );

        assertEq(
            contractBalanceAfterWithdrawal,
            contractBalanceBeforeWithdrawal - excess,
            "contract balance should decrease by excess amount"
        );
    }

    function test_WithdrawExcessTokens_EmitsExcessTokensWithdrawn_WhenExcessWithdrawn() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 contractBalanceBeforeWithdrawal = vestingToken.balanceOf(address(tokenVesting));
        uint256 outstandingAllocation = tokenVesting.totalOutstandingAllocation();

        uint256 excess = contractBalanceBeforeWithdrawal - outstandingAllocation;

        vm.prank(owner);

        vm.expectEmit(false, false, false, true);
        emit ExcessTokensWithdrawn(excess);

        tokenVesting.withdrawExcessTokens();
    }

    ///////////////////////////
    /// hasVestingSchedule ///
    /////////////////////////

    function test_HasVestingSchedule_ReturnsTrue_WhenBeneficiaryExists() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        assertTrue(tokenVesting.hasVestingSchedule(beneficiary1), "function should return true");
    }

    function test_HasVestingSchedule_ReturnsFalse_WhenBeneficiaryDoesNotExist() public {
        assertFalse(tokenVesting.hasVestingSchedule(beneficiary1), "function should return false");
    }

    function test_HasVestingSchedule_ReturnsFalse_WhenBeneficiaryIsZeroAddress() public {
        assertFalse(tokenVesting.hasVestingSchedule(address(0)));
    }

    ///////////////////////////
    /// getClaimableAmount ///
    /////////////////////////

    function test_GetClaimableAmount_ReturnsZero_WhenBeneficiaryIsZeroAddress() public {
        uint256 claimableAmount = tokenVesting.getClaimableAmount(address(0));
        assertEq(claimableAmount, 0, "getClaimableAmount should return 0 for the zero address");
    }

    function test_GetClaimableAmount_ReturnsZero_WhenBeneficiaryDoesNotExist() public {
        uint256 claimableAmount = tokenVesting.getClaimableAmount(beneficiary1);
        assertEq(claimableAmount, 0, "getClaimableAmount should return 0 when beneficiary does not exist");
    }

    function test_GetClaimableAmount_ReturnsZero_BeforeCliffEnds() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 cliffEnd = START_TIME + CLIFF_DURATION;
        vm.warp(cliffEnd - 1);

        uint256 claimableAmount = tokenVesting.getClaimableAmount(beneficiary1);
        assertEq(claimableAmount, 0, "getClaimableAmount should return 0 when cliff has not expired");
    }

    function test_GetClaimableAmount_ReturnsCorrectAmount_WhenMidVesting() public {
        vm.prank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 fractionOfVested = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;
        uint256 claimableAmount = tokenVesting.getClaimableAmount(beneficiary1);

        assertEq(
            fractionOfVested,
            claimableAmount,
            "getClaimableAmount should return correct vested fraction amount at mid-vesting"
        );
    }

    function test_GetClaimableAmount_ReturnsOnlyUnclaimedAmount_AfterPartialClaim() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 firstClaimAmount = tokenVesting.getClaimableAmount(beneficiary1);

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 secondClaimTime = midVestingTime + 10 days;
        vm.warp(secondClaimTime);

        uint256 totalVestedAtSecondClaimTime = (ALLOCATION * (secondClaimTime - START_TIME)) / VESTING_DURATION;

        uint256 expectedClaimableAmount = totalVestedAtSecondClaimTime - firstClaimAmount;

        uint256 actualClaimableAmount = tokenVesting.getClaimableAmount(beneficiary1);

        vm.stopPrank();

        assertEq(
            actualClaimableAmount, expectedClaimableAmount, "claimable amount should exclude previously claimed tokens"
        );
    }

    function test_GetClaimableAmount_ReturnsRecordedVestedAmount_AfterScheduleRevoked() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 claimAmountBeforeRevoke = tokenVesting.getClaimableAmount(beneficiary1);

        tokenVesting.revokeSchedule(beneficiary1);

        uint256 claimAmountAfterRevoke = tokenVesting.getClaimableAmount(beneficiary1);

        vm.stopPrank();

        assertEq(
            claimAmountAfterRevoke,
            claimAmountBeforeRevoke,
            "claimable amount should return vested amount pre-revocation"
        );
    }

    function test_GetClaimableAmount_ReturnsZero_AfterAllVestedTokensClaimed() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.warp(START_TIME + VESTING_DURATION + 10 days);

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 claimableAmount = tokenVesting.getClaimableAmount(beneficiary1);

        vm.stopPrank();

        assertEq(claimableAmount, 0, "claimable amount should be 0 after all vested tokens have been claimed");
    }

    ///////////////////////////////
    /// getRemainingAllocation ///
    /////////////////////////////

    function test_GetRemainingAllocation_ReturnsZero_WhenBeneficiaryIsZeroAddress() public {
        uint256 remainingAllocation = tokenVesting.getRemainingAllocation(address(0));
        assertEq(remainingAllocation, 0, "getRemainingAllocation should return 0 for the zero address");
    }

    function test_GetRemainingAllocation_ReturnsZero_WhenBeneficiaryDoesNotExist() public {
        uint256 remainingAllocation = tokenVesting.getRemainingAllocation(beneficiary1);
        assertEq(remainingAllocation, 0, "getRemainingAllocation should return 0 when beneficiary does not exist");
    }

    function test_GetRemainingAllocation_ReturnsFullAllocation_BeforeAnyClaim() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 allocationBeforeClaim = tokenVesting.getRemainingAllocation(beneficiary1);

        vm.stopPrank();

        assertEq(allocationBeforeClaim, ALLOCATION);
    }

    function test_GetRemainingAllocation_ReturnsReducedAllocation_AfterPartialClaim() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        uint256 midVestingTime = START_TIME + CLIFF_DURATION + ((VESTING_DURATION - CLIFF_DURATION) / 2);
        vm.warp(midVestingTime);

        uint256 allocationBeforeClaim = tokenVesting.getRemainingAllocation(beneficiary1);

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 totalAllocationAtMidVesting = (ALLOCATION * (midVestingTime - START_TIME)) / VESTING_DURATION;

        uint256 remainingAllocationAfterPartialClaim = allocationBeforeClaim - totalAllocationAtMidVesting;

        uint256 allocationAfterClaim = tokenVesting.getRemainingAllocation(beneficiary1);

        vm.stopPrank();

        assertEq(
            allocationAfterClaim,
            remainingAllocationAfterPartialClaim,
            "remaining allocation should decrease by the claimed amount"
        );
    }

    function test_GetRemainingAllocation_ReturnsZero_AfterFullAllocationIsClaimed() public {
        vm.startPrank(owner);
        tokenVesting.addBeneficiary(beneficiary1, ALLOCATION, START_TIME, CLIFF_DURATION, VESTING_DURATION);

        vm.warp(START_TIME + VESTING_DURATION + 10 days);

        tokenVesting.claimVestedTokens(beneficiary1);

        uint256 remainingAllocation = tokenVesting.getRemainingAllocation(beneficiary1);

        vm.stopPrank();

        assertEq(
            remainingAllocation, 0, "remaining allocation amount should be 0 after all vested tokens have been claimed"
        );
    }

    //////////////////////
    /// pause/unpause ///
    /////////////////////

    function test_Pause_SetsPausedStateToTrue_WhenCalledByOwner() public {
        vm.prank(owner);

        tokenVesting.pause();

        assertTrue(tokenVesting.paused(), "contract should be paused");
    }

    function test_Unpause_SetsPausedStateToFalse_WhenCalledByOwner() public {
        vm.prank(owner);
        tokenVesting.pause();

        vm.prank(owner);
        tokenVesting.unpause();

        assertFalse(tokenVesting.paused(), "contract should be unpaused");
    }

    function test_Pause_Reverts_WhenAlreadyPaused() public {
        vm.prank(owner);
        tokenVesting.pause();

        vm.prank(owner);

        vm.expectRevert(Pausable.EnforcedPause.selector);

        tokenVesting.pause();
    }

    function test_Unpause_Reverts_WhenContractIsNotPaused() public {
        vm.prank(owner);

        vm.expectRevert(Pausable.ExpectedPause.selector);

        tokenVesting.unpause();
    }

    function test_Pause_Reverts_WhenCalledByNonOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        vm.prank(nonOwner);

        tokenVesting.pause();
    }

    function test_Unpause_Reverts_WhenCalledByNonOwner() public {
        vm.prank(owner);
        tokenVesting.pause();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        vm.prank(nonOwner);

        tokenVesting.unpause();
    }
}
