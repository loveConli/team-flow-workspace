# 架构 / API / DB 设计增强方案 · v0.9（产品级 change 拆分治理 + 产品级↔变更级产物交接契约）

> 版本：v0.9 · 重大修订（增量式，承袭 v0.8）
> 目标插件版本：**v0.22.0**（占位；最终以 P4 `npm version` 为准）
> 修订依据：v0.8 全量内容**继续有效**；v0.9 仅记录本次增量修订。
> 触发来源：LT 两项 plugin 待办——① 产品阶段 change 拆分不合理（应按用户故事/功能模块拆、且不要拆细）；② `workflow-orchestrator` 与 `workflow-start` 两阶段产物未对齐（实证：在 VRM 工作区跑 `/team-flow:workflow-start` 被判"无活跃 change → 进入 DP-0 手动创建"，即 orchestrator 已拆好分发的 change 在变更层被当白纸）。
>
> **⚠️ 自包含声明（重要）**：本仓库 `docs/` 下**不存在 v0.7 全文文件**（CLAUDE.md「设计增强方案版本管理」亦将 v0.7 列入"已删除"），而 v0.8 对 v0.7 的 §17.2（change 拆分）/ §17.8（编排层只编排）等锚点存在引用悬空风险。为避免重蹈此覆辙，**§23 / §24 所需的全部正向定义已内嵌本文**，不依赖任何缺失旧文；凡提及 v0.7 锚点，一律"标注承袭关系 + 内嵌所需定义摘录"双处理。
>
> **v0.9 修订摘要（相较 v0.8）**：
> - **§23 产品级 → 变更级产物交接契约**：新增 `change-brief.md` 交接物，由 orchestrator S4 在审计 PASS 后落盘到每个 change 目录；变更层（workflow-start / need-explorer / spec-writer）继承 scope/AC/技术方向，不再重复询问意图、不再重复决策拆分——修复两层产物断链。
> - **§24 拆分维度治理**：正向钉死 change 拆分维度 = 用户故事 / 功能模块（内聚功能域）；`change-split-auditor` 新增 **D5 拆分维度合规硬门禁**（拆到单接口/单文件/单任务 = Critical = FAIL），与原 D3 数值粒度（advisory）正交。
> - **§25 文档一致性修正**：修正 state-model.md / s1-path-router.md 关于变更级状态文件名的现状口吻漂移（`.team-flow.yaml` → 当前仍为 `.spec-superflow.yaml`，v1.0.0 改名）。
> - **§26 架构设计显式编排与产物独立化**：workflow-start 显式编排 architecture-design 子代理（判断+执行一体化）；产出目录从 `specs/<cap>/` 提升为独立 `architecture/`；spec-writer Required Inputs 增加 `architecture/` 读取；hotfix/tweak 不豁免。
> - **§27 身份统一：spec-superflow → team-flow 全量迁移**：完成 P1-6 第二阶段——npm 包名 `spec-superflow` → `team-flow`、CLI 前缀 `ssf` → `tf`、状态文件 `.spec-superflow.yaml` → `.team-flow.yaml`、脚本文件名 `spec-superflow.mjs` → `team-flow.mjs`；全量 721 处引用一刀切迁移；存量项目通过 `tf doctor` 自动迁移。
> - **第二十章**决策落实状态新增第 15 条。
> - **零脚本逻辑改动**：本修订全部为指令文本 / 文档措辞 / 设计文档；`hash.mjs` / `state-loader.mjs` / `cmd-state.mjs` / `infer-workflow.mjs` 均不动（详见 §23.3 决策记录）。

---

## 二十三、产品级 → 变更级产物交接契约（v0.22.0，待办 2）

### 23.0 问题诊断（实证）

产品级编排层（workflow-orchestrator S1-S5）与变更级执行层（spec-superflow，入口 workflow-start）之间存在**产物断链**：

| 断点 | 现象 | 根因 |
|------|------|------|
| 意图断链 | S4 对每个 `changes/<name>/` 只跑 `mkdir + ssf state init`，写出的 `.spec-superflow.yaml` 为 `state: exploring / 全 dp_*: null` 空壳；scope/AC/需求描述**未写入 change 目录**（只活在产品级 `prd/vN/plan.md`） | S4 无交接物落盘步骤 |
| 变更层不读产品层 | workflow-start 全文件对产品层关键词（orchestrator / change_dag / registry / plan.md）零命中；产物一空即触发 DP-0 **重新询问** change 意图 | 变更层纯内容驱动，无上游继承机制 |
| AC 死产物 | S4 必选门禁 `change-split-auditor` 算出的 AC 覆盖矩阵因 agent 只读不落盘，spec-writer 拿不到 | auditor 只读职责 + 无落盘载体 |
| 技术方向断链 | `s3-plan-pipeline.md` 写保留全局技术方向是"为避免各 change 的 spec-writer 各自为政"，但 spec-writer Required Inputs 不读 plan.md | 设计意图无对应实现机制 |
| 拆分决策重复 | need-explorer 的交付物含 decomposition decision，与 S3+S4 已审计的拆分重复 | 变更层对产品级拆分无感知 |

LT 贴图的"无活跃 change → DP-0"即"意图断链"的直接表象：即便 orchestrator 已 S3/S4 拆好分发，变更层仍当 change 目录是白纸。

### 23.1 两层衔接现状与扩展

orchestrator 与 workflow-start 的衔接，原声明为"通过 change 目录 + `.spec-superflow.yaml` 衔接"。本版**扩展**为：

> 衔接 = change 目录 + `.spec-superflow.yaml`（状态机载体） + **`change-brief.md`（上游意图交接物，v0.9 新增）**。

`.spec-superflow.yaml` 只承载状态机字段（state / workflow / hashes / dp_* / 执行进度），**不**承载产品级意图；产品级意图由 `change-brief.md` 承载。二者职责分离，互不污染。

### 23.2 change-brief.md 契约

**定位：上游输入（upstream input），非 spec-superflow 产物。** spec-superflow 的产物契约固定为五个文件——`proposal.md` / `specs/` / `design.md` / `tasks.md`（规划产物）+ `execution-contract.md`（执行握手）（见外部参考 `docs/external-references/spec-superflow/docs/artifact-contract.md`，五产物定义与"实施前产物齐备+契约批准"守卫均不含 brief）。`change-brief.md` 是 S4 时刻产品级决策的**投影快照**，外置于五产物契约之外。

**schema**（frontmatter 机器可读 + 正文人可读）：

```markdown
---
upstream_source: orchestrator          # orchestrator | manual | null
upstream_req_id: <req-id>              # 对应 .team-flow/requirements/<req-id>/
upstream_plan_ref: prd/vN/plan.md      # hotfix/快速通道为 null
upstream_change_id: C2                 # 对应 change_dag.id
plan_hash: sha256:<plan.md 内容摘要>    # 检测产品层改动后变更层未同步
---
# Change Brief: <change-name>

## Scope
<用户故事/功能模块级 scope，与 plan.md 该 change 的 Scope 一致>

## 约束
<来自 plan.md 的全局约束 / 该 change 的已知约束>

## AC 列表
<取自 auditor 报告 Dim1 覆盖矩阵中映射到本 change 的 AC，逐条>

## 全局技术方向
<取自 plan.md 高阶技术设计段要点：模块边界/技术选型/数据流方向>

## PRD & plan 引用
- PRD: prd/vN/prd.md §<相关章节>
- Plan: prd/vN/plan.md ### <C-ID>
```

