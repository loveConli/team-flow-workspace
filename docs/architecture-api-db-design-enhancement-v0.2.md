# 架构 / API / DB 设计增强方案 · v0.2（全量修订版）

> 版本：v0.2 · 全量修订
> 底座：**architecture-design skill**（book-to-skill 蒸馏自 LT 知识库 4A/DDD 培训材料，含 F1–F8 框架）
> 修订依据：四方专家会审（DDD/4A 架构、spec-superflow 机制、compound-engineering 复利、知识管理/第二大脑）全部意见已吸收
> 相较 v0.1 的关键修正：As-Is 冻结防漂移、术语正名（4A 四域/架构域）、Discoverability 正名+架构一致性检查、原型合规回写路径、guard 软集成、全局文档分目录组织、SOP 化（LLM 块+脚本）、第二大脑整合。

---

## 一、设计目标（用户原话落地）
1. 架构设计：每需求做"增强"——对**当前现状 + 需求对应架构变更**做设计；**复利环节回写全局架构设计**。
2. DB 设计：与架构**同样模式**（每变更增量 + 复利回写全局）。
3. API 设计：主要在**每变更需求内**设计（不进全局层）。
4. 架构方法：**DDD**（领域驱动设计）。
5. 借鉴 compound-engineering（复利工程）可补充本块的好经验。

## 二、方法论底座（architecture-design skill）
- **F1 4A 分叉依赖**：`BA→(IA∥AA)→TA`，BA 先行、IA/AA 并行双向对齐、TA 最后。
- **F2 跨域一致性**：AA 功能≥1 IA 实体支撑，IA 实体≥1 AA 功能消费；结构+语义双对齐（发布门禁）。
- **F3 变更分叉级联**：直接/间接/隐式三层次必覆盖。
- **F4 DDD 聚合四要素**：实体+值对象+聚合根+事务边界；仅业务服务有聚合。
- **F5 限界上下文/Context Map**：语义边界=L3 应用服务；映射 Shared Kernel/ACL/OHS。
- **F6 CQRS 写读模型**：事务型→写模型，分析型→读模型；Command/Read→写模型，Query 经阻断测试分流。
- **F7 三维判定**：失忆(归属)+阻断(类型)+孤岛(层级)。
- **F8 增量设计+复利回写闭环**：As-Is 冻结+版本锚点 → To-Be → 全局锚点复利。

## 三、总体闭环（SOP 步骤）
```
模糊需求
 └─[ce-brainstorm→ce-plan 就地 enrich]→ proposal.md/PRD (requirements-only → implementation-ready)
       │  注：演进是 ce-brainstorm→ce-plan 的"就地 enrich"，PRD 完备态在 enrich 之后
       ▼
spec-superflow: exploring→specifying→bridging→approved-for-build→executing→closing
  每变更 specs/<cap>/ 内：
   ①(LLM) 读全局 ARCHITECTURE.md grounding → 活动对象矩阵识别聚合/上下文
   ②(LLM) To-Be: 聚合+Context Map+CQRS+4A 跨域对齐
   ③【As-Is 冻结】复制全局相关章节当前原文 + 版本锚点(ARCHITECTURE.md@<change_id>#<章节>)，变更内不可变
   ④(脚本) 填 frontmatter + advisory 校验
   ⑤(LLM) 写 ADR；api.md 标 Command/Read/Query + 阻断测试归属
   ⑥(脚本) 回写全局 + 生成 API-INDEX
       ▼
[复利环节 · 独立 arch-compound skill/overlay，不进状态机硬矩阵]
   把每变更 architecture.md/database.md 的 delta 合并进 docs/architecture/ARCHITECTURE.md + DATABASE.md
       ▼
全局作为下一 change 的 grounding → 闭环
```
**原型验证→回写 PRD（合规路径）**：原型结论以 `handoff --type prototype` 承载，人工评审后作为**新 requirement delta** 走正常 `specifying→contract→closing→spec-merger` 闭环；**design.md 保持不可变**（遵守 spec-superflow 原型覆盖层规则：never mutate design.md/tasks.md）。

