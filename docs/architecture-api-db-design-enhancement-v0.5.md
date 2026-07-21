# 架构 / API / DB 设计增强方案 · v0.5（全量修订版 + 原型内循环 + 产品级编排 + 复利贯穿）

> 版本：v0.5 · 全量修订
> 底座：**architecture-design skill**（book-to-skill 蒸馏自 LT 知识库 4A/DDD 培训材料，含 F1–F8 框架）
> 修订依据：v0.3 全量内容保留；v0.5 新增四项核心修订——① 原型从 PRD 后独立阶段改为 **PRD 内循环验证手段**；② 新增**产品级工作流编排层**（workflow-orchestrator）；③ ce-plan 职责收窄为**产品级策略**（change 拆分 + 依赖 + 技术方向）；④ 复利从被动触发升级为**复利贯穿机制**（三层索引 + 阶段感知注入 + 主动捕获 + 晋升）。
> 相较 v0.3 的关键修正：① 第三节 SOP 图重画（原型内循环 + 产品级编排 + 复利贯穿层）；② 第四节产物结构补 `docs/solutions/` 三层索引 + `prd/vN/prototype-review.md`；③ 第七节复利回写升级为复利贯穿（新增 8-12 条）；④ 第十节补产品级编排层 + spec-writer 读原型 + 复利不阻断；⑤ 第十一节补 prototype-sync CLI + 复利脚本；⑥ 第十五章 §15.1 重写（原型内循环）+ §15.2 新增（内循环 SOP）+ §15.3 新增（制品链真相来源）；⑦ 新增第十七章产品级工作流编排；⑧ 新增第十八章复利贯穿机制；⑨ 决策落实状态补 v0.5 决策。

---

## 一、设计目标（用户原话落地）
1. 架构设计：每需求做"增强"——对**当前现状 + 需求对应架构变更**做设计；**复利环节回写全局架构设计**。
2. DB 设计：与架构**同样模式**（每变更增量 + 复利回写全局）。
3. API 设计：主要在**每变更需求内**设计（不进全局层）。
4. 架构方法：**DDD**（领域驱动设计）。
5. 借鉴 compound-engineering（复利工程）可补充本块的好经验。
6. **原型设计（v0.3 新增，v0.5 修正）**：原型是 **PRD 的内循环验证手段**（非 PRD 后的独立阶段）；全局一份、与 PRD 同级、随 PRD 版本 git 分支演进；PRD + 原型一起冻结为需求基线；change 引用全局原型作 UI 契约；change 完成增量回写全局原型/架构/API；设计系统由项目 config 注入、复利回写（详见第十五章）。
7. **复利贯穿（v0.5 新增）**：复利不是事后补记，是**流程内嵌机制**——三层索引（INDEX.md + 分阶段目录 + 按需全文）控制上下文占用；阶段感知注入（进入每阶段自动加载相关经验）；主动捕获（阶段转换点自动检测可复利时刻）；晋升机制（change 内经验经验证后晋升为产品级经验）。复利从始至终贯穿产品级和变更级（详见第十八章）。
8. **产品级编排（v0.5 新增）**：新增产品级工作流编排层（workflow-orchestrator），编排 ce-brainstorm→原型内循环→ce-plan→拆 change→分发到 spec-superflow；与变更级 workflow-start（8 态状态机）分层协作（详见第十七章）。

## 二、方法论底座（architecture-design skill）
- **F1 4A 分叉依赖**：`BA→(IA∥AA)→TA`，BA 先行、IA/AA 并行双向对齐、TA 最后。
- **F2 跨域一致性**：AA 功能≥1 IA 实体支撑，IA 实体≥1 AA 功能消费；结构+语义双对齐（发布门禁）。
- **F3 变更分叉级联**：直接/间接/隐式三层次必覆盖。
- **F4 DDD 聚合四要素**：实体+值对象+聚合根+事务边界；仅业务服务有聚合。
- **F5 限界上下文/Context Map**：语义边界=L3 应用服务；映射 Shared Kernel/ACL/OHS。
- **F6 CQRS 写读模型**：事务型→写模型，分析型→读模型；Command/Read→写模型，Query 经阻断测试分流。
- **F7 三维判定**：失忆(归属)+阻断(类型)+孤岛(层级)。
- **F8 增量设计+复利回写闭环**：As-Is 冻结+版本锚点 → To-Be → 全局锚点复利。

## 三、总体闭环（SOP 步骤，v0.5 重画）
```
模糊需求
  │
  ▼
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  产品级编排层（workflow-orchestrator，v0.5 新增）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  │
  ├─ S1 ce-brainstorm ──→ PRD(vN) 草稿 ◀──┐
  │     │                                  │ 原型内循环（v0.5 修正，可选）
  │     ├─ 判断是否需要原型 ────────────────┤
  │     │     │                            │
  │     │     ▼                            │
  │     │   prototype skill ──→ 原型       │
  │     │     │                            │
  │     │     ▼                            │
  │     │   原型审查（对照 PRD 功能点）─────┘
  │     │     │  发现问题 → 回到 brainstorm 修正（最多 3 次）
  │     │     │  审查通过 ↓
  │     │     ▼
  │     │   PRD + 原型 冻结（需求基线 vN）
  │     │     产出 prd/vN/prototype-review.md（审查记录）
  │     │
  ├─ S2 ce-plan ──→ plan(vN)（v0.5 收窄）
  │     │  产品级策略：change 拆分方案 + 依赖 + 技术方向
  │     │  细粒度任务留给 spec-writer（不在 ce-plan 内展开）
  │     │
  ├─ S3 拆 change ──→ change-1, change-2, ...
  │     │  每 change 定义：scope + 依赖 + 优先级
  │     │
  └─ S4 分发 ──→ 各 change 进入 spec-superflow（workflow-start）
       │
  [复利贯穿层（v0.5 新增）] ← 每个阶段转换点自动检测
       │  检测可复利时刻 → 捕获 → 写入索引 → 下阶段注入
       │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  变更级执行层（workflow-start，8 态状态机，不变）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  exploring → specifying → bridging → approved-for-build
  → executing → closing
       │
  spec-writer 读取全局 prototype/ 作 UI 契约（v0.5 新增）
  architecture-design 增量设计
       │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  复利回写层（closing 期，v0.5 增强）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  arch-merge → prototype-sync（顺序提交，v0.5 实现为 CLI）
  复利晋升：change 内经验 → 全局 docs/solutions/（v0.5 新增）
  全局 ARCHITECTURE.md / DATABASE.md / prototype/ / design-system.md
       │
       ▼
  全局作为下一 change / 下一 PRD 版本的 grounding → 闭环
```

**原型合规路径（v0.5 修正）**：原型是 **PRD 的内循环验证手段**（非 PRD 后的独立阶段）。ce-brainstorm 产出 PRD 草稿后，判断是否需要原型；如需要则调用 prototype skill 产出原型，对照 PRD 审查，发现问题回到 brainstorm 修正，审查通过后 PRD + 原型一起冻结为需求基线。原型仍是**全局产物**（与 PRD 同级、一份、git 分支隔离），由「本地 HTML 原型 skill」产出维护进 `prototype/`。spec-superflow 的 `handoff --type prototype` 仅作可选可行性草图旁路，**不复用**其 per-change overlay 作为主机制。原型的 UX 增量经 change 完成后增量回写全局 `prototype/` 与 `design-system.md`，并流入 `execution-contract.md` 驱动开发；design.md 保持不可变。

**制品链真相来源（v0.5 新增）**：PRD 阶段结束时 PRD + 原型一起冻结，后续阶段不可回改 PRD（需升版 vN+1 走完整内循环）。上游制品是下游的真相来源，下游发现上游有问题触发上游升版，不回改上游。

