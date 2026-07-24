# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

本工作区的核心目标是**开发和测试 team-flow 工作流**。team-flow 是一个统一插件，整合了：
- **spec-superflow**：Spec 驱动开发（9 skills）
- **compound-engineering 核心子集**：全局复利（6 skills）
- **architecture-design**：4A+DDD 增量设计（1 skill）
- **prototype**：本地 HTML 原型（1 skill）
- **产品级编排**：workflow-orchestrator（1 skill）
- **既有项目接入**：workflow-bootstrap（1 skill）
- **E2E 测试**：e2e（1 skill）

当前版本：`v0.11.0`

## 工作区结构

```
team-flow-workspace/
├── docs/                                          # 设计文档（工作区级）
│   ├── architecture-api-db-design-enhancement.md       # 设计增强方案 v1（初版，历史参考）
│   ├── architecture-api-db-design-enhancement-v0.2.md  # 设计增强方案 v0.2（四方专家会审，历史参考）
│   ├── architecture-api-db-design-enhancement-v0.3.md  # 设计增强方案 v0.3（原型能力并入，历史参考）
│   ├── architecture-api-db-design-enhancement-v0.5.md  # 设计增强方案 v0.5/v0.6（★ 当前权威版本）
│   ├── prototype-design-research.md                    # 原型方案选型调研（已吸收，历史参考）
│   ├── team-flow-architecture-design-v0.3.html         # 架构设计可视化（v0.3 配套）
│   ├── external-references/                            # 外部参考资料
│   │   ├── architecture-design-source/                 # 架构设计源文件
│   │   ├── compound-engineering/                       # 复合工程参考
│   │   ├── skills/                                     # GLAF4 技能定义参考
│   │   └── spec-superflow/                             # Superflow 规范参考
│   └── plan/                                           # 实现计划
└── team-flow/                                     # 核心工具库（独立 Git 仓库）
```

## 设计文档体系

### 文档层级与定位

```
设计增强方案（唯一真相源，定义 WHY + WHAT + 决策记录）
  → AGENTS.md（插件运行时参考，定义 HOW，必须与真相源同步）
  → 各 SKILL.md（执行指令，必须与 AGENTS.md 一致）
  → CLAUDE.md（本文件，工作区级指令摘要，必须与 AGENTS.md 一致）
```

### 核心设计文档

| 文档 | 路径 | 定位 | 版本规则 |
|------|------|------|---------|
| **架构/API/DB 设计增强方案** | `docs/architecture-api-db-design-enhancement-v{X}.md` | team-flow 插件的**唯一权威设计文档**。定义设计目标、方法论底座（F1-F8）、SOP 闭环、产物结构、复利机制、集成规则、决策落实状态 | 文件名带版本号；每次重大设计变更**新增版本文件**，旧版保留不删；文件内部标题版本可超前于文件名（如文件名 v0.5 内部标注 v0.6） |
| **插件设计总纲** | `team-flow/AGENTS.md` | 面向 LLM 和贡献者的运行时参考：能力概览、Skills 索引（必须与实际 `skills/` 目录一致）、SOP、产物结构、配置、约束 | 必须与最新设计增强方案和实际 skills/ 目录保持同步 |
| 原型设计调研 | `docs/prototype-design-research.md` | 原型方案选型调研（五方案对比），结论已吸收进设计增强方案第十五章 | 仅作历史参考，不再独立维护 |

### 辅助文档（team-flow/ 子仓库内）

| 文档 | 路径 | 定位 |
|------|------|------|
| README | `team-flow/README.md` | 安装指南 + 快速上手（面向用户），skill 计数必须与实际一致 |
| CHANGELOG | `team-flow/CHANGELOG.md` | 版本变更记录 |
| 状态机 | `team-flow/docs/state-machine.md` | 8 态状态机详细定义 |
| 决策点 | `team-flow/docs/decision-points.md` | DP-0 到 DP-7 决策门定义 |
| 平台矩阵 | `team-flow/docs/platform-matrix.md` | 9 安装面兼容性矩阵 |
| 制品契约 | `team-flow/docs/artifact-contract.md` | 制品格式与校验规则 |

