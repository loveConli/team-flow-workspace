# 架构 / API / DB 设计增强方案 · v0.8（subagent 编排下沉 + 状态治理 + PRD/Plan 规范修复）

> 版本：v0.8 · 重大修订（增量式，承袭 v0.7）
> 目标插件版本：**v0.15.0**（专题版「subagent 编排 + 状态治理」）
> 修订依据：v0.7 全量内容**继续有效**；v0.8 仅记录 v0.15.0 增量修订。
> 触发来源：LT 跑通一轮真实需求（Session `29d058e5-30b5-45bd-981d-bb6513d3bfbf`，VRM 管理驾驶舱）后的实证复盘 + 第 20 轮设计讨论。
>
> **v0.8 修订摘要（相较 v0.7）**：
> - **横展主线**：新增 §18.1「subagent 结构化交接协议」——主代理只编排、执行下沉子代理；阻断/非阻断疑问统一用返回结构表达（不依赖 agent team，保跨平台健壮性）。修订 §17.8。
> - **状态模型重构**：`.workflow-orchestrator.yaml` 从「单需求单文件」升级为「每需求一份 + 注册表索引」，支持多需求并行。修订 §17.9.1。
> - **状态文件治理**：所有状态文件收敛到 `.team-flow/` 目录（P1-6 第一阶段，仅状态文件；npm 包名/CLI/npx 全量重命名仍按 v1.0.0）。
> - **workflow-bootstrap**：B1 侦察改为并行子代理 + 确定性脚本（`ssf recon`），可复现可横展对比。
> - **ce-brainstorm**：新增 `prd-completeness-reviewer` 子代理（PRD 完整性评审）；修复冻结措辞 BUG（`frozen_downstream` 误写为升版语义）；新增 PRD 版本格式规范。
> - **prototype**：SKILL.md 重构为「内部编排器」，绘制/探查/评审下沉子代理（新增 `prototype-builder`、`design-system-architect` 子代理），主代理只编排；新增设计系统生命周期。
> - **ce-plan**：模式强制询问（pipeline 下由 orchestrator 问定后显式传参）；一人公司模式收窄到「高阶设计」（删接口清单）；钉死产品级/变更级作用边界。
> - 第二十章决策落实状态补 v0.8 决策。
> - **v0.16.0 增量（2026-07-25 追加）**：新增 §21「会话交接 + 工作流反馈」——`session-handoff`（上下文腐化时压缩会话为交接文档）+ `workflow-feedback`（工作流使用问题结构化记录）。LT 确认四项决策（保存位置 `.team-flow/`、feedback git 跟踪、允许模型建议触发、目标版本 v0.16.0）。

---

## 十八、v0.15.0 增量设计

### 18.0 修订背景（会话实证）

LT 在 VRM 项目跑通完整一轮（bootstrap → orchestrator S1-S4 → brainstorm → prototype → plan），动作时间线还原暴露的系统性问题：

| 阶段 | 实证现象 | 根因归类 |
|------|---------|---------|
| bootstrap B1 | 主代理直跑 ~12 条 ad-hoc Bash 侦察 | 缺子代理下沉 + 缺确定性脚本 |
| orchestrator S1 | `.workflow-orchestrator.yaml` 落在项目根目录 | 状态文件未治理 |
| brainstorm S2 | PRD 写完无完整性评审，仅 claim verifier | 缺 PRD 完整性评审子代理 |
| prototype S2 | 主代理亲自 Write + Edit index.html 16 次 | 主代理既编排又实施 |
| plan S3 | `mode: 一人公司模式` 自行假设；plan.md 含「接口清单」 | 模式未问 + 越界做变更级设计 |
| PRD 冻结 | 措辞写「升版 v2」 | `frozen_downstream`/`frozen_absolute` 混淆（BUG） |
| 状态结构 | yaml 单需求结构 | 无多需求并行设计 |

**贯穿主线**：除头脑风暴（需多轮人机交互）外，执行步骤普遍未下沉子代理，主代理上下文被实施细节占满。本版以「主代理瘦身 + 执行下沉 + 状态规范化」为专题。

### 18.1 subagent 结构化交接协议（横展主线，修订 §17.8）

> **设计原则（承 §17.8）**：编排层只负责编排（状态判断、路由决策、阶段转换、用户确认），执行委托 subagent。**硬约束**：Claude Code subagent 在独立上下文运行，**不能调用 AskUserQuestion**。

**18.1.1 交互疑问的工程化表达**

LT 原则：「子代理有疑问——无阻断则继续，完成后将遗留问题返回主代理；有阻断则马上反馈主代理。」因 subagent 不能 AskUserQuestion，「马上反馈」的工程实现 = subagent 提前结束并以结构化返回 `status: blocked`，由主代理裁决。统一返回契约：

```
subagent final response 结构契约（所有新/改 sub-agent 强制遵守）：
{
  status: "done" | "done_with_questions" | "blocked",
  deliverable: <产物绝对路径或内容>,
  blockers: [ { question, why_blocking, options[] } ],          # 阻断项：主代理必须裁决才能继续
  outstanding_questions: [ { question, default_assumption } ],  # 非阻断：已按默认假设继续，回主代理批量确认
  summary: <3-5 行 gist>
}
```

| 情形 | subagent 行为 | 主代理行为 |
|------|--------------|-----------|
| 无疑问 | `done` + deliverable | 接收产物，推进 |
| 非阻断疑问 | 按 `default_assumption` 继续跑完，记入 `outstanding_questions`，`done_with_questions` | 批量确认遗留项（可一次 AskUserQuestion 合并） |
| 阻断疑问 | **立即停止**，返回 `blocked` + `blockers[]`（不强行猜测） | 裁决后重启/续跑该 subagent |