## 四、产物结构（全量，v0.5 增补）
```
项目根/
├── prd/                    # 【全局层，与 prototype 同级】PRD + 实施方案，有版本 v1→v2→v3（git 分支隔离）
│   └── vN/
│       ├── prd.md          # 业务要件（ce-brainstorm 产出，定义 WHAT）
│       ├── plan.md         # 实施方案（ce-plan 产出，定义 HOW，v0.5 收窄为产品级策略）
│       └── prototype-review.md  # 【v0.5 新增】原型审查记录（PRD 内循环产出，审查结论+版本+日期）
├── prototype/              # 【全局层，一份，git 分支隔离】原型系统（见第十五章 §15.3）
│   ├── index.html          # 入口 / 全局导航
│   ├── pages/              # 多页面（首页/列表/详情/设置…）
│   ├── components/         # 可复用组件（统一设计系统）
│   ├── assets/             # style.js / design-tokens.css
│   ├── design-system.md    # 本项目设计系统（项目 config 注入，9 段 schema）
│   └── flow.md             # 页面跳转 / 用户流
├── STRATEGY.md              # 产品/BA 锚点（compound，不动）
├── CONCEPTS.md              # 领域词汇（追加 DDD 术语，复利累积）
├── AGENTS.md                # 追加一节暴露 docs/architecture/ 与 prototype/（Discoverability）
├── docs/
│   ├── architecture/       # 【技术锚点层，独立于 STRATEGY.md，起步即按 bounded context 分目录】
│   │   ├── ARCHITECTURE.md      # 瘦锚点总览：Context Map + 各 bc 链接 + 关键决策（覆盖式当前态）
│   │   ├── DATABASE.md          # 全局 DB 总览（实体+读写模型+OLTP/OLAP，覆盖式）
│   │   ├── <bc>/                # 每个限界上下文一目录（天然扩展点）
│   │   │   ├── context.md       # 该 bc 的聚合/实体/服务/读写模型/事务边界
│   │   │   └── evolution.md     # 该 bc 演进日志（append-only，含 change_id+来源）
│   │   └── API-INDEX.md         # 脚本生成（扫描所有 specs/*/api.md），非手写
│   └── solutions/          # 【v0.5 新增】复利经验库（三层索引，见第十八章）
│       ├── INDEX.md        # L1 轻量索引（≤150行，每条一行摘要+标签）
│       ├── prd/            # 按阶段分目录
│       ├── plan/
│       ├── prototype/
│       ├── spec/
│       ├── build/
│       ├── review/
│       └── cross-phase/    # 跨阶段通用经验
├── specs/<cap>/             # 【变更层，一份 PRD 可拆多 change】
│   ├── spec.md / design.md / tasks.md / execution-contract.md   # spec-superflow 原产物
│   ├── architecture.md      # 【每变更 DDD 增量】
│   ├── database.md          # 【每变更 DB 增量】
│   ├── api.md               # 【每变更 API 设计】
│   └── learnings.md         # 【v0.5 新增】change 内经验（候选晋升到全局 docs/solutions/）
```
> **两层归属说明**：`prd/` 与 `prototype/` 在**全局层**（产品级，与 PRD 同级），各一份，版本演进靠 git 分支/标签隔离；`specs/<cap>/` 在**变更层**，一份 PRD（某版本）可拆多个 change，change 是 spec-superflow 实施单位，引用全局 `prototype/` 作 UI 契约。
> **复利经验归属说明（v0.5 新增）**：`docs/solutions/` 在**全局层**（产品级经验），`specs/<cap>/learnings.md` 在**变更层**（change 内经验，候选晋升）。晋升条件：severity ≥ medium 且 type = pitfall/pattern，且与全局 INDEX 无重复。

## 五、每变更增量模板
### 5.1 architecture.md
```yaml
---
cap_id: <cap>
date: YYYY-MM-DD
change_type: new | modify
bounded_contexts: [<上下文>]
aggregates_affected: [<聚合>]
cqrs: [write:<x>, read_model:<y>]   # 注：read_model 承载 Read 指令与 Query
tags: [ddd, <领域>]
---
```
- **## 现状快照(As-Is，冻结基线)**：复制 `docs/architecture/ARCHITECTURE.md` 相关章节**当前原文**，记录来源锚点 `ARCHITECTURE.md@<change_id>#<章节>`。**本变更内不可变**，不得用"见全局第 X 节"活引用。
- **## 本次架构变更(To-Be)**：新增/调整限界上下文与 Context Map 关系；聚合(实体+值对象+聚合根+事务边界)；CQRS 写读模型；4A 跨域对齐(IA/AA/TA，结构+语义双对齐)。
- **## 架构决策(ADR)**：决策与理由（复用 design.md 的 ADR 风格）。
- **硬规则**：聚合仅存业务服务（数据/技术服务无聚合）；Query 经阻断测试分流。

### 5.2 database.md
```yaml
---
cap_id: <cap>
date: YYYY-MM-DD
change_type: new | modify
entities_affected: [<实体>]
cqrs: [write:<x>, read_model:<y>]
oltp_olap: [oltp:<t>, olap:<a>]
tags: [db, <领域>]
---
```
- **现状快照(As-Is，冻结)**：同上机制。
- **本次 DB 变更(To-Be)**：实体+生命周期；聚合对应表/事务边界；写模型(OLTP) vs 读模型(OLAP，派生自写模型)。
- **迁移策略**：前向兼容/双写/回填。

### 5.3 api.md（仅每变更）
- **API 清单**：端点/方法/职责。
- **指令映射(L6)**：每端点标 Command/Read/Query；Query 标阻断测试归属(业务/数据服务)。
- **契约**：请求/响应 schema、错误码、幂等。
- 下游脚本扫所有 api.md 生成 `API-INDEX.md`（消除跨 change 一致性留债，近零成本）。
- **硬消费钉死（v0.3）**：api.md 经 `execution-contract.md` 被 build-executor **硬消费**（TDD 实现），不得仅作参考；跨 change 一致性由 `API-INDEX.md` 脚本兜底。

## 六、全局架构/DB 文档（分目录 + 瘦锚点 + 双视图）
- **总览层（覆盖式当前态）**：`docs/architecture/ARCHITECTURE.md` 瘦锚点总览 = Context Map（各 bc 链接）+ 关键决策；`DATABASE.md` = 全局 DB 总览（实体+读写模型+OLTP/OLAP）。
- **每上下文层（分目录，起步即建）**：`docs/architecture/<bc>/context.md` 承载该 bc 的聚合/实体/服务/读写模型/事务边界（元素+制品层）；`docs/architecture/<bc>/evolution.md` 承载该 bc 演进日志（append-only，含 change_id+来源）。
- **三层内容（来自 F 产出三层）**：
  - 元素层：BA 活动 / IA 数据实体 / AA 功能与聚合 / TA 技术服务（四域一等元素，命名注册表防漂移）。
  - 制品层：Context Map、业务流程图(功能→聚合映射)、CQRS 读写模型。
  - 交付件层：架构评审文档（**生成视图**，非手写巨著）。
- **双视图（防多版本矛盾）**：总览 `ARCHITECTURE.md` 当前态覆盖式更新；各 `<bc>/evolution.md` append-only 保留历史。

### 6.1 技术锚点定性的设计影响与高质量可拓展保障（决策 3）
用户确认：技术架构(IA/AA/TA)独立于产品策略(BA/STRATEGY.md)，ARCHITECTURE.md 作为"瘦锚点"而非评审巨著。这一定性对后续设计的**具体约束与保障**如下：
- **两份独立文档、互相链接不混写**：STRATEGY.md 答"做什么/为什么"(BA)，ARCHITECTURE.md 答"怎么建"(IA/AA/TA)；改业务不重写技术，改技术不污染策略。这是 compound "Anchor not plan" 延伸到技术域。
- **分目录 = 天然扩展点（决策 1 落地）**：每新增限界上下文 = 新增 `docs/architecture/<bc>/` 目录，不膨胀单文件，检索粒度与一致性检查随规模线性可控 → 高质量可拓展的结构前提。
- **命名注册表防语义漂移**：元素层标准化命名（用户/客户/consumer 不并存）是跨上下文可拓展的术语基础；新增 bc 时强制对照注册表，避免概念分裂。
- **双视图保证当前真相清晰**：总览覆盖式当前态 + 各 bc 演进日志 append-only，任何时刻能确定"现在是什么"与"怎么来的"，扩展时不丢失历史。
- **跨域一致性门禁保障扩展质量**：每次回写跑 AA≥1 IA 实体（结构+语义双对齐），新 bc 接入不破坏既有对齐 → 可拓展不以一致性妥协为代价。
- **瘦锚点保障可持续**：避免评审交付巨著，单人也能维护，使架构资产随项目长期复利而非一次性文档。