### 当前版本说明

- **设计增强方案当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.5.md`（文件名 v0.5，内部标注 v0.6，含 20 章 + 决策落实状态）
- **插件版本**：`v0.11.0`（20 skills）
- 设计增强方案的历史版本（v1 / v0.2 / v0.3）保留在 `docs/` 下，仅供追溯，不作为实施依据

## team-flow 工作流核心

### 六套能力（20 skills）

| 模块 | Skills | 职责 |
|------|--------|------|
| spec-superflow | workflow-start, need-explorer, spec-writer, contract-builder, build-executor, code-reviewer, spec-merger, release-archivist, bug-investigator | Spec 驱动开发全流程（变更级） |
| compound 核心子集 | ce-brainstorm, ce-plan, ce-compound, ce-strategy, ce-ideate, ce-proof | 全局复利策略 |
| architecture-design | architecture-design | 4A+DDD 增量设计 |
| prototype | prototype | 本地 HTML 原型 |
| 产品级编排（v0.11.0 新增） | workflow-orchestrator | 产品级工作流编排（brainstorm→原型内循环→plan→拆change→分发） |
| 既有项目接入（v0.11.0 新增） | workflow-bootstrap | 既有项目一次性侦察+基线建立（代码库侦察→架构基线→领域词汇→目录初始化） |
| E2E（v0.10.0 新增） | e2e | AC 驱动 Playwright E2E 测试 |

### 工作流 SOP（v0.11.0 修订，对应设计增强方案 v0.6 第三节）

```
模糊需求
  → [既有项目接入层 workflow-bootstrap]（一次性，已有 baseline.md 则跳过）
       B1 代码库侦察 → B2 架构基线文档化 → B3 领域词汇提取 → B4 目录初始化
  → [产品级编排层 workflow-orchestrator]
  → S1 ce-brainstorm → PRD(vN) 草稿
       ├─ 原型内循环（可选）：prototype skill → 原型审查 → 修正 → PRD+原型冻结
       └─ 不需要原型 → PRD 直接冻结
  → S2 ce-plan → plan(vN)（产品级策略：change拆分+依赖+技术方向）
  → S3 拆 change → change-1, change-2, ...
  → S4 分发 → 各 change 进入 spec-superflow（workflow-start 8态状态机）
  → [复利贯穿层] 每个阶段转换点：检测→捕获→索引→注入
  → change 完成：arch-merge → prototype-sync（顺序提交）+ 复利晋升
```

### 常用开发命令

```bash
# 在 team-flow/ 目录下执行
cd team-flow

# 构建
npm run build

# 运行测试
npm test

# 验证产物
npm run validate

# 检查版本一致性
npm run check-versions

# v0.11.0 新增 CLI 命令
ssf prototype-sync <change-dir> [--source <path>]   # UX 增量回写全局 prototype/
ssf solutions index-gen                              # 重建复利索引
ssf solutions inject --phase <p> --domain <d>        # 阶段感知注入（top-5）
ssf solutions capture --phase <p> --domain <d> --type <t> --severity <s> --summary <text>  # 捕获经验
ssf solutions promote <change-dir>                   # change→product 晋升
```

### 全局产物结构

```
prd/               PRD + 实施方案 + 原型审查记录（v1→v2，分支隔离）
  └── vN/
      ├── prd.md              # 业务要件（ce-brainstorm 产出）
      ├── plan.md             # 实施方案（ce-plan 产出，产品级策略）
      └── prototype-review.md # 原型审查记录（PRD 内循环产出）
prototype/         全局原型（UI 契约真相源，git 分支隔离）
docs/
  ├── architecture/  全局架构锚点（ARCHITECTURE.md / DATABASE.md / <bc>/）
  └── solutions/     复利经验库（v0.11.0 新增，三层索引）
      ├── INDEX.md   # L1 轻量索引（≤150行）
      ├── prd/ plan/ prototype/ spec/ build/ review/ cross-phase/
