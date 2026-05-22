// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * 场景：合约 A → 合约 B 转账（发送 ETH）。
 *
 * 要点：
 * 1）对「合约地址」转 ETH 时，目标合约必须在链上有可执行的入口：
 *    - 常见是 `receive() external payable`（无 calldata 的转账）；
 *    - 若没有 `receive`，而 `fallback` 标注为 `payable`，则可能由 `fallback` 接收以太。
 * 2）若既没有 `receive` 也没有可用的 `payable fallback`，`.call{value: x}` 仍可能返回 false，
 *    交易会失败。
 * 3）演示里用 `call`，避免 `.transfer`/`.send` 的 gas 限制导致「收款方逻辑稍复杂就失败」，
 *    但这是语言机制问题；本例重点仍是「谁在收 ETH」。
 * 4）部分 Remix（ethers v6）在编码 `uint256` 时会出现 `1` 被编成 `1,` 等非数字串，报错 invalid BigNumberish；
 *    可换用 `payout(..., string 表示的 ETH 数量, ...)` 在链上解析（默认单位 ETH），或 `payoutOneWei` / `payoutAll`。
 */

/// @dev 会通过 call 给其他合约转 ETH 的「付款方」
contract SenderBank {
    uint256 internal constant WEI_PER_ETH = 1 ether;

    /// @dev 允许部署时在 Remix 的 VALUE 栏附带以太；否则 deployment 设为 0 后再转账也可。
    constructor() payable {}

    /// @notice 用本合约余额向 `target` 转 `amount` wei；`data` 为空即裸转 ETH，`data` 非空可帮助触发目标的 `fallback`。
    /// @dev 转账是否成功看返回值 `ok`。若 Remix 对 `uint256 amount` 编码异常，改用 `payout(..., string, ...)` 或 `payoutOneWei` / `payoutAll`。
    function payout(address payable target, uint256 amount, bytes calldata data)
        external
        returns (bool ok)
    {
        return _send(target, amount, data);
    }

    /// @notice `amountEth`：十进制 ETH 数量字符串（链上换算为 wei 后转出），兼容 Remix string 编码。
    /// @dev 允许可选小数点与小数至多 18 位（超出位数截断）；整数、小数分段均仅含 `0`-`9`；禁止逗号/科学计数/`e`/`E`。
    ///      例：`"1"` = 1 ETH，`"0.000000000000000001"` = 1 wei。仅一个小数点 `"."` 会得到 0 wei（相当于 0 ETH）。
    function payout(address payable target, string calldata amountEth, bytes calldata data)
        external
        returns (bool ok)
    {
        return _send(target, parseEtherString(amountEth), data);
    }

    /// @notice Remix 规避：`amount` 固定为 1 wei，不落盘到 ABI 大额数字字段。
    function payoutOneWei(address payable target, bytes calldata data)
        external
        returns (bool ok)
    {
        return _send(target, 1, data);
    }

    /// @notice Remix 规避：转出本合约当前全部 ETH 余额（仅填地址与可选 calldata）。
    function payoutAll(address payable target, bytes calldata data)
        external
        returns (bool ok)
    {
        uint256 amt = address(this).balance;
        if (amt == 0) {
            return false;
        }
        return _send(target, amt, data);
    }

    function _send(address payable target, uint256 amount, bytes memory data)
        internal
        returns (bool ok)
    {
        require(address(this).balance >= amount, "insufficient balance");
        (ok, ) = target.call{value: amount}(data);
    }

    /// @dev 将以太数量字符串解析为 wei；`whole.frac`，按截断至多 18 位小数后再乘 `WEI_PER_ETH`。
    function parseEtherString(string calldata s) internal pure returns (uint256 weiAmount) {
        (bytes memory b, uint256 lo, uint256 hi) = _trimToBytes(s);
        require(lo < hi, "empty amount");

        uint256 dot = type(uint256).max;
        for (uint256 i = lo; i < hi; i++) {
            uint8 ch = uint8(b[i]);
            if (ch == 0x2e) {
                require(dot == type(uint256).max, "multi dot");
                dot = i;
                continue;
            }
            require(ch >= 0x30 && ch <= 0x39, "non-digit");
        }

        uint256 wholeWei;
        if (dot == type(uint256).max) {
            uint256 wholes = _parseAsciiDigitsBounded(b, lo, hi);
            wholeWei = wholes * WEI_PER_ETH;
        } else {
            uint256 wl = dot > lo ? _parseAsciiDigitsBounded(b, lo, dot) : 0;
            wholeWei = wl * WEI_PER_ETH;

            uint256 fracStart = dot + 1;
            if (fracStart < hi) {
                uint256 fracEnd = hi - fracStart > 18 ? fracStart + 18 : hi;
                uint256 fracDigits = fracEnd - fracStart;
                if (fracDigits != 0) {
                    uint256 fracVal = _parseAsciiDigitsBounded(b, fracStart, fracEnd);
                    wholeWei += fracVal * pow10u(18 - fracDigits);
                }
            }
        }
        return wholeWei;
    }

    /// @dev 仅整段必须为数字且无分隔符时使用（已由 parseEtherString 分拆好区间）。
    function _parseAsciiDigitsBounded(bytes memory b, uint256 lo, uint256 hi)
        internal
        pure
        returns (uint256 result)
    {
        require(lo <= hi, "bounds");
        for (uint256 i = lo; i < hi; i++) {
            uint8 c = uint8(b[i]);
            require(c >= 0x30 && c <= 0x39, "non-digit");
            result = result * 10 + (c - 0x30);
        }
    }

    function pow10u(uint256 exp) internal pure returns (uint256 p) {
        require(exp <= 18, "pow10");
        p = 1;
        for (uint256 i; i < exp; i++) {
            p *= 10;
        }
    }

    function _trimToBytes(string calldata s)
        internal
        pure
        returns (bytes memory b, uint256 lo, uint256 hi)
    {
        b = bytes(s);
        lo = 0;
        hi = b.length;
        while (lo < hi && uint8(b[lo]) == 0x20) {
            unchecked {
                ++lo;
            }
        }
        while (hi > lo && uint8(b[hi - 1]) == 0x20) {
            unchecked {
                --hi;
            }
        }
    }

    receive() external payable {}
}

