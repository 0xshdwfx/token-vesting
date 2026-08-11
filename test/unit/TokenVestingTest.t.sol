// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../../src/TokenVesting.sol";
import {VestingToken} from "../../src/VestingToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenVestingTest is Test {
    TokenVesting public tokenVesting;
    VestingToken public vestingToken;

    address public owner = address(0x1);
    address public beneficiary1 = address(0x2);
    address public beneficiary2 = address(0x3);
    address public beneficiary3 = address(0x4);

    uint256 public constant ALLOCATION = 1000e18;
    uint256 public constant CLIFF_DURATION = 30 days;
    uint256 public constant VESTING_DURATION = 365 days;

    event BeneficiaryAdded(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );

    function setUp() public {
        vm.startPrank(owner);
        vestingToken = new VestingToken();
        tokenVesting = new TokenVesting(address(vestingToken));
        vestingToken.transfer(address(tokenVesting), 1_000_000e18);
        vm.stopPrank();
    }
}
