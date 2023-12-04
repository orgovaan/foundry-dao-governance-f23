// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Contract for the DAO's governance token
 * This has been constructed by the OpenZeppelin contract wizard:
 * https://wizard.openzeppelin.com/
 * @notice have to install an older version of OpenZeppelin: forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
 */

// forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**
 * allows approvals to be made via signatures
 * allows you to sign a trx without sending it, and let somebody else send the trx
 */
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
/**
 * 1. Keeps a history of each account's voting power. (snapshot)
 * 2. Allows voting rights to be delegated to somebody else.
 */
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // @notice this is a function that we added. Now much thought in here. In general we wouldnot want anybody to be able to mint.
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