## 七、复利回写机制（借 ce-compound，v0.5 升级为复利贯穿）
1. **结构化 frontmatter（原则借鉴）**：架构专用 schema（cap_id/date/change_type/bounded_contexts/aggregates/cqrs），非直接复用 schema.yaml（那是 learnings 专用）。
2. **one change per run**：一次回写一个变更 delta（变更可追溯、不混杂多变更）。
3. **双视图回写**：当前态覆盖 + 演进日志追加。
4. **架构一致性/漂移检查（独立机制，非 Discoverability）**：①结构冲突（重复 BC/聚合 key）②语义冲突（同义异名，如客户vs用户，按命名注册表）③跨域一致性门禁（AA≥1 IA 实体，反之亦然）。
5. **Discoverability 正名（compound 原义）**：在 AGENTS.md/CLAUDE.md 暴露 `docs/architecture/` 与 `prototype/`（存在/结构/何时检索），使代理设计前"发现并查阅"；仅在未暴露时追加一节。
6. **下游检索复用**：下一 change 设计前从 `docs/architecture/` 检索相关上下文/聚合，grounding 用 CONCEPTS.md（已含 DDD 术语）。
7. **设计系统复利（v0.3 新增）**：change 完成回写的 UX 增量若涉及设计系统迭代（新组件/新 token/新 anti-pattern），合并进全局 `prototype/design-system.md`，作为项目级风格唯一真相源复利累积；design-system.md 是项目资产（config 注入），回写发生在项目内，不污染插件通用性。
8. **三层索引架构（v0.5 新增）**：复利经验按三层组织——L1 `docs/solutions/INDEX.md`（≤150 行轻量索引，每条一行摘要+标签，每次流程启动加载 ~2k token）；L2 阶段过滤（进入每阶段时按 phase+domain 取 top-5，~1k token）；L3 按需全文（高度相关时读取单文件，≤100 行/篇，最多同时 2 篇）。最坏情况 ~6.5k token，上下文可控。
9. **阶段感知注入（v0.5 新增）**：每个阶段启动时自动读取 INDEX.md，按 `phase = 当前阶段 OR cross-phase` 且 `domain` 匹配过滤，取 top-5 摘要注入。各阶段注入点：ce-brainstorm(Phase 1.1)→prd/cross-phase；ce-plan(Phase 1.1)→plan/cross-phase；prototype(设计前)→prototype/prd；spec-writer(生成前)→spec/cross-phase；build-executor(wave 前)→build/spec；code-reviewer(审查前)→review/build；release-archivist(归档前)→cross-phase。
10. **主动捕获：可复利时刻（v0.5 新增）**：在阶段转换点自动检测，不阻塞流程——需求矛盾（原型审查发现 PRD 遗漏）、设计返工（spec/design 被拒）、重复缺陷（同类问题第 2 次）、范围蔓延（超出原始 scope）、契约漂移（re-bridge 触发）、阶段回退（mandatory rewind）。检测到时生成经验草稿（phase+domain+type+一句话摘要）写入 INDEX.md + 对应目录。
11. **晋升机制（v0.5 新增）**：change 内经验存 `specs/<cap>/learnings.md`；release-archivist 归档时检查晋升条件（severity ≥ medium 且 type = pitfall/pattern，且与全局 INDEX 无重复）→ 晋升到全局 `docs/solutions/`；domain+type 匹配已有条目 → 标记"已确认模式"，severity 升级。
12. **上下文占用控制（v0.5 新增）**：INDEX.md 硬上限 150 行，超出按 severity 淘汰低优先级条目；单经验文件 ≤100 行；每次注入最多 top-5 摘要 + 2 篇全文；阶段退出复盘 ≤500 token。

## 八、全局文档组织（已定：起步即分目录）
用户决策：**起步即按 bounded context 分目录** `docs/architecture/<bc>/`（非单文件分节）。这是 compound `problem_type→directory` 的真类比，也是高质量可拓展基础——每新增限界上下文=新增目录，不膨胀单文件，检索粒度与一致性检查随规模线性可控。结构见第四节与第六节。

## 九、compound-engineering 经验借鉴（修正后清单）
| # | 经验 | 本方案映射（修正） |
|---|---|---|
| 1 | 全局锚点（STRATEGY.md, Anchor not plan） | → `docs/architecture/` 作**技术架构单一事实源**；业务策略(BA/STRATEGY.md)与技术架构(IA/AA/TA)是两份独立文档、互相链接不混写——填补 compound 无技术架构产物的缺位（非"修正其错误"）；ARCHITECTURE.md 是**瘦锚点**(短稳 what&why)，非评审交付巨著 |
| 2 | 结构化复利回写 | → 架构专用 frontmatter + 双视图回写（原则借鉴，非套用 schema.yaml）；**v0.5 升级为三层索引 + 阶段感知注入 + 主动捕获 + 晋升**（第十八章） |
| 3 | requirements-only→implementation-ready | → **ce-brainstorm→ce-plan 独立文档** 演进：ce-brainstorm 产出 PRD（业务要件，定义 WHAT），ce-plan 基于 PRD 产出独立的实施方案（定义 HOW），两份产物共同作为后续输入。ce-plan 支持两种模式：业务模式（产品视角，不关心技术选型）/ 一人公司模式（技术视角，补充技术方案）。**v0.5 收窄**：ce-plan 聚焦产品级策略（change 拆分+依赖+技术方向），细粒度任务留给 spec-writer |
| 4 | one learning per run + 并行 | → 一次一变更 delta 回写 |
| 5 | pulse 大环 | → （增强项）架构健康度脉冲，后续 |
| 6 | **复利贯穿（v0.5 新增）** | → 复利从"事后补记"升级为"流程内嵌"：三层索引控上下文、阶段感知注入、主动捕获可复利时刻、change→product 晋升。贯穿产品级（orchestrator 各阶段）和变更级（spec-superflow 各状态）|

## 十、与 spec-superflow 集成（软集成，保全零依赖，v0.5 增补）
- **状态机**：8 态不变；三份增量文档为**推荐产出、软提示、非阻断**（复用 `config.artifacts.skip`，不改 core guard）。
- **guard 扩展**：frontmatter 校验降级为**独立 advisory 脚本**（正则提取 key，warning 级，**不引第三方 YAML 依赖**）；全局回写经独立 `arch-compound` skill/overlay，**不进状态机硬矩阵**。
- **原型机制（v0.5 修正）**：原型为 **PRD 内循环验证手段**（非 per-change overlay），由「本地 HTML 原型 skill」产出维护进全局 `prototype/`；spec-superflow `handoff --type prototype` 仅作可选可行性草图旁路；design.md 保持不可变，原型 UX 增量经 change 增量回写全局 `prototype/` 与 `design-system.md`，并流入 `execution-contract.md` 驱动开发。
- **产品级编排层（v0.5 新增）**：workflow-orchestrator 是产品级编排器，**不改变 8 态状态机**。它通过创建 change 目录 + `.spec-superflow.yaml` 触发 workflow-start，通过 release-archivist 的 closing 回调感知 change 完成。产品级编排与变更级执行分层协作。
- **spec-writer 读取全局 prototype/（v0.5 新增）**：spec-writer 生成 design.md 时，读取全局 `prototype/` 的 `flow.md` 和 `pages/` 目录作为 UI 契约输入，在 design.md 中引用原型页面路径；tasks.md 中 UI 相关任务引用原型组件。
- **复利贯穿不阻断流程（v0.5 新增）**：所有复利操作（注入/捕获/晋升）为 **advisory 级**，不阻断状态转换。INDEX.md 读取失败时静默跳过，不报错。
- **术语正名**：IA/AA 非"技术架构"（仅 TA 是）；4A 是四域非三层；全局回写≠spec-merger（后者只合并 delta spec 进 main spec base，触发于 closing）。

