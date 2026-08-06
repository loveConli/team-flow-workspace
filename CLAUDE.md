# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

本工作区的核心目标是**开发和测试 team-flow 工作流**。team-flow 是一个统一插件（24 skills + 15 agents），整合了 spec-superflow（9）、compound-engineering（6）、architecture-design（1）、prototype（1）、design-system（1）、workflow-orchestrator（1）、workflow-bootstrap（1）、e2e（1）、session-handoff（1）、workflow-feedback（1）、test-strategy（1）。

- **设计增强方案当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.17.md`
- **插件版本**：`v0.39.1`（24 skills + 15 agents；0.32.0 打包事故撤回，版本号不可复用）
- **测试能力增强方案**：`docs/plan/test-capability-enhancement-design.md`（v0.34.0 新增，conventions 机制 + glaf4-test 通用能力吸收）
- **工作空间支持**：conventions-generator 支持多子项目扫描（v0.34.1 新增）

## 工作区结构

```
team-flow-workspace/
├── docs/                          # 设计文档（工作区级）
│   ├── architecture-api-db-design-enhancement-v0.17.md # ★ 当前权威版本
│   ├── architecture-api-db-design-enhancement-v0.16.md # 历史保留版本
│   ├── architecture-api-db-design-enhancement-v0.15.md # 历史保留版本
│   ├── architecture-api-db-design-enhancement-v0.14.md # 历史保留版本
│   ├── architecture-api-db-design-enhancement-v0.12.md # 历史保留版本
│   ├── architecture-api-db-design-enhancement-v0.11.md # 历史保留版本
│   ├── roadmap-and-todos.md       # Roadmap + 待办列表（从本文件抽取）
│   ├── design-doc-system.md       # 设计文档体系 + 版本规则（从本文件抽取）
│   ├── doc-maintenance.md         # 文档维护规范 + 同步清单（从本文件抽取）
│   ├── dev-reference.md           # 开发命令 + 产物结构 + 配置（从本文件抽取）
│   ├── external-references/       # 外部参考资料
│   └── plan/                      # 实现计划
├── tests/                         # 无头测试脚本和输出
├── .claude/skills/                # 项目级 skill（team-flow-e2e-test）
└── team-flow/                     # 核心工具库（独立 Git 仓库）
```

## 按需加载参考

以下内容已抽取到独立文件，**按需读取，不要一次性全部加载**：


| 场景                   | 读取文件                        |
| -------------------- | --------------------------- |
| 迭代规划、检查待办、更新 Roadmap | `docs/roadmap-and-todos.md` |
| 设计文档维护、版本规则、文档层级     | `docs/design-doc-system.md` |
| P4 同步阶段、迭代同步清单、一致性校验 | `docs/doc-maintenance.md`   |
| 开发命令、产物结构、配置项        | `docs/dev-reference.md`     |


## 工作流 SOP

```
模糊需求
  → [既有项目接入层 workflow-bootstrap]（一次性，已有 baseline.md 则跳过）
       B1 代码库侦察（recon-probe.sh + codebase-recon-analyst 并行子代理）
       → B2 架构基线文档化 → B3 领域词汇提取 → B4 目录初始化
  → [产品级编排层 workflow-orchestrator]
  → S1 路径路由器 → 需求选择（.team-flow/registry.yaml）+ 判断入口路径
  → S2 PRD + 原型 → ce-brainstorm + prd-completeness-reviewer + prototype 内部编排器 → 冻结
  → S3 计划 → ce-plan（plan_mode 入口问定）→ plan.md（change 拆分+依赖+高阶技术方向，不含接口清单）
  → [ARCH 产品级架构设计（v0.36.0 新增）] → architecture-design product 模式 8 步设计 → docs/architecture/iterations/vN/architecture.md（6 产物快照，预测态，不写全局）→ 产品级评审门（architecture-reviewer product 视角）→ skip 须物化
  → S4 拆分验证与分发 → arch-readiness 门（快照覆盖 change 触及 BC；arch_baseline 缺失 → WARN 不阻断）→ change-split-auditor 审计（必选）→ 创建 changes/<name>/ + change-brief.md
  → S5 全局监控（change≥2 必选）→ 跨 change 一致性 + 复利晋升 + 动态重规划
  → [复利贯穿层] 每个阶段转换点：检测→捕获→索引→注入
  → change 完成：arch-merge → prototype-sync + 复利晋升
```

### 变更级状态机（workflow-start 编排，state-loader.mjs 驱动）

```
exploring → [architecture-design 判断门 ★设计层面] → specifying → bridging → approved-for-build → executing → closing
              (五项检查→required/skipped)                                                              ↕ debugging
