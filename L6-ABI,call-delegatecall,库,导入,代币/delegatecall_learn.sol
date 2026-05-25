// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * delegatecall 学习示例（Remix：依次部署 DelegateLogic、DelegateProxy，再在 Proxy 上操作）
 *
 * 核心语义（与其它低级调用的差别）：
 * 1）`delegatecall` 在当前合约（示例里的 Proxy）的 **存储 / ETH 余额 / address(this)** 上下文中，
 *    执行 **目标地址（Logic）的机器码**。`msg.sender` / `msg.data` / `msg.value` 沿用 **外层** 这笔调用，
 *    不向 `delegatecall` 目标附加以太（ Solidity 里也 **不允许** `{value: ...}(data)`）。
 * 2）因此：逻辑合约「自己编译出来的 storage 变量槽位」在正常代理用法下 **常常被忽略**，真正读写的是 Proxy 的同槽布局。
 * 3）⚠️ 代理模式铁律：**Proxy 与 Logic 里「会被 delegate 到的函数所写到的状态变量」，必须自上而下槽位完全一致**，
 *    否则会写错字段、可被利用成严重漏洞。（本例故意让两边第一个槽都是 `storedValue`。）
 * 4）与 `call` 对比：`call` 改的是 **目标是合约自己的存储**；delegatecall 改的是 **发起 delegatecall 的那份合约存储**。
 */

/// 逻辑实现：可被直接 call，也应只被 Proxy 用以 delegatecall
contract DelegateLogic {
    /*
     * ⚠️ 教学用：下面这些状态变量定义的「槽位顺序」必须与 DelegateProxy 一致。
     * 若只通过 delegatecall 使用本合约改状态，Deployed 实例上读的 `storedValue`
     * 往往是「没被 delegate 写到的旧默认值」；请以 Proxy 上读到的为准。
     */
    uint256 public storedValue; // slot 0 — 必须与 Proxy.slot0 对齐

    event LogicSet(uint256 newValue, address thisAlias, address sender);

    function setStoredValue(uint256 v) external returns (bool) {
        storedValue = v;
        emit LogicSet(v, address(this), msg.sender);
        return true;
    }
}

/// 「代理合约」：自己保存状态；把逻辑 bytecode 的执行「借」到本合约上下文里
contract DelegateProxy {
    uint256 public storedValue; // slot 0 — 必须与 DelegateLogic 对齐

    /// 演示 A：delegatecall → 写的是 **Proxy** 上的 `storedValue`
    function execDelegateSet(address logic, uint256 v) external returns (bool ok, bytes memory ret) {
        bytes memory data = abi.encodeCall(DelegateLogic.setStoredValue, (v));
        (ok, ret) = logic.delegatecall(data);
    }

    /// 演示 B：普通 call → 写的是 **Logic 实例**上的 `storedValue`，Proxy 这边 **不变**
    function execPlainCall(address logic, uint256 v) external returns (bool ok, bytes memory ret) {
        bytes memory data = abi.encodeCall(DelegateLogic.setStoredValue, (v));
        (ok, ret) = payable(logic).call(data);
    }

    /*
     * 对比步骤（建议在 Remix 里自己点一遍）：
     * - 记下 Proxy.storedValue 与 Logic.storedValue 初值；
     * - 调 Proxy.execPlainCall(logicAddr, 11)，再看两边：应为 **仅 Logic** 变了；
     * - 再调 Proxy.execDelegateSet(logicAddr, 99)，应为 **仅 Proxy** 变了（Logic 仍为 11）；
     * - LogicSet 日志里：`thisAlias` 在 delegatecall 下应是 **Proxy 地址**（ ADDRESS 语境），
     *   plain call 下是 **Logic 地址**。
     */
}