## 十一、SOP 化（LLM 块 + 明确脚本，v0.5 增补）
- **LLM 负责（人守深度思考）**：限界上下文/聚合识别、Context Map 关系选型、4A 跨域对齐推理、CQRS 划分、API 指令映射、ADR 理由、架构一致性语义判定、**原型 UX 流向全局 prototype/ 与 design-system.md 的决策**、**原型审查对照 PRD 功能点（v0.5）**、**可复利时刻识别与经验草稿生成（v0.5）**。
- **明确脚本（零/低 LLM）**：
  - `validate-frontmatter`：校验三份增量 frontmatter 字段完整性（advisory）。
  - `arch-merge`：delta 以 append + 版本锚点合入全局，one change per run。
  - `discovery-check`：扫描重复/冲突 BC/聚合（机械查重；语义冲突归 LLM）。
  - `api-index-gen`：扫描所有 `specs/*/api.md` 生成 `API-INDEX.md`。
  - `asis-extract`：按版本锚点从全局抽取相关章节填入增量 As-Is（防漂移）。
  - `prototype-sync`（v0.3 定义，**v0.5 实现为 CLI 子命令**）：`ssf prototype-sync <change-dir> --source <ux-delta-path>`，change 完成 → UX 增量 + design-system 迭代回写全局 `prototype/` 与 `design-system.md`（one change per run，与 `arch-merge` 同级；不引第三方依赖）。release-archivist closing 时调用。
  - **回写顺序（closing 期，评审修正 B）**：`arch-merge` → `prototype-sync` **顺序提交**（同一 change closing 内），避免全局 `docs/architecture/` 与 `prototype/` 半更新态被下一 change grounding。
  - `solutions-index-gen`（v0.5 新增）：扫描 `docs/solutions/*/` 目录，解析 frontmatter，重建 INDEX.md（防索引漂移）。
  - `solutions-inject`（v0.5 新增）：`ssf solutions inject --phase <p> --domain <d>`，过滤 INDEX.md 输出 top-5 摘要（供各 skill 调用）。
  - `solutions-capture`（v0.5 新增）：`ssf solutions capture --phase <p> --domain <d> --type <t> --severity <s> --summary <text>`，写入一条经验到 INDEX.md + 对应目录文件。
  - `solutions-promote`（v0.5 新增）：`ssf solutions promote <change-dir>`，检查 `specs/<cap>/learnings.md` 中经验的晋升条件，执行 change→product 晋升。

## 十二、第二大脑整合（ima「LT的知识库」）
- **方法层(kb)**：存 `architecture-design` skill + `prototype` skill + 每限界上下文一个 `architecture-anchor` 资产（frontmatter: tags/bounded_contexts/aggregates 作索引键）。
- **项目层(repo)**：`docs/architecture/` 为权威源；`prototype/` 为 UI 契约权威源。设计前检索 kb skill + 读全局 ARCHITECTURE.md 与全局 prototype/ 作 grounding；回写后**批量**同步 Context Map 索引入 kb（避免每 delta 双写）。
- **人机协同闸点**：每变更设计末尾设 human gate——ADR 批准 + Context Map 关系确认 + 原型 UX 评审（LLM 出 draft，人守深度思考）。

---

## 十三、四方专家会审结论摘要（已吸收，v0.2）
- **共识**：方向正确、需修改、主体可落地；全量吸收下列硬伤。
- **DDD/4A 专家**：As-Is 漂移(R1/R2)、IA/AA 误称技术架构(R3)、4A 误称三层(R4)、Discoverability 仅查重名(R5)、聚合仅业务服务/Query 阻断测试/Read 与读模型术语消歧、元素层补 BA 活动与 AA 功能。
- **spec-superflow 专家**：原型直接改 design.md 违规（须 handoff→delta）、guard YAML 校验破零依赖（降级 advisory）、全局回写硬 gate 扭曲同步闭包（改 overlay）、design.md 已是架构一等公民（职责需划清）。
- **compound 专家**：Discoverability 误读（正名为 AGENTS.md 暴露）、problem_type→directory 未实例化（改分目录）、"技术架构折叠进 STRATEGY"误述（实为缺位）、Anchor not plan 应延伸到技术锚点、ARCHITECTURE.md 瘦锚点非评审巨著。
- **知识管理专家**：草稿是设计稿非可执行 SOP（已补第十一章）、一人创业成本（已补 MVP 章节）、第二大脑整合（已补第十二章）、API 留债（已补脚本化索引）、As-Is 版本锚点（已补第五章）。

---

## 十四、落地路线（用户决策：初期即全量铺开）
> 用户决策：**不缓步 MVP，初期即按全量蓝图落地**（决策 2）。以下 MVP-0..4 作为**全量骨架的内部结构分期参考**——骨架一次性建好、后续持续复利，而非"先验证再补"。

**全量骨架一次性建立（初期即启用）**：
- `architecture-design` skill 已蒸馏（底座）。
- `prototype` skill（v0.3 新增，待定稿后并入统一插件）：本地 HTML 原型内核（零外部依赖）+ 配置驱动读取项目 design-system.md。
- `docs/architecture/` **分目录**建好（ARCHITECTURE.md 总览 + DATABASE.md + 每个已知 bc 的 `<bc>/context.md`+`<bc>/evolution.md`）。
- `specs/<cap>/` 三份增量（architecture/database/api）全量启用。
- 全局 `prd/`（v1 基线）+ 全局 `prototype/`（随 PRD v1 初始化，含 design-system.md 由项目 config 注入）建好。
- 4+1 脚本落地：`validate-frontmatter` / `arch-merge` / `discovery-check` / `api-index-gen`（+ `asis-extract`）+ `prototype-sync`（v0.3 定义，v0.5 实现）。
- `AGENTS.md` 暴露 `docs/architecture/` 与 `prototype/`（Discoverability）。
- **v0.5 新增**：`docs/solutions/` 三层索引建好（INDEX.md + 分阶段目录）；`workflow-orchestrator` skill 建好；复利脚本 4 个落地（solutions-index-gen / inject / capture / promote）；`prototype-sync` CLI 实现。

**分期参考（能力启用节奏，非强制缓步）**：
- MVP-0 方法论+脚本底座 → 已随全量一并建立。
- MVP-1 架构单轨 / MVP-2 加 DB / MVP-3 加 API 索引 → 全量初期即启用，非按需后加。
- MVP-4 硬化 → `discovery-check` 语义规则随语料增长持续硬化（分目录已就绪，无需后期重构）。
- **MVP-5（v0.5 新增）**：复利贯穿机制启用 → 三层索引 + 阶段感知注入 + 主动捕获 + 晋升。

---

## 十五、原型设计能力（v0.3 新增，v0.5 修正）

> 本章为 v0.3 新增原型章，v0.5 修正核心定位：原型从"PRD 后的独立阶段"改为"PRD 的内循环验证手段"。调研原文见 `prototype-design-research.md`。

### 15.0 五方案对比结论（调研事实）
| 方案 | 形态 | 对"纯 CLI 插件"可用性 | 结论 |
|---|---|---|---|
| Claude Design（Anthropic, 2026-04 beta） | 对话生成设计/交互原型/幻灯片；组织设计系统自动继承 | 强依赖 web/desktop 画布，无纯 CLI；唯一非 GUI 通道是 MCP（底层仍依赖 api.anthropic.com） | **不适合内嵌** |
| Open Design（nexu-io, Apache-2.0） | 本地优先开源替代；71 品牌级 DESIGN.md + 5 方向调色板 | 需本地 daemon + Vite React 前端 + 浏览器预览，非纯 CLI | **不内嵌；但其 DESIGN.md 概念值得借鉴** |
| Trae Work Design（字节） | 生成/迭代界面设计，导出 Figma/HTML/ZIP | 强依赖 GUI 画布/可视化编辑器 | **不适合内嵌** |
| spec-superflow handoff --type prototype | 验证变更设计可行性的 overlay | 纯 CLI 但仅草图，无设计系统、无闭环、非主流 | **仅作可选草图旁路** |
| **本地 HTML 原型 skill（本方案）** | 自包含 HTML 原型系统 + 内嵌 Tweaks + 项目设计系统板 | 纯 CLI 产出、零外部依赖、可离线 | **最优** |

- **结论**：对"无应用、纯 CLI 插件"，最优原型 = **本地 HTML 原型 skill（零外部依赖）+ 借鉴 Open Design 的 DESIGN.md 概念**（内化，非调用产品）。
- **硬约束**：不安装/不调用任何 GUI 设计软件（Claude Design / Open Design / Trae 均不安装）。spec-superflow 的 `handoff --type prototype` 仅作可选可行性草图旁路，**不复用**其 per-change overlay 作为主机制。

### 15.1 原型定位修正（v0.5）

**v0.3 定位**：原型是 PRD 之后的独立阶段，change 引用全局原型。

**v0.5 修正**：原型是 **PRD 的内循环验证手段**。

```
ce-brainstorm 产出 PRD 草稿
    │
    ├─ 判断是否需要原型（用户选择 / PRD 含 UI 功能点自动建议）
    │     │
    │     ├─ 不需要 → PRD 直接冻结
    │     │
    │     └─ 需要 → prototype skill 产出原型
    │           │
    │           ▼
    │         原型审查（对照 PRD 功能点清单）
    │           │
    │           ├─ 发现问题 → 回到 brainstorm 对话修正 PRD → 更新原型 → 再审查
    │           │
    │           └─ 审查通过 → PRD + 原型一起冻结为需求基线 vN
    │
    ▼
ce-plan 读取冻结的 PRD + 原型
```

