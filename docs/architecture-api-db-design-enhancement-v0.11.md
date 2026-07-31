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

## 三十五、architecture-design Agent 精简 + Skill 预加载（v0.28.1）

### 35.0 问题诊断

**来源**：workflow-feedback 2026-07-31（P1-1）

architecture-design agent 被 workflow-start dispatch 时，只加载了 `agents/architecture-design.md` 中的 system prompt（~229 行），其中堆满了 HOW 内容：

- Context Loading Protocol（加载哪些项目文件）
- Conventions Injection（如何注入项目规范）
- Execution Flow（执行步骤详情）
- F1-F8 核心框架详情（每条一段话）

但 Skill 的完整知识库（6 个 chapters + templates + conventions 模板 + glossary/cheatsheet）**完全没有被加载**。Agent prompt 中的 F1-F8 只是概要，缺少 chapters 中的详细方法论指导、worked examples 和 anti-pattern catalogs。

**根因**：Agent 和 Skill 的职责被混淆了。Agent 里堆了大量 HOW（怎么做），违反了 Claude Code 官方文档的核心分层原则：

| 层 | 职责 | 文件 |
|----|------|------|
| Agent (.md) | **WHO**（角色人设）+ **WHAT**（职责范围、输出契约） | `agents/*.md` |
| Skill (SKILL.md) | **HOW**（步骤流程、方法论、模板、规范） | `skills/*/SKILL.md` + `references/` + `chapters/` |

两条反模式（官方与课程都点名）：
- ❌ Agent prompt 里堆 SOP → 流程应抽成 Skill 再预加载
- ❌ Skill 里写角色设定 → 角色属于 Agent 文件

### 35.1 方案设计

采用 **写法 2**（自定义 Agent 预加载 Skill）：在 `agents/architecture-design.md` 的 frontmatter 中增加 `skills:` 字段：

```yaml
---
name: architecture-design
model: inherit
color: blue
tools: ["Read", "Bash", "Grep", "Glob", "Write", "Edit"]
skills:
  - architecture-design    # ← 启动时全文注入 SKILL.md
---
```

**确定性保证**：`skills:` 字段在 agent 启动时将指定 Skill 的完整 SKILL.md 注入上下文（100% 确定性），不依赖语义匹配发现。Agent 的 system prompt 中用一句话指向：

> "Your preloaded Skill contains the detailed methodology (F1-F8 frameworks, chapter knowledge, templates, conventions protocol, context loading protocol). Follow it for HOW. This prompt defines WHO you are and WHAT you must deliver."

### 35.2 Agent 精简结果

| 维度 | 修改前 | 修改后 |
|------|--------|--------|
| 行数 | 229 行 | ~100 行 |
| 包含内容 | WHO + WHAT + HOW（加载协议、F1-F8 详情、执行流程、conventions 注入） | WHO + WHAT + 输出契约 + 红线 |
| Skill 知识注入 | 无（Agent prompt 中的概要是唯一来源） | `skills: [architecture-design]` 预加载完整 SKILL.md |
| Chapters 可访问 | 否（Agent 不知道 chapters 存在） | 是（通过预加载的 SKILL.md 的 Chapter Index 得知路径，按需 Read） |
| Templates 可访问 | 仅文字引用 | 是（SKILL.md 中的产出目录 + templates/ 路径） |

**Agent 保留的内容**（WHO/WHAT 层）：
- Iron Law（角色定义 + 职责边界）
- Inputs（输入参数表）
- Five-Check Gate（五项检查判定门——这是 WHAT，不是 HOW）
- Output Directory（产出目录结构）
- Structured Output Contract（YAML 输出契约）
- api.md Positioning（产出定位说明）
- Red Lines（DO/DON'T 红线）

