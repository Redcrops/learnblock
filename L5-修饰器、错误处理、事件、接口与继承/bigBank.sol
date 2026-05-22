// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Bank} from "./Bank.sol";

/// @title BigBank
/// @notice 继承 `Bank`，单笔入账必须严格大于 `0.001 ether`；同样支持 `transferAdmin`/`withdraw` 语义。
contract BigBank is Bank {
    error DepositTooSmall(uint256 sent);

    /// @dev `msg.value` 必须 **严格大于** `0.001 ether`（相等也不通过）
    modifier requireMinDeposit() {
        uint256 value = msg.value;
        if (value <= 0.001 ether) {
            revert DepositTooSmall(value);
        }
        _;
    }

    receive() external payable override requireMinDeposit {
        _deposit();
    }

    function deposit() external payable override requireMinDeposit {
        _deposit();
    }
}