**核心准则**：
- 原型不是 PRD 的下游，是 PRD 的**验证工具**。
- PRD 阶段结束时，PRD + 原型一起冻结，后续阶段不可回改 PRD（需升版 vN+1 走完整内循环）。
- 原型仍是**全局产物**（与 PRD 同级、一份、git 分支隔离），不变。
- 原型审查记录写入 `prd/vN/prototype-review.md`。

### 15.2 原型内循环 SOP（v0.5 新增）

```
Phase A：原型触发判断
  - PRD 草稿中是否包含 UI/画面/交互相关功能点？
  - 用户是否需要可视化验证？
  - 如果是 → 进入 Phase B
  - 如果否 → 跳过，PRD 直接冻结

Phase B：原型产出
  - 读取 PRD 草稿中的功能点清单
  - 读取 design-system.md（config 注入）
  - 调用 prototype skill 产出原型页面
  - 产出 prototype/ 目录（index.html + pages/ + components/ + flow.md）

Phase C：原型审查（对照 PRD）
  - 逐功能点检查：PRD 中每个 UI 功能点是否在原型中有对应页面/组件？
  - 状态流转检查：PRD 中的状态流转是否在原型 flow.md 中完整体现？
  - 边界检查：PRD 中的边界条件是否在原型中有体现（空状态/错误状态/加载状态）？
  - 产出审查报告：覆盖/遗漏/矛盾清单

Phase D：修正循环（如果 Phase C 发现问题）
  - 遗漏 → 回到 ce-brainstorm 对话，补充 PRD 功能点 → 更新原型 → 回 Phase C
  - 矛盾 → 回到 ce-brainstorm 对话，解决矛盾 → 更新原型 → 回 Phase C
  - 最多循环 3 次，超过则标记为"需人工介入"
  - 每次修正触发复利捕获（可复利时刻：需求矛盾）

Phase E：冻结
  - PRD + 原型审查通过
  - 写入 prd/vN/prototype-review.md（审查结论 + 版本 + 日期）
  - PRD 标记为 frozen，后续阶段不可回改
```

### 15.3 制品链真相来源（v0.5 新增）

| 制品 | 真相来源 | 冻结时机 | 后续阶段可否回改 |
|------|---------|---------|----------------|
| PRD（WHAT） | ce-brainstorm | PRD + 原型审查通过后 | ❌ 不可回改（需升版 vN+1） |
| 原型（UI 契约） | prototype skill（PRD 内循环） | 同 PRD | ❌ 不可回改（需升版） |
| plan（HOW 策略） | ce-plan | 用户确认后 | ⚠️ 可修订（需记录修订原因） |
| spec/design/tasks | spec-writer | DP-2 确认后 | ❌ 不可回改（需 re-specify） |
| execution-contract | contract-builder | DP-3 批准后 | ❌ 不可回改（需 re-bridge） |
| 代码 | build-executor | closing 后 | — |

**冲突解决原则**：上游制品是下游的真相来源。下游发现上游有问题，不回改上游，而是**触发上游升版**（PRD vN → vN+1，走完整内循环）。

### 15.4 两层产物层级模型（全局层 vs 变更层，第 16 轮确认）
必须先厘清 PRD / 原型 / 代码 / change 的层级关系，否则原型归属会错（此前误把原型放 change 维度）。

**全局层（产品级，与 PRD 同级）：**
- `prd/`：PRD，**有版本迭代** v1→v2→v3…，每个版本是完整需求基线。
- `prototype/`：原型，**全局一份**，与 PRD 同级；随 PRD 版本演进，物理一份，git 分支隔离版本。
- `design-system.md`：全局一份，config 注入。
- `architecture.md`（即 `docs/architecture/`）：全局架构，复利回写目标。
- `api.md`（即 `docs/architecture/API-INDEX.md` 聚合）：全局 API 索引，复利回写目标。
- `src/`：代码，全局一份，git 分支隔离。

**变更层（spec-superflow change，从 PRD 拆解）：**
- `specs/<cap>/`：spec.md / design.md / tasks.md / execution-contract.md / architecture.md / database.md / api.md / learnings.md（v0.5 新增）。
- 每个 change 走 spec-superflow 8 状态机。
- **一份 PRD（某版本）可拆出多个 change**；change 是实施工作单位，不是产品基线。

**关系链：**
```
PRD(vN) ──拆解──┬─▶ change-1 ─▶ spec-superflow（exploring→…→closing）
                ├─▶ change-2 ─▶ spec-superflow
                └─▶ change-3 ─▶ spec-superflow
全局 prototype/ ──（UI 契约参考）──▶ 各 change 的 build-executor
各 change 完成 ──（增量合并）──▶ 全局 architecture.md / api.md / prototype / src
```
**核心准则**：原型不是 per-change 的 overlay，而是全局一份、与 PRD 同级；版本演进靠 git 分支，不靠 change 内 v1/v2 目录。

### 15.5 原型迭代模型（全局一份，随 PRD 版本 git 分支演进）
- 原型是**全局产物**（与 PRD 同级），**物理一份**，不是某个 change 的子目录。
- **版本演进靠 git 分支**：PRD 升版（v1→v2）时，原型在对应分支上演进到该版本形态（如 `prd-v2` 分支上的 `prototype/` = v2 产品原型）；一份代码/原型，git 隔离版本。
- **PRD 有版本，原型/代码无多份**：PRD 持续迭代产生 v1/v2/v3 需求基线；原型与代码各自只有"当前形态一份"，历史版本由 git 分支/标签保留。
- **change 引用全局原型**：每个 change 实施时，把全局 `prototype/` 作为 UI 契约参考（进 execution-contract.md）；change 不直接拥有原型文件。
- change 完成 → 其 UX 增量合并回全局 `prototype/` 与 `architecture.md`/`api.md`（compound 复利回写，见 §15.9）。

### 15.6 产物维护（完整原型系统，全局一份）
原型目录位于**全局层**（与 PRD 同级），是完整原型系统，不是单页、不是 change 子目录：
```
prototype/                      # 全局，一份，git 分支隔离版本
├── index.html                  # 入口 / 全局导航
├── pages/                      # 多页面（首页 / 列表 / 详情 / 设置 …）
├── components/                 # 可复用组件（按钮 / 表单 / 卡片 …），统一设计系统
├── assets/                     # 共享 style.js / design-tokens.css
├── design-system.md            # 本项目设计系统（config 注入，9 段 schema）
└── flow.md                     # 页面跳转 / 用户流说明
```
- 版本管理：**git 分支 / 标签**隔离 PRD 版本（非 change 内 v1/v2 目录）。
- 复利回写：change 完成 → 原型结论 + 设计系统迭代回写**全局** `design-system.md` / `architecture.md` / `api.md`；design-system 是项目资产（config 注入），回写发生在项目内。
- 全局 `design-system.md` 作本项目风格唯一真相源，随 PRD 版本演进复利，防漂移。
- **原型膨胀防控（评审修正 C）**：`components/` 必须复用 `design-system.md` 定义的组件，**禁止页面内联样式漂移**；新增组件先沉淀进 design-system 再引用。
- **分支约定（评审修正 C）**：原型随 **PRD 当前版本分支**维护（如 `prd-v2` 分支的 `prototype/` = v2 产品原型）；change 引用其所在 PRD 版本分支的 `prototype/`，避免原型领先/落后于未合并代码分支。

### 15.7 配置驱动（插件通用 + 项目注入）
- **插件通用**：原型 skill 不固化任何公司/产品风格；PRD 模板与设计系统由项目级配置注入。
- **项目注入点**：基于 spec-superflow 真实的 `spec-superflow.config.json`（已 config-aware，支持 `artifacts.order`/`artifacts.skip`，由 `ssf runtime config --get <key>` 读取）。扩展注入：
  - `prd.template`：项目独特 PRD 模板路径（覆盖默认 `templates/prd.md`）。
  - `prototype.designSystem`：项目 `design-system.md` 路径（9 段 schema：color/typography/spacing/layout/components/motion/voice/brand/anti-patterns）+ 5 方向确定性调色板。
  - `prototype.entry`：原型入口（默认 `prototype/index.html`）。
- 模板走 `ssf runtime asset read templates/<name>.md`，项目可覆盖；插件保持零风格依赖、可离线。
- **⚠️ 配置字段边界（评审修正 A）**：`prd.template` / `prototype.designSystem` / `prototype.entry` 为**插件层扩展字段，非 spec-superflow 原生 schema**（原生仅证实 `artifacts.order`/`artifacts.skip`）。插件层用 `ssf runtime config --get <key>` 自读，字段命名须避开原生 key 冲突。建插件时需实测 `ssf runtime config --get prototype.designSystem` 验证读取路径可用。