**Agent 移除的内容**（全部在 Skill 中有更详细版本）：
- Context Loading Protocol → Skill 的「上下文加载协议」段
- Conventions Injection → Skill 的「Conventions Injection」段
- Execution Flow → Skill 的「执行流程」段
- F1-F8 框架详情 → Skill 的 Core Frameworks + chapters/
- Skill Knowledge Loading 段（之前错误的 HOW 堆砌） → `skills:` 字段预加载

### 35.3 对比：三种 Agent + Skill 协作模式

| 模式 | Agent 复杂度 | Skill 注入方式 | 确定性 | 适用场景 |
|------|------------|--------------|--------|---------|
| 写法 1：纯 fork | 中（prompt 含任务指令） | context: fork 注入 SKILL.md | 100% | 一次性重任务 |
| **写法 2：自定义 Agent + skills 预加载** | **低（WHO/WHAT only）** | **skills: 字段全文注入** | **100%** | **反复出现的角色（本方案采用）** |
| 写法 3：叠加 | 中 | fork + skills 双重 | 100% | 角色稳定 + 任务多变 |

### 35.4 横展验证

检查所有其他 agent 是否存在同样的"Agent 堆 HOW"反模式：

| Agent | 行数 | 是否堆了 HOW | 是否有对应 Skill | 建议 |
|-------|------|-------------|----------------|------|
| architecture-reviewer | ~252 行 | 是（6 维度检查流程详情） | 无独立 Skill | 暂不改——reviewer 的 HOW 就是检查流程，无独立 Skill 可预加载 |
| bug-investigator | ~180 行 | 待评估 | bug-investigator Skill 存在 | 后续迭代 |
| change-split-auditor | ~260 行 | 待评估 | 无独立 Skill | 暂不改 |
| code-reviewer | ~144 行 | 待评估 | code-reviewer Skill 存在 | 后续迭代 |
| prototype-builder | ~324 行 | 待评估 | prototype Skill 存在 | 后续迭代 |

**结论**：architecture-design 是第一个被修正的，其他 agent 可作为后续迭代。当前不阻塞本次发布。

---

## 三十六、workflow-start 主干补强 auto-review 三步协议（v0.28.1）

### 36.0 问题诊断

**来源**：workflow-feedback 2026-07-31（P1-2）

architecture-design agent 完成架构设计产出后，workflow-start 仅做了**人肉 reasonableness check**（CC 自己 Read 产出文件并总结），**未启动** `architecture-reviewer` agent 执行 6 维度自动审查。

**根因**：routing-rules.md **已经**包含 Step 2 auto-review（§34 审查增强），但 workflow-start SKILL.md **主干**的 Route to architecture-design 段落只写了一句 "Dispatch + reasonableness check"，漏掉了中间的 auto-review 步骤。主干太简略 → LLM 执行时跳过了 reference 中的详细步骤。

**信息层次问题**：

```
SKILL.md 主干（LLM 首先看到的）     references/routing-rules.md（按需加载）
┌──────────────────────────────┐   ┌──────────────────────────────┐
│ Route to architecture-design  │   │ Route to architecture-design  │
│ Dispatch → reasonableness     │   │ Step 1: Dispatch              │
│ check → write yaml            │   │ Step 2: Auto-review ← 缺失!  │
│                               │   │ Step 3: Reasonableness check  │
│ （一句话概括，无 auto-review） │   │ （完整三步协议）              │
└──────────────────────────────┘   └──────────────────────────────┘
```

LLM 先看到主干的简略描述就开始执行，根本没去加载 routing-rules.md 的详细步骤。

### 36.1 方案设计

在 workflow-start SKILL.md **主干**中展开三步协议摘要，而不是只在 reference 中保留：

**修改前**（主干）：
```
Dispatch `architecture-design` as sub-agent; after return, run reasonableness check and write yaml.
```

