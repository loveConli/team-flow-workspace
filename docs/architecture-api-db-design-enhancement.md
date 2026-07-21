# 架构 / API / DB 设计增强方案（草稿 v0.1 · 待专家会审）

> 适用范围：在 **spec-superflow**（开发过程 work flow，change-centric）+ **compound-engineering**（全局产物管理 + 复利机制）两个工作流之上，增补架构/API/DB 设计能力。
> 设计目标（来自用户原话）：
> 1. 架构设计：每个需求做"增强"——对**当前现状 + 需求对应的架构变更**做设计；在**复利环节回写全局架构设计**。
> 2. DB 设计：与架构**同样模式**（每变更增量设计 + 复利回写全局）。
> 3. API 设计：主要在**每个变更的需求内**做设计即可（无需全局层）。
> 4. 架构方法：一般用 **DDD（领域驱动设计）** 方式。
> 5. 借鉴 compound-engineering（复利工程）工作流中可补充本块的好经验。

---

## 一、现状与缺口确认

### 1.1 spec-superflow 现状
- 产物结构（change-centric）：`proposal.md` / `specs/<cap>/spec.md`（delta）/ `design.md` / `tasks.md` / `execution-contract.md` / `.spec-superflow.yaml`。
- `design.md` 仅有 `Decisions` 区（ADR 风格）承载架构片段；API 散落 specs+tasks；DB **不强制**。
- **缺口**：① 无独立的架构/API/DB 产物；② spec-driven 而非 design-driven；③ 缺"全局架构单一事实源"；④ 原型验证→回写 PRD 循环弱。

### 1.2 compound-engineering 现状
- 持久产物层：`STRATEGY.md`（产品/业务级策略锚点，8 section，"Anchor not plan"）、`CONCEPTS.md`、`docs/plans`（requirements-only→implementation-ready）、`docs/solutions`（经验复利，结构化 solution doc）、`docs/specs`、`docs/pulse-reports`。
- 复利回写：`ce-compound` 把经验写成带 **YAML frontmatter** 的 solution doc，两条轨道（Bug / Knowledge），`problem_type→directory` 映射 + Discoverability Check，下游 `learnings-researcher` 自动检索复用。
- **关键局限（本方案要修正）**：compound-engineering **无独立技术架构产物**，其 `STRATEGY.md` 是业务/产品级而非技术架构级——技术架构被折叠进策略。按用户 4A 方法论（BA 先行→IA/AA 并行对齐→TA），技术架构（IA/AA/TA）应与业务策略（BA）**分离且对齐**，不能直接塞进 STRATEGY.md。

---

## 二、总体闭环设计

```
模糊需求
  └─[借鉴 ce-brainstorm]→ docs/plans/<date>-<type>-<topic>-plan.md (requirements-only 统一计划)
        │  (ce-plan 就地 enrich → implementation-ready；对应 spec-superflow proposal.md/PRD)
        ▼
spec-superflow: exploring → specifying → bridging → approved-for-build → executing → closing
        │  每变更目录 specs/<cap>/ 内新增三份增量设计：
        │    • architecture.md  (DDD 增量：现状快照 + 本次架构变更)
        │    • database.md      (DB 增量：现状快照 + 本次 DB 变更，写/读模型)
        │    • api.md           (API 设计：Command/Read/Query 映射)
        ▼
[复利环节] 把每变更的 architecture.md / database.md 的「变更 delta」
        └─ 合并回写 → docs/architecture/ARCHITECTURE.md + DATABASE.md（全局架构单一事实源）
        ▼
全局文档成为下一个 change 的 grounding（architecture.md 设计前先读全局确认现状）
        └─ 闭环（下一需求）
```

**原型验证→回写 PRD 补充**：在 `executing` 阶段前插入轻量「原型验证」回环（借鉴 compound 的 pulse 回环思想），验证结论通过 spec-merger / reuse 回写 `spec.md` 与 `design.md`，闭合"原型→PRD"迭代。

---

## 三、产物结构增强（目录树）