```

**代码强制执行点**：
- `.team-flow.yaml` 的 `state` 字段（guard.mjs 校验状态转换合法性）
- `artifacts_hash`（proposal + specs + design + tasks + architecture/*.md 的 hash）
- `contract_hash`（execution-contract.md 的 hash）
- `spec_merged` + `test_result`（closing 前置条件）
- `arch_design_decision`（guard.mjs arch-design 维度，required 时硬阻断 exploring→specifying）

**设计层面约定（SKILL.md 文档约束）**：
- architecture-design 判断门——`tf state set arch_design_*` 命令已全链路贯通（v0.22.5+），state-loader/cmd-state/guard/hash 四处一致
- change-brief.md 交接——orchestrator S4 prompt 指示 LLM 手写，无脚本、无模板
- architecture/ 三件套产出与消费——architecture/*.md 已纳入 `artifacts_hash`（v0.23.0 §30），guard.mjs 有 `arch-design` 维度（`arch_design_decision: required` 时硬阻断 exploring→specifying）

## 产物结构（代码验证版）

### 代码强制执行的制品（state-loader.mjs + hash.mjs）

| 产物 | 路径 | 校验机制 |
|------|------|---------|
| 状态文件 | `changes/<name>/.team-flow.yaml` | state-loader 硬编码 `STATE_FILE` |
| 提案 | `changes/<name>/proposal.md` | hash.mjs → `artifacts_hash` |
| 规格 | `changes/<name>/specs/*.md` | hash.mjs → `artifacts_hash` |
| 设计 | `changes/<name>/design.md` | hash.mjs → `artifacts_hash` |
| 任务 | `changes/<name>/tasks.md` | hash.mjs → `artifacts_hash` |
| 执行契约 | `changes/<name>/execution-contract.md` | hash.mjs → `contract_hash` |

### 设计层面约定的制品（SKILL.md 文档引用，无代码强制校验）

| 产物 | 路径 | 状态 |
|------|------|------|
| 产品级 PRD | `prd/vN/prd.md` | ce-brainstorm 引用 |
| 产品级计划 | `prd/vN/plan.md` | ce-plan 引用 |
| 变更简报 | `changes/<name>/change-brief.md` | orchestrator S4 产出，hash.mjs 显式排除 |
| 架构设计 | `changes/<name>/architecture/{architecture,database,api}.md` | hash.mjs 纳入 artifacts_hash（v0.23.0），guard.mjs arch-design 维度（v0.22.5） |
| SDD 执行计划 | `changes/<name>/.superpowers/sdd/execution-plan.json` | 代码创建但不在 guard |
| 需求注册表 | `.team-flow/registry.yaml` | workflow-orchestrator 引用 |
| 全局架构基线 | `docs/architecture/baseline.md` | workflow-bootstrap 引用 |
| 产品级架构快照 | `docs/architecture/iterations/vN/architecture.md` | S3.5 ARCH 阶段产出（v0.36.0，预测态，不写全局） |
| 项目架构基线标记 | `.team-flow/arch-state.json` | `tf arch init` 打戳 `arch_baseline`（v0.36.0）；缺失 = 存量信号 → arch 门禁 WARN 不 FAIL |

> **全局架构三层维护（v0.36.0，v0.14 §57.3）**：L1 全局当前态（docs/architecture/，arch-merge 生成式：ARCHITECTURE marker 区 / PHYSICAL-MODEL / DATABASE / API-INDEX / INDEX）= 实际落地态唯一权威；L2 变更级增量（changes/<name>/architecture/）= 只写 delta；L3 迭代快照 + 演进日志 + changelog（iterations/vN/ + changelog/）= 预测态退役。回写时序：产品级设计只写快照，change 关闭时 arch-merge 回写实际增量，迭代收尾快照标 archived。

### 状态文件内置字段（state-loader.mjs BUILTIN_DEFAULTS）

**核心状态**：`state` / `workflow` / `revision`
**哈希校验**：`artifacts_hash` / `contract_hash`
**执行进度**：`execution_mode` / `execution_plan_hash` / `execution_plan_revision` / `batches_completed` / `test_result` / `spec_merged`
**变更标识**：`change_name` / `last_transition` / `last_transition_from` / `last_transition_to`
**决策点**：`dp_0_result` ~ `dp_7_result` + 对应 `_timestamp` / `dp_0_decisions` / `dp_0_confirmed`
**架构设计门控**：`arch_design_decision` / `arch_design_reason` / `arch_design_timestamp` / `arch_design_artifacts`（v0.22.5+ 已全链路贯通：state-loader BUILTIN_DEFAULTS → cmd-state SETTABLE_FIELDS → writeState 序列化 → guard arch-design 维度）
**架构审查**：`arch_review_verdict` / `arch_review_rounds` / `arch_review_report`（v0.28.1 §36）
**DP-A 确认门**：`dp_a_result` / `dp_a_timestamp` / `dp_a_adjustments`（v0.29.0 §37）
**复利门控**：`compound_skipped`（v0.24.0）
**测试矩阵门控**：`test_matrix_hash` / `test_matrix_skipped` / `test_matrix_skip_reason`（v0.12 §42.5 + v0.13 §48）+ `test_evidence_path`（v0.13 §50：tf test record 落盘的 runner 输出证据）
**版本标记**：`schema_version`（v0.13 §48.1：**不在 BUILTIN_DEFAULTS**，仅 `tf state init` 创建 change 时打戳；字段缺失 = 存量 change，是测试门禁的豁免键）

### 关键差异说明（v0.32.0 更新）

CLAUDE.md 和 AGENTS.md 中描述的工作流包含 architecture-design 门控（v0.9 §26）和 change-brief.md 交接等设计。代码实现与文档的差距已在 v0.22.5/v0.23.0 中修复：

| 设计承诺 | 代码现实（v0.32.0） |
|----------|----------|
| `arch_design_*` 字段持久化 | ✅ state-loader BUILTIN_DEFAULTS 含 4 字段、cmd-state SETTABLE_FIELDS 白名单包含、writeState 序列化到独立段落 |
| architecture-design 门控 BLOCK | ✅ guard.mjs `exploring:specifying` 含 `arch-design` 维度（`arch_design_decision: required` 时硬阻断，`null` 时透明放行兼容存量 change） |
| `architecture/*.md` 产出 | ✅ hash.mjs 白名单纳入 architecture/{architecture,database,api}.md（v0.23.0 §30），sql/*.sql 明确不纳入 |
| `change-brief.md` 交接 | 无脚本创建、无模板（hash 排除是有意设计，代码层零引用，纯文档产物） |
| 测试门禁（v0.13 硬化） | ✅ 豁免键 = `schema_version`（init 打戳，缺失 = 存量）；`test-matrix-ready` 挂 approved-for-build→executing（full）；`test-matrix-complete` 删除内容型豁免与 hash null 短路；`tests-passing` 只认 `tf test record` 程序化证据（非存量），dp_6_result 自述不再是证据（BUG-A 通道仅存量保留）；`test_result` 移出 SETTABLE_FIELDS；`tf execution review` 禁止 base==head |

**当前强制执行**的包括：核心 4+1 制品（proposal/specs/design/tasks + execution-contract）的状态管理 + architecture/*.md 的 hash 纳入 + arch-design guard 维度 + 测试门禁硬化（v0.32.0：矩阵入口门禁 + 程序化测试证据）。change-brief.md 仍为纯文档层产物（有意设计，不纳入 hash）。

## 文档治理规则

### 设计增强方案版本管理

- **当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.17.md`
- **历史版本**：v0.16/v0.15/v0.14/v0.13/v0.12/v0.11/v0.8 保留不删；v0.2/v0.3/v0.5/v0.7 已删除，可通过 `git log --all -- "docs/architecture-api-db-design-enhancement-v0.*.md"` 追溯
- **新版本规则**：重大设计变更时创建新版本文件，旧版本保留不删

### Roadmap 更新策略

- **版本发布时**：更新里程碑状态（✅ + 完成版本/日期）
- **待办完成时**：只更新状态列（✅ + 日期），不重新整理
- **新增待办时**：追加行，注明优先级和来源

## Git 管理规则

### 父级仓库（当前仓库）

- 管理工作空间级文档和目录结构
- `.gitignore` 忽略 `team-flow/` 子仓库目录
- 不跟踪子工程的任何文件

### 子工程（team-flow）

- 位于 `team-flow/` 目录，是独立的 Git 仓库
- 变更必须进入子目录单独提交：`cd team-flow && git add -A && git commit -m "..."`

### 升级后必做（强制规则）

1. **子仓库**：`npm version <new> --no-git-tag-version`（自动同步所有文件）+ 提交
2. **主项目空间**：更新 CLAUDE.md（版本号、skills 数量等）+ 提交

### 版本发布 Checklist

版本发布时（`npm version` 之后），**必须**完成以下事项：

1. **Roadmap 更新**：在 `docs/roadmap-and-todos.md` 中
   - 更新里程碑状态（标记 ✅ + 完成版本/日期）
   - 完成的待办标记 ✅ + 日期
   - 新增待办追加行（注明优先级和来源）
2. **CHANGELOG 更新**：记录本版本的变更内容
3. **设计文档检查**：如涉及重大设计变更，创建新版本设计文档（v0.8 → v0.9）
4. **一致性验证**：`npm run check-versions` + `npm test` 全部通过
5. **子仓库提交**：`cd team-flow && git add -A && git commit -m "vX.Y.Z: ..."`
6. **npm 发布**：`cd team-flow && npm publish --registry=https://registry.npmjs.org --//registry.npmjs.org/:_authToken="$(cat /Users/litong/Documents/work/code/practice/team-flow-workspace/docs/npm-token)"`
   - 本地 `.npmrc` 指向 npmmirror 镜像不支持发布，必须显式指定官方 registry + token 文件（绝对路径）
   - 发布成功后会自动创建 git tag
7. **主项目提交**：更新 CLAUDE.md 版本号 + 提交
8. **远程推送**（子仓库 → 父仓库，顺序不可反）：
   ```bash
   # 先推子仓库（npm 已发布，远程代码需同步）
   cd team-flow && git push
   # 再推父仓库（CLAUDE.md 版本号引用子仓库版本）
   cd .. && git push
   ```
   - 网络不稳定时 retry（GitHub 偶发 75s 超时），不要跳过此步骤
   - 推送失败 = 远程与本地不同步，后续协作会出问题

## 插件迭代工作流（强制规则）

```
P1 设计 → P2 实施 → P3 代码审查 → P4 验证 → P5 提交
```

| 阶段        | 动作                                                                                                                                                                | 工具                     |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| **P1 设计** | 更新设计增强方案 + LT 确认决策                                                                                                                                                | —                      |
| **P2 实施** | 新 skill→`/plugin-dev:skill-development`；新 agent→`/plugin-dev:agent-development`；新 hook→`/plugin-dev:hook-development`；新 command→`/plugin-dev:command-development` | plugin-dev 技能集         |
| **P3 代码审查** | 变更影响分析 + 跨文件一致性 + 设计-代码对齐（见下方详细规范）                                                                                                                          | —                      |
| **P4 验证** | ① plugin-validator ② skill-reviewer ③ `npm run check-versions` ④ `npm test`                                                                                       | plugin-dev agent + npm |
| **P5 提交** | 子仓库 `npm version` + commit → `npm publish`（官方 registry）→ 父仓库 commit + 更新版本号                                                                            | 见 Git 管理规则 + 版本发布 Checklist |

**P3 代码审查规范**：

实施完成后、自动化验证前，执行以下审查（人工 + 辅助工具）：

1. **变更清单确认**：`git diff --stat` 列出所有改动文件，确认每个文件的改动都属于本次迭代范围（无遗漏、无越界）
2. **上下游影响分析**：对每个改动文件，检查其消费者/依赖者是否需要同步修改。典型场景：
   - SKILL.md 改了流程 → references/ 是否需要同步？
   - agent frontmatter 改了 tools/skills → 子代理行为是否受影响？
   - CLI 命令改了参数 → 帮助文本、测试用例是否同步？
   - 新增导出函数 → 有无对应的 import 消费者？
3. **跨文件一致性**：改动涉及多文件时，检查命名、术语、版本号、行号引用是否一致
4. **设计-代码对齐**：实现是否与 P1 设计文档一致？偏差是否有记录？
5. **横展检查**：本次改动解决的问题，是否在类似区域存在同类问题？（CLAUDE.md 已要求"对类似区域进行横展"）
6. **制品链关联校验**：制品的结构、位置、新增或删除变更时，必须遍历其所有引用点（guard 维度、SKILL.md 依赖声明、hash.mjs 白名单、state-loader 字段定义等）同步更新，确保制品链完整无断链

审查产出：确认通过 / 列出待修复项。待修复项全部解决后才能进 P4。

**约束**：

- P1 未完成（设计文档未更新 / LT 未确认）→ 不进 P2
- P3 未通过（存在未修复的审查项）→ 不进 P4
- P4 的 check-versions 和 plugin-validator 是门禁，不通过 → 不进 P5
- P5 提交时 pre-commit hook 自动执行版本一致性检查和修复
- 新 SKILL.md ≤150 行，详细内容进 references/（渐进式披露）

**自动化同步（pre-commit hook）**：

- skill 计数自动更新（plugin.json, AGENTS.md, README.md）
- npx 引用自动更新（skills/*/SKILL.md, skills/*/references/*.md）
- 修复后自动 re-stage，确保包含在提交中
- 绕过方式：`git commit --no-verify`（仅限紧急情况）

## 关键路径约束

- **change 目录位置**：项目根 `changes/<name>/`（不是 `.team-flow/changes/`），由 S4 创建，内含 `.team-flow.yaml`
- `**.team-flow/` 只存产品级编排状态**：registry.yaml / requirements/ / handoffs/ / feedback/
- **设计增强方案是唯一真相源**：定义 WHY + WHAT；AGENTS.md 定义 HOW；SKILL.md 是执行指令
- **历史版本保留不删**：设计增强方案旧版文件仅供追溯

## Agent 与 Skill 协作规范

### 职责分离（第一性原理）

| 层 | 职责 | 文件 |
|----|------|------|
| Agent (.md) | **WHO**（角色人设）+ **WHAT**（职责范围、输入、输出契约、红线） | `agents/*.md` |
| Skill (SKILL.md) | **HOW**（步骤流程、方法论、模板、规范、上下文加载协议） | `skills/*/SKILL.md` + `references/` + `chapters/` |

Agent prompt 保持精简（目标 ≤100 行），只定义"谁来做、做什么、交付什么、禁止什么"。所有"怎么做"的细节属于 Skill。

### 反模式（强制禁止）

- ❌ **Agent 里堆 SOP/方法论/加载流程** → 流程应抽成 Skill，通过 `skills:` 字段预加载
- ❌ **Skill 里写角色设定** → 角色属于 Agent 文件
- ❌ **Agent prompt 中重复 Skill 已有的内容** → Agent 只引用，Skill 是唯一真相源

### 三种协作写法

| 写法 | 适用场景 | Agent frontmatter | 确定性 |
|------|---------|-------------------|--------|
| **写法 1：纯 fork** | 一次性重任务，无需建 agent 文件 | `context: fork` + `agent: general-purpose` | 100%（SKILL.md 作为任务 prompt） |
| **写法 2：自定义 Agent + skills 预加载**（推荐） | 反复出现的角色 | `skills: [skill-name]`（启动时全文注入 SKILL.md） | 100% |
| **写法 3：叠加** | 角色稳定 + 任务多变 | `context: fork` + `agent: custom` + `skills:` | 100% |

**当前项目采用写法 2**：`agents/architecture-design.md` 通过 `skills: [architecture-design]` 预加载完整 SKILL.md 知识库。

### 子代理知识注入通道（确定性从高到低）

1. **`skills:` 字段预加载**（推荐）：启动时把 SKILL.md 全文注入上下文，确定性 100%。**硬前提：agent frontmatter 必须是合法 YAML**——v0.33.0 事件（v0.13 §54）：非法 YAML（description 内顶格 `<example>`）导致 Claude Code 静默降级，skills:/tools:/description 全部被丢弃且无任何警告，缺陷存活整个插件生命周期。现由 frontmatter-lint 测试（npm test）强制守护
2. **`context: fork` 注入**：SKILL.md 成为子 agent 的任务 prompt，确定性 100%
3. **运行时自主发现**：靠语义匹配触发，不保证，不可依赖
4. **Agent prompt 中硬写指令**：作为兜底，优先级最低

### 注意事项

- 子代理**不继承**主 Agent 的 Skills（上下文隔离是有意设计）
- `skills:` 预加载是全量注入 SKILL.md，`references/` 和 `chapters/` **不会自动带上**——Agent 需在执行中按需 Read
- Agent prompt 中用一句话指向 Skill："Your preloaded Skill contains the detailed methodology. Follow it for HOW."
- 措辞强度决定遵循度：关键指令用 MUST/DO NOT，放 prompt 开头
- **agent description 必须单句**（v0.33.0 起）：`<example>` 块会破坏 YAML 块标量导致整个 frontmatter 静默失效；触发示例的代价不值得冒这个险（team-flow 的 agent 由 workflow-start 显式 dispatch，不依赖 description 自动触发）
- **`tools:` 限制自 v0.33.0 起真实生效**：子代理只握有 frontmatter 声明的工具（此前静默降级为全量工具）。若某 agent 需要 MCP 工具，必须在 `tools:` 显式声明
- **机制断言必须实证**（v0.13 §54.6 教训）：任何"通道/机制有效"的写法定论，必须附一次实证探针（dispatch 子代理 → 行为探针问规则语义，勿用精确字符串内省——有假阴性）

# 约束

使用中文回复我（包含思考）