**落盘职责（写死）**：auditor 是只读 agent（其 tools 仅 Read/Bash/Grep/Glob，明令 read-only），**只在审计报告输出 Dim1 覆盖矩阵**；**落盘动作归 orchestrator S4**（与写 change_dag 同属编排层自做）。即：读 auditor 报告 Dim1 矩阵 → orchestrator 写 brief 的 AC 段。已存在 brief 则**覆盖更新**（防 S4→S3 回退后 brief 陈旧）。

**hash 豁免依据（内嵌代码事实，不改代码）**：brief 放 change 根目录，天然不进入 `artifacts_hash`——
- `team-flow/scripts/lib/hash.mjs` 的 `computeArtifactsHash` 只统计四类：`proposal.md` + `specs/*/spec.md` + `design.md` + `tasks.md`，空则返回 null；
- `team-flow/scripts/lib/spec-paths.mjs` 的 `findCanonicalSpecFiles` 只 walk `specs/` 子树，且要求 basename = `spec.md` 且路径为两层 `specs/<cap>/spec.md`。
- brief 在 change 根目录 → 第一重即不在统计列表；即便误放 `specs/` 下也被第二重排除。**故空 change 的 `artifacts_hash` 仍为 null**，状态机"无产物"判定（`cmd-state.mjs` 一致性判定 / `isContractFresh`）不受污染。**绝不**让 brief 入 hash。

**双源权威规则**：scope / 技术方向以 `prd/vN/plan.md` 为准、AC 以 PRD 功能清单为准；**brief 只是 S4 时刻快照，不是第二真相源**。brief 与 plan 冲突 → 变更层以 plan 为准 + 触发 §23.5 的 Brief drift 提示。

### 23.3 机器判源：为何主载体是 brief frontmatter 而非 yaml 字段（决策记录）

DP-0 需判定 change 来源（orchestrator 分发 vs 手动新建）。曾考虑在 `.spec-superflow.yaml` 加 `origin` 嵌套块，经代码约束验证**否决**，改以 **brief frontmatter 为主载体、brief 文件存在为 DP-0 主信号**，yaml `upstream_*` 降为可选增强（本次不实施）。否决理由（内嵌代码事实）：

1. `state-loader.mjs` 的 `parseYaml` 仅解析**顶层字段**（注释明写 "top-level fields only... No nested structures needed"，正则只匹配 `key: value`）——嵌套 `origin:\n  source:` 会被错误扁平化。
2. 仅往 `BUILTIN_DEFAULTS` 加字段而不扩 `writeState` 的硬编码序列化块，新字段会在首次 `ssf state set/transition` 后**丢失**（`updateField` 整文件重写）；外加 `cmd-state.mjs` 的 `SETTABLE_FIELDS` 白名单拒写白名单外字段——yaml 方案须**三文件脚本联动**且易错。
3. 字段名 `origin` 已被 ce-plan `references/plan-sections.md` 占用（"repo-relative path to an upstream brainstorm"，且明令不许改名 `source`）——须避让，用 `upstream_*`。

**以 brief 存在为主信号的额外收益**：hotfix / 单 change 快速通道也是 orchestrator 创建的 change，但**不产 brief**；以 brief 存在为信号可天然排除这两条路径，且对存量手动 change（无 brief）零误伤——无需为存量 change 强写 `manual` 标记。

**结论**：本次修订**不碰任何脚本逻辑**，整套改动退化为指令文本 + 文档措辞，对现有 state-loader / hash 约束最贴合、回归风险最小。

> 备忘（本次不实施）：若未来需跨会话 `ssf state get upstream_*`，才做三文件联动——`state-loader.mjs` `BUILTIN_DEFAULTS` + `writeState` 序列化行 + `cmd-state.mjs` `SETTABLE_FIELDS`，字段用扁平 `upstream_*`（禁 `origin`）。

### 23.4 继承规则（三接入点 + 判定伪代码）

**DP-0（workflow-start）**——主信号 = brief 存在：

```
brief = read(<change-dir>/change-brief.md)
if brief 存在 and brief.upstream_source == "orchestrator":
    defaults = { name: brief.upstream_change_id/<basename>,
                 intent: brief.Scope, constraints: brief.约束, AC: brief.AC 列表 }
    问用户(一次): 继承并开始 / 逐项修正 defaults     # 不重新问"你想做什么"
else:
    照常 DP-0（手动新建 / hotfix / 单change快速通道 / 存量 change）
两分支最终都写 dp_0_confirmed=true
```

**need-explorer**——「Inspect Context First」后加「Upstream Inheritance」：有 brief → 读 Scope/约束/AC 作为提问默认值，只就未覆盖或存疑部分追问；decomposition decision **默认采纳产品级拆分**（本 change 是 PRD 经 ce-plan + auditor 拆出的独立单元，默认不再二次拆分；用户显式提出再拆分需明确确认）。

**spec-writer**——Required Inputs 加「Change Brief」+「Plan Technical Direction」：brief 的 Scope 作 proposal scope 基线、AC 列表作 specs/ 的 AC 覆盖上限（不静默丢弃 brief AC、不静默超出 brief scope，冲突以 plan.md 为准并注明）；读 plan.md 高阶技术设计段作 design.md Decisions 约束，**禁止**反向要求 plan.md 提供接口清单/字段定义（防复活 v0.8 §18.7.2 已修复的越界 BUG）。Working Rules 加「Honor Brief」呼应「Honor DP-0」。

### 23.5 brief staleness 语义

brief 是**上游输入**，**不**混入 workflow-start 现有三条产物互查（stale contract / stale planning artifacts / stale tasks，均检查 change 内部产物互洽性），**不**进入 `artifacts_hash`。新增**独立**的 **Brief drift（advisory，不阻断）**：brief 的 `plan_hash` 与当前 `prd/vN/plan.md` 不一致，或 brief AC 与 PRD 功能清单明显出入 → 提示"产品层已变更，brief 可能过期，建议回 orchestrator 重新分发（S4→S3 环路）"，**不**触发产物重审、**不**写 hash。

---

## 二十四、拆分维度治理——所有权自包含根因判据（v0.22.0 重写，待办 1）

### 24.0 问题诊断与迭代历程

**v0.9 初稿（已作废为根因）**：初稿以"用户故事 / 功能模块 vs 实现单元"作为 D5 判据。这是**表层启发式**——scope 文本"像不像故事/模块"。LT 在 VRM 管理驾驶舱实战中实证暴露盲区：6 个 change 按视角/层切分（4 视角 + 读侧基座 + 页面骨架），每个 scope 文本上"像个模块"，初稿 D5 放行 PASS；但它们**共享同一看板读模型/契约的所有权**，6 家 change 的 architecture-design 增量设计互相重叠、复利回写打架——正是"产品阶段拆太细"的活样本。

**根因**：CC 把判据用错了层次——把"粒度尺子"当"标签章"用（先接受 6 change 结果、再各盖 PASS/🟡），且把**变更级实现组织**（按视角/层组织 specs/tasks）误提级为**产品级 change 边界**。

