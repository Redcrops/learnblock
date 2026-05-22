// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// / @title Bank — 练习：直接存款、记账、管理员提款、存款 Top3 排行
// / @notice 部署者即为管理员。向合约地址转 ETH 会触发 `receive()` 并累计 `balances`。
// /         管理员 `withdraw()` 会提走合约当前全部余额；链上余额与「历史累计存款」可能不一致，仅作教学示例。
contract Bank {
    /// 合约部署者，唯一可调用 `withdraw` 的地址
    address public immutable admin;

    /// 每个地址累计存入的 ETH（wei）
    mapping(address => uint256) public balances;

    /// 存款金额最高的前 3 名地址（与 `topAmounts` 下标对应，按金额降序）
    address[3] public topUsers;

    /// 与 `topUsers` 对应的存款金额（wei），便于前端直接读数组
    uint256[3] public topAmounts;

    error NotAdmin();
    error WithdrawFailed();
    error NothingToWithdraw();

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// 通过钱包直接向合约地址转 ETH 时触发（Metamask「发送」到合约）
    receive() external payable {
        _deposit();
    }

    /// 显式存款（与 `receive` 行为一致，便于在钱包里「调用」数据）
    function deposit() external payable {
        _deposit();
    }

    function _deposit() internal {
        balances[msg.sender] += msg.value;
        _refreshTopThree(msg.sender);
    }

    /// 仅管理员：将合约内全部 ETH 转到管理员地址
    function withdraw() external onlyAdmin {
        // 合约没有自己定义 balance 变量，而是直接用 address(this).balance 访问当前合约地址上实际存放的 ETH 数量
        // 这个是 Solidity/EVM 的内置机制，所有合约或地址都可以用 .balance 查询持有的 ETH，和自己声明变量无关
        uint256 bal = address(this).balance;
        if (bal == 0) revert NothingToWithdraw();

        // xxx.call，其中 xxx 是代币（ETH）的接收方地址，本例中为管理员地址 admin
        // call 的用法是：接收方.call{value: 金额}(数据)
        // 这里只发送 ETH，不带 data，空字符串 "" 表示空数据
        (bool ok, ) = payable(admin).call{value: bal}("");
        if (!ok) revert WithdrawFailed();
    }

    /// 用「本轮存款地址 + 原 Top3」共至多 4 个地址重新排序，写入前 3 名
    function _refreshTopThree(address account) internal {
        address[4] memory cand;
        uint256 n = 0;

        cand[n++] = account;

        for (uint256 i = 0; i < 3; i++) {
            address u = topUsers[i];
            if (u == address(0)) continue;
            if (u == account) continue;
            cand[n++] = u;
        }

        // 对 cand[0..n) 按 balances 降序，简单选择排序，n <= 4
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
