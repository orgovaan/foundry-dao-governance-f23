// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Test contract for the governance system
 * @author Norbert Orgován
 * @notice Just because one mints it does not mean one can vote. we need to delegate voting power.
 * @notice contrary to popular belief, the governed contract needs to be owner not by the DAO (governor), but by the TiemLock.
 */

import {Test, console} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {MyGovernor} from "../src/MyGovernor.sol"; // there is a Governor.sol contract that this contract inherits from
import {TimeLock} from "../src/TimeLock.sol";

contract MyGovernorTest is Test {
    // without a specifier, these are gonna be internal vars
    Box box;
    GovToken govToken;
    MyGovernor governor;
    TimeLock timeLock;

    address public USER = makeAddr("user");

    address[] proposers;
    address[] executors;

    // array vars for the args of the propose() function
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // has to wait 2 hour with execution after a passed proposal
    uint256 public constant VOTING_DELAY = 1; // how many block till a vote is active. set this in the Openzeppelin contract wizard
    uint256 public constant VOTING_PERIOD = 50400; // == 1 week. set this in the Openzeppelin contract wizard

    function setUp() public {
        // For now, deployment is handled here, not separately with a deploy script.
        // In order to delpoy the governor, we need both the govToken and the Timelock, so we deploy those first
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        // @notice just because we minted this token and have a balance, we cannot vote. We need to delegate voting power to ourselves
        vm.startPrank(USER);
        govToken.delegate(USER); // delegate here

        // by leaving the proposers[] and executors[] array empty, we say that anybody can propose and execute
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        // now that we have the govToken and the timeLock, we can finally deploy our governor
        governor = new MyGovernor(govToken, timeLock);

        /**
         * Timelock starts with some default roles. (These are defined as public vars, so there is a getter for them by default.)
         * We need to grant the governor roles, and then we need to remove the USER as the admin of the timelock.
         *
         * The timeLock.TIMELOCK_ADMIN_ROLE() statement creates a constant hash that uniquely represents a role, in this case, TIMELOCK_ADMIN_ROLE.
         * This pattern is typical in access control mechanisms within smart contracts, where roles are often represented by unique hashes.
         * By using a hash instead of the string itself, the contract saves gas when performing role checks.
         * A bytes32 comparison is cheaper in terms of gas than string comparisons.
         */
        bytes32 proposerRole = timeLock.PROPOSER_ROLE(); //returns a hashed version of the string "PROPOSER_ROLE"
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        //grantRole() funcion is defined in AccessControl.sol, TImeLockConroller inherits it.
        timeLock.grantRole(proposerRole, address(governor)); // only the governor can propose to the timelock
        timeLock.grantRole(executorRole, address(0)); // anybody can execute
        timeLock.revokeRole(adminRole, USER);

        vm.stopPrank();

        box = new Box();
        /**
         * timeLock owns the DAO, and the DAO owns the timeLock (strange relship),
         * but it is the timeLock that has the ultimate say in what goes where,
         * so we need to transfer the ownership of the box to the timeLock
         */
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        uint256 valueToStore = 888;
        vm.expectRevert();
        box.store(valueToStore);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;

        /**
         * first we need to come up with a proposal
         * args of the propose() function, in reverse order:
         */
        string memory description = "Store 888 in box.";
        // This next is the callDatas. With abi.encodeWithSiganture we can call anything, see the sublesson of the NFT lesson
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);

        calldatas.push(encodedFunctionCall);
        values.push(0); // we wont be sending any ETH, let it be empty
        targets.push(address(box));

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        // View the state of the proposal
        // Pending= 0 Active = 1 Canceled = 2 Defeated = 3 Succeeded = 4 Queued = 5 Expired = 6 Executed = 7
        console.log("Proposal state is: ", uint256(governor.state(proposalId))); // cast to uint256
            // at this point, the proposal should be pending = 0, so

        // 2. wait until the voting delay passes
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // 3. vote
        string memory reason = "coz blue frog is cool";
        uint8 voteWay = 1; // == voting yes (0 = against, 2 = abstain)
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // 4. wait until voting period ends
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        // 5. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // 6. Wait the min delay before execution
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 7. execute
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
        console.log("Box value: ", box.getNumber());
    }
}