### 15.8 本地 HTML 原型 skill（零外部依赖内核）
- **内核形态**：自包含 HTML 原型系统（CSS 进 `<style>`、JS 进 `<script>`，页面内 `<div>` Tweaks 控件替代云端工具栏），**avoid remote dependencies，可完全离线、零网站依赖**。
- **设计系统渲染**：原型 skill 读取项目 `design-system.md` 渲染 token（颜色/字体/间距/组件），保证风格与品牌一致。
- **产出**：`prototype/` 完整系统（多页面 + 组件 + 导航 + flow.md），纯 CLI 产出，不依赖任何 GUI 设计产品。
- **不内嵌** Claude Design / Trae / Open Design 的 GUI，只借鉴其"设计系统驱动风格"思想，内核自研为 skill。

### 15.9 复利回写设计系统
- 设计系统由项目 `spec-superflow.config.json` 注入的 `design-system.md`（9 段 schema + 5 方向调色板，项目资产）。
- change 完成 → 其 UX 增量若涉及设计系统迭代（新组件/新 token/新 anti-pattern）→ 经 `prototype-sync` CLI 命令合并回全局 `prototype/design-system.md`，作为项目级风格唯一真相源复利累积。
- design-system.md 回写发生在项目内（config 注入），插件保持通用、不固化任何风格。

### 15.10 与实施阶段衔接（闭环，两层）
```
PRD(vN) ──拆解──┬─▶ change-1 ─┐
                ├─▶ change-2 ─┼─▶ spec-superflow: spec-writer → contract-builder → build-executor
                └─▶ change-3 ─┘         （各 change 引用全局 prototype/ 作 UI 契约）
                                              │
        全局 prototype/ ◀── 增量合并 ────────┘（change 完成回写 UX / 架构 / API）
        compound 复利回写: design-system.md / architecture.md / api.md
```
- 原型（全局）→ 架构：原型确认的 UX 流向全局 `architecture.md` 限界上下文映射（DDD）。
- 原型 → API：原型交互 → 端点设计 → 流入 `execution-contract.md` + build-executor。
- 原型 → 开发：全局原型作 UI 契约参考进 `execution-contract.md`，build-executor 按契约 + TDD 实现。
- 闭环：PRD 版本演进 → 拆 change → spec-superflow 实施 → 增量回写全局原型/架构/API；原型随 PRD 持续迭代不腐烂。