**LT 判据（CC 认同为根因）**："能独立做架构设计来拆分"——精确化为**所有权自包含**：一个 change 当且仅当它对应一个所有权自包含的架构设计单元。

> 承袭说明：v0.7 §17.2 为 change 拆分的原始设计锚点，但该文件在本仓库不存在。下述正向定义**自包含**给出，不依赖 v0.7 §17.2 原文。

### 24.1 根因判据（自包含，全文）

**change 边界 = 所有权边界**。一个 change 当且仅当它对应**一个所有权自包含的架构设计单元**——即该 change 能独立做一次架构增量设计（`architecture-design` skill 核心动作：识别聚合 / 限界上下文 / 读写模型 / API 指令映射），且该设计不依赖其它 change 去重新定义同一聚合/上下文/读模型/契约的所有权。

**认知声明**：一个迭代版本的 PRD 通常涵盖**多个所有权自包含的设计单元**。产品级 change 拆分的首要动作是**识别这些所有权单元**——不是识别"视角""页面""接口""层"等实现组织。用户故事 / 功能模块 / 视角 / 层 / 页面，都是 **change 内部** spec-writer / build-executor 的实现组织启发式，**不提级**为 change 边界。

**启发式近似**（与根因判据冲突时以根因为准）：
- 一个用户故事（角色-动作-价值）通常 ≈ 一个所有权单元 → 通常 = 一个 change
- 一个内聚功能模块（如"下单""权限体系"）通常 ≈ 一个所有权单元 → 通常 = 一个 change
- 但若多个故事/视角/层**共享同一所有权单元**（如看板多视角共享同一读模型），应合为一个 change

**为何如此**：变更级 `architecture-design` 对每个 change 做"架构增量设计"。若两个 change 共享同一聚合/读模型/契约所有权，则两家的增量设计互相重叠、复利回写打架、所有权不自包含——这是"拆太细"的真正病根。反过来，一个所有权单元内部按视角/层/页面组织 specs 和 tasks，是**变更级实现组织**，完全正确且推荐。

**反模式**（Critical）：
- **切碎所有权**：把一个所有权单元按视角/层/页面/前后端/DB 切成多个 change。例：看板 4 视角 + 读侧基座 + 页面骨架共享同一看板读模型/契约 → 应合为 **1 个 change**，而非 6 个。又如把"下单"按 C-后端 + C-前端 + C-读模型 切 3 change → 三家瓜分"下单"聚合所有权 → FAIL
- **跨无关节所有权单元**：一个 change 横跨 ≥2 个互不相关的限界上下文/所有权单元
- **细到无所有权单元**：scope 是单接口/单文件/单方法/单 SQL/单 task → 无设计单元可识别

**正例**：
- scope = "管理驾驶舱（含总览 KPI / 进度流 / 价值流矩阵 / 三层下钻 / 读侧基座 / 页面骨架，持有看板限界上下文完整所有权）" → **1 个 change**，内部按视角/层组织 specs/tasks
- scope = "订单下单（含创建接口+库存校验+下单页，持有下单聚合完整所有权）" → PASS
- scope = "读侧 CQRS 查询基座（持有看板读模型完整所有权，上层 change 消费不重设计）" → PASS（合法基座）

### 24.2 D5 所有权粒度合规硬门禁

`change-split-auditor` D5 从"scope 文本标签检查"**重构**为"所有权粒度分析"，**severity = Critical**。

**判定方法**（非文本标签，而是所有权分析）：
1. 从每个 change 的 scope 识别其声明的**架构所有权对象**（聚合/限界上下文/读模型/契约/层）
2. **切碎检测**（最核心）：若 ≥2 change 的 architecture-design 会重复设计同一聚合/上下文/读模型/契约 → 所有权被瓜分 → FAIL，要求合并
3. **无设计单元检测**：scope 细到无法识别任何架构所有权对象 → FAIL
4. **跨单元臃肿检测**：横跨 ≥2 互不相关的所有权单元 → FAIL

**安全港**：① 单 change 计划整体豁免；② hotfix / tweak / 快速通道不经审计；③ 合法基座/横切前置层（持有**完整**层/契约所有权，上层只消费不重设计）→ PASS。关键区分：合法基座 = 持有完整所有权；非法切碎 = 与别家瓜分同一所有权。

**与 D3 正交**：D3 管数值粒度（advisory/Important，不 FAIL）；D5 管所有权粒度（Critical）。二者正交。

**判定表**：Critical = coverage gap, DAG cycle, dangling dependency reference, **ownership-granularity violation (D5: 切碎/无设计单元/跨单元臃肿)**；Important 集合不变。

### 24.3 与 ce-plan 作用边界呼应

ce-plan SKILL.md「作用边界」硬声明（v0.8 §18.7.3 确立，v0.9 重写为所有权判据）：

> **ce-plan = 产品级策略**：change 拆分（scope+依赖+优先级+复杂度）、change 依赖 DAG、技术方向决策、风险与里程碑。**change 边界 = 所有权边界**——一个 change 当且仅当一个所有权自包含的架构设计单元（见 ce-plan `references/change-splitting.md` v0.9 根因判据）；用户故事/功能模块/视角/层是 change **内部**的实现组织启发式，不提级为 change 边界。
> **ce-plan ≠ 变更级详细设计**：接口清单、字段定义、方法签名、文件级 Implementation Unit 一律属各 change 的 spec-writer / architecture-design，不进 plan.md。

D5 硬门禁即作用边界在审计层的强制落点：作用边界说"接口/文件级不进 plan"，D5 说"若 plan 把 change 拆到无所有权单元可识别的粒度则 FAIL"；作用边界说"change 内组织由 spec-writer 负责"，D5 说"若 plan 把 change 内组织（视角/层）提级为 change 边界则切碎 = FAIL"。二者闭环。

---

## 二十五、文档一致性修正记录（v0.22.0）

变更级状态文件名的文档漂移修正，准绳为 v0.8 §18.3（"v0.15.0 保持 `.spec-superflow.yaml` 不变，检测逻辑不动；npm 包名/CLI/npx 全量重命名按 v1.0.0"）：

| 文件 | 修正前（现状口吻，与 §18.3 矛盾） | 修正后（将来时，对齐 §18.3） |
|------|----------------------------------|------------------------------|
| `skills/workflow-orchestrator/references/state-model.md` L18 | "由 `.spec-superflow.yaml` 改名为 `.team-flow.yaml`，检测逻辑保留对旧文件名的向后兼容探测" | "当前仍为 `.spec-superflow.yaml`，检测逻辑不动；计划 v1.0.0 改名" |
| `skills/workflow-orchestrator/references/state-model.md` L55 | `# 从 .team-flow.yaml 同步` | `# 从 .spec-superflow.yaml 同步（计划 v1.0.0 改名 .team-flow.yaml）` |
| `skills/workflow-orchestrator/references/s1-path-router.md` L63 | "从各 change 的 `.team-flow.yaml` 同步" | "从各 change 的 `.spec-superflow.yaml` 同步（计划 v1.0.0 改名）" |