**修改后**（主干）：
```
**Three-step protocol (MUST execute in order)**:
1. **Dispatch**: `architecture-design` as sub-agent → returns `decision` + `reason` + `artifacts`
2. **Auto-review** (decision=required 时触发): 校验产物文件存在且非空 → dispatch `architecture-reviewer` sub-agent → FAIL 则循环修正（≤3 轮 + 收敛检测，不收敛转人工）→ 报告落盘 `changes/<name>/architecture/auto-review.md`
3. **Reasonableness check + state write**: skipped + brief 含架构关键词 → BLOCK; required + artifacts 缺失 → BLOCK; required + auto-review FAIL → BLOCK
```

**设计决策**：主干放摘要（三步 + 关键阻断条件），routing-rules.md 保留详细命令和完整协议。这确保 LLM 即使不加载 reference 也能执行正确的三步流程。

### 36.2 配套变更

**Guardrails 新增**：
```
No arch state write without auto-review PASS (v0.28.1 §36):
when decision: required, auto-review MUST complete with PASS or PASS_WITH_WARNINGS
before writing arch_design_decision to yaml. FAIL → loop fix (≤3 rounds) or escalate.
```

**State Writes 新增字段**（decision=required 时写入）：
- `arch_review_verdict`：`PASS` | `PASS_WITH_WARNINGS`
- `arch_review_rounds`：审查轮次（1-3）
- `arch_review_report`：`architecture/auto-review.md` 路径

**routing-rules.md 补充**：Step 3 的 state set 命令增加 `arch_review_*` 三个字段的写入命令。

### 36.3 职责分离确认

| 角色 | 职责 | 不做什么 |
|------|------|---------|
| architecture-design agent | 判断 + 产出 | 不自我审查、不写 yaml |
| architecture-reviewer agent | 6 维度只读审查 | 不修改文件、不做判断门 |
| workflow-start skill | 编排三步协议 + reasonableness check + 状态写入 | 不产出架构设计、不做 6 维度审查 |

---

## 三十七、横展修复：bug-investigator / code-reviewer / prototype-builder Agent 精简（v0.28.1 §35 横展）

### 37.0 问题诊断

**来源**：v0.28.1 §35 Agent/Skill 职责分离修正的横展验证

横展扫描发现 3 个 agent 存在与 architecture-design 同样的反模式——Agent prompt 中堆砌了大量 HOW 内容（方法论、流程、模板），而对应的 Skill 中已有或应有这些内容。

| Agent | 行数 | 对应 Skill | Skill 行数 | Agent/Skill 比例 | 问题 |
|-------|------|-----------|-----------|----------------|------|
| bug-investigator | 180 | bug-investigator | 77 | 2.34x | Agent 堆砌 Phase 1-4 详细调查流程、Report Format、Quality Standards、Edge Cases |
| code-reviewer | 171 | code-reviewer | 88 | 1.94x | Agent 堆砌 6 步 Review Process、Calibration Rules、Severity Definitions |
| prototype-builder | 230 | prototype | 112 | 2.05x | Agent 堆砌 Build Process Steps 0-4、Hard Constraints、Seed Composition、P0/P1/P2 自检、Deliverable Hard Gate |

**对比基准**：architecture-design agent 修复前 229 行（Skill 210 行，比例 1.09x），修复后 ~100 行（比例 0.48x）。上述 3 个 agent 的比例均 >1.9x，严重违反 Agent=WHO/WHAT、Skill=HOW 的职责分离原则。

### 37.1 修复方案

采用与 §35 一致的 **写法 2**（自定义 Agent + skills 预加载）：

1. **Agent 精简**：移除所有 HOW 内容（方法论、流程、模板），只保留 WHO/WHAT（角色定义、Iron Law、输入参数、输出契约、Red Lines）
2. **Skill 增强**：将移除的 HOW 内容迁移至对应 Skill 的 SKILL.md 或 references/ 目录
3. **skills: 字段预加载**：Agent frontmatter 增加 `skills: [skill-name]`，启动时全文注入 SKILL.md
4. **一句话指向**：Agent prompt 增加 "Your preloaded Skill contains the detailed methodology. Follow it for HOW."