### 15.11 I/O 钉死（补全前 12 轮三处未定义）
- **I/O-1：design.md ↔ architecture.md 关系**：`design.md` 是 spec-superflow 内核的**每变更架构一等公民**（per-change，随 change 状态机走，不可变）；全局 `docs/architecture/ARCHITECTURE.md` 是**跨 change 技术锚点**（复利回写目标）。change 完成 → 其 `design.md`/增量 `architecture.md` 的 delta **增量回写**全局，design.md 本身保持不可变。二者职责划清：design.md=变更内设计稿，ARCHITECTURE.md=全局锚点。
- **I/O-2：api.md 硬消费**：每变更 `api.md` 经 `execution-contract.md` 被 **build-executor 硬消费**（TDD 实现），不得仅作参考文档；跨 change 一致性由 `api-index-gen` 脚本扫所有 `specs/*/api.md` 生成 `API-INDEX.md` 兜底（消除留债）。
- **I/O-3：tasks.md 引用架构/API**：`tasks.md` 显式引用**本 change** 的 `architecture.md`/`api.md` 章节锚点（如 `architecture.md#聚合-x`），**不得活引用全局**；build-executor 按 tasks + execution-contract + 全局 `prototype/` 实现，保证任务与架构/API/原型契约一致。
- **I/O-4（v0.5 新增）：design.md 引用全局 prototype/**：`design.md` 的 UI 相关章节引用全局 `prototype/` 的页面路径（如 `prototype/pages/login.html`）和 `flow.md` 的跳转定义，作为 UI 契约真相源；**不得在 design.md 内重新定义 UI 交互**，引用即可。

---

## 十六、E2E 测试集成（v0.4 设计修订）

> 设计修订号 v0.4（打包版本 0.10.0）。详细方案、双专家评审与决策记录见 `docs/e2e-integration-design.md`。来源：gtmc `acceptance-test` SKILL.md v3.0.0 + `test-verifier.md`；spoko.space《AI & Playwright E2E Testing 2026》。

### 16.1 决策记录
| 维度 | 决策 |
|---|---|
| 原型框架 | 维持 HTML 自包含 + 强化 `data-testid` 契约（守 v0.3 零依赖/可离线） |
| E2E 挂载 | 独立 `e2e` skill（17→18；可选 overlay，不进核心状态机） |
| `data-testid` 规范 | 搬 gtmc 命名；选择器优先级统一 spoko；元素级仅关键锚点 |
| 覆盖率门禁 | 分级：原型期放宽 / 集成期严格照搬 gtmc |
| AC 提取 | 门禁按维度条件触发 + 关键字回退（解除"可选→强制"陷阱） |
| 验收证据归属 | `release-archivist`（非 `ce-proof`；`ce-proof` 是 Proof 编辑器） |

### 16.2 背景与缺口
- 现有测试纪律：`build-executor` 的 TDD Iron Law + SDD + review gate + 8 态状态机；`spec.md` 的 `#### Scenario:` 是"可测行为"源，但仅作 spec 内容校验，**未自动执行为 Playwright**。
- 核心缺口：**spec 场景 / 验收标准 → 可执行 E2E (Playwright) 的桥接未自动化**。gtmc 的 `acceptance-test` + `test-verifier` 是此桥接的完整参考实现（AC 驱动黑盒 + 机械覆盖率 + Playwright 生成）。

### 16.3 核心约束
- **零依赖/可离线**：`data-testid` 为纯 HTML 属性，不引入 JS/CSS/构建/Playwright；Playwright 仅进**用户项目**，不进插件。
- **通用不固化框架**：E2E 靠 `data-testid` 契约跨框架复用，不假设 Vue/React。

### 16.4 data-testid 契约
- **命名层级**：场景级 `S-{nn}-{slug}`、页面级 `P-{xx}-{slug}`、元素级 `{语义名}`（如 `create-btn`）。
- **选择器优先级**：`getByRole` > `data-testid` > `id` > `getByLabel` > CSS/XPath（禁用于新测试）；`data-testid` 仅用于动态/hydration 边界；禁止 `waitForTimeout`。
- **打标纪律**：场景/页面级必带；元素级仅**关键交互锚点**（提交、主操作、状态切换）带，内部优先 `getByRole`/`getByText`（避免过度打标）。
- **可选开启**：项目 config `prototype.e2e: true` 时强制；避免无测试需求项目被迫加 testid。
- **契约治理**：`execution-contract.md` 记录 UI 契约；提供 testid checker 比对原型与实际代码两侧 testid 集合，漂移即报警。

### 16.5 spec → Playwright 映射
- **提取源**：`#### Scenario:`（→ HP）/ 可选 `##### Exception:`（→ EX）/ `##### State:`（→ ST）/ `##### Boundary:`（→ BND）。
- **解除"可选→强制"陷阱**：① 维度条件触发——仅含某维度标签才考核该维度，未含标 `N/A` 不阻断；② 关键字回退——未打标签时从 Scenario 文本提取 error/invalid/fail/边界 等作 EX/ST/BND 来源。二者至少取一，保向后兼容。
- **AC 公式**：`Total = HP×1 + EX×2 + ST×2 + BND×1`（ST-invalid 若已被 EX 覆盖则去重）。
- **阶段映射**（不用 gtmc 编号）：bridging/prototype（验证可执行性）→ executing（集成）→ closing（验收，release-archivist gate）。

### 16.6 门禁分级
| 指标 | 原型期（验证可执行性，静态 mock） | 集成期（实际代码） |
|---|---|---|
| AC 覆盖率 | ≥ 80%（HP 必测） | ≥ 95% |
| 异常 EX | 有则测、无则带说明（不阻断） | ≥ 80% |
| 状态 ST | 有则测、无则带说明（不阻断） | ≥ 90% |
| 边界 BND | 有则测、无则带说明（不阻断） | ≥ 75% |
| 阻断级别 | AC<80% = BLOCKER | AC/EX<门槛 = BLOCKER；ST/BND = WARNING |

门禁随被测体成熟度**单调递增**；原型 mock 结构性做不到 EX/ST 全覆盖，强行照搬会产出虚假 BLOCKER。

### 16.7 e2e skill 设计
- frontmatter：`name: e2e` / `user-invocable: true` / 用法 `/e2e [原型|集成|验收] [spec路径]`。
- **执行流程（5 步）**：① 确定测试类型；② AC 提取与分类生成矩阵（总测试数 ≥ AC×1.5）；③ 调用 `test-verifier` 生成脚本；④ 执行与报告（AC 覆盖率/四维/类型分布/未覆盖/根因）；⑤ 覆盖率审计（分级门槛判定 BLOCKER/WARNING）。
- **落盘位置（统一 `e2e/`，不放 `prototype/`）**：`playwright.config.ts` 的 `projects`（baseURL）切被测体——`prototype` project → http-server 托管 HTML；`integration` project → 真实应用。脚本一致，**仅切地址 + 少量选择器/断言适配**（高重叠复用，非零触碰；原型绿 ≠ 集成绿）。

### 16.8 test-verifier 执行层（MVP 子集）
- **保留**：AC 深度分析（4 类提取 + 分级门禁）、选择器纪律、E2E 决策矩阵（轻量）、执行与报告。
- **移交 `release-archivist`**：4 级制品验证（L1 存在→L4 数据流；设计→实现追溯）。
- **DEFER / 归 `prototype-reviewer`**：8 维健康评分、每页 7 点视觉走查（需 axe/Lighthouse，不匹配自包含原型 MVP）。

### 16.9 对现有 skill 影响面
| Skill | 改动 |
|---|---|
| `prototype` | 补 `data-testid` 产出（场景/页面级必带 + 关键锚点；config 可选开启；零依赖声明） |
| `build-executor` | 不改（TDD 管单测；E2E 独立） |
| `ce-proof` | 不改（Proof 编辑器，与验证无关） |
| `release-archivist` | 接入 e2e 报告 + 4 级制品比对（closing 验收 gate）；**v0.5 增加 prototype-sync 调用 + 复利晋升** |
| `architecture-design` | API/DB 设计文档供制品比对使用 |
| `spec-writer` | specs 规则补可选子标签说明；补回归用例；**v0.5 增加读取全局 prototype/** |
| `design-system`（=模板/项目 design-system.md，**非 skill**） | 不在 9 段视觉 schema 加测试段；testid 契约只置 `execution-contract.md` |

### 16.10 实施状态（v0.4）
- ✅ 新建 `skills/e2e/SKILL.md` + `skills/e2e/references/test-verifier.md`
- ✅ 改 `prototype/SKILL.md`（data-testid 契约段）
- ✅ 改 `spec-writer/SKILL.md`（可选子标签 + 回归用例）
- ✅ 改 `release-archivist/SKILL.md`（接入 e2e + 4 级制品比对）
- ✅ `plugin.json` "17 skills" → "18 skills"
- ⏳ 待用户在 Claude Code 跑 `npm test` / `npm run validate` 验证插件不因新增 skill 破损

---

## 十七、产品级工作流编排（v0.5 新增）

### 17.1 编排层定位

| 层级 | 编排器 | 管辖范围 |
|------|--------|---------|
| 产品级 | **workflow-orchestrator**（v0.5 新增） | ce-brainstorm → 原型内循环 → ce-plan → 拆 change → 分发 |
| 变更级 | workflow-start（不变） | exploring → ... → closing（8 态状态机） |

**分层原则**：workflow-orchestrator 管"做什么、什么顺序"（产品级策略），workflow-start 管"怎么做"（变更级执行）。二者通过 change 目录 + `.spec-superflow.yaml` 衔接，orchestrator 创建 change，workflow-start 执行 change。

### 17.2 workflow-orchestrator 职责

```
S1 需求接收
  - 接收模糊需求
  - 判断路径：需要头脑风暴？直接计划？需要原型？
  - 复利注入：读取 docs/solutions/INDEX.md，注入 prd/cross-phase 经验

S2 PRD 阶段（含原型内循环）
  - 调用 ce-brainstorm 产出 PRD 草稿
  - 执行原型内循环（§15.2）
  - PRD + 原型冻结
  - 复利捕获：检测可复利时刻

S3 计划阶段
  - 调用 ce-plan 产出 plan(vN)
  - ce-plan 聚焦：change 拆分方案 + 依赖 + 技术方向
  - 复利注入：读取 plan/cross-phase 经验
  - 复利捕获：检测可复利时刻

S4 拆分与分发
  - 按 plan 中的 change 拆分方案，创建各 change 目录
  - 每 change 初始化 .spec-superflow.yaml
  - 记录 change 间依赖和优先级
  - 各 change 进入 spec-superflow（workflow-start）

S5 全局监控（可选）
  - 跟踪各 change 进度（通过 .spec-superflow.yaml 状态）
  - 检测跨 change 一致性（共享聚合/实体/API 的变更冲突）
  - 复利晋升：change closing 时检查经验晋升
```

### 17.3 与 workflow-start 的边界

```
workflow-orchestrator（产品级）
  │
  │  S4 分发：创建 change 目录 + .spec-superflow.yaml
  │
  ▼
workflow-start（变更级）
  │
  │  8 态状态机流转
  │
  ▼
release-archivist（closing）
  │
  │  复利回写（arch-merge → prototype-sync）
  │  复利晋升（solutions-promote）
  │
  ▼
workflow-orchestrator 收到 change 完成通知（通过状态文件检测）
```

### 17.4 ce-plan 职责收窄（v0.5 修正）

| v0.3 ce-plan | v0.5 ce-plan |
|-------------|-------------|
| Implementation Units 细到文件级 | **change 拆分方案**（每 change 的 scope + 依赖） |
| 每 unit 含 Files/Approach/Test scenarios | **change 间依赖图**（DAG） |
| 一人公司模式含完整技术设计 | **整体技术方向**（技术选型、架构策略，不含文件级细节） |
| 与 spec-writer 高度重叠 | **明确分工**：ce-plan 定"做什么、什么顺序"，spec-writer 定"怎么做" |

ce-plan 产出 plan.md 的核心章节：
```markdown
## Change 拆分方案
| change | scope | 依赖 | 优先级 | 预估复杂度 |
## 技术方向（一人公司模式）
## 风险与依赖
## 验收策略
```

**不再产出**：Implementation Units、Files 列表、Test scenarios（这些归 spec-writer）。

### 17.5 skill 定义

```yaml
---
name: workflow-orchestrator
description: 产品级工作流编排器。编排 ce-brainstorm→原型内循环→ce-plan→拆change→分发到 spec-superflow。当用户提出模糊需求、需要从头开始产品级流程时使用。不替代 workflow-start（变更级），而是其上游编排层。
---
```

---

## 十八、复利贯穿机制（v0.5 新增）

### 18.1 设计原则

1. **复利不是事后补记，是流程内嵌机制**——每个阶段转换点自动检测。
2. **上下文可控**——三层索引，最坏 ~6.5k token。
3. **阶段感知**——只注入与当前阶段+领域相关的经验。
4. **主动捕获**——不依赖用户手动调用，流程自动检测可复利时刻。
5. **晋升机制**——change 内经验经验证后晋升为产品级经验。
6. **不阻断流程**——所有复利操作为 advisory 级，不阻断状态转换。

### 18.2 三层索引架构

```
docs/solutions/
├── INDEX.md                  # L1：轻量索引（≤150行，每轮可加载，~2k token）
├── prd/                      # 按阶段分目录
│   ├── 2026-07-15-需求歧义导致原型返工.md
│   └── ...
├── plan/
├── prototype/
├── spec/
├── build/
├── review/
└── cross-phase/              # 跨阶段通用经验
```

**三层加载策略**：

| 层级 | 内容 | 加载时机 | 上下文占用 |
|------|------|---------|-----------|
| **L1 索引** | INDEX.md：每条经验一行摘要 + 标签（phase/domain/type/severity） | 每次流程启动时加载 | ≤150 行，约 2k token |
| **L2 阶段过滤** | 从 INDEX 按当前阶段 + 领域过滤，取 top-5 | 进入每个阶段时 | ≤5 条摘要，约 1k token |
| **L3 按需全文** | 读取具体经验文件 | 发现高度相关时按需读取 | 单文件 ≤100 行 |

**INDEX.md 格式**：
```markdown
# Solutions Index
<!-- 每条一行，按 severity 降序，≤150 行硬上限 -->
| date | phase | domain | type | severity | summary | file |
|------|-------|--------|------|----------|---------|------|
| 2026-07-15 | prd | auth | pitfall | high | 需求歧义导致原型返工，PRD须含状态流转图 | prd/2026-07-15-需求歧义.md |
```

**经验文件 frontmatter**：
```yaml
---
phase: prd          # 阶段标签
domain: auth        # 领域标签
type: pitfall       # pitfall | pattern | decision | insight
severity: high      # high | medium | low
date: 2026-07-15
source: change-id   # 来源 change（晋升时保留）
---
```

### 18.3 阶段感知注入

每个阶段启动时自动执行：
1. 读取 `docs/solutions/INDEX.md`（L1）
2. 过滤条件：`phase = 当前阶段 OR phase = cross-phase`，且 `domain` 与当前 PRD/change 的领域标签匹配
3. 取 top-5（按 severity 降序）
4. 仅注入摘要（L2），不加载全文
5. 发现高度相关条目 → 按需读取全文（L3）

**各阶段注入点**：

| 阶段 | 注入时机 | 过滤条件 |
|------|---------|---------|
| ce-brainstorm | Phase 1.1 Existing Context Scan | phase=prd, cross-phase |
| ce-plan | Phase 1.1 Local Research | phase=plan, cross-phase |
| prototype（内循环） | 原型设计开始前 | phase=prototype, prd |
| spec-writer | 生成制品前 | phase=spec, cross-phase |
| build-executor | 每个 wave 开始前 | phase=build, spec |
| code-reviewer | 审查开始前 | phase=review, build |
| release-archivist | 归档前 | phase=cross-phase |

### 18.4 主动捕获：可复利时刻

在阶段转换点自动检测，不阻塞流程：

| 可复利时刻 | 触发条件 | 捕获内容 |
|-----------|---------|---------|
| 需求矛盾 | 原型审查发现 PRD 遗漏/矛盾 | PRD 阶段应检查的维度 |
| 设计返工 | spec/design 被拒绝或大幅修改 | 返工原因 + 预防措施 |
| 重复缺陷 | bug-investigator 发现同类问题第 2 次 | 根因模式 + 预防检查项 |
| 范围蔓延 | change 执行中超出原始 scope | scope 边界判断经验 |
| 契约漂移 | re-bridge 触发 | 契约一致性维护经验 |
| 阶段回退 | 任何 mandatory rewind | 回退原因 + 前序阶段拦截方法 |

**捕获机制**：阶段退出时执行轻量复盘（≤30秒，不阻塞流程）：
- 本阶段是否触发回退/返工/重复问题？
- 是 → 生成经验草稿（phase + domain + type + 一句话摘要）→ 调用 `ssf solutions capture` 写入 INDEX.md + 对应目录
- 否 → 跳过，不产生噪音

### 18.5 晋升机制

| 维度 | change 内经验 | 产品级经验 |
|------|-------------|-----------|
| 存储位置 | `specs/<cap>/learnings.md` | `docs/solutions/` |
| 触发时机 | 阶段转换点自动检测 | release-archivist 归档时 |
| 晋升条件 | severity ≥ medium 且 type = pitfall/pattern，且与全局 INDEX 无重复 | — |
| 重复检测 | domain + type 匹配已有条目 → 标记"已确认模式"，severity 升级 | — |

**晋升流程**（release-archivist closing 时）：
1. 读取 `specs/<cap>/learnings.md`
2. 逐条检查晋升条件
3. 符合条件 → 调用 `ssf solutions promote <change-dir>` 写入全局 `docs/solutions/`
4. 与已有条目重复 → 更新已有条目的 severity 和确认次数
5. 输出晋升报告

### 18.6 上下文占用控制

| 场景 | 占用 | 控制手段 |
|------|------|---------|
| 流程启动 | ~2k token | INDEX.md ≤150 行硬上限 |
| 阶段进入 | ~1k token | top-5 过滤 |
| 按需全文 | ~1k token/篇 | 单文件 ≤100 行，最多 2 篇 |
| 阶段退出复盘 | ~500 token | 仅检测，不展开 |
| **最坏情况** | **~6.5k token** | 索引 + 摘要 + 全文 + 复盘 |

**INDEX.md 膨胀控制**：超过 150 行时，按 severity 降序保留前 150 条，淘汰 low severity 且 date 最早的条目。淘汰的条目文件保留在对应目录，仅从 INDEX 中移除。

### 18.7 与现有 ce-compound 的关系

ce-compound 从"手动触发的记录工具"升级为"复利贯穿引擎的执行层"：

| 现有 ce-compound | v0.5 升级 |
|-----------------|----------|
| 手动调用 `/ce-compound` | 阶段转换点自动检测 + 手动补充 |
| 写入 `docs/solutions/` 无索引 | 写入 INDEX.md + 分阶段目录 |
| 无阶段感知 | 按 phase/domain 标签过滤注入 |
| 无晋升机制 | change→product 晋升规则 |
| 全量加载 | 三层索引按需加载 |

### 18.8 脚本支持

| 脚本 | 职责 | CLI 命令 |
|------|------|---------|
| `solutions-index-gen` | 扫描 `docs/solutions/*/` 重建 INDEX.md（防索引漂移） | `ssf solutions index-gen` |
| `solutions-inject` | 按 phase+domain 过滤 INDEX.md，输出 top-5 摘要 | `ssf solutions inject --phase <p> --domain <d>` |
| `solutions-capture` | 写入一条经验到 INDEX.md + 对应目录 | `ssf solutions capture --phase <p> --domain <d> --type <t> --severity <s> --summary <text>` |
| `solutions-promote` | 检查晋升条件，执行 change→product 晋升 | `ssf solutions promote <change-dir>` |

---

## 十九、决策落实状态
1. **全局文档组织**：✅ 已定——起步即按 bounded context 分目录（第八节）。
2. **落地节奏**：✅ 已定——初期即全量铺开（第十四节）。
3. **技术锚点定性**：✅ 已定——瘦锚点、与 STRATEGY.md 分离补位；设计影响与高质量可拓展保障见 6.1。
4. **注册 skill**：✅ 已注册——`architecture-design`（id `7484551995606787`），用 ima_skill_create 注册完成。
5. **原型设计能力（v0.3 新增，v0.5 修正）**：
   - 原型内核选型（本地 HTML 原型 skill，零外部依赖）：✅ 已认可（第 13–15 轮）。
   - 配置驱动原则（插件通用 + 项目 config 注入 PRD 模板/设计系统）：✅ 已认可。
   - 产物层级模型（全局 PRD 有版本 / 原型·代码各一份 git 分支隔离 / 变更层一份 PRD 拆多 change）：✅ 已确认（第 16 轮 LT "符合"）。
   - **原型定位修正（v0.5）**：原型从"PRD 后独立阶段"改为"PRD 内循环验证手段"：✅ 已确认。
   - **制品链真相来源 + 冻结机制（v0.5）**：PRD + 原型一起冻结，后续不可回改：✅ 已确认。
   - 并入 v0.3 原型章 + 起草→评审→决策→建插件流程：✅ 已授权（第 16 轮决策点 4、5）。
   - 插件名已定：**team-flow**（v0.3 定稿后 LT 拍板）；compound 范围已定：**核心子集**（非全量 33）。
6. **产品级工作流编排（v0.5 新增）**：
   - 产品级编排层（workflow-orchestrator）：✅ 已确认。
   - ce-plan 聚焦产品级策略（change 拆分+依赖+技术方向）：✅ 已确认。
   - 与 workflow-start 分层协作（orchestrator 管产品级，workflow-start 管变更级）：✅ 已确认。
7. **复利贯穿机制（v0.5 新增）**：
   - 三层索引架构（INDEX.md + 分阶段目录 + 按需全文）：✅ 已确认。
   - 阶段感知注入（进入每阶段自动加载相关经验）：✅ 已确认。
   - 主动捕获（可复利时刻检测）：✅ 已确认。
   - 晋升机制（change→product）：✅ 已确认。
   - 上下文占用控制（最坏 ~6.5k token）：✅ 已确认。
   - 复利操作 advisory 级不阻断流程：✅ 已确认。

---

*v0.3 由 copilot(阿通) 基于 architecture-design skill + 四方专家会审（v0.2）+ 第 13–16 轮原型调研，全量修订；v0.5 由 CC 基于 LT 第 17 轮核对（实现 vs 设计缺口分析）+ 四项核心修订（原型内循环 + 产品级编排 + ce-plan 收窄 + 复利贯穿），全量修订。*