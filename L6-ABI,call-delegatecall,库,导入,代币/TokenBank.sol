// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";

/// @title TokenBank — 与 `BaseERC20.sol` 配套的存取与记账
/// @notice 存入前须在 `BaseERC20` 上对 `TokenBank` 合约地址执行 `approve`。
contract TokenBank {
    BaseERC20 public immutable token;

    /// @notice 用户在银行内的账面余额（不是 `BaseERC20.balanceOf` 的直接别名）
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance();

    constructor(BaseERC20 token_) {
        token = token_;
    }

    /// @notice 将自己钱包中的 Token 存入银行（需事先 `approve`）
    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "TokenBank: transferFrom failed");

        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice 取回此前存入的部分或全部 Token
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;

        bool ok = token.transfer(msg.sender, amount);
        require(ok, "TokenBank: transfer failed");

        emit Withdrawn(msg.sender, amount);
    }
}
