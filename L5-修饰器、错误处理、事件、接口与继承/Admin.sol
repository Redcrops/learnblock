// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBank} from "./IBank.sol";

/// @title Admin — 代收 BigBank/Bank 资金
/// @notice 先将目标 Bank/BigBank 的 `admin` `transferAdmin` 到本合约地址；随后由 `owner`
///         调用 `adminWithdraw`。`bank.withdraw()` 会把该行合约余额全额打到 **当时的 admin**，
///         即本合约 → ETH 记在 `Admin` 合约余额上。
contract Admin {
    address public owner;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    receive() external payable {}

    /// @notice 调用 `bank.withdraw()`，资金进入本合约地址（前提：`bank.admin() == address(this)`）
    function adminWithdraw(IBank bank) external onlyOwner {
        bank.withdraw();
    }
}
