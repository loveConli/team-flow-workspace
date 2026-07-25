# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

本工作区的核心目标是**开发和测试 team-flow 工作流**。team-flow 是一个统一插件（22 skills + 8 agents），整合了 spec-superflow（9）、compound-engineering（6）、architecture-design（1）、prototype（1）、workflow-orchestrator（1）、workflow-bootstrap（1）、e2e（1）、session-handoff（1）、workflow-feedback（1）。

- **设计增强方案当前权威版本**：`docs/architecture-api-db-design-enhancement-v0.8.md`
- **插件版本**：`v0.16.0`（22 skills + 8 agents）

## 工作区结构

```
team-flow-workspace/
├── docs/                          # 设计文档（工作区级）
│   ├── architecture-api-db-design-enhancement-v0.8.md  # ★ 当前权威版本
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

| 场景 | 读取文件 |
|------|---------|
| 迭代规划、检查待办、更新 Roadmap | `docs/roadmap-and-todos.md` |
| 设计文档维护、版本规则、文档层级 | `docs/design-doc-system.md` |
| P4 同步阶段、迭代同步清单、一致性校验 | `docs/doc-maintenance.md` |
| 开发命令、产物结构、配置项 | `docs/dev-reference.md` |

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
  → S4 拆分验证与分发 → change-split-auditor 审计（必选）→ 创建 changes/<name>/ → 进入 spec-superflow
  → S5 全局监控（change≥2 必选）→ 跨 change 一致性 + 复利晋升 + 动态重规划
  → [复利贯穿层] 每个阶段转换点：检测→捕获→索引→注入
  → change 完成：arch-merge → prototype-sync + 复利晋升
```

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

## 插件迭代工作流（强制规则）

```
P1 设计 → P2 实施 → P3 验证 → P4 同步 → P5 提交
```

| 阶段 | 动作 | 工具 |
|------|------|------|
| **P1 设计** | 更新设计增强方案 + LT 确认决策 | — |
| **P2 实施** | 新 skill→`/plugin-dev:skill-development`；新 agent→`/plugin-dev:agent-development`；新 hook→`/plugin-dev:hook-development`；新 command→`/plugin-dev:command-development` | plugin-dev 技能集 |
| **P3 验证** | ① plugin-validator ② skill-reviewer ③ `npm run check-versions` ④ `npm test` | plugin-dev agent + npm |
| **P4 同步** | 按 `docs/doc-maintenance.md` 迭代同步清单逐项检查 + 更新 `docs/roadmap-and-todos.md` | 见 doc-maintenance.md |
| **P5 提交** | 子仓库 `npm version` + commit → 父仓库 commit | 见 Git 管理规则 |

**约束**：
- P1 未完成（设计文档未更新 / LT 未确认）→ 不进 P2
- P3 的 check-versions 和 plugin-validator 是门禁，不通过 → 不进 P4
- P4 同步清单有遗漏 = 迭代未完成
- 新 SKILL.md ≤150 行，详细内容进 references/（渐进式披露）

## 关键路径约束

- **change 目录位置**：项目根 `changes/<name>/`（不是 `.team-flow/changes/`），由 S4 创建，内含 `.spec-superflow.yaml`
- **`.team-flow/` 只存产品级编排状态**：registry.yaml / requirements/ / handoffs/ / feedback/
- **设计增强方案是唯一真相源**：定义 WHY + WHAT；AGENTS.md 定义 HOW；SKILL.md 是执行指令
- **历史版本保留不删**：设计增强方案旧版文件仅供追溯
