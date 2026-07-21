# tasks.md — 任务分解文档模板（SDD 阶段2）

> 报告引用: §3 提示词工程 / §6.2 阶段3 实现与内部质量门 / §8 Pipeline
> 定位: SDD 三文档第三阶：spec → plan → tasks。每个任务原子化、可独立完成和验证。
> 质量门: Pre-push Quality Gate（PMD + 覆盖率 + git hook 硬卡）
> 标签: 【来源已核验✅】

## 任务清单

> 原则：
> 1. **任务粒度原子化**：每个任务足够小，可独立完成和验证（≤30分钟或≤200行变更）。
> 2. **严格遵循 TDD**：先写测试定义对错，再写代码通过测试。每个任务标记 TDD 状态。
> 3. **标记无依赖的并行任务**：明确哪些任务可并行执行（多 Worker 或单 Agent 多步骤并行）。
> 4. **明确阶段划分**：任务按阶段组织，有清晰的先后顺序。

### 阶段1：基础设施与测试准备
| 任务ID | 描述 | TDD | 并行 | 依赖 | 状态 |
|--------|------|-----|------|------|------|
| T-001 | ... | ✅ | 是 | 无 | ⏳PENDING |
| T-002 | ... | ✅ | 是 | 无 | ⏳PENDING |

### 阶段2：核心实现
| 任务ID | 描述 | TDD | 并行 | 依赖 | 状态 |
|--------|------|-----|------|------|------|
| T-003 | ... | ✅ | 否 | T-001 | ⏳PENDING |
| T-004 | ... | ✅ | 否 | T-002 | ⏳PENDING |

### 阶段3：集成与验证
| 任务ID | 描述 | TDD | 并行 | 依赖 | 状态 |
|--------|------|-----|------|------|------|
| T-005 | ... | ✅ | 否 | T-003, T-004 | ⏳PENDING |
| T-006 | ... | ✅ | 否 | T-005 | ⏳PENDING |

## 变更追踪
- 变更包ID: `[CHANGE_PACKAGE_ID]`（关联 status-tracker.ci_id）
- 关联 plan.md: `[PLAN_FILE_PATH]`
- 关联 spec.md: `[SPEC_FILE_PATH]`
- 审计日志起始事件: `[START_EVENT_ID]`（对应 audit-log.schema.md 的 idempotency_key）

## 状态机记录
- 当前 Phase: `IMPLEMENTING`
- 下一活动: 测试（CI 校验 + eco-gate）
- 质量门: Pre-push Quality Gate（PMD + 覆盖率 + git hook 硬卡）
- 禁止：未过 pre-push gate 直接 push

---
> 填写说明：每个需求一份 tasks.md。产出后进入 `IMPLEMENTING`，按 TDD 原则逐任务执行。
> 每个任务完成须更新状态并触发 pre-push gate（若已激活）。
