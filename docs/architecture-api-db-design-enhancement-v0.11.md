# 架构 / API / DB 设计增强方案 · v0.11（Agent 补全 + 项目级规范被动沉淀机制）

> 版本：v0.11 · 重大修订（增量式，承袭 v0.10）
> 目标插件版本：**v0.28.0**（占位；最终以 P4 `npm version` 为准）
> 修订依据：v0.10 全量内容**继续有效**；v0.11 仅记录本次增量修订。
> 触发来源：workflow-feedback 2026-07-31（P1 agent-quality + P2 artifact-quality）
>
> **v0.11 修订摘要（相较 v0.10）**：
> - **§32 architecture-design agent 创建**：解决 routing-rules.md 引用为 sub-agent 但实际只有 skill 定义的类型不匹配问题。基于现有 agent 格式创建 `/agents/architecture-design.md`，五项检查逻辑封装为 agent 独立执行。横展确认：workflow-start 路由体系 9 个目标中仅此处存在不匹配。
> - **§33 项目级规范被动沉淀机制**：新增 conventions 配置段 + `.team-flow/conventions/` 目录 + 被动式自动沉淀（用户纠正时建议 + 阶段转换前主动建议）。各阶段 skill 上下文加载时读取 conventions 注入为约束。
> - **§34 architecture-reviewer agent 创建**：架构设计自动审查子代理。参考 prototype-reviewer 设计模式（独立上下文 + 只读 + 分层检查 + 循环修正），对照 PRD/plan/change-brief + 全局基线 + conventions 审查架构产出质量。填补 architecture-design 阶段"设计完无审查"的缺口。

---

## 三十二、architecture-design agent 创建（v0.28.0）

### 32.0 问题诊断

`workflow-start/references/routing-rules.md` 第 12 行明确写：

> Dispatch `architecture-design` as sub-agent with inputs

但 `architecture-design` 仅存在于 `skills/architecture-design/` 目录（16 个文件，含 SKILL.md + chapters/ + templates/），`agents/` 目录下**不存在** `architecture-design.md` 定义文件。

**后果**：workflow-start 无法以 `Agent` 工具自动派发，只能通过 `Skill` 工具手动调用，routing-rules 描述与实际机制不一致。

### 32.1 横展验证

扫描 workflow-start 全部 9 个路由目标：

| # | 路由目标 | 引用方式 | Skill | Agent | 判定 |
|---|---------|---------|:-----:|:-----:|:----:|
| 1 | need-explorer | Route to | ✅ | ❌ | ✅ 仅路由 skill |
| 2 | **architecture-design** | **Dispatch as sub-agent** | ✅ | ❌ | ⚠️ **类型不匹配** |
| 3 | spec-writer | Route to | ✅ | ❌ | ✅ 仅路由 skill |
| 4 | contract-builder | Route to | ✅ | ❌ | ✅ 仅路由 skill |
| 5 | build-executor | Route to | ✅ | ❌ | ✅ 仅路由 skill |
| 6 | bug-investigator | Route to | ✅ | ✅ | ✅ 正常 |
| 7 | code-reviewer | Route to | ✅ | ✅ | ✅ 正常 |
| 8 | release-archivist | Route to | ✅ | ❌ | ✅ 仅路由 skill |
| 9 | spec-writer | Route to | ✅ | ❌ | ✅ 仅路由 skill |

**结论**：仅 `architecture-design` 存在 skill/agent 类型不匹配，其他 8 个引用正确。

### 32.2 方案设计

**创建 `/agents/architecture-design.md`**，基于现有 agent 格式（参考 `change-split-auditor.md` / `code-reviewer.md`）：

#### Agent 定义结构

```yaml
---
name: architecture-design
description: 架构设计门控 agent——执行五项检查，判断是否需要架构设计，若需要则产出三件套（architecture.md + database.md + api.md）+ SQL 制品
model: inherit
color: blue
tools: ["Read", "Bash", "Grep", "Glob", "Write", "Edit"]
---
```

#### Agent 职责