## 四、产物结构（全量）
```
项目根/
├── STRATEGY.md              # 产品/BA 锚点（compound，不动）
├── CONCEPTS.md              # 领域词汇（追加 DDD 术语，复利累积）
├── AGENTS.md                # 追加一节暴露 docs/architecture/（Discoverability）
├── docs/architecture/       # 【技术锚点层，独立于 STRATEGY.md，起步即按 bounded context 分目录】
│   ├── ARCHITECTURE.md      # 瘦锚点总览：Context Map + 各 bc 链接 + 关键决策（覆盖式当前态）
│   ├── DATABASE.md          # 全局 DB 总览（实体+读写模型+OLTP/OLAP，覆盖式）
│   ├── <bc>/                # 每个限界上下文一目录（天然扩展点）
│   │   ├── context.md       # 该 bc 的聚合/实体/服务/读写模型/事务边界
│   │   └── evolution.md     # 该 bc 演进日志（append-only，含 change_id+来源）
│   └── API-INDEX.md         # 脚本生成（扫描所有 specs/*/api.md），非手写
├── specs/<cap>/
│   ├── spec.md / design.md / tasks.md / execution-contract.md   # spec-superflow 原产物
│   ├── architecture.md      # 【每变更 DDD 增量】
│   ├── database.md          # 【每变更 DB 增量】
│   └── api.md               # 【每变更 API 设计】
```
> **归属说明**：`specs/<cap>/` 三层增量是 spec-superflow 内核的**推荐扩展**（软提示、非阻断）；`docs/architecture/` 是 compound 侧产物层，spec-superflow 仅以可选 overlay 感知。二者通过"复利回写"连接，不混进 spec-superflow 状态机硬矩阵。

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

## 七、复利回写机制（借 ce-compound，已正名）
1. **结构化 frontmatter（原则借鉴）**：架构专用 schema（cap_id/date/change_type/bounded_contexts/aggregates/cqrs），非直接复用 schema.yaml（那是 learnings 专用）。
2. **one change per run**：一次回写一个变更 delta（变更可追溯、不混杂多变更）。
3. **双视图回写**：当前态覆盖 + 演进日志追加。
4. **架构一致性/漂移检查（独立机制，非 Discoverability）**：①结构冲突（重复 BC/聚合 key）②语义冲突（同义异名，如客户vs用户，按命名注册表）③跨域一致性门禁（AA≥1 IA 实体，反之亦然）。
5. **Discoverability 正名（compound 原义）**：在 AGENTS.md/CLAUDE.md 暴露 `docs/architecture/`（存在/结构/何时检索），使代理设计前"发现并查阅"；仅在未暴露时追加一节。
6. **下游检索复用**：下一 change 设计前从 `docs/architecture/` 检索相关上下文/聚合，grounding 用 CONCEPTS.md（已含 DDD 术语）。

## 八、全局文档组织（已定：起步即分目录）
用户决策：**起步即按 bounded context 分目录** `docs/architecture/<bc>/`（非单文件分节）。这是 compound `problem_type→directory` 的真类比，也是高质量可拓展基础——每新增限界上下文=新增目录，不膨胀单文件，检索粒度与一致性检查随规模线性可控。结构见第四节与第六节。

## 九、compound-engineering 经验借鉴（修正后清单）
| # | 经验 | 本方案映射（修正） |
|---|---|---|
| 1 | 全局锚点（STRATEGY.md, Anchor not plan） | → `docs/architecture/` 作**技术架构单一事实源**；业务策略(BA/STRATEGY.md)与技术架构(IA/AA/TA)是两份独立文档、互相链接不混写——填补 compound 无技术架构产物的缺位（非"修正其错误"）；ARCHITECTURE.md 是**瘦锚点**(短稳 what&why)，非评审交付巨著 |
| 2 | 结构化复利回写 | → 架构专用 frontmatter + 双视图回写（原则借鉴，非套用 schema.yaml） |
| 3 | requirements-only→implementation-ready | → **ce-brainstorm→ce-plan 就地 enrich** 演进（PRD 完备态在 enrich 后） |
| 4 | one learning per run + 并行 | → 一次一变更 delta 回写 |
| 5 | pulse 大环 | → （增强项）架构健康度脉冲，后续 |