> 注：state-model.md 的 L51/L99/L107 本就为正确将来时（"P1-6 第二阶段 v1.0.0 改名"），本次**未动**；本次修正 L18（过去时漂移）+ L55（yaml 示例注释中残留的旧文件名）。代码层 `state-loader.mjs` 的 `STATE_FILE = '.spec-superflow.yaml'` 无 `.team-flow.yaml` 兼容探测逻辑（改名属 v1.0.0 未来事项），文档修正后与代码一致。

---

## 二十、决策落实状态（v0.9 增补）

15. **v0.22.0 产品级 change 拆分治理 + 产品级↔变更级产物交接契约（v0.9 §23/§24/§25 新增）**：
    - change 拆分根因判据 = **所有权自包含**（一个 change 当且仅当一个所有权自包含的架构设计单元；用户故事/功能模块/视角/层降为 change 内部实现组织启发式）+「大 PRD = 多所有权单元合集」认知声明（§24.1，ce-plan `change-splitting.md` + SKILL.md 作用边界）：✅ 已实施于 v0.22.0。
    - `change-split-auditor` D5 **重构**为所有权粒度合规硬门禁（切碎检测/无设计单元/跨单元臃肿，Critical，与 D3 正交，含单 change 安全港 + 合法基座安全港）（§24.2）：✅ 已实施于 v0.22.0。
    - 新增 `change-brief.md` 交接物，S4 审计 PASS 后由 orchestrator 落盘（AC 取自 auditor Dim1 矩阵，落盘归 orchestrator 不归 auditor）（§23.2）：✅ 已实施于 v0.22.0。
    - 机器判源主载体 = brief frontmatter + brief 存在为 DP-0 主信号；yaml `upstream_*` 可选增强本次不实施（§23.3 决策记录）：✅ 已实施于 v0.22.0。
    - 变更层三接入点继承（workflow-start DP-0 / need-explorer / spec-writer，含 Honor Brief + Plan Technical Direction）（§23.4）：✅ 已实施于 v0.22.0。
    - brief staleness = 独立 advisory，不混入三条产物互查、不入 artifacts_hash（§23.5）：✅ 已实施于 v0.22.0。
    - 命名漂移文档修正 state-model.md L18 + s1-path-router.md L63（§25）：✅ 已实施于 v0.22.0。
    - **零脚本逻辑改动**（hash.mjs / state-loader.mjs / cmd-state.mjs / infer-workflow.mjs 不动）：✅ 已实施于 v0.22.0。
    - **档 C**（变更层消费 change_dag 的 depends_on/priority/parallel_group，经 brief 抄录）：⏸️ **后续独立增量**，本次不做。
    - **v0.7 悬空引用根治**：§23/§24 自包含，不依赖 v0.7 全文；v0.7 锚点"标注 + 内嵌摘录"双处理：✅ 已实施于 v0.22.0。

---

*v0.9 由 CC 基于 LT 两项 plugin 待办（产品阶段 change 拆分维度 + workflow-orchestrator↔workflow-start 产物对齐实证）增量修订，承袭 v0.8 全量内容。核心为「拆分维度正向定义 + D5 硬门禁」（§24）与「change-brief.md 交接契约 + brief-frontmatter 中心判源」（§23），全案零脚本逻辑改动。鉴于 v0.7 全文在本仓库缺失，§23/§24 正向定义自包含内嵌，不依赖任何缺失旧文。*

---

## 二十六、架构设计显式编排与产物独立化（v0.23.0）

> 触发来源：LT 与 CC 讨论——架构设计（API/DB/聚合/限界上下文/CQRS）是变更级必须经过的一道门，即使最终判断不涉及架构设计，也应有显式判断记录。当前设计中 architecture-design 是独立 skill，不在 workflow-start 路由表中，完全靠用户主动触发，缺乏纪律性保障。

### 26.0 问题诊断

| 断点 | 现象 | 根因 |
|------|------|------|
| 架构设计无必经之门 | architecture-design 不在 workflow-start 路由表中，spec-writer 可直接产出 design.md 而不经过架构审视 | workflow-start 路由表无 architecture-design 入口 |
| 判断与执行分离 | 架构设计判断由 workflow-start 或用户做，执行由 architecture-design 做，判断者不是最专业者 | 职责分层不当 |
| 产出语义混杂 | 架构产出（architecture.md / database.md / api.md）放在 `specs/<cap>/` 下，与行为规格混杂 | 目录设计未区分架构产物与行为规格 |
| 下游消费断裂 | spec-writer 未读取架构设计产出作为 design.md 约束输入，架构设计与 spec-writer 之间无显式衔接 | spec-writer Required Inputs 不含 architecture/ |

### 26.1 workflow-start 显式编排 architecture-design

**状态机变化**：workflow-start 在 `exploring` 完成后、`specifying` 之前，**必须调用** architecture-design 子代理。

```
exploring → [architecture-design 子代理调用] → specifying → bridging → ...
```

**职责分层**：

| 层 | 职责 |
|---|------|
| workflow-start | 编排：调用子代理 → 确认结果合理性 → 路由下游 |
| architecture-design | 领域能力：判断 + 执行一体化（判断者即执行者，最专业） |
| spec-writer | 下游消费：读取架构设计产出（若有），作为 design.md 约束 |

**架构设计子代理契约**：

**输入**：
- `change-brief.md`（scope / AC / 技术方向）
- `prd/vN/plan.md` 高阶技术设计段
- 现有 `specs/`（若有）
- 全局 `docs/architecture/`（As-Is 基线）

**输出**（结构化）：
```yaml
decision: required | skipped
reason: "..."                    # skip 时必填理由；required 时填设计摘要
artifacts:                       # required 时的产出路径列表
  - architecture/architecture.md
  - architecture/database.md
  - architecture/api.md
```

**内部分流逻辑**：
1. 先做架构变更判定（五项检查：是否新增/修改聚合、限界上下文边界变化、读写模型变化、API 新增/变更、DB schema 变更）
2. 全部为否 → `decision: skipped` + reason
3. 任一为是 → `decision: required` → 执行完整 4A+DDD 增量设计

### 26.2 workflow-start 确认机制

workflow-start 接收子代理结果后做**合理性校验**（非被动接收）：

| 子代理返回 | workflow-start 校验 | 不通过时 |
|-----------|-------------------|---------|
| `skipped` + reason | reason 与 brief/plan scope 一致性（如 scope 含"新增 API"但 reason 说不涉及架构变更 → 不合理） | BLOCK，提示用户复核 |
| `required` + artifacts | artifacts 文件实际存在 | BLOCK，要求重跑 |
| `null`（未判定） | — | BLOCK |

**yaml 字段**：
```yaml
arch_design_decision: required | skipped    # null = BLOCK
arch_design_reason: "..."                   # skip 时必填
arch_design_artifacts: [architecture/*.md]  # required 时必填
arch_design_timestamp: "..."
```

**hotfix / tweak 不豁免**：同样过 architecture-design 子代理（hotfix 可能正是架构缺陷导致的，更需要过这道门）。

### 26.3 架构产出独立目录

**目录结构修订**：