**18.1.2 为何不用 agent team**

claude agent team（SendMessage 多代理常驻）交互更灵活，但**通用性/健壮性不足**：绑死 Claude Code、依赖常驻 teammate、Codex/Antigravity/Pi 等 harness 无对等原语。本协议坚持 **Task 一次性子代理 + 结构化返回**，把「阻断反馈」用返回结构而非实时消息实现，全平台可降级运行（对齐 §17.8 model-tiers 降级规则）。**结论：不引入 agent team。**

**18.1.3 会话级 skill 内部编排（A4 第 3 点落地）**

ce-brainstorm / ce-plan / prototype 因需多轮交互**永远不能变 subagent**，但其**内部非交互子步骤**应自行派发 subagent（ce-plan 已有此模式）。本版将 bootstrap、prototype 也改造为此模式（见 §18.4 / §18.6）。

### 18.2 多需求并行状态模型（修订 §17.9.1）

> **决策（LT 确认 2026-07-25）**：每需求一份状态文件 + 注册表索引。

**18.2.1 结构**

```
.team-flow/
├── registry.yaml                        # 需求注册表（索引 + 活跃指针）
└── requirements/
    ├── <req-id>/                        # 每个需求独立目录（req-id = prd 迭代主题短码）
    │   ├── orchestrator.yaml            # 该需求的产品级编排状态（原 .workflow-orchestrator.yaml）
    │   └── ...                          # 该需求其他产品级状态
```

**registry.yaml schema**：
```yaml
schema_version: 1
active_requirement: <req-id>          # 当前活跃需求（orchestrator 默认操作对象）
requirements:
  - id: <req-id>
    title: <需求标题>
    prd_version: v1
    phase: S3                          # 冗余快照，真相源仍是各 orchestrator.yaml
    orchestrator_state: .team-flow/requirements/<req-id>/orchestrator.yaml
    created_at: "..."
    updated_at: "..."
```

**18.2.2 并发与单写者**

- 每个需求的 `orchestrator.yaml` 只由该需求的 orchestrator 实例单写——多需求并行时**天然隔离**，无写冲突（原「单写者」约束自动成立）。
- `registry.yaml` 只在需求创建/切换/状态快照时由 orchestrator 写，写入频率低。
- 各 change 仍只写自己的 `.team-flow/<change>/.team-flow.yaml`（变更级状态，见 §18.3）。

**18.2.3 S1 入口需求选择**

orchestrator S1 路径路由器新增「需求选择」：读 `registry.yaml`，若有多个需求则询问 LT 操作哪个（或新建）；`active_requirement` 决定后续阶段读写哪份 `orchestrator.yaml`。幂等恢复仍走「yaml + 制品存在性」双重校验。

### 18.3 状态文件治理：统一 `.team-flow/`（P1-6 第一阶段）

> **决策（LT 确认 2026-07-25）**：本版本先做**产品级**状态文件迁移；npm 包名/CLI 前缀/74 处 npx 全量重命名仍按 v1.0.0（P1-6 第二阶段）。

| 文件 | 旧位置 | 新位置 | 版本 |
|------|-------|-------|------|
| 产品级编排状态 | `<root>/.workflow-orchestrator.yaml` | `.team-flow/requirements/<req-id>/orchestrator.yaml` | **v0.15.0** |
| 需求注册表 | （无） | `.team-flow/registry.yaml` | **v0.15.0** |
| 变更级状态 | `<change>/.spec-superflow.yaml` | `<change>/.team-flow.yaml` | **P1-6 第二阶段（v1.0.0）** |

- **产品级迁移（v0.15.0 落地）**：检测旧 `<root>/.workflow-orchestrator.yaml` 存在时，自动迁移到 `.team-flow/requirements/<req-id>/orchestrator.yaml` 并登记 registry（一次性，提示用户）。orchestrator skill 全链路引用已更新。
- **变更级改名（P1-6 第二阶段，v1.0.0）**：`.spec-superflow.yaml` → `.team-flow.yaml` 与 npm 包名/CLI 前缀同批改造。**原因**：变更级状态文件由 npm `ssf` CLI（`ssf state init` 等）创建，单独改名会与现行 CLI 失配，必须与 npm 包重命名同步。v0.15.0 保持 `.spec-superflow.yaml` 不变，检测逻辑不动。
- **范围边界**：本阶段**不改** npm 包名（spec-superflow）、CLI 前缀（ssf）、SKILL.md 中的 npx 引用、变更级 `.spec-superflow.yaml`——这些属 P1-6 第二阶段（v1.0.0）。

### 18.4 workflow-bootstrap：侦察子代理 + 脚本化探查

> **决策（LT 确认 2026-07-25）**：B1 侦察下沉并行子代理；新增确定性脚本固定化代码质量探查。

**18.4.1 B1 改造为子代理编排**

主代理（bootstrap）只做编排：派发 → 汇总 → 写 baseline.md。新增 `references/agents/codebase-recon-analyst.md`（种子提示形态，按 §18.1 协议返回）。**并行派发**以下侦察子代理（按 Quick/Deep 模式裁剪）：

| 子代理任务 | Quick | Deep | 产出 |
|-----------|:---:|:---:|------|
| 技术栈识别（语言/框架/构建/DB） | ✓ | ✓ | 技术栈摘要 |
| 模块结构（分层/边界） | ✓ | ✓ | 模块树 |
| 已有架构模式（DDD/MVC/微服务） | ✓ | ✓ | 模式判断 |
| 数据模型（实体/迁移/聚合根候选） | — | ✓ | 数据模型摘要 |
| API 表面（REST/gRPC/CLI） | — | ✓ | API 清单 |
| 测试现状 + 已有文档 | ✓ | ✓ | 测试/文档摘要 |