### 37.2 修复详情

#### bug-investigator（180 → ~85 行）

**移除内容**（迁移至 `skills/bug-investigator/SKILL.md`）：
- Phase 1-4 详细调查流程（Root Cause Investigation → Pattern Analysis → Hypothesis and Testing → Report）
- Report Format 模板（Summary / Symptom / Investigation Trail / Root Cause / Recommended Fix / DP-5 Escalation）
- Writing Investigation Notes 指南
- Quality Standards（5 项：Evidence over intuition / Specificity / Completeness / Actionability / Honesty）
- Edge Cases（Environmental / Timing/race / External dependencies / Cannot reproduce）

**保留内容**：
- Iron Law（"No conclusions without evidence"）
- Inputs（symptom_description / reproduction_steps / context）
- Output Contract（报告必须包含的 5 个段落摘要）
- DP-5: Debug Escalation（3+ Failed Hypotheses 的架构问题信号）
- Red Lines（DO/DON'T 列表）

**新增**：
- `skills: [bug-investigator]` frontmatter 字段
- 一句话指向："Your preloaded Skill contains the detailed methodology (Phase 1-4 investigation process, report template, quality standards, edge case handling). Follow it for HOW."

#### code-reviewer（171 → ~100 行）

**移除内容**（迁移至 `skills/code-reviewer/SKILL.md`）：
- 6 步 Review Process（Gather Context → Spec Compliance Check → Code Quality Review → Architecture Review → Test Coverage Review → Documentation Review）
- Severity Levels 表格（Critical / Important / Minor）
- Verdict Criteria 表格（PASS / PASS_WITH_WARNINGS / FAIL）
- Calibration Rules（5 项）
- Critical Rules（DO/DON'T 详细列表）

**保留内容**：
- Iron Law（"You are a read-only reviewer"）
- Inputs（change_dir / specs_dir / design_path / implementation_files）
- Output Contract（报告必须包含的 5 个段落摘要）
- Verdict Criteria（简化的 3 条判定规则）
- Red Lines（DO/DON'T 精简列表）

**新增**：
- `skills: [code-reviewer]` frontmatter 字段
- 一句话指向："Your preloaded Skill contains the detailed methodology (6-step review process, calibration rules, severity definitions, critical rules). Follow it for HOW."

#### prototype-builder（230 → ~95 行）

**移除内容**（迁移至 `skills/prototype/references/builder-methodology.md`）：
- Hard Constraints（零外部依赖 + 防漂移的 3 条详细规则）
- Build Process Steps 0-4（Precondition Gate → Render Design Tokens → Seed Composition → Build Structure → Flow + Consistency → P0/P1/P2 Quality Self-Check → 修正轮）
- data-testid Discipline（可选配置驱动规则）
- Structured Handoff 格式（JSON 风格交接协议）
- Deliverable Hard Gate（v0.20.0 禁止谎报完成的详细规则）
- Decision-Point Interaction（v0.21.0 stop-and-resume 中继协议的 3 步流程）

**保留内容**：
- Iron Law（"You are a write-focused builder"）
- Inputs（design_files_dir / design_system_dir / output_dir / requirements）
- Output Contract（产出结构的 5 项要求）
- Quality Standards（简要列出 5 项：Accessibility / Performance / Responsiveness / Code quality / Design system compliance）
- Red Lines（DO/DON'T 精简列表）

**新增**：
- `skills: [prototype]` frontmatter 字段
- 一句话指向："Your preloaded Skill contains the detailed methodology (HTML/CSS construction patterns, design system integration, quality assurance process). Follow it for HOW."
- `skills/prototype/SKILL.md` 增加"prototype-builder agent 方法论（v0.28.1 §37）"段落，指向 `references/builder-methodology.md`

### 37.3 修复效果对比