/*
=== 操作流程（任选测试网 Remix / Foundry）===

 1）部署 SenderBank（构造函数 payable，可在 Remix VALUE 中带 ETH）；或 VALUE=0，部署后再向合约转账。
 2）调试 `payout(..., uint256, ...)` 若报 BigNumber invalid：改用 `payout(target, "字符串ETH", 0x)`（例 `"1"` = 1 ETH）；或 `payoutOneWei` / `payoutAll`。
 3）部署 ReceiverWithReceiveAndFallback：
    - `payout`/字符串/`payoutAll`，data 为 0x → 一般会进 receive，发 Received。
    - bytes 为非匹配片段 → payable fallback，发 FallbackGot。
 4）部署 ReceiverFallbackOnly，用 `payoutOneWei`、`payoutAll` 或 `payout`+字符串 → hitCount++（payable fallback 接 ETH）。
 5）部署 ReceiverCannotAcceptEther，同样转出 → ok == false。

说明：fallback 的典型作用之一，就是在「没带对函数」或合约只实现 fallback、无 receive 时，
     仍能通过 payable fallback 接住其它合约打来的 ETH。
*/
/// @dev 同时拥有 receive 与 payable fallback：前者收「裸 ETH」；后者收「带不认识的选择器/data 的 ETH」
contract ReceiverWithReceiveAndFallback {
    event Received(address indexed from, uint256 value);
    event FallbackGot(address indexed from, uint256 value, bytes data);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FallbackGot(msg.sender, msg.value, msg.data);
    }
}

/// @dev 故意不写 receive，只写 payable fallback —— 「纯 ETH、无 calldata」仍可能进到 fallback（见 Solidity 文档）
contract ReceiverFallbackOnly {
    uint256 public hitCount;

    fallback() external payable {
        hitCount++;
    }
}

/// @dev 无 receive / 无可付 fallback —— 收不了 ETH，`call{value}` 应为 false（需检查返回值）
contract ReceiverCannotAcceptEther {
    // 占位，避免误以为空合约仍可收款
}