每个子代理消费 §18.4.2 脚本的结构化输出 + 按需补读源码，按 §18.1 协议返回。主代理汇总后写 `docs/architecture/baseline.md`。

**18.4.2 确定性脚本 `ssf recon`（新增 CLI）**

固定化采集，**可复现、可横展对比**（同项目两次接入结果一致）：

```bash
ssf recon [--root <path>] [--out <json>]
# 固定采集：目录树（限深）、依赖清单（pom/package.json/requirements/go.mod）、
#          LOC 与文件类型分布、测试文件计数、DB 迁移文件清单、README/docs 探测
# 输出：结构化 JSON（供侦察子代理消费）+ 人类可读摘要
```

- 脚本只做**确定性机械采集**（§17.8 第四类载体），语义判断（架构模式/聚合根推断）仍由子代理 LLM 完成。
- 与子代理协作：脚本先跑出 JSON 基底 → 子代理在基底上做语义增强 → 主代理汇总。

### 18.5 ce-brainstorm：PRD 完整性评审 + 冻结修复 + 版本格式

**18.5.1 新增 `prd-completeness-reviewer` 子代理（2.4）**

> 与现有 Phase 2.6 `claim verifier` 分工明确：claim verifier 管「说得**对不对**」（核查事实声明），completeness reviewer 管「说得**全不全、能否落地**」。

- **形态**：插件 agent（只读，对齐 prototype-reviewer 模式：tools = Read/Bash/Grep/Glob，无 Write，报告写在 response，编排层落盘到 `prd/vN/prd-completeness-review.md`）。
- **触发**：PRD 写入后、冻结前（orchestrated 模式由 orchestrator S2 派发；standalone 模式由 ce-brainstorm Phase 3 后派发）。
- **评审维度**（按「能否支撑 plan/spec 实施」）：
  | 维度 | 检查 | 级别 |
  |------|------|------|
  | 用户故事完整性 | 每个功能是否有明确 actors/流程/结果 | Critical |
  | 验收标准 | 是否有可验证的 AC/成功信号 | Critical |
  | 边界与非功能 | 空/错/异常状态、性能/兼容约束 | Important |
  | 术语一致性 | 与 CONCEPTS.md / §6 业务术语一致 | Minor |
  | 范围闭环 | in/out scope 明确，无悬空功能 | Important |
- **判定**：对齐 prototype-reviewer 柔性判定（PASS / PASS_WITH_WARNINGS / FAIL，仅 Critical>0 触发 FAIL）。FAIL → 回 Phase 1.3 补充。

**18.5.2 冻结措辞 BUG 修复（2.5）**

> **BUG 定性**：ce-brainstorm §3.5.5 第 400 行「需升版 vN+1 走完整内循环」把 `frozen_downstream` 误写成 `frozen_absolute` 语义，违反 §17.9 feedback-loops「迭代内变更不升版」与双层冻结设计。

- **正确措辞**（写入 PRD frontmatter 之后的正文冻结声明 + ce-brainstorm §3.5.5 + PRD 模板）：
  > 本文档已冻结（`frozen_downstream`）。下游阶段（plan/spec/build）**不可直接修改**；如 plan 或实施暴露 scope 问题，经 **S3→S2 回退在 vN 内修订**并记录「决策与变更履历」（不升版）。仅当**启动新迭代 vN+1** 或**用户显式绝对冻结**（`frozen_absolute`）时，才需升版。
- **横展排查**：同步修复 ce-brainstorm SKILL.md §3.5.5、`templates/prd.md` 模板、`prd-mapping.md` 冻结段、prototype-sync 相关冻结引用。

**18.5.3 PRD 版本格式规范（2.3）**

> **BUG 定性**：生成的 PRD frontmatter `iteration_version: v1`/`frozen: true`，正文却写「产品版本 v1.0」「文档状态 编辑中」——格式不统一且状态自相矛盾。根因：`prd-mapping.md` 未定义版本格式规范。

`prd-mapping.md` 新增「版本格式规范」：
- **迭代版本**（frontmatter `iteration_version`）：`vN`（v1/v2/...），表示产品迭代。
- **文档修订次版本**（正文 §1 版本信息）：`vN.M`（v1.0/v1.1/...），vN 内修订递增 M（呼应反馈环路 vN 内修订）。
- **文档状态枚举**：`编辑中` / `已冻结-下游(frozen_downstream)` / `已冻结-绝对(frozen_absolute)`。
- **一致性硬约束**：正文文档状态**必须与 frontmatter `frozen` 字段一致**——`frozen: true` 时文档状态不得为「编辑中」。PRD 写入时自检，不一致即修正。

### 18.6 prototype：内部子代理编排 + 设计系统生命周期

> **决策（LT 确认 2026-07-25）**：prototype SKILL.md 重构为内部编排器，主代理只编排不实施；支持设计系统的设计与更新。

**18.6.1 内部编排流程（主代理只编排）**

```
prototype skill（主代理 = 编排器，严禁 Write 原型文件）
  ① 环境探查（sub: prototype-env-scout）
       → 设计系统现状/原型仓库分支/PRD 版本/已有页面，产出环境简报 + 原型方案设计
  ② 方案评审（主代理）→ 人工评审（主代理 AskUserQuestion）
  ③ 原型绘制（sub: prototype-builder）
       → 按已确认的设计系统/分支/版本绘制 prototype/（Write 权在此 agent）
  ④ 原型评审（sub: prototype-reviewer，复用，对照 PRD 6 维度）
  ⑤ 循环编排（主代理）：FAIL→回③修正（≤3轮，收敛检测）；PASS→⑥
  ⑥ 人工评审路由（主代理 AskUserQuestion）：
       → PRD 有问题 → 回 orchestrator S2 修订 PRD（vN 内修订）→ 再更新原型
       → 原型需调整 → 回 ③ 派 prototype-builder 实施
       → 通过 → 冻结
```

