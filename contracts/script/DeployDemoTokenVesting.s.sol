// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {DemoTokenVesting} from "../src/DemoTokenVesting.sol";
import {VestingToken} from "../src/VestingToken.sol";

contract DeployDemoTokenVesting is Script {
    uint256 private constant DEMO_FUNDING = 100e18;

    function run() external returns (VestingToken demoToken, DemoTokenVesting demoVesting) {
        vm.startBroadcast();

        demoToken = new VestingToken();
        demoVesting = new DemoTokenVesting(address(demoToken));

        demoToken.transfer(address(demoVesting), DEMO_FUNDING);

        vm.stopBroadcast();

        console.log("Demo token deployed at:", address(demoToken));
        console.log("Demo vesting deployed at:", address(demoVesting));
        console.log("Demo vesting funding:", DEMO_FUNDING);
    }
}