specs/<cap>/       每变更设计/任务/契约 + learnings.md（候选晋升）
STRATEGY.md        策略文档
CONCEPTS.md        领域词汇
```

## Git 管理规则

### 父级仓库（当前仓库）
- 管理工作空间级文档和目录结构
- `.gitignore` 忽略 `team-flow/` 子仓库目录
- 不跟踪子工程的任何文件

### 子工程（team-flow）
- 位于 `team-flow/` 目录，是独立的 Git 仓库
- 变更必须进入子目录单独提交：
  ```bash
  cd team-flow && git add -A && git commit -m "..."
  ```

### 升级后必做（强制规则）
每次升级 team-flow 后，必须完成以下步骤：
1. **子仓库**：升级 plugin 版本号（`npm version <new> --no-git-tag-version`，自动同步所有文件）+ 提交变更
2. **主项目空间**：更新 `CLAUDE.md`（版本号、skills 数量、SOP、产物结构、命令等）+ 提交变更

## 插件迭代工作流（强制规则）

每次 team-flow 插件迭代（新增/修改 skill、agent、hook、command、SOP 等）必须按以下五阶段执行：

```
P1 设计 → P2 实施 → P3 验证 → P4 同步 → P5 提交
```

| 阶段 | 动作 | 工具 |
|------|------|------|
| **P1 设计** | 更新设计增强方案（重大→新版本文件，小幅→当前版本修订）+ LT 确认决策 | — |
| **P2 实施** | 新 skill→`/plugin-dev:skill-development`；新 agent→`/plugin-dev:agent-development`；新 hook→`/plugin-dev:hook-development`；新 command→`/plugin-dev:command-development`；结构问题→`/plugin-dev:plugin-structure` | plugin-dev 技能集 |
| **P3 验证** | ① `plugin-dev:plugin-validator` agent 全面校验 ② `plugin-dev:skill-reviewer` agent 审查新/改 skill ③ `npm run check-versions` ④ `npm test` | plugin-dev agent + npm |
| **P4 同步** | 按下方「文档维护规范 · 迭代同步清单」逐项检查 + 更新 Roadmap 和待办列表 | 见文档维护规范 |
| **P5 提交** | 子仓库 `npm version` + commit → 父仓库 commit | 见 Git 管理规则 |

**约束**：
- P1 未完成（设计文档未更新 / LT 未确认）→ 不进 P2
- P3 的 check-versions 和 plugin-validator 是门禁，不通过 → 不进 P4
- P4 同步清单有遗漏 = 迭代未完成
- 新 SKILL.md ≤150 行，详细内容进 references/（渐进式披露）

## 文档维护规范（强制规则）

### 迭代同步清单

每次 team-flow 版本迭代（含 skill 新增/修改/删除、SOP 变更、产物结构变更、CLI 命令变更），**必须**按以下清单同步更新相关文件。遗漏任何一项视为迭代未完成。

| 变更类型 | 必须更新的文件 |
|---------|--------------|
| **新增/删除 skill** | ① 设计增强方案（新增版本文件或修订当前版本） ② `team-flow/AGENTS.md` Skills 索引表 ③ `team-flow/README.md` 能力列表 ④ `CLAUDE.md` skills 表 ⑤ `team-flow/plugin.json` description 中的 skill 计数 |
| **修改 skill 内容**（涉及能力描述变化） | ① `team-flow/AGENTS.md`（能力概览） ② 设计增强方案（如涉及 SOP/产物/集成规则变化） |
| **SOP 变更** | ① 设计增强方案（第三节 SOP 图） ② `team-flow/AGENTS.md`（标准工作流） ③ `CLAUDE.md`（工作流 SOP） |
| **产物结构变更** | ① 设计增强方案（第四节产物结构） ② `team-flow/AGENTS.md`（全局产物结构） ③ `CLAUDE.md`（全局产物结构） |
| **CLI 命令变更** | ① `team-flow/AGENTS.md`（Commands） ② `CLAUDE.md`（常用开发命令） ③ 设计增强方案（如涉及新脚本，第十一节） |
| **版本号变更** | ① `team-flow/package.json` ② `team-flow/plugin.json` ③ `team-flow/README.md` ④ `CLAUDE.md` ⑤ 所有 SKILL.md 中的 `npx --package spec-superflow@x.y.z` 版本引用 |
| **设计升级 / 新待办发现** | ① `CLAUDE.md` Roadmap（更新里程碑） ② `CLAUDE.md` 待办列表（追加条目） |
| **待办完成实施** | ① `CLAUDE.md` 待办列表（状态改 ✅，注明完成版本/日期） ② `CLAUDE.md` Roadmap（对应里程碑标记 ✅） |

### 设计增强方案版本规则

- **文件命名**：`docs/architecture-api-db-design-enhancement-v{X}.md`，X 为版本号
- **新增 vs 修订**：重大设计变更（新章节、SOP 重画、方法论变更）→ 新增版本文件；小幅修订（措辞修正、决策状态更新）→ 在当前版本文件内修订
- **旧版保留**：历史版本文件**保留不删**，仅供追溯
- **修订摘要**：每个版本文件开头必须有修订摘要，说明相较上一版的关键变更点
- **决策落实状态**：设计增强方案末尾的"决策落实状态"章节是决策追踪的唯一真相源，每次决策确认后必须更新

### 一致性校验要求

`npm run check-versions` 应扩展为同时校验以下一致性（当前仅校验版本号）：

1. **版本号一致性**（现有）：package.json / plugin.json / README / 各 SKILL.md
2. **skill 计数一致性**（待扩展）：plugin.json description / README / AGENTS.md / CLAUDE.md 中的 skill 数量 vs 实际 `skills/` 目录数
3. **npx 版本引用一致性**（待扩展）：所有 SKILL.md 中的 `spec-superflow@x.y.z` 应与当前 package.json version 一致

## 目录管理规范

### docs/（工作区级设计文档）
- `architecture-api-db-design-enhancement*.md`：设计增强方案版本系列（唯一权威设计文档），版本规则见"文档维护规范"
- `prototype-design-research.md`：原型方案选型调研（已吸收，仅作历史参考）
- 新增设计文档时，必须在本节和"设计文档体系"中登记

### docs/external-references/
存放外部参考资料，包括架构参考、最佳实践、第三方文档等。新增时请维护 README.md 索引。

### docs/plan/
存放实现计划与方案文档。

## 配置

项目根 `spec-superflow.config.json` 可注入扩展字段：
```json
{
  "prd.template": ".team-flow/prd.template.md",
  "prototype.designSystem": "prototype/design-system.md",
  "prototype.entry": "prototype/index.html"
}
```

## Roadmap

> **维护规则**：每次设计升级或版本迭代时更新本节；完成实施的里程碑标记 ✅ 并注明完成版本。

### 已完成里程碑

| 版本 | 里程碑 | 状态 |
|------|--------|------|
| v0.3 | 原型能力并入、四方专家会审、设计增强方案 v0.3 | ✅ |
| v0.5 | 原型内循环修正、产品级编排层、ce-plan 收窄、复利贯穿机制 | ✅ |
| v0.6（设计文档） | 既有项目接入层（workflow-bootstrap）、SOP 补 bootstrap 层 | ✅ |
| v0.10.0 | E2E skill（AC 驱动 Playwright 测试） | ✅ |
| v0.11.0 | workflow-orchestrator + workflow-bootstrap + e2e 集成、复利 CLI 命令、三层索引 | ✅ |

### 规划中里程碑

| 版本 | 里程碑 | 核心内容 | 状态 |
|------|--------|---------|------|
| v0.12.0 | **治理债务清理** | ① 身份命名统一（team-flow vs spec-superflow） ② AGENTS.md 同步到 v0.11.0 ③ 版本号硬编码修复（74 处 npx 引用） ④ skill 计数全链路一致 ⑤ check-versions 扩展（计数 + npx 引用校验） | ✅ 2026-07-24 完成 |
| v0.13.0 | **渐进式披露 + Agent 化** | ① ce-compound / ce-plan SKILL.md 拆分到 references/（控制在 150 行内） ② code-reviewer / bug-investigator 改为 agent ③ 13 个无 references/ 的 skill 补充支撑文件 | ✅ 2026-07-24 完成 |
| v1.0.0 | **成熟版** | ① 触发词去重（orchestrator 作唯一入口，内部路由） ② PreToolUse hook 执行期状态守护 ③ "ce-" 前缀统一（或在 README 中明确命名来源） ④ 设计增强方案 v1.0 全量定稿 | 🔲 进行中（②已完成） |

## 待办列表

> **维护规则**：发现新待办时追加（注明优先级和来源）；完成实施后将状态改为 ✅ 并注明完成版本/日期；已废弃的待办标记 🗑️ 并注明原因。**每次迭代必须检查本列表。**

### P0（阻断级，下一版本必须完成）

| ID | 待办 | 状态 | 目标版本 | 备注 |
|----|------|------|---------|------|
| P0-1 | AGENTS.md 同步到 v0.11.0：补 3 skill 到索引（17→20）；更新 SOP；补复利系统；更新状态机描述 | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 |
| P0-2 | 修复 2 处 `spec-superflow@0.10.2` → `@0.11.0` | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 |
| P0-3 | plugin.json description "17 skills" → "20 skills"（含 .claude-plugin/ 副本） | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 |
| P0-4 | 身份命名关系文档化：AGENTS.md 新增"身份与依赖关系"节，明确 team-flow（插件）包含 spec-superflow（npm 底座） | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 C1 |
| P0-5 | check-version-consistency.mjs 扩展：skill 计数校验 + npx 版本引用校验（正向+负向测试通过） | ✅ 2026-07-24 | v0.12.0 | 来源：文档维护规范 |

### P1（重要，两个版本内完成）

| ID | 待办 | 状态 | 目标版本 | 备注 |
|----|------|------|---------|------|
| P1-1 | ce-compound SKILL.md 拆分：850行→114行，新建 7 个 reference 文件 | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 C4 |
| P1-2 | ce-plan SKILL.md 拆分：837行→114行，新建 9 个 reference 文件 | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 C4 |
| P1-3 | code-reviewer agent 创建（只读审查员，tools: Read/Bash/Grep/Glob，171行） | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 W2 |
| P1-4 | bug-investigator agent 创建（自主调查员，tools: Read/Bash/Grep/Glob/Write，180行） | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 W2 |
| P1-5 | README.md 同步：七套能力 20 skills + SOP + 产物结构 | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 |

### P2（改善，按节奏推进）

| ID | 待办 | 状态 | 目标版本 | 备注 |
|----|------|------|---------|------|
| P2-1 | 触发词去重：workflow-orchestrator 作为唯一产品级入口，内部路由 | 🔲 待实施 | v1.0.0 | 来源：v0.11.0 设计评审 W3 |
| P2-2 | PreToolUse hook 执行期状态守护（14/14 测试通过，~22ms，防御性优先） | ✅ 2026-07-24 | v1.0.0 | 来源：v0.11.0 设计评审 W5 |
| P2-3 | 13 个 skill 补 references/：3 个已填充内容（workflow-start/build-executor/release-archivist），10 个目录已就绪 | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 W1 |

### P3（低优先级，时机成熟再做）

| ID | 待办 | 状态 | 目标版本 | 备注 |
|----|------|------|---------|------|
| P3-1 | "ce-" 前缀统一：改为 "tf-" 或在 README 中明确命名来源（compound-engineering 遗产） | 🔲 待实施 | v1.0.0 | 来源：v0.11.0 设计评审 W4，涉及破坏性重命名 |