| 步骤 | 载体 | 写文件权 |
|------|------|---------|
| ①环境探查+方案设计 | sub `prototype-env-scout`（新增） | 仅写简报到 scratch |
| ②方案/人工评审 | 主代理 | 无 |
| ③绘制 | sub `prototype-builder`（新增，对齐 code-reviewer 反向：有 Write） | prototype/ 全部 |
| ④评审 | sub `prototype-reviewer`（复用，只读） | 无（报告写 response） |
| ⑤循环编排 | 主代理 | 落盘评审报告 |
| ⑥人工路由 | 主代理 | 无 |

- **主代理只编排不实施**：prototype skill 加载进主上下文后，主代理**禁止直接 Write/Edit 原型 HTML**，所有绘制经 prototype-builder。这是 §17.8「主代理瘦身」在 prototype 的落地。
- **新增 agent**：`prototype-builder`（绘制，有 Write，按 §18.1 协议返回，阻断如「设计系统缺失」时返回 blocked）、`prototype-env-scout`（环境探查，种子提示）。

**18.6.2 设计系统生命周期（3.2）**

```
首次创建 → 引用 → 增量更新（变更履历）
```
- **首次创建**：项目无 `design-system.md` 时，派 `design-system-architect` 子代理（新增，种子提示）按 9 段 schema + 5 方向确定性调色板产出，主代理评审 + 人工确认后落盘。
- **引用**：prototype-builder 绘制时强制读 `design-system.md` 渲染 token，禁止内联样式漂移（承现有膨胀防控）。
- **增量更新**：prototype-sync 回写时若涉及新组件/token/anti-pattern，合并进 `design-system.md` 并记**变更履历**（时间/变更内容/来源 change）。
- **设计系统也走「主代理只编排」**：architect 子代理产出，主代理不直接写 design-system.md。

### 18.7 ce-plan：模式询问 + 收窄高阶设计 + 作用边界

**18.7.1 模式强制询问（4.1）**

> **决策（LT 确认 2026-07-25）**：pipeline 下由 orchestrator 问定后显式传参；ce-plan 独立调用时永远自问。

- 删除 `planning-modes.md` 第 15 行「Auto-detect from context... default to 一人公司模式」的隐式默认。
- **standalone**：ce-plan Phase 0.2 **强制 AskUserQuestion** 选模式（业务模式 / 一人公司模式），不得静默默认。
- **pipeline**（orchestrator 调用）：orchestrator 在 S3 入口一次性问定模式，**显式传参** `plan_mode: business | solo`（对齐 B6 显式入参规约）。ce-plan 收到 `plan_mode` 即不再询问；未收到（异常）则回退到强制询问。

**18.7.2 一人公司模式收窄到高阶设计（4.2）**

> **定性**：plan.md 出现「### 4.3 接口清单」是 ce-plan **违反自身 v0.5 scope 契约**（SKILL.md 第 15 行：不产出 file-level，属 spec-writer）。根因：`planning-modes.md` 第 9/64 行「API design」表述与 scope 契约矛盾。

- `planning-modes.md` / `plan-structure.md`：一人公司模式的技术方案段从「tech stack + architecture + data model + **API design**」改为「tech stack + architecture + data model + **高阶技术设计**」。
- **删除「接口清单」段**；高阶设计仅含：模块边界、技术选型、数据流方向、关键聚合/上下文划分。
- **明确禁止**：接口签名、字段定义、请求/响应 schema 等**变更级详细设计**不进 plan.md，属各 change 的 spec-writer / architecture-design。

**18.7.3 作用边界声明（4.3）**

ce-plan SKILL.md 顶部新增「作用边界」硬声明：
> **ce-plan = 产品级策略**：change 拆分（scope+依赖+优先级+复杂度）、change 依赖 DAG、技术方向决策、风险与里程碑。
> **ce-plan ≠ 变更级详细设计**：接口清单、字段定义、方法签名、文件级 Implementation Unit 一律属各 change 的 spec-writer / architecture-design，不进 plan.md。

### 18.8 新增/改造组件清单（v0.15.0）

| 组件 | 类型 | 动作 | 优先级 |
|------|------|------|--------|
| subagent 结构化交接协议 | 设计规范（§18.1） | 新增，写进 §17.8 | 必做 |
| 多需求状态模型 + registry | state-model 重构 | 改 §17.9.1 + orchestrator | 必做 |
| `.team-flow/` 状态治理 | 横展改造 | 迁移 + 检测逻辑改造 | 必做 |
| `ssf recon` | CLI 脚本 | 新增 | 必做 |
| `codebase-recon-analyst` | bootstrap 种子代理 | 新增 | 必做 |
| `prd-completeness-reviewer` | 插件 agent（只读） | 新增 | 必做 |
| `prototype-builder` | 插件 agent（有 Write） | 新增 | 必做 |
| `prototype-env-scout` | 种子代理 | 新增 | 必做 |
| `design-system-architect` | 种子代理 | 新增 | 必做 |
| prototype SKILL.md | skill | 重构为内部编排器 | 必做 |
| ce-plan SKILL.md + planning-modes + plan-structure | skill + reference | 模式询问 + 收窄 + 边界 | 必做 |
| ce-brainstorm §3.5.5 + prd-mapping + templates/prd.md | skill + reference + 模板 | 冻结修复 + 版本格式 + 完整性评审接入 | 必做 |

---

## 二十一、v0.16.0 增量设计：会话交接 + 工作流反馈（P1-10）