```
项目根/
├── STRATEGY.md              # compound: 产品/业务策略锚点（4A-BA 视角，不动）
├── CONCEPTS.md              # compound: 领域词汇（追加 DDD 术语，随复利累积）
├── docs/
│   ├── plans/               # compound: 模糊需求→完整计划（沿用）
│   ├── solutions/           # compound: 经验复利（沿用）
│   ├── architecture/        # 【新增】技术架构复利层
│   │   ├── ARCHITECTURE.md  # 【新增】全局架构设计（DDD + 4A 三层 + Context Map）
│   │   └── DATABASE.md      # 【新增】全局 DB 设计（实体+生命周期+读写模型+OLTP/OLAP）
│   └── pulse-reports/       # compound: 产品信号（沿用）
├── .spec-superflow.yaml     # spec-superflow 唯一事实状态（沿用）
├── proposal.md              # spec-superflow 需求（沿用）
└── specs/
    └── <cap>/
        ├── spec.md          # delta 规格（沿用）
        ├── design.md        # 通用设计 + ADR Decisions（沿用）
        ├── architecture.md  # 【新增】每变更 DDD 架构增量
        ├── database.md      # 【新增】每变更 DB 增量
        ├── api.md           # 【新增】每变更 API 设计
        ├── tasks.md         # 沿用
        └── execution-contract.md  # 沿用
```

> **API 不进全局层**（按用户要求：API 主要在每变更内设计即可）。

---

## 四、每变更增量文档模板（specs/<cap>/）

### 4.1 `architecture.md`（DDD 增量设计）
```yaml
---
cap_id: <cap>
date: YYYY-MM-DD
change_type: new | modify
bounded_contexts: [<上下文1>, <上下文2>]   # 本次涉及/新增的限界上下文
aggregates_affected: [<聚合1>, <聚合2>]
read_write_models: [write:<x>, read:<y>]
tags: [ddd, <领域>]
---
```

- **## 现状快照（As-Is）**：引用 `docs/architecture/ARCHITECTURE.md` 的相关章节版本，描述本次变更所依赖的当前架构上下文（限界上下文、相关聚合、事务边界）。
- **## 本次架构变更（To-Be）**：
  - 新增/调整的**限界上下文**与 Context Map 关系（含上下文映射：共享内核/防腐层/开放主机等）。
  - 新增/调整的**聚合**（实体+值对象+聚合根+事务边界）。
  - **CQRS 读写模型**：写模型（事务型，Command 驱动）/ 读模型（分析型，Query 派生）。
  - **4A 三层对齐**：本次变更触发的 IA（数据实体）/ AA（应用功能）/ TA（技术选型）及其跨域一致性（结构+语义双对齐）。
- **## 架构决策（ADR）**：本变更的架构决策与理由（复用 design.md 的 ADR 风格）。

### 4.2 `database.md`（DB 增量设计）
```yaml
---
cap_id: <cap>
date: YYYY-MM-DD
change_type: new | modify
entities_affected: [<实体1>]
read_write_models: [write:<x>, read:<y>]
oltp_olap: [oltp:<t>, olap:<a>]
tags: [db, <领域>]
---
```
- **## 现状快照（As-Is）**：引用 `docs/architecture/DATABASE.md` 相关章节。
- **## 本次 DB 变更（To-Be）**：
  - 实体清单 + 全生命周期（创建→变更→归档）。
  - 聚合对应的表/事务边界。
  - 写模型（OLTP）表结构 vs 读模型（OLAP）派生结构。
- **## 迁移策略**：schema 迁移（向前兼容/双写/回填）。

### 4.3 `api.md`（API 设计，仅每变更）
- **## API 清单**：端点、方法、职责。
- **## 指令映射（L6）**：每个 API 的 Command / Read / Query 分类，映射到对应聚合（业务服务）或数据服务。
- **## 契约**：请求/响应 schema、错误码、幂等。

---

## 五、全局架构/DB 文档结构（docs/architecture/）

### 5.1 `ARCHITECTURE.md`（DDD + 4A 三层体系）
按用户 kb 的「架构产出三层（元素/制品/交付件）」组织：
- **架构元素层（积木）**：业务实体清单（按限界上下文）、聚合（实体+值对象+聚合根+事务边界）、技术服务。
- **架构制品层（图纸）**：Context Map（限界上下文地图）、业务流程图（功能→聚合映射）、CQRS 读写模型。
- **架构交付件层（成品）**：面向架构评审委员会的《系统架构设计文档》（整合上述，供审批——对应 4A 治理三支柱：生命周期管理/审批流程/成熟度评估）。
- **4A 映射**：显式标注 BA（策略，见 STRATEGY.md）/ IA / AA / TA 的依赖与对齐。

