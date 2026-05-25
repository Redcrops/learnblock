// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * 库的「导入 + 挂载」入门（Remix：同一工作区添加本文件与 `LearnLibs.sol` 后再编译）
 *
 * 导入写法常见几种：
 * 1）`import "./LearnLibs.sol";`
 *      导入文件里的一切顶层符号；适合小文件或与旧教程对齐。
 * 2）`import {SymbolA, SymbolB} from "./LearnLibs.sol";`（本文采用）
 *      **按需导入**，避免不必要符号进当前编译单元。
 * 3）`import {Symbol as Alias} from "..." ;`
 *      别名，用于名字冲突或统一命名风格。
 *
 * 库的两种形态（本节只展开 internal 库）：
 * - **`internal` 函数**：编译器常在调用点 **内联** 成普通代码，看起来像「模块化源码」；
 * - **`public` 库**：会生成可被 `DELEGATECALL` 的独立 bytecode，需要先部署再在链接阶段绑地址，
 *   初学阶段少用；本仓库示例全部用 internal，Remix 里零额外部署。
 *
 * `using Lib for Type`：把 `Lib` 里「第一个参数类型为挂载类型」的内部函数改写为后缀调用：
 * `x.scaleUp(10)` ⇔ `ScaleMath.scaleUp(x, 10)`（可读性更接近 OOP）。
 */

import {ScaleMath, MinMax} from "./LearnLibs.sol";

contract UsingLibDemo {
    using ScaleMath for uint256;
    using MinMax for uint256;

    /// Remix：传 `123`，应返回 `1230`
    function demoScale(uint256 base) external pure returns (uint256) {
        return base.scaleUp(10);
    }

    /// 等价于 `ScaleMath.scaleUp(MinMax.max(a, b), 2)`
    function demoChain(uint256 a, uint256 b) external pure returns (uint256) {
        return a.max(b).scaleUp(2);
    }

    /** 不写 `using` 时可直接「模块名`.`函数」调用 */
    function demoQualified(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 hi = MinMax.max(a, b);
        uint256 lo = MinMax.min(a, b);
        return ScaleMath.scaleUp(hi - lo, 1); // ×1：强调「是普通函数」，只是放在库里
    }
}

/** 若想体验「导入整文件」，可新建一空合约文件，仅在顶部写：`import "./LearnLibs.sol";` */
contract FullyImportedStyleNote {
    function doublesViaQualifiedCall(uint256 x) external pure returns (uint256) {
        return ScaleMath.scaleUp(x, 2);
    }
}
