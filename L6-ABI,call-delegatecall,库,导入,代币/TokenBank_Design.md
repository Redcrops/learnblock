# TokenBank 设计文档

## 1. 目标与范围

- **目标**：用户可把**自己的 ERC20 Token** 存入 `TokenBank`，银行按地址**累计记账**；用户仅能**取回自己名下**的入账份额。
- **范围**：**一个 `TokenBank` 实例只对接一种 ERC20**（部署时通过构造函数注入 `token` 地址）。如需多币种，应部署多个实例或后续扩展为 `mapping(asset => ...)` 架构（本实现不展开）。

## 2. 为什么 `deposit` / `withdraw` 需要 `amount` 参数

ERC20 转账依赖 `transfer` / `transferFrom` 的 **`amount`**，链上**无法**像原生币那样用无参 `deposit()` 隐式读取「用户想存多少」。因此接口采用：

- `deposit(uint256 amount)`
- `withdraw(uint256 amount)`

若课程要求「无参」版本，仅适用于**原生 ETH**（用 `msg.value`），与 ERC20 语义不同，需另写 `ETHBank`。

## 3. 核心数据

| 存储 | 含义 |
|------|------|
| `token` | `immutable`，类型为 **`BaseERC20`**（与 `BaseERC20.sol` 同源复用）；本银行托管的 ERC20。 |
| `balances[user]` | 用户在银行内的**账面余额**（与用户钱包里 `token.balanceOf(user)` 分开；用户存钱后进银行池子，余额记在 `balances`）。 |

不在链上单独维护「总存款」也可通过 `token.balanceOf(address(TokenBank))` 查询金库实际 Token 量；为教学简洁本合约未增加 `totalDeposited` 冗余变量。

## 4. 业务流程

### 存入 `deposit(amount)`

1. **前置**：用户在 Token 合约上调用 `approve(TokenBank, amount)`（或更大额度）。
2. **调用**：用户执行 `TokenBank.deposit(amount)`。
3. **链上动作**：`transferFrom(user, TokenBank, amount)`，成功则 `balances[user] += amount`，并发出 `Deposited`。

失败常见原因：未授权、授权不足、用户余额不足、Token 合约返回 `false`。

### 取出 `withdraw(amount)`

1. **检查**：`balances[user] >= amount`。
2. **先减账再转账**（Checks-Effects-Interactions）：`balances[user] -= amount`，再 `token.transfer(user, amount)`，避免重入时重复提款（对恶意回调型 Token 生产环境可再加 `ReentrancyGuard` / `SafeERC20`）。

## 5. 安全注意（教学向摘要）

- **记账与金库一致**：攻击面主要在 Token 是否标准；异常 Token 可能 `transfer` 成功但扣款不对等，生产环境应用 **OpenZeppelin SafeERC20** 并做审计。
- **授权风险**：用户应对 `approve` 额度做最小授权或配合 `increaseAllowance` 策略，避免无限授权被钓鱼合约滥用（属用户侧与前端问题，银行合约仍按标准 `transferFrom` 工作）。

## 6. 与 `BaseERC20.sol` 的复用关系

- `TokenBank.sol` 通过 **`import "./BaseERC20.sol"`** 引入习题代币合约，构造函数参数类型为 **`BaseERC20`**，`deposit` / `withdraw` 内部调用其 **`transferFrom` / `transfer`**（与 ERC20 语义一致）。
- Remix：先部署 **`BaseERC20`**，再部署 **`TokenBank`**，构造参数填入已部署的 **`BaseERC20` 地址**。若需从部署者以外账户存币，先 **`transfer` 一些 BERC20** 到该账户，再 **`approve(TokenBank, amount)`**，最后 **`deposit`** / **`withdraw`**。
