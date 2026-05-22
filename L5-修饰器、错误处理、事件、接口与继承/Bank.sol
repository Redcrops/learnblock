// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBank} from "./IBank.sol";

/// @title Bank（挑战基类）
/// @notice 与 L4 习题版一致：`receive`/`deposit` 入账、排行榜；`withdraw` 仅管理员，把合约全额 ETH 转给当前 `admin`。
///         与习题版区别在于：`admin` 可变，可实现 `IBank.transferAdmin`，`receive`/`deposit` 为 `virtual` 供继承覆盖。
contract Bank is IBank {
    /// 可随时通过 `transferAdmin` 移交；必须与 `withdraw` 目标一致才能完成「代收」流程
    address public admin;

    mapping(address => uint256) public balances;

    address[3] public topUsers;
    uint256[3] public topAmounts;

    error NotAdmin();
    error WithdrawFailed();
    error NothingToWithdraw();
    error ZeroAdmin();

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// @notice 将管理员移交给 `newAdmin`（常为 `Admin` 合约地址）
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAdmin();
        address prev = admin;
        admin = newAdmin;
        emit AdminTransferred(prev, newAdmin);
    }

    receive() external payable virtual {
        _deposit();
    }

    function deposit() external payable virtual {
        _deposit();
    }

    function _deposit() internal {
        balances[msg.sender] += msg.value;
        _refreshTopThree(msg.sender);
    }

    /// @inheritdoc IBank
    function withdraw() external virtual onlyAdmin {
        uint256 bal = address(this).balance;
        if (bal == 0) revert NothingToWithdraw();

        (bool ok, ) = payable(admin).call{value: bal}("");
        if (!ok) revert WithdrawFailed();
    }

    function _refreshTopThree(address account) internal {
        address[4] memory cand;
        uint256 n;

        cand[n++] = account;

        for (uint256 i = 0; i < 3; i++) {
            address u = topUsers[i];
            if (u == address(0)) continue;
            if (u == account) continue;
            cand[n++] = u;
        }

        for (uint256 i = 0; i < n; i++) {
            uint256 best = i;
            for (uint256 j = i + 1; j < n; j++) {
                if (balances[cand[j]] > balances[cand[best]]) {
                    best = j;
                }
            }
            if (best != i) {
                address tmp = cand[i];
                cand[i] = cand[best];
                cand[best] = tmp;
            }
        }

        for (uint256 k = 0; k < 3; k++) {
            if (k < n) {
                topUsers[k] = cand[k];
                topAmounts[k] = balances[cand[k]];
            } else {
                topUsers[k] = address(0);
                topAmounts[k] = 0;
            }
        }
    }
}