1. **五项检查**（聚合 / 限界上下文 / CQRS / API / DB schema 变更）
2. **判断门控**：`decision: required | skipped`
3. **若 required**：产出 `architecture/architecture.md` + `database.md` + `api.md` + `sql/` 制品
4. **结构化输出**：返回 YAML（decision + reason + artifacts）

#### Agent 输入

| 输入文件 | 来源 |
|---------|------|
| `changes/<name>/change-brief.md` | orchestrator S4 交接物 |
| `prd/vN/plan.md` | ce-plan 产出 |
| `changes/<name>/specs/` | 现有规格（如有） |
| `docs/architecture/INDEX.md` | 全局架构索引 |
| `docs/architecture/ARCHITECTURE.md` | 架构基线 |
| `docs/architecture/PHYSICAL-MODEL.md` | 物理模型（按需） |
| `docs/architecture/schema-baseline.sql` | DDL 基线（按需） |
| `docs/architecture/API-INDEX.md` | API 端点索引（按需） |

#### Agent 输出

```yaml
decision: required  # or skipped
reason: "涉及 3 个新聚合、2 个限界上下文变更、1 个新 API 端点"
artifacts:
  - architecture/architecture.md
  - architecture/database.md
  - architecture/api.md
  - architecture/sql/ddl/new_tables.sql
  - architecture/sql/migration/data_migration.sql
```

#### 与 SKILL.md 的关系

| 维度 | SKILL.md（skill 模式） | Agent（agent 模式） |
|------|----------------------|-------------------|
| 调用方式 | `Skill` 工具 | `Agent` 工具 |
| 执行模式 | 交互式（用户可介入） | 自主（独立上下文） |
| 上下文预算 | ~2K tokens（硬编码） | 继承 agent 定义 |
| 适用场景 | 用户显式调用 | workflow-start 子代理调用 |

**共存策略**：SKILL.md 保留，供用户显式调用；Agent 定义新增，供 workflow-start 子代理调用。两者共享 chapters/ 和 templates/ 资源。

### 32.3 routing-rules.md 无需修改

routing-rules.md 已正确描述子代理调用模式，只需创建 agent 定义即可匹配。

---

## 三十三、项目级规范被动沉淀机制（v0.28.0）

### 33.0 问题诊断

各阶段（architecture-design / spec-writer / build-executor）缺少项目级自定义规范注入机制。例如：
- **DB 设计规范**：表名 `t_` 前缀、主键 `t_sequence_generator`、审计字段 `BaseEntity`
- **后端分层规范**：DDD 四层（web/application/domain/infrastructure）+ assembler（MapStruct）
- **API 规范**：GLAF4 注解（`@PostResource/@GetResource`）、权限声明（`hasAuthority`）
- **前端规范**：Vue 2 Options API、Ant Design Vue 1.7、v-has 权限指令

这些规范目前靠 CC 在执行时"记住"，没有结构化注入。

### 33.1 方案设计：被动式自动沉淀

**核心理念**：不让用户主动维护，而是 CC 在两个时机自动触发规范沉淀。

#### 时机 1：用户纠正时自动建议

```
用户：这个表名不对，应该加 t_ 前缀
CC：收到，已修正表名为 t_xxx。

    💡 这条纠正涉及 DB 命名规范，是否应该沉淀到项目级规范中？
    - 是 → 自动追加到 .team-flow/conventions/db-design.md
    - 否 → 仅修正本次产出
```

**触发条件**：
- 纠正涉及命名规范、分层规范、注解规范等**可复用模式**
- 纠正不是针对本次 change 的特定业务逻辑
- 纠正具有**跨 change 适用性**

#### 时机 2：阶段转换前主动建议

阶段即将结束，CC 回顾本阶段工作，**主动提出规范建议**：

