# L4/L5 设计契约附录（Design Contract Stub）

> 状态：📌 **设计契约 stub / TODO / 未实现（deferred）**。本文件钉死 L4 Loop 与 L5 Agent Team 的硬约束契约；当前阶段 **L4/L5 不实现**，仅留此契约与设计要点，待后续落地。
> 依据：四专家评审结论 P0-D（L4/L5 TODO 升级为设计契约 stub）。
> 全仓检索可命中关键词（务必保留）：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。
> 引用方：`l4-loop-engineering/*`、`l5-agent-team/*` 各文件顶部 TODO 标记。

---

## 0. 总原则

- L4 Loop 与 L5 Agent Team **前期不实现**（决策背景已与 LT 对齐）。
- 任何 L4/L5 相关描述**不得伪装成「已实现」**；仅以 stub + 设计契约形式存在，所有相关文件顶部标注 TODO/deferred。
- 在 L4 实现前，`REVISING` / `WAITING_USER` 由 **LT 人肉驱动**（见人工门 F）。

---

## 1. MAX_CYCLES 与熔断（关键词：`MAX_CYCLES` / `熔断`）

- 常量：`MAX_CYCLES`（**默认 6**）。
- 触发强制升级（**禁止** Loop 自调度「再试一次」）：
  - `cycle_count >= MAX_CYCLES`；**或**
  - 同一 bug 修复 `>= 3` 次（重复失败升级）。
- 触发动作：强制抛 `WAITING_USER` / `BLOCKED`，**禁止**自调度下一轮「再试一次」。
- 熔断事件：写 `audit-log.jsonl`，条目**必须含 `reason` 字段**（说明熔断原因）。
- 出处参考：spec-superflow bug-investigator **DP-5（3+ 次失败升级熔断）**。

---

## 2. 独立 Judge 角色 + 剔 Builder 覆盖清单（关键词：`独立 Judge` / `Builder 覆盖清单`）

- **Judge = 独立 Agent**：不持有 Builder 上下文；从 `spec` / `plan` / `contract` **重推**应验证范围。
- **严禁采信 Builder 自报覆盖清单**（防自证陷阱）：Judge 自行推导验证范围，不读 Builder 自算清单。
- 双裁决：`spec-compliance`（规格符合度）+ `code-quality`（代码质量）。
- 输出结构化 **diagnostic envelope**：`{ severity, code, message, target, fix }`。
  - 出处：OpenSpec `diagnostic envelope` 约定。
- 终态判定用**独立更强/不同模型档**，与 Builder 模型**隔离**。
- Judge **不得接受 Builder 自算校验和**作为证据。
- 出处参考：superpowers「**Do Not Trust the Report**」/ task-reviewer **Missing-Extra-Misunderstood**（漏/多/误三类审查）。

---

## 3. `/goal` 独立模型判终态钩子

- 钩子签名：`loop_judge_terminal(goal_state, evidence) -> { met, gaps }`。
- 与 Builder 模型**隔离**（由独立模型档执行终态裁决）。
- 用于否决议 Loop 自报「完成」，防止 Builder 自判终态。

---

## 4. version-lock 作 Loop 事实源

- `traceability-version-lock.json`（artifact-graph）作 Loop **事实源**。
- 形态：`append-only` + **SHA256 哈希链**（每轮追加，前驱 hash 入链）。
- 每轮 cycle 的副作用须**挂账**（append 本轮 effect ledger），供 Judge 对账（与审计总账闭合一致）。
- 与 K1 双真相源一致：version-lock 管「结构/追溯/版本」；`status-tracker`（瘦身）管「需求流程态」。

---

## 5. 合并代理提前下沉为 L4 安全约束

- 即便**单 Agent**，push 主干仅经 `eco-gate` + **单一可信写入方**（合并代理语义从 L5 提前下沉到 L4 即生效）。
- 单一可信写入方 = 唯一可写主干角色（同 L5 合并代理语义，L4 起即生效，杜绝多写方并发污染主干）。

---

## 6. 参考仓库纪律预留（写明出处）

| 纪律 | 出处 | 落到本契约的条款 |
|------|------|------------------|
| 不采信 Agent 自报结论 | superpowers「**Do Not Trust the Report**」 | §2 独立 Judge、§3 独立终态钩子 |
| 漏/多/误三类审查 | superpowers task-reviewer **Missing-Extra-Misunderstood** | §2 双裁决 + diagnostic envelope |
| 3+ 次失败升级熔断 | spec-superflow bug-investigator **DP-5** | §1 MAX_CYCLES / 熔断 |
| 结构化诊断信封 | **OpenSpec** `diagnostic envelope` | §2 `{severity,code,message,target,fix}` |
| 独立终态判定 | **spec-kit** `/speckit.converge` | §3 终态由独立流程裁决，非 Builder 自判 |

---

## 7. 与现有蓝图衔接

- 本契约由 `l4-loop-engineering/01~05-*.md` 与 `l5-agent-team/01~05-*.md` 顶部 TODO 标记引用。
- L4 熔断决策门（人工门 **F**）在 `status-tracker/status-tracker.schema.md` 状态机迁移规则中显式登记（见 P0-C）。
- 落地前：所有 L4/L5 文件维持「设计+骨架，不激活」，仅此处契约为硬约束锚点。