| Agent | 修复前 | 修复后 | 缩减比例 | Skill 增强 |
|-------|--------|--------|---------|-----------|
| bug-investigator | 180 行 | ~85 行 | 53% | SKILL.md 增加 Report Format / Quality Standards / Edge Cases 段落 |
| code-reviewer | 171 行 | ~100 行 | 42% | SKILL.md 增加 Review Process / Severity Levels / Calibration Rules 段落 |
| prototype-builder | 230 行 | ~95 行 | 59% | 新增 references/builder-methodology.md（~180 行）+ SKILL.md 指向段落 |

**核心收益**：
1. **职责清晰**：Agent 只定义"谁来做、做什么、交付什么、禁止什么"，Skill 定义"怎么做"
2. **知识复用**：Skill 的方法论可被多个 agent 共享（如 code-reviewer 的 Review Process 也可被其他 reviewer agent 参考）
3. **上下文优化**：Agent prompt 精简后，子代理上下文窗口有更多空间加载项目文件和 Skill 知识库
4. **一致性保证**：通过 `skills:` 字段预加载，Agent 启动时 100% 注入 SKILL.md，无需运行时自主发现

### 37.4 横展验证结论

本次横展修复了 3 个 Category A2 agent（有对应 Skill 且内容重复），加上 §35 修复的 architecture-design，共计 **4 个 agent 完成 Agent/Skill 职责分离修正**。

**剩余未修复的 agent**：
- **Category B（5 个）**：architecture-reviewer / change-split-auditor / cross-change-consistency-checker / prd-completeness-reviewer / prototype-reviewer —— 无对应 Skill，方法论是 agent 独有核心价值，暂不修复
- **Category C（1 个）**：prototype-env-scout —— 轻量级内部编排 agent，职责清晰，无需修复

**未来迭代建议**：
- 若 Category B 的 5 个 reviewer/auditor agent 的方法论未来被多个 agent 复用，可考虑提取为独立 Skill
- 当前不修复是合理的：这些 agent 的方法论是专属的（如 architecture-reviewer 的 6 维度审查、change-split-auditor 的 5 维度审计），提取为 Skill 反而增加复杂度

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
| P1-22 | architecture-design agent 精简 + Skill 预加载（`skills:` 字段注入，Agent 只保留 WHO/WHAT，229→~100 行） | ✅ 2026-07-31 | v0.28.1 | workflow-feedback 2026-07-31（P1-1 agent-quality） |
| P1-23 | workflow-start SKILL.md 主干补强三步协议摘要（dispatch→auto-review→reasonableness check）+ Guardrails 新增 auto-review PASS 前置条件 + State Writes 新增 arch_review_* 字段 | ✅ 2026-07-31 | v0.28.1 | workflow-feedback 2026-07-31（P1-2 sop-flow） |
| P1-24 | 横展验证：扫描 10 个 agent 是否存在同样的"Agent 堆 HOW"反模式 | ✅ 2026-07-31 | v0.28.1 | LT 横展需求 + §35.4 横展验证；结果：3 个 Category A2 需修复，5 个 Category B 无对应 Skill 暂不修复，1 个 Category C 轻量级无需修复 |
| P1-25 | bug-investigator agent 精简（180→~85 行）+ `skills:` 字段预加载 + HOW 内容迁移至 SKILL.md | ✅ 2026-07-31 | v0.28.1 | P1-24 横展验证 + §37 |
| P1-26 | code-reviewer agent 精简（171→~100 行）+ `skills:` 字段预加载 + HOW 内容迁移至 SKILL.md | ✅ 2026-07-31 | v0.28.1 | P1-24 横展验证 + §37 |
| P1-27 | prototype-builder agent 精简（230→~95 行）+ `skills:` 字段预加载 + HOW 内容迁移至 references/builder-methodology.md | ✅ 2026-07-31 | v0.28.1 | P1-24 横展验证 + §37 |