```
CC：「本阶段即将结束，CC 回顾工作内容后，建议沉淀以下规范：

    📋 架构设计阶段规范建议
    ┌───┬──────────────────────────────────────────────────┐
    │ # │ 规范条目                                          │
    ├───┼──────────────────────────────────────────────────┤
    │ 1 │ DB：表名必须以 t_ 前缀开头                         │
    │   │   来源：用户在 review architecture/database.md 时纠正 │
    │   │   建议写入：.team-flow/conventions/db-design.md    │
    ├───┼──────────────────────────────────────────────────┤
    │ 2 │ 后端：DDD 四层必须包含 assembler 层（MapStruct）    │
    │   │   来源：build-executor 执行时用户补充               │
    │   │   建议写入：.team-flow/conventions/backend-patterns.md │
    ├───┼──────────────────────────────────────────────────┤
    │ 3 │ API：权限声明统一使用 hasAuthority                  │
    │   │   来源：spec-writer 编写时 CC 观察到项目既有代码     │
    │   │   建议写入：.team-flow/conventions/api-conventions.md │
    └───┴──────────────────────────────────────────────────┘

    请逐条确认（接受/拒绝/修改），或输入「全部接受」：」
```

**阶段转换点清单**：

| 阶段转换 | 询问内容 | 规范沉淀目标 |
|---------|---------|-------------|
| architecture-design → spec-writer | 架构设计阶段是否有规范变更？ | db-design.md / backend-patterns.md / api-conventions.md |
| spec-writer → build-executor | 规格编写阶段是否有规范变更？ | 所有 conventions |
| build-executor → closing | 构建执行阶段是否有规范变更？ | backend-patterns.md / api-conventions.md |
| workflow-orchestrator S1 → S2 | PRD 阶段是否有规范变更？ | frontend-patterns.md（如适用） |

**建议生成逻辑**：

| 信息来源 | 提取规则 |
|---------|---------|
| 本阶段用户纠正 | 涉及命名/分层/注解/格式等可复用模式的纠正 |
| 本阶段 CC 观察到的项目既有模式 | 在读取项目代码时发现的统一风格 |
| 本阶段踩坑记录 | 已写入 `docs/solutions/` 的 pitfall/pattern，如果具有规范性质则同步提取 |
| 已有 convention 文件的缺口 | 对比本阶段产出与已有 convention，发现未覆盖的规范点 |

**过滤规则**：
- ❌ 排除：仅适用于本次 change 的特定业务逻辑
- ❌ 排除：已在 convention 中存在的条目（去重）
- ✅ 保留：跨 change 可复用、可检查、可执行的规范

### 33.2 conventions 目录结构

```
.team-flow/
├── conventions/
│   ├── db-design.md          # DB 设计规范
│   ├── backend-patterns.md   # 后端分层规范
│   ├── api-conventions.md    # API 规范
│   └── frontend-patterns.md  # 前端规范
```

### 33.3 team-flow.config.json 配置段

```json
{
  "conventions": {
    "database": ".team-flow/conventions/db-design.md",
    "backend": ".team-flow/conventions/backend-patterns.md",
    "api": ".team-flow/conventions/api-conventions.md",
    "frontend": ".team-flow/conventions/frontend-patterns.md"
  }
}
```

### 33.4 Convention 文件格式规范

```yaml
---
phase: database          # 适用阶段：prd | spec | build | database | backend | api | frontend
domain: db               # 领域标签（与 PRD/change 的领域对应）
severity: high           # high | medium | low（影响注入优先级）
date: 2026-07-31
---

# DB 设计规范

## 表命名
- 表名必须以 `t_` 前缀开头
- 主键使用 `t_sequence_generator` 表生成
- 审计字段必须包含 `BaseEntity` 基类字段

## DDL 管理
- 所有 DDL 必须写入 `schema-baseline.sql`
- 增量变更必须提供 migration 脚本
```

### 33.5 各阶段注入机制

#### 注入流程

```
各 skill 上下文加载
  ├─ 通过 tf runtime config --get conventions 获取配置
  ├─ 根据当前 skill 的 phase 标签，过滤匹配的 convention 文件
  ├─ 读取对应文件的 YAML frontmatter，提取适用阶段
  ├─ 将规范内容作为上下文约束注入（advisory 级，非强制 guard）
  └─ 产出制品时遵循规范约束
```