### 5.2 `DATABASE.md`（全局 DB 设计）
- 实体清单 + 全生命周期。
- 读写模型派生机理（CQRS：读模型派生自写模型）。
- OLTP（写模型）/ OLAP（读模型）分库策略。

> **复利回写规则**：`ARCHITECTURE.md` / `DATABASE.md` 只增不改结构；每变更 delta 以 append + 版本锚点方式合入，保留历史演进（对应 compound 的"知识以 doc 形式持久化跨会话存活"）。

---

## 六、复利回写机制（借鉴 ce-compound schema）

直接借用 compound-engineering 的复利回写机制作为"架构/DB 全局回写"的实现模板：

1. **结构化 frontmatter（借鉴 schema.yaml）**：每变更 `architecture.md` / `database.md` 带 YAML（cap_id/date/change_type/bounded_contexts/aggregates），保证跨 change 可检索。
2. **Discoverability Check（借鉴 ce-compound）**：回写前检查全局文档是否存在重复/冲突的限界上下文或聚合定义，防漂移。
3. **下游自动检索复用（借鉴 learnings-researcher）**：下一个 change 设计 `architecture.md` 前，自动从 `docs/architecture/` 检索相关限界上下文/聚合，复用而非重建。
4. **One change per run**：一次复利回写处理一个变更的 delta，保持结构化与可追溯（对应 ce-compound 的 one learning per run）。
5. **回写触发点（集成 spec-superflow）**：在 change 进入 `closing`（或 `approved-for-build`）后触发；可作为 spec-superflow 的一个新增 guard 检查点或独立 skill（如 `arch-compound`）。

---

## 七、借鉴 compound-engineering 的具体经验清单

| # | compound-engineering 经验 | 本方案的映射用法 |
|---|---|---|
| 1 | 全局锚点（STRATEGY.md，Anchor not plan，每步读取） | → `docs/architecture/ARCHITECTURE.md` 作技术架构单一事实源；每 change 先读它确认现状（**修正**：技术架构与产品策略分离，不塞进 STRATEGY.md） |
| 2 | 结构化复利回写 schema（YAML frontmatter + problem_type→directory + Discoverability Check） | → 架构/DB 回写的元数据契约 + 防冲突检查（金矿级借鉴） |
| 3 | requirements-only → implementation-ready 演进（ce-brainstorm unified plan contract） | → 模糊需求→完整 PRD/计划 的现成模板（`artifact_readiness` 字段） |
| 4 | One learning per run + 并行 subagents | → 架构回写的"增量、一次一变更、可并行检索"特性 |
| 5 | pulse-reports 大环（真实数据回填 Key metrics） | → （增强项，后续）可做"架构健康度脉冲"，闭合策略↔执行↔测量 |

---

## 八、与 spec-superflow 状态机/guard 的集成点

- **状态机**：现有 8 态（exploring→specifying→bridging→approved-for-build→executing→closing + debugging + abandoned）。
- **新增产物校验**：在 `specifying` 阶段要求 `specs/<cap>/` 下产出 `architecture.md`/`database.md`/`api.md`；`bridging`/`approved-for-build` 阶段将"全局回写完成"作为 guard 检查项之一（可选，先软后硬）。
- **guard 扩展**：`scripts/guard/` 状态机守门员增加对上述三份增量文档的存在性与 frontmatter 合规校验（轻量，不阻断，仅提示）。

---

## 九、待专家会审的焦点问题

1. **DDD 产物结构是否完整严谨**？（限界上下文/聚合/事务边界/CQRS/Context Map 是否覆盖到位；4A 三层落地是否合理）
2. **每变更增量 vs 全局回写的边界**是否清晰？现状快照引用机制是否会漂移？
3. **复利回写机制**（借 ce-compound schema）直接套用到架构/DB 是否合适？Discoverability Check 在架构语境怎么定义"冲突"？
4. **与 spec-superflow 集成**的侵入度是否可接受？guard 扩展是否会破坏其零依赖/轻量哲学？
5. **技术架构与产品策略分离**（docs/architecture/ 独立于 STRATEGY.md）是否符合用户 4A 方法论与一人创业的实际操作成本？
6. **API 仅每变更内设计**（不进全局）是否会在跨 change 的 API 一致性上留债？是否需要轻量 API 索引？

---
*草稿 v0.1 — 由 copilot(阿通) 基于 spec-superflow + compound-engineering 源码及用户 4A/DDD 知识库材料起草，待四方专家会审后修订。*
