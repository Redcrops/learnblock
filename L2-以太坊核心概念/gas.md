# 以太坊 Gas 与 EIP-1559 费用机制

本文整理 **EIP-1559**（伦敦升级后）下的 gas 计费方式，以及两道典型计算题。

---

## 1. 机制说明

交易里与费用相关的常见字段：

| 字段 | 含义 |
|------|------|
| **Gas Limit** | 本交易**最多**能消耗的 gas 上限；实际扣费按 **实际消耗 gas** 计算，但不超过 Gas Limit。 |
| **Max Fee Per Gas**（Max Fee） | 你愿意为**每单位 gas** 支付的上限（GWei）。 |
| **Max Priority Fee Per Gas**（Max Priority Fee） | 你愿意给验证者（原「矿工」概念中的出块方）的**每单位 gas 小费上限**（GWei）。 |
| **Base Fee**（区块基础费） | 由协议按父块情况自动调整，**整块内对该交易而言在打包时已确定**。**Base Fee 对应的 ETH 会被销毁，不给验证者。** |

每一单位 gas，用户实际付出的价格（有效 gas 价）由协议按下面规则确定；验证者只拿其中的 **priority（小费）** 部分。

### 1.1 每单位 gas 的小费（Priority Fee Per Gas）

验证者每单位 gas 实际能拿到的小费为：

\[
\text{priority\_per\_gas} = \min\left(\text{MaxPriorityFee},\ \text{MaxFee} - \text{BaseFee}\right)
\]

含义：小费不能超过你声明的 **Max Priority Fee**；也不能超过 **Max Fee − Base Fee**（否则总价会超过你愿意付的 Max Fee）。

若计算结果 **≤ 0**，则小费按 0 处理（交易可能因 Max Fee 低于 Base Fee 而无法被打包）。

### 1.2 每单位 gas 用户总共支付多少

用户为每单位 gas 支付（不含合约内 value 转账）：

\[
\text{price\_per\_gas} = \text{BaseFee} + \text{priority\_per\_gas}
\]

且受 **Max Fee** 封顶：协议保证 `price_per_gas ≤ MaxFee`（在上述 `min` 定义下已隐含）。

### 1.3 总费用拆分

设 **实际消耗 gas** 为 \(g\)（\(g \leq \text{GasLimit}\)）：

| 去向 | 金额（GWei） |
|------|----------------|
| **销毁（Base Fee）** | \(g \times \text{BaseFee}\) |
| **验证者（Priority / Tip）** | \(g \times \text{priority\_per\_gas}\) |

**钱包需覆盖的 gas 最坏情况**（无额外 `value` 时）：常用上界为 **`GasLimit × MaxFee`**（假定每单位 gas 都按 Max Fee 封顶扣款）。

---

## 2. 例题一：钱包里该准备多少 GWei？（仅 gas）

**条件：** Gas Limit = 10 000，Max Fee = 10 GWei，Max Priority Fee = 1 GWei。  
**问：** 不考虑向他人转账的 `value`，仅从 gas 角度，账户至少应能付出多少 GWei？

**答：** 单笔交易因 gas 而被扣款的**理论上限**为：

\[
\text{GasLimit} \times \text{MaxFee} = 10\,000 \times 10 = \mathbf{100\,000\ \text{GWei}}
\]

**说明：** Max Priority Fee 只影响 Base / Tip 的拆分，不改变「每单位 gas 最多付 Max Fee」这一上限。多数钱包会按 `GasLimit × MaxFee`（或等价 wei）检查余额是否够付 gas。若有 `value`，需另加转账金额。

---

## 3. 例题二：验证者实际拿到多少手续费？

**条件：**

- Gas Limit = 10 000  
- Max Fee = 10 GWei  
- Max Priority Fee = 1 GWei  
- 打包时 Base Fee = **5 GWei**  
- **实际消耗 gas** = **5000**

**问：** 矿工/验证者拿到的手续费是多少 GWei？

**解：**

1. 先算每单位 gas 的小费：

   \[
   \text{priority\_per\_gas} = \min(1,\ 10 - 5) = \min(1,\ 5) = 1\ \text{GWei/gas}
   \]

2. 验证者总收入（仅 tip）：

   \[
   5000 \times 1 = \mathbf{5\,000\ \text{GWei}}
   \]

**核对（理解用）：**

- 用户为 gas 大致支付：\(5000 \times (5 + 1) = 30\,000\) GWei。  
- 其中销毁：\(5000 \times 5 = 25\,000\) GWei。  
- 验证者：\(5000 \times 1 = 5\,000\) GWei。

---

## 4. 小结

- **验证者收入** = `实际 gas 用量 × priority_per_gas`，其中 `priority_per_gas = min(MaxPriorityFee, MaxFee - BaseFee)`。  
- **Base Fee 不进验证者口袋**，全部销毁。  
- **余额规划**（不传 ETH 时）：至少准备 **`GasLimit × MaxFee`**（GWei 层面即相乘；更严谨可统一换成 Wei 再换算）。