#### 各 skill 注入点

| Skill | 注入时机 | 注入方式 |
|-------|---------|---------|
| **architecture-design** | 五项检查前 | 读取 `conventions.database` / `conventions.backend` / `conventions.api`，注入为架构决策约束 |
| **spec-writer** | 生成 specs/design/tasks 前 | 读取所有 conventions，注入为规格约束 |
| **build-executor** | 执行任务前 | 读取 `conventions.backend` / `conventions.api`，注入为实施约束 |
| **workflow-orchestrator** | S1 路由时 | 读取 conventions，注入为需求分析上下文 |

#### 注入优先级

按 `severity` 字段排序，top-3 注入（避免上下文过载）。

### 33.6 与复利机制的关系

| 维度 | conventions（规范） | docs/solutions（复利） |
|------|-------------------|----------------------|
| **定位** | 定义"必须遵守的规范" | 沉淀"踩坑经验" |
| **维护方式** | 被动式自动沉淀 | 主动记录 + 晋升机制 |
| **注入时机** | 各阶段上下文加载 | S1 路由 + spec-writer |
| **强制性** | advisory（可忽略） | advisory（可忽略） |
| **适用场景** | 命名/分层/注解/格式规范 | pitfall/pattern/decision/insight |

**互补关系**：conventions 定义"应该怎样"，solutions 记录"实际怎样"。两者独立维护，互不冲突。

---

## 三十四、architecture-reviewer agent 创建（v0.28.0）

### 34.0 问题诊断

architecture-design 阶段完成五项检查 + 三件套产出后，**直接进入 spec-writer**，没有自动审查环节。

对比 prototype 阶段：builder 产出原型 → prototype-reviewer 自动审查（6 维度 + Craft 4 席）→ FAIL 则循环修正（≤3 轮）→ PASS 才进人工评审。

**差距**：

| 维度 | prototype 阶段 | architecture-design 阶段 |
|------|--------------|------------------------|
| 自动审查 agent | ✅ prototype-reviewer | ❌ 不存在 |
| 审查维度 | 6 维度 + P0 工艺 + Craft 4 席 | 无 |
| 循环修正 | ≤3 轮 + 收敛检测 | 无 |
| PRD 对照 | 结构化逐节对照 | 无 |
| 判定标准 | PASS / FAIL / PASS_WITH_WARNINGS | 无 |

### 34.1 方案设计

参考 prototype-reviewer 设计模式（独立上下文 + 只读 + 分层检查 + 循环修正），创建 `architecture-reviewer` agent。

#### Agent 定义

```yaml
---
name: architecture-reviewer
description: 架构设计自动审查 agent——独立上下文、只读审查，对照 PRD/plan/change-brief + 全局基线 + conventions 审查架构产出质量
model: inherit
color: yellow
tools: ["Read", "Bash", "Grep", "Glob"]
---
```

**铁律**：reviewer 在未参与产出的独立上下文中运行，**绝不修改任何文件**，报告写在 response，由编排层落盘。

#### 输入

| 参数 | 说明 |
|------|------|
| `prd_path` | PRD 文件路径（如 `prd/v1/prd.md`） |
| `plan_path` | 计划文件路径（如 `prd/v1/plan.md`） |
| `change_brief_path` | 变更简报路径（如 `changes/<name>/change-brief.md`） |
| `architecture_dir` | 架构产出目录（如 `changes/<name>/architecture/`） |
| `global_arch_dir` | 全局架构目录（如 `docs/architecture/`） |
| `conventions` | conventions 配置（从 team-flow.config.json 读取） |

#### 审查维度（6 维度）

##### Phase 1: Pre-check（Bash 结构化预检，机械化）

| 维度 | 基准源 | 检查内容 | 严重级别 |
|------|--------|---------|---------|
| **A1 产出完整性** | architecture-design 结构化输出 | `architecture.md` / `database.md` / `api.md` 文件存在且非空 | Critical |
| **A2 SQL 制品完整性** | `database.md` 中引用的 SQL 路径 | `sql/ddl/*.sql` / `sql/migration/*.sql` 文件存在且可执行（语法检查） | Critical |
| **A3 模板合规性** | `architecture-design/templates/` | 产出文件结构与模板一致（YAML frontmatter + 必要章节） | Important |