```
changes/<name>/
├── .spec-superflow.yaml
├── change-brief.md              # 上游交接物（orchestrator S4）
├── proposal.md                  # spec-writer：why + scope
├── design.md                    # spec-writer：decisions + trade-offs
├── tasks.md                     # spec-writer：implementation steps
├── execution-contract.md        # contract-builder：execution handshake
│
├── specs/                       # 行为规格（spec-writer）
│   └── <cap>.md                 # SHALL/MUST + Scenario + WHEN/THEN
│
├── architecture/                # ★ 架构设计（architecture-design，独立一等产物）
│   ├── architecture.md          # DDD 增量（聚合/限界上下文/CQRS）
│   ├── database.md              # DB 增量（实体/读写模型变更）
│   └── api.md                   # API 增量（Command/Read/Query 分流）
│
└── prototype/                   # 原型（prototype skill）
```

**修订理由**：
- **语义分离**：架构设计与行为规格是不同专业领域，混在 `specs/<cap>/` 下语义不对
- **可选性清晰**：目录存在 = 有架构产出，目录不存在 = 判定为不需要
- **消费方显式读取**：spec-writer 明确读取 `architecture/` 作为约束输入
- **arch-merge 逻辑简洁**：整个 `architecture/` 目录统一回写全局 `docs/architecture/`

### 26.4 上下游衔接关系

```
上游输入                         architecture-design              下游消费
────────                        ────────────────                ──────
change-brief.md (scope/AC)  ──→                                  ──→ spec-writer: design.md Decisions 约束
plan.md (高阶技术方向)       ──→  判断 + 执行一体化  ──→ architecture/architecture.md ──→ spec-writer: design.md Decisions 约束
全局 docs/architecture/     ──→                                  ──→ architecture/database.md     ──→ spec-writer: design.md + tasks.md 数据层约束
                                                                 ──→ architecture/api.md          ──→ spec-writer: tasks.md 接口定义约束
                                                                           ↓
                                                              release-archivist → arch-merge
                                                                           ↓
                                                              全局 docs/architecture/ 回写
```

### 26.5 需修订的文件清单

| 文件 | 修订内容 |
|------|---------|
| `skills/workflow-start/SKILL.md` | 路由表增加 architecture-design 调用 + 确认机制 + yaml 字段写入 |
| `skills/architecture-design/SKILL.md` | 增加判断+执行一体化 SOP + 结构化输出契约 + 产出目录改为 `architecture/` |
| `skills/architecture-design/chapters/ch06-integration.md` | 产物布局修正（`specs/<cap>/` → `architecture/`） |
| `skills/spec-writer/SKILL.md` | Required Inputs 增加 `architecture/` 读取段 |
| `skills/contract-builder/SKILL.md` | 检查是否需要读取 architecture/ 作为约束 |
| `docs/roadmap-and-todos.md` | 新增待办条目 |

---

## 二十七、身份统一：spec-superflow → team-flow → @xulthekl/team-flow 全量迁移（v0.15.0 → v0.22.3 → v0.22.4）

> 触发来源：P1-6 三阶段
> - **第一阶段 v0.15.0**：产品级状态文件 `.team-flow/` 化
> - **第二阶段 v0.22.3**：spec-superflow → team-flow 全量迁移（v0.22.2 版本错位问题实证暴露——npx 找不到本地包 @0.22.2 而回退到 npm 公共 @0.11.0，根因为身份分裂：产品名 team-flow 与底座包名 spec-superflow 并存）
> - **第三阶段 v0.22.4**：npm 包 scope 化（npm publish 权限冲突——`team-flow` 包名被占 + 2FA/OTP 机制不匹配 macOS 密码 App，改用 scoped package `@xulthekl/team-flow` 绕过）

### 27.0 问题诊断

| 断点 | 现象 | 根因 |
|------|------|------|
| 身份分裂 | 产品名 `team-flow`（23 skills + 8 agents 统一插件），底座 npm 包名 `spec-superflow`（停在 0.11.0 未发布） | 历史遗留：spec-superflow 是 team-flow 的 CLI 底座，但包名从未重命名 |
| 版本错位 | skill 文件引用 `spec-superflow@0.22.2`，npm 公共最新只有 `0.11.0`，npx 找不到 → 回退旧版 → 命令缺失/字段不匹配 | `npm version` pre-publish hook 只同步版本号 + git commit，无自动 `npm publish` |
| CLI 前缀分裂 | CLI 命令 `ssf`（spec-superflow CLI），与产品名 `tf`（team-flow）不一致 | 身份分裂的表象 |
| 状态文件分裂 | 变更级状态文件 `.spec-superflow.yaml`，产品级目录 `.team-flow/`，命名不统一 | 身份分裂的表象 |
| 99 处 npx 引用断裂 | 18 个 skill 文件中 99 处 `npx --package spec-superflow@X.Y.Z ssf ...` 全部指向未发布的包版本 | 身份分裂 + 发布流程缺失 |

### 27.1 迁移决策（LT 确认 4 项）

| 维度 | 现状 | 目标 | 策略 |
|------|------|------|------|
| npm 包名 | `spec-superflow` | `team-flow` | 一刀切（package.json `name` + npm publish） |
| CLI 前缀 | `ssf` | `tf` | 一刀切（package.json `bin` + 99 处 npx 引用同步） |
| npx 安装方式 | `npx --yes --package spec-superflow@X.Y.Z ssf` | `npx --yes --package team-flow@X.Y.Z tf` | 保持 npx 远程安装（不改本地路径调用） |
| 状态文件（变更级） | `.spec-superflow.yaml` | `.team-flow.yaml` | 扁平文件（不进 `.team-flow/` 目录，与产品级 `.team-flow/` 平级区分） |
| 脚本文件名 | `spec-superflow.mjs` | `team-flow.mjs` | 一刀切（1 文件重命名 + 多处引用同步） |
| 配置文件 | `spec-superflow.config.json` | `team-flow.config.json` | 一刀切 |
| 存量项目迁移 | 存量 change 目录下有 `.spec-superflow.yaml` | 自动迁移到 `.team-flow.yaml` | `tf doctor` 检测 + 一键迁移脚本 |

### 27.2 影响面评估（721 处引用）