> **决策（LT 确认 2026-07-25）**：新增 `session-handoff` + `workflow-feedback` 两个 skill，目标版本 v0.16.0。
> 四项决策：① 交接文档保存到 `.team-flow/handoffs/`（项目内，新会话可发现）；② 问题记录 git 跟踪（`.team-flow/feedback/`，不 gitignore）；③ session-handoff 允许模型主动建议触发（不设 `disable-model-invocation`）；④ 目标版本 v0.16.0。

### 21.0 修订背景

| 问题 | 现象 | 根因 |
|------|------|------|
| 上下文腐化 | 长时间对话后产出质量下降，重复提问、遗忘约束 | 无会话级交接机制，换会话后隐性知识丢失 |
| 工作流问题散落 | 使用中遇到的 skill 触发不准、SOP 不顺等问题只在对话中提及，无法追踪 | 无结构化问题收集端，与 ce-compound（经验沉淀端）不对称 |

**与已有机制的边界**：

| 已有机制 | 层级 | 本 skill 的关系 |
|---------|------|---------------|
| `ssf handoff`（CLI） | change 级任务委派（prototype/research/experiment） | 不冲突，`session-handoff` 是会话级，不处理 change 级任务委派 |
| `ssf checkpoint`（CLI） | change 级执行进度快照 | 不冲突，checkpoint 记录任务进度，session-handoff 记录会话上下文 |
| `.team-flow/` yaml | 产品级跨 session 状态恢复（结构化数据） | 互补，yaml 记录结构化状态，handoff 记录非结构化隐性知识 |
| §18.1 交接协议 | subagent→主代理进程内返回 | 不同层级，§18.1 是进程内，session-handoff 是跨会话 |
| ce-compound | 经验沉淀端（解决方案→docs/solutions/） | 互补，workflow-feedback 是问题发现端 |
| CLAUDE.md 待办列表 | 手动维护的问题/改进清单 | workflow-feedback 输出可直接映射为待办条目 |

### 21.1 session-handoff：会话级上下文交接

**定位**：当长时间对话导致上下文腐化（context rot）时，将当前会话的工作上下文压缩为结构化交接文档，供新会话无缝继续。核心价值 = 把"只存在于对话上下文中的隐性知识"显性化。

**Frontmatter**：
```yaml
---
name: session-handoff
description: >
  将当前会话的工作上下文压缩为结构化交接文档，供新会话无缝继续。
  当长时间对话导致上下文腐化、产出质量下降时使用；
  也可在切换设备、交接给其他开发者时使用。
  不适用于：change 级任务委派（用 ssf handoff）、
  产品级状态恢复（已由 .team-flow/ yaml 自动处理）、
  subagent 进程内交接（已由 §18.1 交接协议覆盖）。
argument-hint: "[下一个会话的关注点描述]"
---
```

**核心工作流**：

```
触发 → 1. 环境感知 → 2. 上下文萃取 → 3. 文档生成 → 4. 恢复指引
```

| 步骤 | 动作 | 说明 |
|------|------|------|
| 1. 环境感知 | 自动检测 `.team-flow/registry.yaml`、`orchestrator.yaml`、`.spec-superflow.yaml`、`prd/vN/` | 无状态文件时降级为通用 handoff 模式 |
| 2. 上下文萃取 | 从当前对话提取：进度摘要、关键决策（未写入产物的）、未解决问题、用户偏好、失败尝试 | 敏感信息脱敏（`${PLACEHOLDER}`） |
| 3. 文档生成 | 输出到 `.team-flow/handoffs/<timestamp>-<req-id>.md` | 引用产物路径，不复制内容 |
| 4. 恢复指引 | 输出到终端：新会话的恢复操作 + 建议 skills | 基于触发域分层表精准推荐 |

**交接文档结构**（10 节）：

| 节 | 内容 | 来源 |
|----|------|------|
| §1 下一个会话的关注点 | 用户传入的 argument 或从对话推断 | 用户/推断 |
| §2 工作流状态 | 活跃需求、SOP 阶段、状态机状态、PRD 版本（引用 yaml 路径） | 自动检测 |
| §3 本次会话进度 | 已完成/正在进行/下一步 | 对话萃取 |
| §4 关键决策 | 未写入产物的决策（表格：决策/理由/影响） | 对话萃取 |
| §5 未解决问题与临时假设 | 表格：问题/默认处理/需确认？ | 对话萃取 |
| §6 失败尝试 | 放弃的方案及原因（避免重蹈覆辙） | 对话萃取 |
| §7 用户偏好与约束 | 不在文档中的隐性偏好 | 对话萃取 |
| §8 建议 Skills | 表格：优先级/Skill/理由（基于触发域分层） | 自动推荐 |
| §9 关键产物引用 | 路径列表（PRD/原型/设计方案/复利经验） | 自动检测 |
| §10 敏感信息声明 | 脱敏声明 | 固定 |

**触发域**：步骤级-独立工具。触发词：handoff、交接、换会话、上下文太长、context rot、新会话继续。排除：`ssf handoff`（change 级）、`checkpoint`（执行进度）。

**模型建议触发**：允许。当检测到上下文腐化迹象（重复提问、遗忘约束、响应质量下降）时，模型可建议用户触发 session-handoff。

### 21.2 workflow-feedback：工作流问题记录

**定位**：记录 team-flow 工作流使用过程中发现的问题和改进建议。核心价值 = 把"用的时候觉得不好用"转化为可追踪的改进项。与 ce-compound（经验沉淀端）互补，构成"问题发现→经验沉淀"闭环。

