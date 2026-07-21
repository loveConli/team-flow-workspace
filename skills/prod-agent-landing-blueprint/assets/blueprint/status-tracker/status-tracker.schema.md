# status-tracker 结构化字段规范（需求流程态真相源 / 双真相源之一）

> 报告引用: §9 H2 决策 / §9.1 / §9.2 / §10.4
> **K1 双真相源定位**: `requirement/status-tracker.md` = **需求流程态真相源**，与 `artifact-graph` 并存、**不互相替代**。
> - `artifact-graph` = **结构 / 追溯 / 版本真相源**（`config.yaml` + `traceability-version-lock.json`）。
> - `status-tracker`（瘦身）= **需求流程态真相源**，仅承载下方**七字段**（artifact-graph 不覆盖此七字段）。
> **唯一写入方**: status-tracker 仅由**合并代理 / LT**（单一可信写入方）维护；与 L5 合并代理语义一致，L4 起即生效。
> 机制: 每次会话由 workflow-check **只读读取**；活动完成必更新。
> 标签: 【来源已核验✅·落地依赖Hook配置⚠️】（落地依赖 workflow-check 读取器/Hook 配置）

## 一、机器可解析字段（必填，供 10.4 eco-gate 与 CI 自动读取）
避免仅自然语言描述导致判定不可机读。以下 7 字段须以「机读块」形式出现（见第二节格式）。

| 字段 | 含义 | 取值 |
|------|------|------|
| `state` | 活动状态（workflow-check 四态） | `⏳PENDING` / `🔄IN PROGRESS` / `🔁REVISING` / `⏸️BLOCKED` |
| `phase` | 需求级状态机当前阶段 | 见第三节枚举 |
| `activity` | 当前具体活动（Pipeline 活动） | 如「实现与内部质量门」 |
| `owner` | 责任方/维护者（人工或 LLM 视图归属） | 如 `LT` |
| `ci_id` | CI 检查标识，关联变更包与 CI | 如 `ci-2026-0711-0042` |
| `last_event_id` | 最近一条审计事件 ID（支撑总账闭合/崩溃恢复） | 如 `ev-000123` |
| `blocked_reason` | 阻塞原因（仅 `⏸️BLOCKED` 时填） | 自由文本 |

## 二、机读块格式（建议放在文件顶部注释块，供脚本正则解析）
```markdown
<!-- status-tracker-machine-readable
state: 🔄IN PROGRESS
phase: IMPLEMENTING
activity: 实现与内部质量门
owner: LT
ci_id: ci-2026-0711-0042
last_event_id: ev-000123
blocked_reason: ""
-->
```

## 三、phase 枚举 = 需求级状态机（§9.2）
主干（线性推进）：
```
DRAFT → CLARIFYING → DESIGNING → IMPLEMENTING → TESTING
     → REVIEWING → VERIFYING → RELEASING → CLOSED
```
分支（任意节点可转出）：
- `REVISING`（退回修正）：可从主干**任意节点**转出
- `WAITING_USER`：在**人工确认点**挂接
- `BLOCKED`：发生**阻塞**时挂接

> 补充说明（§9.2 六态关联映射）：草稿/评审中 ↔ ⏳PENDING/🔄IN PROGRESS（未发布可自由改）；
> 已发布 ↔ 进入 published 基线，任何改动触发升级评估；已变更 ↔ 🔁REVISING（须走 ECO 闭环）；
> 退役/归档 ↔ 退出活跃基线，变更须先复活。Run/Step/waiting_user 描述 Agent 执行态，与六态正交。

## 三（补）、需求级状态机人工门（PAUSE / go 需人）— 评审 P0-C

> 以下人工门在状态机迁移规则中**显式强制**：凡标注「人工 PAUSE」的迁移节点，未经人确认不得自动越过；`WAITING_USER` 须由 LT 显式拍板后才恢复。
> L4 熔断决策门（F）硬约束见包根 `design-contract-stub.md`（关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`）。

- **A 进入实现授权门**：`DESIGNING` → `IMPLEMENTING` **必过一次人工 PAUSE**；`design` 制品**不得由生成它的 AI 自审**（正中「AI 不能完全出完整方案」误区，须独立人/评审拍板）。
- **B 发布门**：`RELEASING` → `CLOSED` **人工拍板**；涉**外部 API / 付费 / 权限变更**必过此门。
- **C ECO 升级评估门**：已发布基线**任何改动** → 进入 `WAITING_USER` 升级评估（走 ECO 闭环，触 C 即不得静默直改）。
- **D 越权/高成本操作门**：调**外部 API / 花钱 / 改权限**前**人工确认**（须经 eco-gate / 权限框架拦截，不得默认放行）。
- **E 知识蒸馏门**：蒸馏产物**人工审查（`WAITING_USER`）后**方可执行写入（稳定知识→wiki、反复问题→skill/prompt）。
- **F L4 熔断决策门**：闭环自验不过或**熔断**时，由人决定**接受 / 继续 / 放弃**（见 `design-contract-stub.md`）。**L4 实现前**：`REVISING` / `WAITING_USER` 由 **LT 人肉驱动**，不得伪装成自动闭环；`cycle_count >= MAX_CYCLES` 或同 bug 修复 ≥3 次 → 强制 `WAITING_USER`/`BLOCKED`，禁止自调度「再试一次」，熔断事件写 `audit-log.jsonl` 含 `reason`。

## 四、内容要素（§9.1）
各 Phase/活动状态、待审阅项、产出索引、版本化。
- 版本化：每次手维护更新建议带版本号与时间戳。
- 产出索引：关联各阶段出口制品路径。

## 五、落地依赖（⚠️）
- `workflow-check` 只读读取器需通过 Hook 配置挂载，才能自动读机读块。
- 当前环境：schema 可机读校验，但读取器/真实 `requirement/` 目录待配 → 仅部分可跑。

> 完整示例见 `status-tracker.example.md`。