## 十、与 spec-superflow 集成（软集成，保全零依赖）
- **状态机**：8 态不变；三份增量文档为**推荐产出、软提示、非阻断**（复用 `config.artifacts.skip`，不改 core guard）。
- **guard 扩展**：frontmatter 校验降级为**独立 advisory 脚本**（正则提取 key，warning 级，**不引第三方 YAML 依赖**）；全局回写经独立 `arch-compound` skill/overlay，**不进状态机硬矩阵**。
- **原型合规**：design.md 不可变；原型结论走 `handoff --type prototype` → 新 delta → 正常闭环。
- **术语正名**：IA/AA 非"技术架构"（仅 TA 是）；4A 是四域非三层；全局回写≠spec-merger（后者只合并 delta spec 进 main spec base，触发于 closing）。

## 十一、SOP 化（LLM 块 + 明确脚本）
- **LLM 负责（人守深度思考）**：限界上下文/聚合识别、Context Map 关系选型、4A 跨域对齐推理、CQRS 划分、API 指令映射、ADR 理由、架构一致性语义判定。
- **明确脚本（零/低 LLM）**：
  - `validate-frontmatter`：校验三份增量 frontmatter 字段完整性（advisory）。
  - `arch-merge`：delta 以 append + 版本锚点合入全局，one change per run。
  - `discovery-check`：扫描重复/冲突 BC/聚合（机械查重；语义冲突归 LLM）。
  - `api-index-gen`：扫描所有 `specs/*/api.md` 生成 `API-INDEX.md`。
  - `asis-extract`：按版本锚点从全局抽取相关章节填入增量 As-Is（防漂移）。

## 十二、第二大脑整合（ima「LT的知识库」）
- **方法层(kb)**：存 `architecture-design` skill + 每限界上下文一个 `architecture-anchor` 资产（frontmatter: tags/bounded_contexts/aggregates 作索引键）。
- **项目层(repo)**：`docs/architecture/` 为权威源。设计前检索 kb skill + 读全局 ARCHITECTURE.md 作 grounding；回写后**批量**同步 Context Map 索引入 kb（避免每 delta 双写）。
- **人机协同闸点**：每变更设计末尾设 human gate——ADR 批准 + Context Map 关系确认（LLM 出 draft，人守深度思考）。

---

## 十三、四方专家会审结论摘要（已吸收）
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
- `docs/architecture/` **分目录**建好（ARCHITECTURE.md 总览 + DATABASE.md + 每个已知 bc 的 `<bc>/context.md`+`<bc>/evolution.md`）。
- `specs/<cap>/` 三份增量（architecture/database/api）全量启用。
- 4 脚本落地：`validate-frontmatter` / `arch-merge` / `discovery-check` / `api-index-gen`（+ `asis-extract`）。
- `AGENTS.md` 暴露 `docs/architecture/`（Discoverability）。

**分期参考（能力启用节奏，非强制缓步）**：
- MVP-0 方法论+脚本底座 → 已随全量一并建立。
- MVP-1 架构单轨 / MVP-2 加 DB / MVP-3 加 API 索引 → 全量初期即启用，非按需后加。
- MVP-4 硬化 → `discovery-check` 语义规则随语料增长持续硬化（分目录已就绪，无需后期重构）。

---

## 十五、决策落实状态
1. **全局文档组织**：✅ 已定——起步即按 bounded context 分目录（第八节）。
2. **落地节奏**：✅ 已定——初期即全量铺开（第十四节）。
3. **技术锚点定性**：✅ 已定——瘦锚点、与 STRATEGY.md 分离补位；设计影响与高质量可拓展保障见 6.1。
4. **注册 skill**：✅ 已注册——`architecture-design`（id `7484551995606787`），用 ima_skill_create 注册完成。

---
*由 copilot(阿通) 基于 architecture-design skill + 四方专家会审，全量修订为 v0.2；MVP 章节见第十四节。*
