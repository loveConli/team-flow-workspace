# 六阶段纵向闭环编排（L4 Loop · Phase 0→6）

> 报告引用: §6.2 六阶段纵向闭环 / §8 产研全流程 Pipeline / §11 L4 行
> 定位: 端到端 Agent 产研流程的六阶段纵向闭环，每阶段有明确的输入、动作、质量门、工具和产出。
> 依赖: L3 Harness 已激活（至少 pre-push gate 硬卡）
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L4 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 六阶段总览

| Phase | 名称 | 输入 | 动作 | 质量门 | 工具 | 产出 | 工程归属 |
|-------|------|------|------|--------|------|------|----------|
| 0 | 上下文组织 | 需求材料 + 长期业务知识 | 拉取需求材料 + 长期业务知识，按阶段组织上下文 | 事实源缺失才人工补 | Aone API、钉钉文档、wiki 检索 | 上下文快照 | L2 上下文工程 |
| 1 | 需求澄清 | 上下文快照 | superai-clarify 生成 requirements | 人确认 | superai-clarify skill、CR 评论留痕 | requirements 文档 | L1 提示词 + L3 Harness |
| 2 | 技术方案 | requirements 文档 | superai-plan 写 plan.md | CR 确认 | superai-plan skill、superai-tjx、superai-mt | plan.md | L1 + L3 + L2 |
| 3 | 实现与内部质量门 | plan.md + tasks.md | superai-execute 按 TDD 改代码 | Pre-push Quality Gate | superai-execute skill、git hook、PMD、lint | 代码变更 + 测试 | L3 Harness + L1 |
| 4 | 协同反馈 | 代码变更 + CR 评论 | superai-aone 读写 CR 评论、milestone 回刷 | 所有 CR 评论 resolve | superai-aone skill、Aone API | 修改后代码 + resolved CR | L4 Loop + L3 Harness |
| 5 | 验收验证 | 修改后代码 + 验收标准 | HSF/SLS/监控核对 | 人工确认后才可主预发 | HSF、SLS、监控平台 | 验收证据 | L4 Loop + L3 Harness |
| gtmc | P3.5 业务流程校准 | 业务流程与已实现功能 | 对齐校准，产出差异清单 | gtmc 强制门禁（不可跳过） | workflow-check、差异清单工具 | 校准报告 | L4 Loop + L3 |
| gtmc | A-5.16 用户手册终验 | 用户手册与交付物 | 终验签署 | gtmc 强制门禁（不可跳过） | 手册终验工具 | 终验签署件 | L4 Loop |
| 6 | 发布与结项 | 验收通过的代码 | 观察期 + 结项蒸馏 | 观察期无异常 | SLS、监控、superai-finish | 稳定知识→wiki，改进→skill | L4 Loop |

## 状态机流转

```
DRAFT（需求起草）
  │ superai-clarify
  ▼
CLARIFYING（需求澄清）──► 质量门: 人工确认 ──► ✅ / ❌ WAITING_USER
  │ 人工确认通过
  ▼
DESIGNING（技术方案）──► 质量门: CR 确认 ──► ✅ / ❌ REVISING
  │ CR 通过
  ▼
IMPLEMENTING（实现）──► 质量门: pre-push gate ──► ✅ / ❌ REVISING
  │ git hook 通过
  ▼
TESTING（测试）──► 质量门: CI green + eco-gate ──► ✅ / ❌ REVISING
  │ CI 通过
  ▼
REVIEWING（评审）──► 质量门: 所有 CR resolve ──► ✅ / ❌ REVISING
  │ CR resolve
  ▼
VERIFYING（验证）──► 质量门: 人工确认 ──► ✅ / ❌ WAITING_USER
  │ 人工确认通过
  ▼
RELEASING（发布）──► 质量门: 观察期无异常 ──► ✅
  │
  ▼
CLOSED（结项）──► superai-finish 蒸馏
```

## 分支状态

| 分支 | 触发条件 | 处理方式 | 回归路径 |
|------|----------|----------|----------|
| **REVISING** | 质量门未通过（任意节点） | 记录修正项 → 重走修正后的 phase | 从 REVISING → 回到触发节点的前一 phase |
| **WAITING_USER** | 需要人工确认/决策 | 暂停执行 → 人工输入后恢复 | 从 WAITING_USER → 回到触发节点的下一 phase |
| **BLOCKED** | 外部依赖/致命错误 | 暂停执行 → 解决阻塞后继续 | 从 BLOCKED → 回到当前 phase |

## 质量门降级策略（§10.4 / degradation-channels.md）

| Phase | 质量门 | 降级通道 | 降级条件 |
|-------|--------|----------|----------|
| 1 | 人工确认 | WAITING_USER（最长等待） | 确认人不可用 |
| 2 | CR 确认 | WAITING_USER + 限期补 CR | 审查员不可用 |
| 3 | pre-push gate | 人工审查 + CI backstop | hook 未激活 |
| 4 | CR resolve | 人工 resolve + 限期 | CR 工具不可用 |
| 5 | 人工确认 | WAITING_USER + gtmc 校准替代 | HSF/SLS 不可用 |
| 6 | 观察期 | 缩短观察期 + 监控兜底 | 监控平台不可用 |

## 与 status-tracker 集成

- 每个 phase 转移时自动更新 `status-tracker.md` 机读块
- `phase` 字段 = 当前六阶段名称
- `state` 字段 = 当前活动状态（PENDING/IN PROGRESS/REVISING/BLOCKED）
- `last_event_id` 字段 = 最近一个质量门事件的 audit-log ID
- `ci_id` 字段 = 当前变更包的 CI 标识

## 激活条件

> ⚠️ L4 激活前提：L3 Harness 硬门禁已跑通

| 前提 | 状态 | 说明 |
|------|------|------|
| pre-push gate 激活 | 待激活（骨架已产出） | 必须 |
| eco-gate 激活 | 待激活（骨架已产出） | 必须 |
| status-tracker 可读 | 待激活（骨架已产出） | 必须 |
| audit-log 落盘 | 待激活（骨架已产出） | 必须 |
| CI required checks 注册 | 待激活（骨架已产出） | 必须 |

---
> 此文件为**编排骨架**。真实项目需按实际工具（Aone/HSF/SLS/监控）、API endpoint、质量门阈值填充。
> 六阶段闭环是 L4 的核心，建议先在 1-2 个真实需求上跑通全流程，再规模化。
