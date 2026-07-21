# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

本工作区的核心目标是**开发和测试 team-flow 工作流**。team-flow 是一个统一插件，整合了：
- **spec-superflow**：Spec 驱动开发（9 skills）
- **compound-engineering 核心子集**：全局复利（6 skills）
- **architecture-design**：4A+DDD 增量设计（1 skill）
- **prototype**：本地 HTML 原型（1 skill）

当前版本：`v0.11.0`

## 工作区结构

```
team-flow-workspace/
├── docs/                              # 设计文档
│   ├── external-references/           # 外部参考资料
│   │   ├── architecture-design-source/ # 架构设计源文件
│   │   ├── compound-engineering/       # 复合工程参考
│   │   ├── skills/                     # GLAF4 技能定义参考
│   │   └── spec-superflow/             # Superflow 规范参考
│   └── plan/                          # 实现计划
└── team-flow/                         # 核心工具库（独立 Git 仓库）
```

## team-flow 工作流核心

### 五套能力（19 skills）

| 模块 | Skills | 职责 |
|------|--------|------|
| spec-superflow | workflow-start, need-explorer, spec-writer, contract-builder, build-executor, code-reviewer, spec-merger, release-archivist, bug-investigator | Spec 驱动开发全流程（变更级） |
| compound 核心子集 | ce-brainstorm, ce-plan, ce-compound, ce-strategy, ce-ideate, ce-proof | 全局复利策略 |
| architecture-design | architecture-design | 4A+DDD 增量设计 |
| prototype | prototype | 本地 HTML 原型 |
| 产品级编排（v0.11.0 新增） | workflow-orchestrator | 产品级工作流编排（brainstorm→原型内循环→plan→拆change→分发） |
| E2E（v0.10.0 新增） | e2e | AC 驱动 Playwright E2E 测试 |

### 工作流 SOP（v0.11.0 修订）

```
模糊需求
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
每次升级 team-flow 后，必须完成以下两步：
1. **子仓库**：升级 plugin 版本号（`npm version <new> --no-git-tag-version`，自动同步所有文件）+ 提交变更
2. **主项目空间**：更新 `CLAUDE.md`（版本号、skills 数量、SOP、产物结构、命令等）+ 提交变更

## 目录管理规范

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
