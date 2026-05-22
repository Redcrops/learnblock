// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice 提款入口：应由当前「管理员地址」调用，资金会转到该 Bank/BigBank 记录的 admin。
interface IBank {
    function withdraw() external;
}
