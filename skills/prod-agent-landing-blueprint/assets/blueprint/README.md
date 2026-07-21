# 全五阶段实施蓝图 · 设计+骨架（路线 B）

> 依据《产研端到端Agent深度调研报告》§11 分阶段实施路径，产出全五阶段（L1→L2→L3→L4→L5）设计+骨架。
> 本包为**设计+骨架**（不激活），未写 `.git/hooks`、未注册 CI、未改 Claude Code settings，可安全审阅。
> 遵循「先骨架后填充、先最小可行后完备」。所有脚本默认 `SAFE_MODE=1`（warn-only），真实环境 `SAFE_MODE=0` 才硬卡。**评审 P0-A：真实环境必须把 `SAFE_MODE` 置 0（fail-closed），不可长期 warn-only；插件 fail-closed 可作模板。**

## 五阶段总览（§11 分阶段实施路径）

| 阶段 | 做什么 | 解决什么痛点 | 落地产出（本次骨架） |
|------|--------|------------|----------------------|
| **L1 提示词基础** | 编写 CLAUDE.md/AGENTS.md；定义 Skill 调度逻辑；建立 SDD 三文档模板 | Agent 不知道该做什么、做到什么标准 | `CLAUDE.md` / `AGENTS.md` / `sdd-templates/` / `skill-dispatch-rule.md` |
| **L2 上下文夯实** | 五种策展策略；三仓库记忆生命周期；会话管理；区分约束 vs 信息型上下文 | Agent 信息不够导致无法正确执行 | `strategies.md` / `three-repos.md` / `session-management.md` / `constraint-vs-info.md` |
| **L3 Harness 重点建设** | 硬门禁（pre-push / eco-gate / 三线快照）+ 权限框架 + 沙箱审批 + 成本监控 + 零件叠加 | 好上下文但执行不可靠 | `gates/` + `status-tracker/` + `ci/` + `l3-harness-engineering/` |
| **L4 Loop 谨慎试点** | 六阶段纵向闭环；自我验收；反馈学习层；六原语五前提；压缩持久化 | 一次做完无积累 | `l4-loop-engineering/` |
| **L5 Agent Team 扩展** | Coordinator-Worker 架构；合并代理；Scratchpad；按独立判断/产物/并行/责任隔离拆分 | 单 Agent 处理复杂需求失稳 | `l5-agent-team/` |

## 阶段间依赖（必须先跑通前序才激活后序）
```
L1 + L2 ──┬── L3 Harness ─── L4 Loop ─── L5 Agent Team
          │  （硬门禁必须先跑通） （闭环稳定后） （多Agent协作）
```
- L1/L2 可与 L3 并行起底（无硬依赖）
- L3 硬门禁必须先跑通（否则 L4 执行不可靠）
- L4 Loop 必须先跑通（否则 L5 多 Agent 无反馈保障）

## 标签体系
- 【来源已核验✅】= 概念可信（报告一手来源已核实）
- 【落地待验证⚠️】= 需补 P0 前置资产（Git hook + 分支保护 + CI required checks + 架构注册表）方可激活

## 产物安全机制
所有脚本默认 `SAFE_MODE=1`（warn-only，不阻断），骨架在当前 sandbox 可空跑验证。
真实环境设 `SAFE_MODE=0` 才硬阻断（**fail-closed**；评审 P0-A：不可长期 warn-only，防止在缺前置资产时误杀）。
> 门禁硬依赖（status-tracker / ECO_TEST_REPORT / 架构注册表）缺失即非零失败（采纳插件「依赖缺失即非零退出」反绕过，见 `gates/eco-gate.sh`）。

## 单仓化 monorepo 结构（评审 P1 · 已决策 ✅）

> **决策（LT 2026-07-12，方式一）**：落地依赖 3 个 Git 仓（`artifact-graph` 引擎 / `artifact-chain-assistant` 插件 / 自建主仓）合并为单一 monorepo；上游两仓作 `git submodule` 精确钉死 commit（未发版防漂移），主仓单 CI 单 clone。
> 本 36 文件蓝图位于主仓 `product/blueprint/`；`code/` `memory/` `wiki/` 为报告 L2 三仓库的目录隔离，与 monorepo 不冲突。
> 完整目录布局、submodule 锁 commit 纪律、上游补丁跟踪 TODO 见 `l2-context-engineering/02-three-repos.md`「落地仓结构」节。

## 目录结构
```
phase1-landing-package/
├── README.md                     # 本文件（全五阶段总览）
├── phase-catalog.md              # 五阶段产物目录（状态/依赖/可跑/缺什么）
├── degradation-channels.md     # 降级通道汇总（不阻塞主链路）
├── gates/                        # L3 硬门禁（03A）
│   ├── pre-push-gate.sh
│   ├── eco-gate.sh
│   ├── eco-gate.settings.json
│   └── worktree-create-snapshot.sh
├── status-tracker/               # 需求流程态真相源（双真相源之一；结构/追溯/版本真相源由 artifact-graph version-lock 承担）
│   ├── status-tracker.schema.md
│   ├── status-tracker.example.md
│   └── audit-log.schema.md
├── ci/                           # L3 CI 骨架
│   └── required-checks.yml
├── l1-prompt-engineering/        # L1 提示词基础
│   ├── CLAUDE.md
│   ├── AGENTS.md
│   ├── sdd-templates/
│   │   ├── spec.md
│   │   ├── plan.md
│   │   └── tasks.md
│   └── skill-dispatch-rule.md
├── l2-context-engineering/       # L2 上下文夯实
│   ├── 01-strategies.md
│   ├── 02-three-repos.md
│   ├── 03-session-management.md
│   └── 04-constraint-vs-info.md
├── l3-harness-engineering/       # L3 补充（03B-E）
│   ├── 03B-permission-framework.md
│   ├── 03C-sandbox-approval.md
│   ├── 03D-cost-monitor.md
│   ├── 03E-harness-parts.md
│   └── error-handling.md
├── l4-loop-engineering/          # L4 Loop 谨慎试点
│   ├── 01-six-stage-pipeline.md
│   ├── 02-self-acceptance.md
│   ├── 03-feedback-learning-layer.md
│   ├── 04-compression-persistence.md
│   └── 05-primitive-checklist.md
└── l5-agent-team/                # L5 Agent Team 扩展
    ├── 01-coordinator-worker.md
    ├── 02-permissions.md
    ├── 03-merge-agent.md
    ├── 04-scratchpad.md
    └── 05-role-split.md
```

## 下一步（待你拍板）
按你「先专家评审再落地」的习惯，全五阶段蓝图产出后下一步：
**召集 Harness / DDD / Loop / IPD-ITIL + Skill 架构专家，并行评审此全蓝图** → 汇总意见 → 你决策落地优先级与分批策略 → 按优先级分批激活。

> 当前全五阶段「设计+骨架」已完成（不激活），具备提交专家评审条件。见 `phase-catalog.md` 查看各阶段详细状态。