##### Phase 2: Deep-check（LLM 语义对比，建议级）

| 维度 | 基准源 | 检查内容 | 严重级别 |
|------|--------|---------|---------|
| **A4 需求覆盖** | change-brief + plan | 每个业务需求 → 对应的架构设计（聚合/BC/API/DB 覆盖） | Critical |
| **A5 基线一致性** | 全局 `ARCHITECTURE.md` + `PHYSICAL-MODEL.md` + `API-INDEX.md` | 增量设计与全局基线无矛盾（命名/分层/边界不冲突） | Critical |
| **A6 conventions 合规** | `.team-flow/conventions/` | 架构产出遵循项目级规范（DB 命名/后端分层/API 注解等） | Important |

#### 判定标准

| Verdict | 条件 | 后续动作 |
|---------|------|---------|
| **PASS** | Critical=0 且 Important=0 | 进入 spec-writer 阶段 |
| **PASS_WITH_WARNINGS** | Critical=0 且 Important>0 | 警告项交人工裁定，不阻断 |
| **FAIL** | Critical>0 | 必须修正后重新审查 |

#### 输出格式

```markdown
# Architecture Auto-Review Report

## Metadata
- PRD: prd/v1/prd.md
- Plan: prd/v1/plan.md
- Change Brief: changes/<name>/change-brief.md
- Architecture Dir: changes/<name>/architecture/
- Review Round: 1
- Timestamp: 2026-07-31T10:00:00+08:00

## Verdict: PASS / PASS_WITH_WARNINGS / FAIL

## Severity Summary
| Critical | Important | Minor |
|----------|-----------|-------|
| 0        | 0         | 0     |

## A1 产出完整性
- architecture.md: ✅ 存在且非空（XXX 行）
- database.md: ✅ 存在且非空（XXX 行）
- api.md: ✅ 存在且非空（XXX 行）

## A2 SQL 制品完整性
- sql/ddl/new_tables.sql: ✅ 存在且语法检查通过
- sql/migration/data.sql: ✅ 存在且语法检查通过

## A3 模板合规性
- architecture.md: ✅ YAML frontmatter 完整 + 必要章节齐全
- database.md: ⚠️ 缺少 "Migration Strategy" 章节

## A4 需求覆盖
| 需求项 | change-brief 来源 | 架构覆盖位置 | 状态 |
|--------|------------------|-------------|------|
| 新增 XX 聚合 | §2.1 | architecture.md §1 | ✅ |
| 修改 YY 表结构 | §2.3 | database.md §2 | ✅ |
| 新增 ZZ API | §2.5 | api.md §3 | ✅ |

## A5 基线一致性
- 聚合命名：✅ 与全局 ARCHITECTURE.md 一致
- BC 边界：✅ 无冲突
- 表命名：✅ 与 PHYSICAL-MODEL.md 一致
- API 路由：✅ 与 API-INDEX.md 无冲突

## A6 conventions 合规
- db-design.md: ✅ 表名 t_ 前缀 / 主键策略 / 审计字段
- backend-patterns.md: ✅ DDD 四层 / assembler
- api-conventions.md: ⚠️ 权限声明未使用 hasAuthority

## Inconsistency Summary
| Dim | Severity | 基准源 | 产出位置 | 描述 |
|-----|----------|--------|---------|------|
| A6  | Important | conventions/api-conventions.md | api.md §3 | 权限声明未使用 hasAuthority |

## Coverage Statistics
| 维度 | 需求项数 | 覆盖数 | 覆盖率 |
|------|---------|--------|--------|
| 聚合 | 3 | 3 | 100% |
| BC   | 2 | 2 | 100% |
| API  | 5 | 5 | 100% |
| DB   | 4 | 4 | 100% |
```

### 34.2 编排流程

architecture-design 产出后的审查编排由 **workflow-start**（或 **architecture-design skill**）负责：

