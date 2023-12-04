// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//install: forge install openzeppelin/openzeppelin-contracts --no-commit
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_number;

    event NumberChanged(uint256);

    // empty constructor
    constructor() {}

    function store(uint256 newNumber) public onlyOwner {
        s_number = newNumber;
        emit NumberChanged(newNumber); //changing stat var, so emit an event
    }

    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
