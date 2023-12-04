// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {MyGovernor} from "../src/MyGovernor.sol"; // there is a Governor.sol contract that this contract inherits from
import {TimeLock} from "../src/TimeLock.sol";

contract Deployer is Script {
    uint256 public constant MIN_DELAY = 3600; // has to wait 2 hour with execution after a passed proposal

    address[] public proposers;
    address[] public executors;

    function run() external returns (Box, GovToken, MyGovernor, TimeLock, address) {
        Box box;
        GovToken govToken;
        MyGovernor governor;
        TimeLock timeLock;

        address USER = msg.sender;

        // In order to delpoy the governor, we need both the govToken and the Timelock, so we deploy those first
        govToken = new GovToken();

        // by leaving the proposers[] and executors[] array empty, we say that anybody can propose and execute
        vm.prank(USER); // prank only the next line. User has to own the timeLock so he becomes the admin who can grant roles in the test contract
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        // now that we have the govToken and the timeLock, we can finally deploy our governor
        governor = new MyGovernor(govToken, timeLock);

        // USER has to own box to so that we can transer the ownership later
        vm.prank(USER);
        box = new Box();

        return (box, govToken, governor, timeLock, USER);
    }
}
