// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * ABI 低级调用入门示例（Remix：先部署 Callee，再部署 Caller，传 Callee 地址调用）
 *
 * 要点简述：
 * 1. 外部函数调用的 calldata 布局：前 4 字节是「函数选择器」= keccak256("函数名(类型,...)") 的前 4 字节；
 *    之后按 ABI 规则编码各参数（通常每参数 32 字节对齐）。
 * 2. 高层写法：直接 `Callee(target).setX(1)`，编译器帮你编码并发起调用。
 * 3. 底层写法：自己 `bytes memory data = abi.encode...` 再 `target.call(data)` / `staticcall(data)`。
 * 4. `call` 可改状态、可附 ETH；对 `view/pure` 目标应优先用 `staticcall`（若用 call 也能跑，但语义不对且浪费 gas）。
 * 5. 务必检查 `(bool ok, bytes memory ret) = ...` 里的 `ok`；失败时 `ret` 里可能是编码后的 revert reason。
 */

/// 被调用方：简单的状态与纯函数，便于观察 ABI 编码与返回值解码
contract Callee {
    uint256 public x;

    event XUpdated(uint256 newX,uint256 money);

    /// 改状态：适合用 `call`
    function setX(uint256 v) external payable returns (bool) {
        x = v;
        emit XUpdated(v,address(this).balance);
        return true;
    }

    /// 只读计算：适合用 `staticcall`
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
}

/// 调用方：演示多种「手工拼 calldata」方式
contract AbiCaller {
    /// 方式 A：按函数签名字符串编码（易读，但字符串写错要到链上才暴露）
    function callSetXWithSignature(address callee, uint256 v) external returns (bool ok, bytes memory ret) {
        bytes memory data = abi.encodeWithSignature("setX(uint256)", v);
        (ok, ret) = callee.call(data);
    }

    /// 方式 B：显式 4 字节 selector + 参数编码（与 A 等价，常见于节省字面量或可复用 selector 常量）
    function callSetXWithSelector(address callee, uint256 v) external returns (bool ok, bytes memory ret) {
        bytes4 sel = bytes4(keccak256("setX(uint256)"));
        bytes memory data = abi.encodeWithSelector(sel, v);
        (ok, ret) = callee.call(data);
    }

    /// 方式 C（推荐）：`encodeCall` 在编译期绑定函数原型，参数类型错位会编译失败
    function callSetXWithEncodeCall(address callee, uint256 v) external returns (bool ok, bytes memory ret) {
        bytes memory data = abi.encodeCall(Callee.setX, (v));
        (ok, ret) = callee.call(data);
    }

    /// 读函数：使用 `staticcall`，并用 `abi.decode` 解析返回值
    function staticCallAdd(address callee, uint256 a, uint256 b)
        external
        view
        returns (bool ok, uint256 sum)
    {
        bytes memory data = abi.encodeCall(Callee.add, (a, b));
        bytes memory ret;
        (ok, ret) = callee.staticcall(data);
        if (!ok) return (false, 0);
        sum = abi.decode(ret, (uint256));
    }

    /// 若被调函数声明了 `returns (bool)`，成功时返回值同样在 `ret` 里（非 view 的外部调用返回值走 returndata）
    function decodeReturnedBool(bytes memory ret) external pure returns (bool b) {
        b = abi.decode(ret, (bool));
    }

    /** 附带向目标发送 ETH：`call{value: ...}(data)`
     *
     * 要求目标合约有可收 ETH 的 `receive()/payable fallback`。本例 Callee 没有 payable 入口，
     * 仅作语法演示 —— 实战中请先确认对方能收下 ETH。
     */
    function callSetXPayable(address callee, uint256 v) external payable returns (bool ok, bytes memory ret) {
        bytes memory data = abi.encodeCall(Callee.setX, (v));
        (ok, ret) = payable(callee).call{value: msg.value}(data);
    }
}