| 类别 | 引用数 | 分布 | 迁移动作 |
|------|--------|------|---------|
| npx 包引用 | 99 | 18 个 skill 文件（workflow-start / spec-writer / contract-builder / build-executor / release-archivist / code-reviewer / bug-investigator / need-explorer / spec-merger + 各自 references/） | `--package spec-superflow@X.Y.Z` → `--package team-flow@X.Y.Z` |
| CLI 命令 | 217 | 同上 + 测试文件 | `ssf` → `tf`（含 `npx ... ssf` → `npx ... tf`） |
| 状态文件名 | 111 | skills/ + tests/ + scripts/ | `.spec-superflow.yaml` → `.team-flow.yaml` |
| 脚本文件名 | ~30 | tests/ + scripts/ 引用 | `spec-superflow.mjs` → `team-flow.mjs` |
| 配置文件名 | ~5 | scripts/ + tests/ | `spec-superflow.config.json` → `team-flow.config.json` |
| 文档/描述 | ~259 | AGENTS.md / README.md / CHANGELOG.md / docs/ / skills/*.md 描述文本 | `spec-superflow` → `team-flow`（描述性文本） |

### 27.3 迁移步骤（P2 实施清单）

#### 步骤 1：package.json 重命名

```json
{
  "name": "team-flow",
  "bin": {
    "tf": "./scripts/team-flow.mjs",
    "team-flow": "./scripts/team-flow.mjs"
  }
}
```

移除旧 `ssf` / `spec-superflow` 别名（一刀切，不保留过渡期）。

#### 步骤 2：脚本文件重命名

```bash
mv scripts/spec-superflow.mjs scripts/team-flow.mjs
```

同步更新所有引用 `spec-superflow.mjs` 的测试文件（~30 处）。

#### 步骤 3：状态文件名迁移

```bash
# 脚本层：state-loader.mjs / cmd-state.mjs / hash.mjs 等
# 搜索 `.spec-superflow.yaml` → 替换为 `.team-flow.yaml`
```

111 处引用全量替换（skills/ + tests/ + scripts/）。

#### 步骤 4：npx 引用全量替换

```bash
# 18 个 skill 文件中 99 处
# `npx --yes --package spec-superflow@X.Y.Z ssf`
# → `npx --yes --package team-flow@X.Y.Z tf`
```

#### 步骤 5：配置文件名迁移

```bash
# `spec-superflow.config.json` → `team-flow.config.json`
```

~5 处引用全量替换。

#### 步骤 6：文档/描述文本替换

```bash
# AGENTS.md / README.md / CHANGELOG.md / docs/ / skills/*.md 描述文本
# `spec-superflow` → `team-flow`（仅描述性，不改代码标识符）
```

~259 处全量替换。

#### 步骤 7：存量项目自动迁移脚本

在 `scripts/lib/cmd-doctor.mjs` 中增加迁移检查：

```javascript
// 检测存量 .spec-superflow.yaml
// 提示用户运行 `tf doctor --migrate` 一键迁移
// 迁移动作：mv .spec-superflow.yaml .team-flow.yaml
```

#### 步骤 8：npm publish

```bash
cd team-flow && npm publish
```

发布 `team-flow@0.23.0` 到 npm registry。

#### 步骤 9：pre-commit hook 增强

在 `scripts/install-git-hooks.mjs` 中增加发布状态检查：

```javascript
// pre-commit hook:
// 1. 读 package.json version
// 2. npm view team-flow@<version> → 404?
//    → WARN: "version X.Y.Z not published, run npm publish"
//    → 阻断提交（或 advisory 警告）
```

防止再次出现"本地版本号领先 npm"的断裂。

### 27.4 需修订的文件清单

| 文件 | 修订内容 |
|------|---------|
| `package.json` | `name` 改 `team-flow`、`bin` 改 `tf` / `team-flow`、移除 `ssf` / `spec-superflow` |
| `scripts/spec-superflow.mjs` → `scripts/team-flow.mjs` | 文件重命名 + 内部引用 `.spec-superflow.yaml` → `.team-flow.yaml` |
| `scripts/lib/*.mjs` | 状态文件名引用全量替换（state-loader / cmd-state / hash / infer-workflow 等） |
| `scripts/check-version-consistency.mjs` | 检查范围扩展到配置文件名 |
| `scripts/install-git-hooks.mjs` | 增加发布状态检查 |
| `scripts/lib/cmd-doctor.mjs` | 增加存量 `.spec-superflow.yaml` 检测 + `--migrate` 迁移命令 |
| `skills/**/SKILL.md` + `skills/**/references/*.md` | 99 处 npx 引用 + 217 处 CLI 命令全量替换 |
| `tests/**/*.mjs` | 111 处状态文件名 + ~30 处脚本文件名 + ~5 处配置文件名全量替换 |
| `AGENTS.md` / `README.md` / `CHANGELOG.md` | 描述文本 `spec-superflow` → `team-flow` |
| `docs/**/*.md` | 描述文本替换 |
| `docs/roadmap-and-todos.md` | P1-6 状态更新为 ✅ |

### 27.5 风险与缓解

| 风险 | 缓解 |
|------|------|
| npm 发布后用户仍在用旧 `spec-superflow` 包 | 在 `spec-superflow` 包发布 deprecation notice，指引迁移到 `@xulthekl/team-flow` |
| 存量项目 `.spec-superflow.yaml` 未迁移导致 workflow 断裂 | `tf doctor` 自动检测 + `--migrate` 一键迁移 |
| 99 处 npx 引用替换遗漏 | `check-version-consistency.mjs` 扩展扫描 + pre-commit hook 拦截 |
| pre-commit hook 误报（本地开发未 publish 时阻断） | 默认 advisory 模式，可通过环境变量 `TF_SKIP_PUBLISH_CHECK=1` 跳过 |

### 27.6 第三阶段：npm 包 scope 化（v0.22.4，2026-07-27）

#### 27.6.0 问题诊断

| 断点 | 现象 | 根因 |
|------|------|------|
| npm publish E403 | `npm publish team-flow@0.22.3` 报 403 Forbidden: "Two-factor authentication required" | npm 强制 scoped/unscoped public package 发布需 2FA 或 Granular Access Token (bypass 2FA) |
| macOS 密码 App 不生成 TOTP | 用户 macOS 密码 App 绑定 npm 2FA，但 CLI publish 时浏览器跳转 passkey 认证后仍报 E402 | npm CLI `--otp` 需要 TOTP 6 位验证码，passkey 浏览器授权是另一套机制，CLI 不识别 |
| `team-flow` 包名被占 | 即便解决 2FA，`team-flow` 作为 unscoped 包名可能已被其他用户/组织注册 | npm 全局命名空间冲突 |

#### 27.6.1 迁移决策（LT 确认）

| 维度 | 现状 | 目标 | 策略 |
|------|------|------|------|
| npm 包名 | `team-flow` | `@xulthekl/team-flow` | Scoped package（用户 npm 账号 `xulthekl` 下，天然私有命名空间） |
| author | `MageByte` | `xulthekl` | 与 npm 账号对齐 |
| 认证方式 | npm login + TOTP | Granular Access Token（bypass 2FA） | Token 保存在 `docs/npm-token`，已加入 `.gitignore` |

#### 27.6.2 影响面评估（179 处引用）

| 类别 | 引用数 | 分布 | 迁移动作 |
|------|--------|------|---------|
| npx 包引用 | 179 | skills/ + scripts/ + tests/ 中所有 `npx --package team-flow@X.Y.Z` | `--package team-flow@X.Y.Z` → `--package @xulthekl/team-flow@X.Y.Z` |
| 正则字面量 | 6 | `check-version-consistency.mjs` / `cmd-version.mjs` / `install.mjs` / `cmd-install-workbuddy.mjs` / `install-zcode.mjs` / `install-cursor.mjs` | 正则中 `/` 需转义为 `\/`（`/@xulthekl\/team-flow@/g`） |
| 版本文件 | 15 | `plugin.json` / `marketplace.json` / `phase-guard.md` / `llms.txt` / `INSTALL.md` / `README.md` / `GEMINI.md` 等 | bump 0.22.3 → 0.22.4 |

#### 27.6.3 迁移步骤（P2 实施清单）

**步骤 1：package.json 改名 + 改 author**

```json
{
  "name": "@xulthekl/team-flow",
  "version": "0.22.4",
  "author": "xulthekl"
}
```

**步骤 2：npx 引用全量替换（179 处）**

```bash
# skills/ + scripts/ + tests/ 中所有
# `npx --yes --package team-flow@X.Y.Z tf`
# → `npx --yes --package @xulthekl/team-flow@X.Y.Z tf`
```

**步骤 3：正则字面量转义（6 个脚本文件）**

```javascript
// 旧：/npx --yes --package team-flow@(\d+\.\d+\.\d+) tf/g
// 新：/npx --yes --package @xulthekl\/team-flow@(\d+\.\d+\.\d+) tf/g
// 注：正则字面量中 / 必须转义为 \/
```

**步骤 4：版本号 bump（15 个文件）**

```bash
# plugin.json / marketplace.json / phase-guard.md / llms.txt / INSTALL.md / README.md / GEMINI.md 等
# 0.22.3 → 0.22.4
```

**步骤 5：npm publish（scoped + public）**

```bash
cd team-flow && npm publish --access public --registry https://registry.npmjs.org
```

注：scoped package 默认 private，需显式 `--access public`。

**步骤 6：验证**

```bash
npm view @xulthekl/team-flow@0.22.4
# 输出：name = '@xulthekl/team-flow', version = '0.22.4', author = 'xulthekl'
```

#### 27.6.4 需修订的文件清单

| 文件 | 修订内容 |
|------|---------|
| `package.json` | `name` 改 `@xulthekl/team-flow`、`author` 改 `xulthekl`、`version` bump `0.22.4` |
| `scripts/check-version-consistency.mjs` | 正则 `team-flow@` → `@xulthekl\/team-flow@` |
| `scripts/lib/cmd-version.mjs` | 12 个 skill 文件版本替换正则更新 |
| `scripts/lib/install.mjs` / `cmd-install-workbuddy.mjs` | npx 正则更新 |
| `scripts/install-zcode.mjs` / `install-cursor.mjs` | npx 正则更新 |
| `skills/**/SKILL.md` + `skills/**/references/*.md` | 179 处 npx 引用 `package team-flow@` → `package @xulthekl/team-flow@` |
| `tests/lib/platform-runtime-distribution.test.mjs` | PREFIX 常量更新 |
| `plugin.json` / `.claude-plugin/plugin.json` / `.cursor-plugin/plugin.json` 等 9 个安装面 | version bump 0.22.4 |
| `.claude/always/phase-guard.md` / `GEMINI.md` / `llms.txt` | 版本戳 bump 0.22.4 |
| `INSTALL.md` / `README.md` / `docs/README_en.md` | 版本戳 bump 0.22.4 |
| `CHANGELOG.md` | 新增 `[0.22.4]` 条目 |
| `docs/npm-token` | 新增文件，保存 Granular Access Token，已加入 `.gitignore` |

#### 27.6.5 风险与缓解

| 风险 | 缓解 |
|------|------|
| scoped package 默认 private，用户安装失败 | `npm publish --access public` 显式公开；INSTALL.md 已更新为新包名 |
| 存量项目仍引用旧 `team-flow@`（无 scope） | `tf doctor` 扩展检测：发现 `package team-flow@` 无 scope 即提示升级 |
| Granular Access Token 泄露 | `docs/npm-token` 已加入 `.gitignore`；Token 设置 30 天过期 + 仅 write scope |
| 正则 `/` 未转义导致 SyntaxError | 6 个脚本文件已全部 `\/` 转义；`check-version-consistency.mjs` 跑通验证 |

---

*v0.9 §27 由 CC 基于 LT 确认的决策增量修订，覆盖 P1-6 三阶段：*
- *第一阶段 v0.15.0：产品级状态文件 `.team-flow/` 化*
- *第二阶段 v0.22.3：spec-superflow → team-flow 全量一刀切迁移（npm 包名 + CLI 前缀 + 状态文件 + 脚本文件 + 配置文件 + 文档描述）721 处引用同步*
- *第三阶段 v0.22.4：npm 包 scope 化 `@xulthekl/team-flow`（解决 npm publish 权限冲突）179 处引用同步*

*全案 900+ 处引用同步，零功能逻辑改动。存量项目通过 `tf doctor` 自动迁移。*

---

## 二十八、制品链评审与修复（v0.22.5）

### 28.0 问题诊断

> 触发来源：LT 要求"对所有阶段的制品的关联、衔接进行评审，评审设计是否合理、制品链的约束是否完整，输入输出制品是否明确"。CC 组织 Workflow 编排 7 个并行代理（4 组 Skill IO 提取 + 2 个代码验证 + 1 个交叉验证），对 23 个 skill 的输入/输出/上下游/触发条件/约束/状态写入进行系统性评审，产出 16 条 findings（2 Critical + 6 Major + 4 Minor + 4 Info）。

> CC 作为 team-flow 负责人逐条验证后，最终接纳 5 条、不接纳 2 条、部分接纳 1 条。

#### 不接纳的误报

| ID | 评审结论 | 不接纳原因 |
|----|---------|-----------|
| F01 (Critical) | dp_4_result 写入路径断裂 | **误报**：评审代理只检查了 `cmd-state.mjs` 的 SETTABLE_FIELDS，未发现 `cmd-execution.mjs:151-152` 通过 `writeState()` 直接写入 dp_4_result（绕过 SETTABLE_FIELDS 白名单）。这是有意设计——dp_4 是 execution plan 的产物，由 `tf execution plan` 命令专门处理 |
| F04 (Major) | artifact-contract.md 孤儿输入 | **误报**：评审代理误解了 "artifact-contract" 的含义。contract-builder 实际读取的是 `templates/execution-contract.md`（模板文件，3.4KB），不是 `docs/artifact-contract.md` |

### 28.1 接纳的问题与修复方案

#### F02 + F06 (Critical): arch_design_* 字段无代码支持 + 权责矛盾

**根因**：
- `architecture-design` SKILL.md 的 `state_writes: []`（未声明）
- `workflow-start` SKILL.md 的 `state_writes` 包含 `arch_design_*`（声明了但不执行判断）
- `cmd-state.mjs` SETTABLE_FIELDS 不包含这些字段
- 代码层无任何脚本写入这些字段
- 权责矛盾：workflow-start 声明写入但不执行判断，architecture-design 执行判断但不声明写入

**修复方案**（v0.22.5 P0）：

1. **state-loader.mjs**：BUILTIN_DEFAULTS 增加 4 个字段 + writeState 序列化
   ```javascript
   // BUILTIN_DEFAULTS
   arch_design_decision: null,
   arch_design_reason: null,
   arch_design_timestamp: null,
   arch_design_artifacts: null,
   
   // writeState 序列化
   lines.push('');
   lines.push('# === Architecture design gate (v0.9 §26) ===');
   lines.push(`arch_design_decision: ${state.arch_design_decision ?? 'null'}`);
   lines.push(`arch_design_reason: ${state.arch_design_reason ?? 'null'}`);
   lines.push(`arch_design_timestamp: ${state.arch_design_timestamp ?? 'null'}`);
   lines.push(`arch_design_artifacts: ${state.arch_design_artifacts ?? 'null'}`);
   ```

2. **cmd-state.mjs**：SETTABLE_FIELDS 增加 4 个字段
   ```javascript
   'arch_design_decision', 'arch_design_reason',
   'arch_design_timestamp', 'arch_design_artifacts',
   ```

3. **architecture-design/SKILL.md**：移除错误的"状态写入"章节，明确职责边界为"判断+产出"
4. **workflow-start/SKILL.md**：增加"State Writes"章节，声明负责 `arch_design_*` 的 reasonableness check + 状态写入

**职责边界（修正后）**：
- architecture-design：负责**判断+产出**（五项检查判断是否涉及架构变更，涉及则产出架构设计文档）
- workflow-start：负责**reasonableness check + 状态写入**（确认判断合理性后写入 yaml）

**验证方法**：
```bash
# 1. 初始化 change
mkdir -p changes/test-arch && npx tf state init changes/test-arch

# 2. 写入 arch_design_decision
npx tf state set changes/test-arch arch_design_decision "skipped"
npx tf state set changes/test-arch arch_design_reason "不涉及架构变更"
npx tf state set changes/test-arch arch_design_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
npx tf state set changes/test-arch arch_design_artifacts ""

# 3. 验证字段写入
npx tf state get changes/test-arch arch_design_decision
# 期望输出：skipped

cat changes/test-arch/.team-flow.yaml | grep arch_design
# 期望输出：4 个 arch_design_* 字段及其值
```

#### F07 (Major): change-brief.md 缺少模板

**根因**：
- `s4-split-validate.md` 有详细的 brief_schema 定义（5 个 frontmatter 字段 + 6 个 body sections）
- 但 `templates/` 目录无对应模板文件
- orchestrator S4 每次生成 brief 都是 LLM 自由发挥，结构可能不一致

**修复方案**（v0.22.5 P1）：
- 创建 `templates/change-brief.md`，内容基于 `s4-split-validate.md` 的 brief_schema
- frontmatter：`upstream_source` / `upstream_req_id` / `upstream_plan_ref` / `upstream_change_id` / `plan_hash`
- body：`# Change Brief` / `## Scope` / `## 约束` / `## AC 列表` / `## 全局技术方向` / `## PRD & plan 引用`

#### F08 (Major): architecture/*.md 缺少模板

**根因**：
- `architecture-design` SKILL.md 要求产出 `architecture.md` / `database.md` / `api.md`
- 基于 4A+DDD 框架有复杂结构要求（聚合、限界上下文、CQRS、API 分流等）
- 但 `templates/` 目录无对应模板

**修复方案**（v0.22.5 P1）：
- 创建 `templates/architecture.md`：包含 As-Is 基线冻结、To-Be DDD 增量设计（聚合/限界上下文/Context Map/CQRS）、变更分叉级联分析、跨域一致性检查、演进日志
- 创建 `templates/database.md`：包含 As-Is 基线冻结、To-Be 增量设计（写模型/读模型/Schema 变更/实体关系/数据迁移脚本）、演进日志
- 创建 `templates/api.md`：包含 As-Is 基线冻结、To-Be 增量设计（Command API/Read API/Query API/端点详细设计/跨域一致性检查）、演进日志

#### F05 (Major): ce-ideate → ce-brainstorm 制品链断裂

**根因**：
- `ce-ideate` SKILL.md 声明 outputs 包含 `docs/ideation/*.md`
- `ce-ideate` downstream 声明 `ce-brainstorm`
- 但 `ce-brainstorm` SKILL.md 的 inputs 未声明消费 `docs/ideation/*.md`

**修复方案**（v0.22.5 P2）：
- 在 `ce-brainstorm` SKILL.md 的 "Feature Description" 前增加 "Optional Inputs" 章节
- 声明：`docs/ideation/*.md`（可选）——如果 ce-ideate 已产出 ideation artifact，读取作为 brainstorm 的起点
- 在 Feature Description 段增加：`If docs/ideation/*.md exists, read it first and use its ranked ideation content as the starting point for the brainstorm.`

#### F03 (Major, 部分接纳): DP-0 多路径不一致

**根因**：
- hotfix/tweak 路径跳过 need-explorer 和 spec-writer
- 但 workflow-start SKILL.md 未明确说明 DP-0 的处理策略

**修复方案**（v0.22.5 P3）：
- 在 `workflow-start` SKILL.md 的 "Fast-Path Routing" 段增加说明：
  > **DP-0 处理**（v0.22.5 F03 修复）：hotfix/tweak 路径隐式跳过 DP-0（`dp_0_confirmed` 保持 `null`），因为意图已明确（修复/微调），无需从零探索。contract-builder 的 DP-3 审批成为唯一门禁。

### 28.2 修复优先级与工作量

| 优先级 | Finding | 修复工作量 | 影响范围 | 状态 |
|--------|---------|-----------|----------|------|
| **P0** | F02+F06 (arch_design_*) | 30 分钟 | architecture-design 门控 | ✅ 已修复 |
| **P1** | F07 (brief 模板) | 45 分钟 | orchestrator → change 衔接 | ✅ 已修复 |
| **P1** | F08 (architecture 模板) | 60 分钟 | architecture-design 产出一致性 | ✅ 已修复 |
| **P2** | F05 (ideation 链) | 10 分钟 | ce-ideate → ce-brainstorm 衔接 | ✅ 已修复 |
| **P3** | F03 (DP-0 说明) | 15 分钟 | hotfix/tweak 路径清晰度 | ✅ 已修复 |

### 28.3 需修订的文件清单

| 文件 | 修订内容 |
|------|---------|
| `scripts/lib/state-loader.mjs` | BUILTIN_DEFAULTS 增加 4 个 arch_design_* 字段 + writeState 序列化 |
| `scripts/lib/cmd-state.mjs` | SETTABLE_FIELDS 增加 4 个 arch_design_* 字段 |
| `skills/architecture-design/SKILL.md` | 移除错误的"状态写入"章节，明确职责边界为"判断+产出" |
| `skills/workflow-start/SKILL.md` | 增加"State Writes"章节（声明 arch_design_* 写入权责）+ Fast-Path Routing 增加 DP-0 处理说明 |
| `skills/ce-brainstorm/SKILL.md` | 增加"Optional Inputs"章节（声明消费 `docs/ideation/*.md`） |
| `templates/change-brief.md` | 新增模板（基于 s4-split-validate.md 的 brief_schema） |
| `templates/architecture.md` | 新增模板（4A+DDD 增量设计结构） |
| `templates/database.md` | 新增模板（CQRS 增量设计结构） |
| `templates/api.md` | 新增模板（Command/Read/Query 增量设计结构） |

### 28.4 风险与缓解

| 风险 | 缓解 |
|------|------|
| arch_design_* 字段写入后，存量 change 的 .team-flow.yaml 缺少这些字段 | `readState()` 合并 BUILTIN_DEFAULTS，缺失字段默认为 `null`，不影响存量项目 |
| 新增模板与现有 LLM 产出不一致 | 模板基于 SKILL.md 和 s4-split-validate.md 的结构定义，LLM 应遵循模板生成 |
| routing-rules.md 中的 `tf state set` 命令版本号为 0.22.4 | pre-commit hook 自动同步所有 npx 引用版本号到 0.22.5 |

---

*v0.9 §28 由 CC 基于制品链评审（Workflow 编排 7 代理并行，401k tokens，82 tool calls）产出 16 条 findings，逐条代码验证后接纳 5 条、不接纳 2 条误报、部分接纳 1 条。P0-P3 全部修复，涉及 3 个脚本文件 + 3 个 SKILL.md + 4 个模板文件。*