```
architecture-design 产出完成
  → 交接后产物校验（defense in depth）
    test -f architecture/architecture.md && test -s architecture/architecture.md
    - OK → 派 architecture-reviewer
    - 缺失 → resume architecture-design 补全
  → architecture-reviewer 审查
    → 报告落盘 changes/<name>/architecture/auto-review.md
    → FAIL → 不一致项交给 architecture-design 修正 → 重新审查（≤3 轮）
    → PASS_WITH_WARNINGS → 警告项交人工裁定
    → PASS → 进入 spec-writer
  → 收敛检测：连续两轮不一致项集合无缩小 → 立即转人工
```

### 34.3 routing-rules.md 更新

在 routing-rules.md 的 architecture-design 路由段中，增加审查步骤：

```
## Route to architecture-design (v0.9 §26)

1. Dispatch `architecture-design` as sub-agent with inputs
2. **Dispatch `architecture-reviewer` as sub-agent with architecture outputs + PRD/plan/brief + conventions**
3. **Review loop: FAIL → resume architecture-design → re-review (≤3 rounds)**
4. **PASS / PASS_WITH_WARNINGS → reasonableness check → proceed to spec-writer**
```

### 34.4 与 prototype-reviewer 的设计对比

| 对比维度 | prototype-reviewer | architecture-reviewer |
|----------|-------------------|----------------------|
| 铁律 | 独立上下文 + 只读 | 独立上下文 + 只读 |
| 工具 | Read/Bash/Grep/Glob | Read/Bash/Grep/Glob |
| 检查分层 | Pre-check（机械）→ Deep-check（语义）→ Craft（rubric） | Pre-check（机械）→ Deep-check（语义） |
| 审查维度 | 6 维度（D1-D6）+ P0 工艺 + Craft 4 席 | 6 维度（A1-A6） |
| 基准源 | PRD §4/§6/§7/§8 + design-system tokens | change-brief + plan + 全局基线 + conventions |
| 循环修正 | ≤3 轮 + 收敛检测 | ≤3 轮 + 收敛检测 |
| 判定标准 | PASS / PASS_WITH_WARNINGS / FAIL | PASS / PASS_WITH_WARNINGS / FAIL |
| Craft rubric | 4 席加权打分 | 无（架构设计不适合 craft rubric） |
| 报告落盘 | prd/vN/prototype-auto-review.md | changes/<name>/architecture/auto-review.md |

**差异说明**：architecture-reviewer 不包含 Craft rubric（工艺质量评审），因为架构设计是结构性文档，不涉及视觉/交互/品牌等工艺维度。如果未来需要架构设计的"方法论质量"评审（如 4A 框架应用是否得当），可作为后续迭代增加。

---

## 待办列表

| 编号 | 待办 | 状态 | 版本 | 来源 |
|------|------|------|------|------|
| P1-18 | 创建 `/agents/architecture-design.md` agent 定义 | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P1-5） |
| P1-19 | 横展验证：检查所有 skill 中 `dispatch as sub-agent` 引用是否都有对应 agent 定义 | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P1-6） |
| P1-20 | 创建 `/agents/architecture-reviewer.md` agent 定义 | ✅ 2026-07-31 | v0.28.0 | LT 需求（2026-07-31） |
| P1-21 | routing-rules.md 增加 architecture-reviewer 审查步骤 | ✅ 2026-07-31 | v0.28.0 | LT 需求（2026-07-31） |
| P2-18 | 设计 `team-flow.config.json` 的 `conventions` 配置段 schema | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P2-3） |
| P2-19 | architecture-design / spec-writer / build-executor / workflow-orchestrator 上下文加载协议增加 conventions 注入 | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P2-4） |
| P2-20 | 提供 conventions 模板（db-design.md / backend-patterns.md 等） | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P2-5） |
| P2-21 | 各阶段 SKILL.md 增加"阶段转换前规范建议"协议（被动式自动沉淀） | ✅ 2026-07-31 | v0.28.0 | workflow-feedback 2026-07-31（P2 新需求） |
