# 架构 / API / DB 设计增强方案 · v0.17（workflow-start 编排模式修正）

> 版本：v0.17 · 重大修订（增量式，承袭 v0.16）
> 目标插件版本：**v0.39.0**
> 修订依据：workflow-feedback 2026-08-06（vrm4teamflow C2-policy-management 项目）—— workflow-start 一次性安排 build-executor 执行所有 wave，期望 build-executor 自行安排 code-review，但 build-executor 无 Agent tool 无法 dispatch code-reviewer，导致 5 个 wave 全部未执行代码审查。
> 决策确认：LT 2026-08-06 决策 ✅
>
> **v0.17 修订摘要（相较 v0.16）**：
> - **§72 workflow-start 编排模式修正**：从"一次性安排 + 被动等待"改为"主动串行编排"——workflow-start 在每个 wave 完成后主动 dispatch code-reviewer，而非期望 build-executor 自行安排 review。
>
> **v0.16 修订摘要（相较 v0.15，承袭保留）**：
> - **§70 test-merge 五 bug 修复**：resolveDeferred 误删 Current Cases / extractSummary 遇 bold 返回 0 / dry-run 实为真写 / mergeExistingBaseline 覆盖式失效 / filter(Boolean) 空列错位。
> - **§71 E2E case 记录与复利闭环**：test-matrix 支持 `test_tier=e2e`（实现补齐 §42.4 三值承诺）、test-merge 复利回写 E2E 层级、release-archivist Step 5b 下游 E2E 确认（AskUserQuestion）、LLM 消费点豁免。
>
> **v0.15 修订摘要（相较 v0.14，承袭保留）**：
> - **§68 阶段同步与原型版本隔离**：5 同步门禁点（S2 冻结 / ARCH 完成 / orchestrator 结束 / execution-contract 完成 / change closing）+ 统一命令 `tf publish` + 原型版本 worktree 隔离（merge 时机=版本收尾）+ 制品链路径版本化修正 + 团队同步闭环（push prd-vN 分支 + 一键拉取）。
> - **§69 决策落实状态**：本次决策逐条记录。
>
> **v0.14 修订摘要（相较 v0.13，承袭保留）**：
> - **§57 总览**：现状三缺口（复利闭环断裂 / 无产品级架构层 / 旧项目无着手路径）+ 三诉求映射到新机制。
> - **§58 设计原则**：四条评审共识（P1 全局=实际态快照=预测态 / P2 机器管结构人管语义 / P3 门禁硬但留逃生舱 / P4 增量有界演进可溯）。
> - **§59 architecture 阶段编排**：S3.5 新阶段 + 场景判定 + skip 物化 + arch-readiness/arch-snapshot 门禁 + arch_baseline 豁免键。
> - **§60 产品级架构文档体系与模板**：三层数据面 + 6 产物模板 + 正向/逆向设计 + 按域分段加载。
> - **§61 变更级架构设计联动**：输入契约扩展 + 五项检查路由分流 + 分工边界 + 防重发明机制。
> - **§62 全局复利回写重构**：arch-merge 从 append 重构为当前态幂等 upsert + 生成式产物 + 冲突预检 + 并发安全 + api-scan。
> - **§63 旧项目适配**：arch_baseline 豁免 + 场景判定 + 逆向重建 + 分层渐进（L0+L1）+ 在途 change 兼容。
> - **§64 实现分层**：v0.36.0 P0 八项 + 后续 P1-P3 深化项。
> - **§65 文档登记**：v0.14 登记点 + Roadmap 待办。
> - **§66 验证方案**：E2E 主线 + Tier1 确定性 fixture 负例。
> - **§67 决策落实状态**（补 v0.13 缺失章节）：本次决策逐条记录。

---

## 七十二、workflow-start 编排模式修正（v0.39.0）

### 72.1 问题描述

**触发来源**：workflow-feedback 2026-08-06（vrm4teamflow C2-policy-management 项目）

