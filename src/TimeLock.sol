// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /**
     * @param minDelay minimum time to wait before a passed proprosal can be implemented
     * @param proposers list of addresses that can submit a proposal
     * @param executors list of exacutors that can exacute
     * @notice and then there is a 4th arg (admin) that has to be passed to TimelockController
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors)
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}
}
