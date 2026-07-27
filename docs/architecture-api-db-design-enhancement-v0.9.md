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

## 二十四、拆分维度治理（v0.22.0，待办 1）

### 24.0 问题诊断

产品阶段 change 拆分维度此前**没有正向钉死**：实际维度散落在 ce-plan `references/change-splitting.md`（"one bounded context or one coherent feature area"）与审计基线（"功能点 / 用户故事 / AC"混合），bounded context（架构话语）与 user story（需求话语）两套词并存未对齐；且"拆得过细"在审计中是**唯一不触发 FAIL 的纯 advisory 维度**（D3），无硬门禁；缺"一个迭代 PRD = 多用户故事/多模块合集"的认知声明。

> 承袭说明：v0.7 §17.2 为 change 拆分的原始设计锚点，但该文件在本仓库不存在。下述正向定义**自包含**给出，不依赖 v0.7 §17.2 原文。

### 24.1 正向定义（自包含，全文）

**认知声明**：一个迭代版本的 PRD 通常是**多个用户故事或多个功能模块的合集**；ce-plan 拆 change 时必须认识到这一点，拆分应**跟着用户故事 / 功能模块走**，而不是跟着接口、文件或任务走。

**拆分维度（硬约束）**：每个 change 的 scope 必须是**一个用户故事**（角色-动作-价值）或**一个内聚功能模块**（如"下单""报表导出""权限体系"）。这与 DDD 的 bounded context 对齐——一个 bounded context 内的一个内聚功能域 = 一个 change。scope 以故事/模块命名，**内部可含多个接口/文件/任务**（这些留给 spec-writer 在 tasks.md 拆）。

**为何不拆细（正向理由）**：变更级 spec-writer 还有 proposal / specs / design / tasks 四层产物 + 实施 task 拆分；产品阶段拆到接口 / 任务级 = **越界做变更级设计**（违反 ce-plan 作用边界，见 §24.3 / v0.8 §18.7.3）+ **重复劳动**（变更层会再拆一遍）。产品阶段的 change 粒度目标止于"用户故事 / 功能模块"，这是变更阶段能**并行设计与实施**的前提。

**反模式（硬约束）**：scope 主体是单个接口路径（`/api/xxx`）、单个文件、单个方法/函数、单条 SQL、单个 task 动作（"添加字段""写校验"）→ 这是实现单元，不是故事/模块，禁止独立成 change。
- 反例：scope = "实现 `/api/order/create` 接口" → 维度错配。
- 正例：scope = "订单下单用户故事（含创建接口 + 库存校验 + 下单页）" → 维度正确（内含的多实现单元正是留给 spec-writer 的层级）。

### 24.2 D5 拆分维度合规硬门禁

`change-split-auditor` 在原有 D1-D4 基础上新增 **D5 拆分维度合规**，**severity = Critical**（进 PASS/FAIL 判定）。

**判定信号**（scope 文本特征）：实现单元信号（单接口/单文件/单方法/单 SQL/单 task 动作）→ Critical；故事/模块信号（以角色-动作-价值或功能模块命名、内含多实现单元）→ PASS。与 D1 复用覆盖单位：若某 change 的 scope 无法映射到 D1 的任何覆盖单位、只能映射到实现单元 → 维度错配。

**Critical 的理由**：维度错配使变更级 spec-writer 的四层产物无从展开——spec 需要"行为"，单接口 scope 给不出行为边界；且与 ce-plan 作用边界硬声明直接冲突，属结构性缺陷而非程度问题。

**安全港（防误杀）**：① 单 change 计划（整 PRD 仅一个 change）整体豁免——无"拆分"可言；② 仅对多 change 计划中被拆细到实现单元的 change 判 Critical；③ hotfix / 单 change 快速通道不经本审计，天然豁免。

**与 D3 正交（不矛盾）**：D3 管数值粒度（太大/太小，advisory，Important，明确不 FAIL）；D5 管维度对错（故事/模块 vs 接口/文件，Critical）。一个 change 可粒度很小但维度正确（极小独立功能模块：D3 flag、D5 PASS）；也可粒度适中但维度错配（"三个接口的打包"：D3 无异常、D5 FAIL）。二者正交，不重叠。

**判定表更新**：Critical = coverage gap, DAG cycle, dangling dependency reference, **splitting-dimension violation (D5)**；Important 集合不变。

### 24.3 与 ce-plan 作用边界呼应

ce-plan SKILL.md「作用边界」硬声明（v0.8 §18.7.3 确立，v0.9 追加拆分维度一句）：

> **ce-plan = 产品级策略**：change 拆分（scope+依赖+优先级+复杂度）、change 依赖 DAG、技术方向决策、风险与里程碑。**产品阶段拆到用户故事/功能模块即止**——拆分维度是用户故事或内聚功能模块（见 ce-plan `references/change-splitting.md` v0.9 正向定义），接口/文件/任务级拆分属变更级 spec-writer。
> **ce-plan ≠ 变更级详细设计**：接口清单、字段定义、方法签名、文件级 Implementation Unit 一律属各 change 的 spec-writer / architecture-design，不进 plan.md。

D5 硬门禁即作用边界在审计层的强制落点：作用边界说"接口/文件级不进 plan"，D5 说"若 plan 把 change 拆到接口/文件级则 FAIL"，二者闭环。

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
    - change 拆分维度正向钉死为「用户故事 / 功能模块」+「大 PRD = 多故事/多模块合集」认知声明（§24.1，ce-plan `change-splitting.md` + SKILL.md 作用边界）：✅ 已实施于 v0.22.0。
    - `change-split-auditor` 新增 D5 拆分维度合规硬门禁（Critical，与 D3 正交，含单 change 安全港）（§24.2）：✅ 已实施于 v0.22.0。
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