**现象**：
1. build-executor 完成了全部 5 个 wave 的实施（W1-B1 ~ W5-B7，92 tests pass），但每个 wave 完成后均未执行代码审查。guard check (`executing → closing`) 返回 5 条 `review receipt missing`。
2. 主代理在 code-reviewer 返回 findings 后，直接执行 Read + Edit 修改前端代码，而非通过 SendMessage 通知 build-executor。
3. F-15 + F-16 修复完成后，主代理直接路由到 release-archivist，没有经过 re-review 确认修复有效，也没有记录 review receipt。

**根因分析**：

| 根因 | 类型 | 责任方 | 说明 |
|------|------|--------|------|
| **编排模式错误** | 编排设计 | workflow-start | 一次性安排所有 wave，被动等待，期望 build-executor 自行安排 review |
| **通信机制缺失** | 架构设计 | workflow-start + build-executor | build-executor 完成 wave 后无法通知 workflow-start |
| **prompt 矛盾** | agent definition | workflow-start | 要求 build-executor "run code review"，但 build-executor 没有 Agent tool，无法 dispatch code-reviewer |
| **产物所有权约束违反** | agent definition | workflow-start | 主代理直接修改子代理代码文件，违反"Artifact Ownership"规则 |
| **修复后缺少 re-review** | 编排设计 | workflow-start | 修复后没有 re-review 确认修复有效，也没有记录 review receipt |

**证据链**：

1. workflow-start dispatch build-executor 时的指令包含"After each wave, run code review"
2. build-executor 的 SKILL.md 第 116-122 行要求"After every wave, write a review report and record receipt"
3. 但 build-executor 的 tools 只有 `["Read", "Bash", "Grep", "Glob", "Write", "Edit"]`，**没有 Agent tool**
4. build-executor 日志中**没有** `dispatch.*code-reviewer` 记录
5. 主会话中只有 1 次 code-reviewer dispatch（用户手动干预后的补救审查）
6. workflow-start dispatch code-reviewer 时传递了完整上下文（worktree 路径、git repos、commits、specs、architecture），说明 workflow-start **知道**如何传递上下文

### 72.2 改进方案

**P1-12：workflow-start 主动串行编排（方案 A）**

从"一次性安排 + 被动等待"改为"主动串行编排"：

**当前逻辑**（错误）：
```
workflow-start dispatch build-executor (执行所有 wave)
workflow-start 被动等待 build-executor 完成
workflow-start 检查 review receipt（发现缺失）
```

**改进逻辑**（正确）：
```
for each wave in waves:
    workflow-start dispatch build-executor (只执行当前 wave)
    workflow-start 等待 build-executor 完成
    workflow-start dispatch code-reviewer (审查当前 wave)
    workflow-start 等待 review receipt + verdict=pass
    workflow-start 通知 build-executor 开始下一 wave
```

**P1-13：build-executor prompt 修正**

修改 build-executor 的 SKILL.md：
- 移除"After every wave, write a review report and record receipt"（因为 build-executor 无法 dispatch code-reviewer）
- 改为"After every wave, notify workflow-start via SendMessage that wave is complete and needs review"

**P1-14：workflow-start 产物所有权约束强化**

**问题**：主代理在 code-reviewer 返回 findings 后，直接执行 Read + Edit 修改前端代码，而非通过 SendMessage 通知 build-executor。

**改进方案**（三层防护）：

**第一层：workflow-start agent definition 显式约束**

在 `agents/workflow-start.md` 的 Guardrails 段增加：
```
- **MUST NOT directly Edit/Write any file under `changes/<name>/` or `.worktrees/`** — always delegate to sub-agents via SendMessage. This applies to all code files, regardless of change size.
- **MUST NOT transition to closing without all planned wave review receipts recorded as `pass`** — re-review after fix is mandatory.
```

**第二层：workflow-start SKILL.md review findings 处理流程标准化**

