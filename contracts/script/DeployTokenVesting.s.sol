// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {VestingToken} from "../src/VestingToken.sol";
import {console} from "forge-std/console.sol";

contract DeployTokenVesting is Script {
    function run() external returns (VestingToken vestingToken, TokenVesting tokenVesting) {
        vm.startBroadcast();

        vestingToken = new VestingToken();
        tokenVesting = new TokenVesting(address(vestingToken));

        vm.stopBroadcast();

        console.log("VestingToken deployed at:", address(vestingToken));
        console.log("TokenVesting deployed at:", address(tokenVesting));
    }
}
