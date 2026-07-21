# 自我验收多层机制（L4 Loop）

> 报告引用: §6.3 自我验收闭环（多层机制）/ §6.2 阶段5 验收验证 / §10.4 审计总账闭合
> 定位: 建立 Agent 自我验收的多层机制，从简单自动化检查到复杂人工确认，确保产出质量。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L4 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 多层验收架构

> 报告 §6.3 提及「自我验收闭环（多层机制）」，以下为骨架定义。

```
Layer 1: 自动化检查层（机器可验证）
  │
  ├─ 静态分析通过（PMD/lint）
  ├─ 测试通过（单元/集成）
  ├─ 覆盖率达标
  ├─ 代码风格合规
  └─ 审计日志闭合（idempotency_key 无重复、CI-ID 一致）
  │
  ▼ 全部通过 → Layer 2
  │ 任一失败 → REVISING / BLOCKED
  │
Layer 2: 契约验证层（半自动）
  │
  ├─ 接口契约一致性（API schema 比对）
  ├─ 数据库 schema 一致性（迁移脚本验证）
  ├─ 配置 schema 校验（superai-tjx / superai-mt）
  └─ 跨域影响面校验（仅架构注册表可用时）
  │
  ▼ 全部通过 → Layer 3
  │ 任一失败 → WAITING_USER（人工确认是否可降级）
  │
Layer 3: 业务逻辑验证层（半自动 + 人工）
  │
  ├─ 正例测试（验证预期行为）
  ├─ 反例测试（验证异常处理）
  ├─ 回归测试（验证不破坏既有功能）
  └─ HSF/SLS/监控核对（gtmc 项目强制）
  │
  ▼ 全部通过 → Layer 4
  │ 任一失败 → REVISING
  │
Layer 4: 人工确认层（最终 gate）
  │
  ├─ 人工验收（PD/业务方确认）
  ├─ 架构审查（聚合根/跨域变更须 CCB/ARB）
  ├─ gtmc P3.5 业务流程校准（gtmc 项目强制）
  └─ gtmc A-5.16 用户手册终验（gtmc 项目强制）
  │
  ▼ 全部通过 → RELEASING
  │ 任一失败 → WAITING_USER / BLOCKED
```

## 各层验收标准定义

### Layer 1: 自动化检查（机器可验证）

| 检查项 | 工具 | 通过标准 | 失败处理 |
|--------|------|----------|----------|
| 静态分析 | PMD / ESLint / Checkstyle | 0 critical / 0 blocker | REVISING（修正后重跑） |
| 单元测试 | Jest / JUnit / pytest | 100% 通过 | REVISING |
| 覆盖率 | JaCoCo / Istanbul / Coverage.py | ≥ 阈值（默认 80%） | REVISING |
| 代码风格 | 项目自定义风格检查 | 0 违规 | REVISING |
| 审计闭合 | audit-log.jsonl 校验器 | idempotency_key 无重复、CI-ID 一致 | BLOCKED（数据不一致，需人工审查） |

### Layer 2: 契约验证（半自动）

| 检查项 | 工具 | 通过标准 | 失败处理 |
|--------|------|----------|----------|
| API 契约 | OpenAPI diff / Schema 校验 | 契约无破坏性变更 | WAITING_USER（确认是否允许破坏性变更） |
| DB 契约 | Flyway / Liquibase 校验 | 迁移脚本可执行、可回滚 | WAITING_USER |
| 配置契约 | superai-tjx / superai-mt | schema 校验通过 | REVISING（修正配置） |
| 跨域影响 | ArchUnit / 架构注册表查询 | 无未声明的跨域依赖 | WAITING_USER（人工确认影响面） |

### Layer 3: 业务逻辑验证（半自动 + 人工）

| 检查项 | 工具 | 通过标准 | 失败处理 |
|--------|------|----------|----------|
| 正例测试 | 功能测试 / E2E 测试 | 所有正例通过 | REVISING |
| 反例测试 | 异常场景测试 | 所有反例正确报错 | REVISING |
| 回归测试 | 全量测试套件 | 既有测试 100% 通过 | BLOCKED（可能引入严重回归） |
| HSF 泛化调用 | HSF 测试框架 | 调用成功、返回预期 | WAITING_USER |
| SLS 查询核对 | SLS 查询 | 日志与预期一致 | WAITING_USER |
| 监控核对 | 监控平台 | 无异常告警 | WAITING_USER |

### Layer 4: 人工确认（最终 gate）

| 检查项 | 审批人 | 通过标准 | 失败处理 |
|--------|--------|----------|----------|
| 业务验收 | PD / 业务方 | 业务方 sign-off | WAITING_USER（修改后重验） |
| 架构审查 | CCB / ARB | 架构委员会批准 | BLOCKED（重新设计） |
| gtmc P3.5 校准 | gtmc 业务专家 | 差异清单为空或已审批 | BLOCKED（不可跳过） |
| gtmc A-5.16 终验 | gtmc 用户代表 | 终验签署件 | BLOCKED（不可跳过） |

## 验收状态机

```
自动化检查中
  │ 全部通过
  ▼
契约验证中
  │ 全部通过
  ▼
业务逻辑验证中
  │ 全部通过
  ▼
人工确认中
  │ 全部通过
  ▼
验收通过（VERIFYING → RELEASING）
```

任何一层失败都可能触发 REVISING（退回修正）或 WAITING_USER（等待人工输入）或 BLOCKED（阻塞）。

## 与 eco-gate 协同

- Layer 1-3 的结果作为 eco-gate 的输入证据
- 只有通过 Layer 4 人工确认后，eco-gate 才允许 merge
- 验收证据（测试报告、校准报告、终验签署件）纳入 CI required checks 边界

---
> 此文件为**验收骨架**。真实项目需按实际工具链、阈值、审批人列表填充。
> 建议从 Layer 1 开始逐步激活，每添加一层验证至少跑通 3 个需求后再加下一层。
