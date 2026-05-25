// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// 可被多个合约通过 `import` 复用的 **库**：函数默认 `internal` 时在同一编译单元会像内联，
/// 不产生「单独部署一段库 bytecode」的普通教学场景（详见 `lib_import_learn.sol` 头注释）。

library ScaleMath {
    /// 将整数放大 `factor` 倍（Solidity 0.8 自带溢出检查）
    function scaleUp(uint256 self, uint256 factor) internal pure returns (uint256) {
        return self * factor;
    }
}

library MinMax {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }
}
