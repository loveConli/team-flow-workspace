# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

本工作区的核心目标是**开发和测试 team-flow 工作流**。team-flow 是一个统一插件（23 skills + 8 agents），整合了 spec-superflow（9）、compound-engineering（6）、architecture-design（1）、prototype（1）、design-system（1）、workflow-orchestrator（1）、workflow-bootstrap（1）、e2e（1）、session-handoff（1）、workflow-feedback（1）。

- **设计增强方案当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.10.md`
- **插件版本**：`v0.26.0`（23 skills + 8 agents）

## 工作区结构

```
team-flow-workspace/
├── docs/                          # 设计文档（工作区级）
│   ├── architecture-api-db-design-enhancement-v0.10.md # ★ 当前权威版本
│   ├── architecture-api-db-design-enhancement-v0.9.md  # 历史保留版本
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
  → S4 拆分验证与分发 → change-split-auditor 审计（必选）→ 创建 changes/<name>/ + change-brief.md
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
- `artifacts_hash`（proposal + specs + design + tasks 的 hash）
- `contract_hash`（execution-contract.md 的 hash）
- `spec_merged` + `test_result`（closing 前置条件）

**设计层面约定（SKILL.md 文档约束，代码层不可执行）**：
- architecture-design 判断门——routing-rules.md 给出的 `tf state set arch_design_*` 命令被 cmd-state.mjs SETTABLE_FIELDS 白名单拒绝，**实际报错**
- change-brief.md 交接——orchestrator S4 prompt 指示 LLM 手写，无脚本、无模板
- architecture/ 三件套产出与消费——无 hash、无 guard、无脚本校验

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
| 架构设计 | `changes/<name>/architecture/{architecture,database,api}.md` | architecture-design SKILL.md 引用，无 hash/guard |
| SDD 执行计划 | `changes/<name>/.superpowers/sdd/execution-plan.json` | 代码创建但不在 guard |
| 需求注册表 | `.team-flow/registry.yaml` | workflow-orchestrator 引用 |
| 全局架构基线 | `docs/architecture/baseline.md` | workflow-bootstrap 引用 |

### 状态文件内置字段（state-loader.mjs BUILTIN_DEFAULTS）

**核心状态**：`state` / `workflow` / `revision`
**哈希校验**：`artifacts_hash` / `contract_hash`
**执行进度**：`execution_mode` / `execution_plan_hash` / `execution_plan_revision` / `batches_completed` / `test_result` / `spec_merged`
**变更标识**：`change_name` / `last_transition` / `last_transition_from` / `last_transition_to`
**决策点**：`dp_0_result` ~ `dp_7_result` + 对应 `_timestamp` / `dp_0_decisions` / `dp_0_confirmed`

**注意**：`arch_design_decision` / `arch_design_reason` / `arch_design_artifacts` / `arch_design_timestamp` 等字段在 SKILL.md / routing-rules.md 中提及但**不在**内置字段中。更严重的是：`cmd-state.mjs` 的 `SETTABLE_FIELDS` 白名单不包含这些字段，routing-rules.md 中给出的 `tf state set arch_design_*` 命令实际执行会报错 `⛔ Field is not settable`——**这是死命令，无法落盘**。`writeState()` 也只序列化内置字段，即使手动写入也会被下次写操作丢弃。

### 关键差异说明

CLAUDE.md 和 AGENTS.md 中描述的工作流包含 architecture-design 门控（v0.9 §26）和 change-brief.md 交接等设计，但代码实现与文档存在显著差距：

| 设计承诺 | 代码现实 |
|----------|----------|
| `arch_design_*` 字段持久化 | state-loader 无字段、cmd-state SETTABLE_FIELDS 拒绝写入、writeState 丢弃 |
| architecture-design 门控 BLOCK | guard.mjs `exploring:specifying` 只查 `artifacts-exist`，无 arch 维度 |
| `architecture/*.md` 产出 | 无 hash、无 guard、无脚本校验 |
| `change-brief.md` 交接 | 无脚本创建、无模板（hash 排除是有意设计） |

**当前强制执行**的仅为核心 4+1 制品（proposal/specs/design/tasks + execution-contract）的状态管理。architecture-design 门控完全依赖 LLM prompt 层自觉，且文档提供的落盘命令在代码里不可执行。若要使其真正强制，需同时改：state-loader.mjs（加字段+序列化）、cmd-state.mjs（SETTABLE_FIELDS 白名单）、guard.mjs（新增 arch 维度挂到 `exploring:specifying`）。

## 文档治理规则

### 设计增强方案版本管理

- **当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.9.md`
- **历史版本**：v0.8 保留不删；v0.2/v0.3/v0.5/v0.7 已删除，可通过 `git log --all -- "docs/architecture-api-db-design-enhancement-v0.*.md"` 追溯
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

## 插件迭代工作流（强制规则）

```
P1 设计 → P2 实施 → P3 验证 → P4 提交
```

| 阶段        | 动作                                                                                                                                                                | 工具                     |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| **P1 设计** | 更新设计增强方案 + LT 确认决策                                                                                                                                                | —                      |
| **P2 实施** | 新 skill→`/plugin-dev:skill-development`；新 agent→`/plugin-dev:agent-development`；新 hook→`/plugin-dev:hook-development`；新 command→`/plugin-dev:command-development` | plugin-dev 技能集         |
| **P3 验证** | ① plugin-validator ② skill-reviewer ③ `npm run check-versions` ④ `npm test`                                                                                       | plugin-dev agent + npm |
| **P4 提交** | 子仓库 `npm version` + commit → `npm publish`（官方 registry）→ 父仓库 commit + 更新版本号                                                                            | 见 Git 管理规则 + 版本发布 Checklist |

**约束**：

- P1 未完成（设计文档未更新 / LT 未确认）→ 不进 P2
- P3 的 check-versions 和 plugin-validator 是门禁，不通过 → 不进 P4
- P4 提交时 pre-commit hook 自动执行版本一致性检查和修复
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



# 约束

使用中文回复我（包含思考）