**Frontmatter**：
```yaml
---
name: workflow-feedback
description: >
  记录 team-flow 工作流使用过程中发现的问题和改进建议。
  当 skill 触发不准、SOP 流程不顺、产物质量不符预期、
  交互体验不好时使用；也可在 change 收尾时回顾性触发。
  不适用于：记录业务代码 bug（用 bug-investigator）、
  沉淀已解决问题的经验（用 ce-compound）。
argument-hint: "[问题简述] [--category <分类>] [--severity <P0-P3>]"
---
```

**问题分类体系**（对应 team-flow 实际组件）：

| 分类 | 说明 | 优化责任方 |
|------|------|-----------|
| `skill-trigger` | skill 触发不准（误触发/不触发/触发域冲突） | skill description + 触发域分层表 |
| `sop-flow` | SOP 阶段转换、路由、回退不顺畅 | orchestrator + 设计增强方案 |
| `artifact-quality` | 产物格式/内容/校验不符预期 | 对应 skill + 制品契约 |
| `state-management` | 状态文件不一致、恢复失败、并发冲突 | state-model + CLI |
| `agent-quality` | subagent 产出质量（交接协议、返回格式） | agent 定义 + §18.1 |
| `cli-command` | ssf CLI 命令问题 | scripts/ |
| `ux-interaction` | 交互不流畅、信息过载、确认过多/过少 | skill 工作流设计 |
| `performance` | token 消耗过大、响应慢 | skill 拆分/渐进式披露 |
| `cross-platform` | 跨平台兼容性（Claude Code/Codex/Cursor 等） | 多安装面配置 |
| `documentation` | 文档不一致、过时、缺失 | 文档维护规范 |

**核心工作流**：

```
触发 → 1. 问题采集 → 2. 上下文关联 → 3. 结构化记录 → 4. 改进建议
```

| 步骤 | 动作 | 说明 |
|------|------|------|
| 1. 问题采集 | 主动模式（用户传入 argument）或回顾模式（分析当前会话） | 回顾模式识别：skill 被纠正、用户不满表达、状态回退、多次确认 |
| 2. 上下文关联 | 关联 SOP 阶段、状态机状态、涉及的 skill/agent/CLI | 自动检测 |
| 3. 结构化记录 | 输出到 `.team-flow/feedback/<timestamp>-<category>.md` | git 跟踪 |
| 4. 改进建议 | 生成可追加到 CLAUDE.md 待办列表的条目 + 优先级建议 | 已有解决方案时建议触发 ce-compound |

**问题记录结构**（YAML frontmatter + Markdown）：

```yaml
---
type: workflow-feedback
version: 1
created_at: <ISO 8601>
category: <分类>
severity: <P0 | P1 | P2 | P3>
status: open
related_skill: <skill-name | null>
related_phase: <S1-S5 | change-level | null>
related_requirement: <req-id | null>
---
```

正文：现象 → 期望 → 复现路径 → 影响（范围+频率） → 改进建议 → 建议待办条目。

**触发域**：步骤级-独立工具。触发词：工作流问题、记录问题、这个不好用、流程有问题、反馈、workflow issue。排除：业务代码 bug（→ bug-investigator）、经验沉淀（→ ce-compound）。

**联动**：release-archivist 收尾时建议触发（"本次 change 有工作流问题要记录吗？"）。

### 21.3 两个 skill 的协同与会话生命周期

```
会话生命周期：
  开始 → 工作 → [遇到问题] → workflow-feedback 记录
                → [上下文腐化] → session-handoff 交接 → 新会话继续
                → [change 完成] → release-archivist 收尾
                                    → 建议 workflow-feedback 回顾
                                    → 建议 ce-compound 沉淀
                                    → 建议 session-handoff（如果还有后续工作）
```

### 21.4 产物结构变更

```
.team-flow/                    # 已有
  ├── registry.yaml            # 已有
  ├── requirements/            # 已有
  ├── handoffs/                # 🆕 session-handoff 输出（建议 .gitignore，临时性质）
  │   └── <timestamp>-<req-id>.md
  └── feedback/                # 🆕 workflow-feedback 输出（git 跟踪，改进输入）
      └── <timestamp>-<category>.md
```

### 21.5 新增组件清单（v0.16.0）

| 组件 | 类型 | 动作 | 触发域层级 |
|------|------|------|-----------|
| `session-handoff` | skill | 新增 | 步骤级-独立工具 |
| `workflow-feedback` | skill | 新增 | 步骤级-独立工具 |
| `.team-flow/handoffs/` | 产物目录 | 新增（.gitignore） | — |
| `.team-flow/feedback/` | 产物目录 | 新增（git 跟踪） | — |

**同步更新清单（P4 预评估）**：

| 变更 | 需更新的文件 |
|------|------------|
| 新增 2 个 skill（20→22） | ① 设计增强方案 ② AGENTS.md Skills 索引 ③ README.md ④ CLAUDE.md skills 表 ⑤ plugin.json description |
| 新增产物目录 | ① 设计增强方案 ② AGENTS.md ③ CLAUDE.md 产物结构 |
| 触发域分层 | AGENTS.md 触发域分层表新增 2 行 |
| release-archivist 联动 | release-archivist SKILL.md（收尾时建议触发 workflow-feedback） |

---

## 二十二、v0.20.0 增量设计：子代理产出质量闸门 + 编排等待范式 + S1 原型补跑入口

> **来源**：workflow-feedback 2026-07-25（VRM mgmt-dashboard S2/S1 实测三份反馈：agent-quality / performance / sop-flow）。对应待办 **P1-13 / P2-11 / P2-12**（见 roadmap-and-todos.md）。

### 22.1 产出型子代理质量闸门（P1-13，修订 §18.1.1 返回契约）