在 workflow-start SKILL.md 中增加：
```
### Review Findings 处理流程（v0.39.0）

当 code-reviewer 返回 findings 时，workflow-start 必须：
1. 分析 findings 的严重程度（Critical/Important/Minor）
2. 通过 SendMessage 将 findings 转发给 build-executor
3. 等待 build-executor 修复并返回结果
4. 禁止直接 Read/Edit/Write 任何代码文件

### 修复后 Re-review 流程（v0.39.0）

build-executor 修复 findings 后，workflow-start 必须：
1. dispatch code-reviewer 进行 re-review
2. 等待 re-review 结果
3. 如果 re-review 通过，记录 review receipt（verdict=pass）
4. 如果 re-review 不通过，重复修复流程
5. 禁止在 review receipt 未记录或 verdict!=pass 时进入下一阶段

### Closing 前置条件检查（v0.39.0）

在路由到 release-archivist 之前，workflow-start 必须检查：
- 所有 planned wave 的 review receipt 是否存在
- 所有 review receipt 的 verdict 是否为 pass
- 如果任何 receipt 缺失或 verdict!=pass，阻断并要求 re-review
```

### 72.3 设计决策

| 决策项 | 决策 | 理由 |
|------|------|------|
| 编排模式 | workflow-start 主动串行编排 | build-executor 无 Agent tool，无法自行 dispatch code-reviewer |
| 通信机制 | build-executor 通过 SendMessage 通知 workflow-start | 复用既有通信机制，无需新增工具 |
| 逐 wave 审查 | 每个 wave 完成后立即审查 | 符合"逐 wave 审查纪律（v0.36.4）"，避免问题延迟发现 |
| 产物所有权 | 主代理禁止直接修改子代理代码 | 保持产物所有权清晰，避免 commit 溯源困难 |
| 修复后 re-review | 修复后必须 re-review 确认修复有效 | 确保修复质量，避免问题残留 |
| closing 前置条件 | review receipt 存在且 verdict=pass | 确保所有 wave 审查通过后才能进入归档阶段 |

### 72.4 实现范围

| 改进项 | 修改文件 | 影响范围 |
|------|----------|----------|
| workflow-start 主动串行编排 | `skills/workflow-start/SKILL.md` | Route to build-executor、Route to code-reviewer |
| build-executor prompt 修正 | `skills/build-executor/SKILL.md`、`agents/build-executor.md` | wave review 相关指令 |
| workflow-start 产物所有权约束强化 | `agents/workflow-start.md`、`skills/workflow-start/SKILL.md` | Guardrails、review findings 处理流程 |
| 修复后 re-review 流程 | `skills/workflow-start/SKILL.md` | 修复后 re-review 流程、closing 前置条件检查 |

### 72.5 验证方案

1. **E2E 验证**：在 vrm4teamflow 项目中创建新的 change，执行 full workflow，验证 workflow-start 在每个 wave 完成后主动 dispatch code-reviewer
2. **回归验证**：验证 hotfix/tweak 模式不受影响
3. **边界验证**：验证 parallel wave 的审查逻辑（多个 task 作为整体审查一次）
4. **产物所有权验证**：验证 workflow-start 在 code-reviewer 返回 findings 后，通过 SendMessage 通知 build-executor 修复，而非直接修改代码
5. **修复后 re-review 验证**：验证 build-executor 修复 findings 后，workflow-start dispatch code-reviewer re-review，并记录 review receipt
6. **closing 前置条件验证**：验证 workflow-start 在路由到 release-archivist 之前，检查所有 review receipt 存在且 verdict=pass

---

## 七十三、决策落实状态（v0.17）

| 决策点 | 决策 | 版本 | 状态 |
|---|---|---|---|
| 编排模式 | workflow-start 主动串行编排 | v0.39.1 | ✅ 已实施 |
| 通信机制 | build-executor SendMessage 通知 | v0.39.1 | ✅ 已实施 |
| 逐 wave 审查 | 每个 wave 完成后立即审查 | v0.39.1 | ✅ 已实施 |
| 产物所有权 | 主代理禁止直接修改子代理代码 | v0.39.1 | ✅ 已实施 |
| 修复后 re-review | 修复后必须 re-review 确认修复有效 | v0.39.1 | ✅ 已实施 |
| closing 前置条件 | review receipt 存在且 verdict=pass | v0.39.1 | ✅ 已实施 |