**问题**：prototype-builder 在大体量产出任务中，规划阶段耗尽输出预算，核心产物 `index.html` **未落盘即返回 `status: done`**（谎报完成）。主代理误信后派 reviewer 对空目录评审 → 流程空转，需手动 SendMessage resume 才真正产出。

**根因**：§18.1.1 返回契约只规定了 `status` 枚举，**未规定"返回 done 的前置条件"**——agent 可在产物未产出时谎报 `done`。

**设计（修订 §18.1.1，新增 done 前置闸门）**：

1. **产物落盘硬闸门（Deliverable Hard Gate）**——返回契约新增硬前置：
   - 声明的 `deliverable` 若为文件路径，该文件必须已 `Write` 落盘且**非空**，否则**禁止** `status: done`。
   - 若因输出预算不足 / 单次 Write 截断风险无法完成产物，必须返回 `status: blocked`（blocker：「核心产物 X 未落盘，输出预算不足，请 resume 续写」）或 `done_with_questions`，**绝不谎报 done**。
   - 终态交接前 agent 自检：`test -f <deliverable> && test -s <deliverable>`（存在且非空）通过方可 `done`。
2. **大产出默认分片**：产出型 agent 对超大文件（经验阈值 ~800 行）默认「先 `Write` 主体骨架 → 再 `Edit` 分段追加（数据层/渲染层/各页面）」，规避单次 Write 截断与输出预算峰值。
3. **主代理交接后产物校验（defense in depth）**：编排层（prototype skill / workflow-orchestrator）收到 builder 交接、**派 reviewer 之前**，强制 `ls`/`test -f` 校验入口文件存在且非空；缺失则 resume builder，**不空转评审**。

**横展范围（统一解决，分层落点）**：

| 层 | 落点 | 说明 |
|----|------|------|
| 通用规则 | §18.1.1 返回契约修订 | 管辖所有新/改 sub-agent，最持久 |
| 具体硬闸门 | `prototype-builder.md`（文件产出型，首发）+ `prototype-env-scout.md`（prototype 家族另一显式 Handoff agent） | 文件产出型直接适用 |
| 安全网 | 编排层交接后校验 | 与具体 agent 是否改造解耦，捕获任何仍谎报者 |
| 后续可选 | 其余 6 个报告型 agent（code-reviewer / prototype-reviewer / prd-completeness-reviewer / change-split-auditor / cross-change-consistency-checker / bug-investigator） | 以文本报告为产出，"产物落盘"不直接适用；由通用契约 + 主代理校验覆盖，是否补显式 Handoff 段列后续可选 |

**22.1.1 决策点交互（可选扩展，修订 §18.1.2，⏸️ 待 LT 确认）**：

反馈改进建议 2 提出「子代理在决策点/阻断点不结束、先经 `SendMessage` 反馈主代理并等待响应」，可减少 terminate→resume 的往返成本（LT 已于 Session d6801ab4 验证后台子代理↔主代理 SendMessage 可行）。**但与 §18.1.2 既有决策有张力**：§18.1.2 明确「不引入 agent team / 坚持 Task 一次性子代理 + 结构化返回，把阻断反馈用返回结构而非实时消息实现」。

CC 评估：产物落盘硬闸门（第 1 条）**单独即可根治"谎报 completed"**——agent 诚实返回 `blocked`，主代理 resume，正是本次手动发生的路径。SendMessage 决策点是减少往返成本的**优化项**，非必需。故本版**强制实施第 1-3 条**；SendMessage 决策点作为**可选扩展**记录如下，待 LT 拍板是否采纳后再写入 agent 定义：

> 若采纳：背景委派的产出型子代理在决策/阻断点**可选** `SendMessage` 主代理并等待响应（保留上下文，不 terminate），作为「terminate-with-honest-blocker」的替代；但 `status` 结构化返回仍为**主协议/必选**，「不引入 agent team 常驻」不变。即 §18.1.2 修订为「以结构化返回为主协议，允许长任务背景子代理在决策点定向使用 SendMessage」。

### 22.2 编排层低消耗等待范式（P2-11）

**问题**：主代理 `TaskOutput(block=true, timeout=600s)` 阻塞等待后台子代理，**超时返回会倾泻完整子代理 JSONL transcript**（含 thinking/tool_use/tool_result），单次数万 token，连续 3-4 次撑爆主上下文，抵消「主代理只编排」的轻上下文优势。

**设计（明文进编排 skill）**：

- 派发后台子代理后**依赖完成通知（`<task-notification>`）再行动**，不原地反复 `TaskOutput(block=true)` 轮询。
- 长任务子代理派发后，主代理可先处理可并行工作或结束当前轮次等待通知，**不空转死等**。
- 确需中途观察用 `block=false` 轻量状态查询（仍会返回转录，尽量不用）。
- **与 P1-13 协同**：builder 分片 + 产物闸门缩短单子代理时长，源头减少等待轮询。
- harness 层（TaskOutput 对 `local_agent` 超时不倾泻转录、只返末态摘要 + 文件路径）非 team-flow 可控，**单独向 Claude Code 反馈**。

### 22.3 S1 路由表新增「原型补跑/重跑」入口（P2-12）

**问题**：PRD 已冻结但 `prototype/` 缺失/为空，用户要求重跑原型，S1 的 **6 种入口无匹配项**，主代理临场变通无 SOP 依据，跨会话路由不一致（可能误路由到「续版 v2」错误升版或「重新计划」不必要重做 plan）。

**设计**：S1 路由表新增第 7 种入口：

| 入口 | 触发条件 | 跳转 | 制品语义 |
|------|---------|------|---------|
| **原型补跑/重跑** | PRD 已冻结（`frozen_downstream`）∧ `prototype/` 缺失/为空，或用户显式要求重做原型 | → 部分重入 S2 原型循环（S2 步骤 2 判断→3 原型循环→4 冻结） | PRD 不动，保留有效 S3 plan / S4 changes，闭环后恢复原 phase |

- **判据分支**（`s1-path-router.md`）：与「重新计划」（针对 plan 调整）、「续版」（加功能升版）区分——本路径仅 prototype 缺失/需重做，PRD/plan/changes 仍有效。
- **部分重入冻结语义**（`state-model.md`）：PRD `frozen_downstream` 保持；S2 状态置 `in-progress(prototype-only)`；原型循环闭环后恢复原 phase（如 `s4-distribution`）；`replan_log` 记录 S4→S2→S4 往返与「未暴露 scope 问题、changes 保持有效」结论。若原型暴露 scope 问题 → 走 S3→S2 回退修订（升级为非原型补跑）。

### 22.4 决策落实状态（v0.20.0）

- 产物落盘硬闸门 + 大产出分片 + 主代理交接后产物校验（§22.1 第 1-3 条）：✅ 实施于 v0.20.0。
- 编排层完成通知等待范式（§22.2）：✅ 实施于 v0.20.0。
- S1 原型补跑/重跑入口（§22.3）：✅ 实施于 v0.20.0。
- 决策点 SendMessage 可选扩展（§22.1.1，修订 §18.1.2）：⏸️ **待 LT 确认**是否采纳（与 §18.1.2「不引入 agent team / 统一返回结构」有张力）。

---

## 二十、决策落实状态（v0.8 增补）

12. **v0.15.0 subagent 编排 + 状态治理（v0.8 新增）**：
    - subagent 结构化交接协议（主代理只编排，阻断/非阻断用返回结构，不上 agent team）：✅ LT 确认（2026-07-25）。
    - 多需求并行状态模型（每需求一份 + 注册表索引）：✅ LT 确认（2026-07-25）。
    - `.team-flow/` 状态治理（本版本仅状态文件，P1-6 全量重命名仍 v1.0.0）：✅ LT 确认（2026-07-25）。
    - ce-plan 模式 pipeline 下 orchestrator 问定后显式传参：✅ LT 确认（2026-07-25）。
    - 版本打包为 v0.15.0 专题版，新增设计文档 v0.8：✅ LT 确认（2026-07-25）。
    - bootstrap 侦察子代理 + `ssf recon` 脚本：✅ 已实施（v0.15.0，2026-07-25）。
    - prd-completeness-reviewer（PRD 完整性评审）：✅ 已实施（v0.15.0，2026-07-25）。
    - 冻结措辞 BUG 修复（frozen_downstream vs absolute）：✅ 已实施（v0.15.0，2026-07-25）。
    - PRD 版本格式规范（vN / vN.M / 状态枚举一致性）：✅ 已实施（v0.15.0，2026-07-25）。
    - prototype 内部子代理编排 + 设计系统生命周期：✅ 已实施（v0.15.0，2026-07-25）。
    - ce-plan 收窄高阶设计（删接口清单）+ 作用边界声明：✅ 已实施（v0.15.0，2026-07-25）。

13. **v0.16.0 会话交接 + 工作流反馈（v0.8 §21 新增，P1-10）**：
    - 新增 `session-handoff` skill（会话级上下文交接，区别于 change 级 `ssf handoff`）：✅ LT 确认（2026-07-25）。
    - 新增 `workflow-feedback` skill（工作流问题结构化记录，与 ce-compound 互补）：✅ LT 确认（2026-07-25）。
    - 交接文档保存到 `.team-flow/handoffs/`（项目内，新会话可发现，.gitignore）：✅ LT 确认（2026-07-25）。
    - 问题记录保存到 `.team-flow/feedback/`（git 跟踪，改进输入持久化）：✅ LT 确认（2026-07-25）。
    - session-handoff 允许模型主动建议触发（不设 disable-model-invocation）：✅ LT 确认（2026-07-25）。
    - 目标版本 v0.16.0：✅ LT 确认（2026-07-25）。

14. **v0.20.0 子代理产出质量闸门 + 编排等待范式 + S1 原型补跑入口（v0.8 §22 新增，P1-13/P2-11/P2-12）**：
    - 三份 workflow-feedback（VRM mgmt-dashboard）合并为 v0.20.0 一次性实施：✅ LT 确认（2026-07-25）。
    - 产物落盘硬闸门（deliverable 未落盘非空禁止 done）+ 大产出分片 + 主代理交接后产物校验：✅ 实施于 v0.20.0（修订 §18.1.1）。
    - 编排层依赖 `<task-notification>` 完成通知、禁反复 `TaskOutput(block=true)` 轮询：✅ 实施于 v0.20.0。
    - S1 路由表新增第 7 种入口「原型补跑/重跑」（部分重入 S2 原型循环，PRD 不动，保留有效 S3/S4）：✅ 实施于 v0.20.0。
    - 决策点 SendMessage 可选扩展（修订 §18.1.2「不引入 agent team」）：⏸️ 待 LT 确认是否采纳（CC 评估硬闸门已根治谎报完成，SendMessage 仅为减少往返的优化项）。

---

*v0.8 由 CC 基于 LT 第 20 轮实证复盘（VRM 管理驾驶舱 Session 29d058e5 全链路动作还原）+ 4 项架构决策（多需求状态模型 / ce-plan 模式传参 / .team-flow 治理节奏 / v0.15.0 打包），增量修订。承袭 v0.7 全量内容，仅记录 v0.15.0 增量。*

*2026-07-25 追加 §21（v0.16.0 会话交接 + 工作流反馈，P1-10），LT 确认四项决策（保存位置 / git 跟踪 / 模型建议触发 / 目标版本）。*
