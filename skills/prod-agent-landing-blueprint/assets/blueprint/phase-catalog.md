# 全五阶段实施蓝图目录

> 路线 B：先产出全阶段设计+骨架（不激活）→ 专家评审并行评一审 → LT 拍板优先级 → 按优先级分批激活落地。
> 依据：《产研端到端Agent深度调研报告》§11 分阶段实施路径 + §3/§4/§5/§6/§8/§10/§13 各章节精确定义。

---

## 阶段间依赖链（必须先跑通前序才激活后序）

```
L1 提示词基础 ─┬─ L2 上下文夯实 ─── L3 Harness 重点建设 ─── L4 Loop 谨慎试点 ─── L5 Agent Team 扩展
               │                    （已产出03A骨架）          
               └─ 可与 L2/L3 并行起底（无硬依赖）
```

- **L3 硬门禁必须先跑通**（否则 L4 六阶段闭环执行不可靠）
- **L4 Loop 必须先跑通**（否则 L5 多 Agent 协作无反馈闭环保障）
- **L1/L2 可与 L3 并行起底**（持久提示层和上下文策展不依赖门禁）

---

## 阶段1: L1 提示词基础（§3 / §5.10 六组件之 AGENTS.md）

| 产物 | 类型 | 标签 | 依赖前置资产 | 当前可跑？ | 缺什么需补 |
|------|------|------|--------------|------------|------------|
| `l1-prompt-engineering/CLAUDE.md` | 持久提示层 | 【来源已核验✅】| — | 是（直接可用） | 项目实际目录结构、构建命令、工程规范填充 |
| `l1-prompt-engineering/AGENTS.md` | 持久提示层 | 【来源已核验✅】| — | 是（直接可用） | 仓库结构、PR期望、约束与禁止模式填充 |
| `l1-prompt-engineering/sdd-templates/spec.md` | SDD模板 | 【来源已核验✅】| — | 是（直接可用） | 每个需求按模板填入实际内容 |
| `l1-prompt-engineering/sdd-templates/plan.md` | SDD模板 | 【来源已核验✅】| — | 是（直接可用） | 按模板填入现状/目标/影响/改动/风险/验收/回滚 |
| `l1-prompt-engineering/sdd-templates/tasks.md` | SDD模板 | 【来源已核验✅】| — | 是（直接可用） | 任务原子化拆分、TDD标记、并行依赖标注 |
| `l1-prompt-engineering/skill-dispatch-rule.md` | Skill调度逻辑 | 【来源已核验✅】| — | 部分 | 项目级 skill 注册表 |

---

## 阶段2: L2 上下文夯实（§4 / §5.10 六组件之上下文工程）

| 产物 | 类型 | 标签 | 依赖前置资产 | 当前可跑？ | 缺什么需补 |
|------|------|------|--------------|------------|------------|
| `l2-context-engineering/01-strategies.md` | 策展策略配置 | 【来源已核验✅】| — | 是 | 数据源（Aone/钉钉/prj mem等）实际 endpoint |
| `l2-context-engineering/02-three-repos.md` | 结构约定 | 【来源已核验✅】| — | 部分 | 真实仓库/分支地址、触发器配置 |
| `l2-context-engineering/03-session-management.md` | 会话管理规范 | 【来源已核验✅】| — | 是 | 各会话 `/clear`/`compact` 触发惯例 |
| `l2-context-engineering/04-constraint-vs-info.md` | 类型区分规范 | 【来源已核验✅】| — | 是 | 约束型文本标准词表 |

---

## 阶段3: L3 Harness 重点建设（§5 / §8 Pipeline / §10.4）

> 03A = 已完成骨架；03B-03E = 本次补充。

| 产物 | 子阶段 | 类型 | 标签 | 依赖 | 当前可跑？ | 缺什么 |
|------|--------|------|------|------|------------|--------|
| `gates/pre-push-gate.sh` | 03A | Git hook | 【来源已核验✅·落地待验证⚠️】| Git hook + 分支保护 + CI | SAFE_MODE=1 ✅ | PMD_CMD / COVERAGE_CMD / 真实仓库 |
| `gates/eco-gate.sh` + `settings.json` | 03A | PreToolUse deny | 【来源已核验✅·落地待验证⚠️】| Claude Code PreToolUse | SAFE_MODE=1 ✅ | ECO 校验逻辑 / status-tracker 路径 |
| `gates/worktree-create-snapshot.sh` | 03A | WorktreeCreate hook | 【落地待验证⚠️】| 三线基线文件 | SAFE_MODE=1 ✅ | 需求/配置/测试基线路径 |
| `status-tracker/schema.md` + `.example.md` | 03A | L1 真相源 schema | 【来源已核验✅·落地依赖Hook配置⚠️】| workflow-check 读取器 | 部分 | 读取器 / 真实 requirement/ |
| `status-tracker/audit-log.schema.md` | 03A | append-only 审计日志 | 【来源已核验✅·落地待验证⚠️】| 项目记忆仓 | 部分 | 项目记忆仓路径 |
| `ci/required-checks.yml` | 03A | CI required checks | 【来源已核验✅·落地待验证⚠️】| CI 供应商 + 分支保护 | 否 | CI 账号 / required checks 注册 |
| `l3-harness-engineering/03B-permission-framework.md` | 03B | 权限框架 | 【来源已核验✅】| — | 部分 | 各 Agent 具体 permission_mode |
| `l3-harness-engineering/03C-sandbox-approval.md` | 03C | 沙箱与审批流程 | 【来源已核验✅·落地待验证⚠️】| sandbox 环境 | 否 | sandbox config、审批人列表 |
| `l3-harness-engineering/03D-cost-monitor.md` | 03D | 成本监控 | 【来源已核验✅·落地待验证⚠️】| Anthropic SDK / cost API | 否 | API key、阈值配置 |
| `l3-harness-engineering/03E-harness-parts.md` | 03E | 零件叠加路线图 | 【来源已核验✅】| — | 部分 | 按优先级逐件填充 |
| `l3-harness-engineering/error-handling.md` | 通用 | 错误处理与恢复 | 【来源已核验✅】| 告警通道 | 部分 | Slack/飞书 / 邮件通道 |

> **评审 P0-C 补丁**：需求级状态机迁移规则已显式登记**六道人工门**——
> **A** 进入实现授权门（`DESIGNING→IMPLEMENTING` 必过人工 PAUSE，`design` 不得由生成它的 AI 自审） /
> **B** 发布门（`RELEASING→CLOSED` 人工拍板，涉外部 API/付费/权限变更必过） /
> **C** ECO 升级评估门（已发布基线任何改动 → `WAITING_USER`） /
> **D** 越权·高成本操作门（调外部 API/花钱/改权限前人工确认） /
> **E** 知识蒸馏门（蒸馏产物人工审查后执行） /
> **F** L4 熔断决策门（闭环自验不过或熔断时人决定接受/继续/放弃；L4 实现前 `REVISING`/`WAITING_USER` 由 LT 人肉驱动）。
> 完整定义见 `status-tracker/status-tracker.schema.md` 第三节（补）；F 硬约束见包根 `design-contract-stub.md`（关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`）。凡标注「人工 PAUSE」的迁移节点，未经人确认不得自动越过。

---

## 阶段4: L4 Loop 谨慎试点（§6 / §8 Pipeline phase 0→6）

| 产物 | 类型 | 标签 | 依赖前置资产 | 当前可跑？ | 缺什么 |
|------|------|------|--------------|------------|--------|
| `l4-loop-engineering/01-six-stage-pipeline.md` | 六阶段纵向闭环编排 | 【来源已核验✅】| L3 Harness 已激活（至少 pre-push gate） | 部分 | 每阶段输入/动作/门/工具/产出定义 |
| `l4-loop-engineering/02-self-acceptance.md` | 自我验收多层机制 | 【来源已核验✅】| — | 部分 | 验收标准定义层 |
| `l4-loop-engineering/03-feedback-learning-layer.md` | 反馈学习层(Distill) | 【来源已核验✅】| 三仓库结构已建 | 部分 | 蒸馏触发条件与人工审查规则 |
| `l4-loop-engineering/04-compression-persistence.md` | 压缩+笔记持久化 | 【来源已核验✅】| — | 是 | 压缩触发阈值(CPU/token) |
| `l4-loop-engineering/05-primitive-checklist.md` | 六原语五前提检查表 | 【来源已核验✅】| — | 是 | — |

---

## 阶段5: Agent Team 扩展（§13 / §5.11 设计原则）

| 产物 | 类型 | 标签 | 依赖前置资产 | 当前可跑？ | 缺什么 |
|------|------|------|--------------|------------|--------|
| `l5-agent-team/01-coordinator-worker.md` | Coordinator-Worker 架构 | 【来源已核验✅】| L4 Loop 已跑通（反馈闭环稳定） | 部分 | 多Agent运行时环境 |
| `l5-agent-team/02-permissions.md` | 工具集隔离(协调者/工作者/合并代理) | 【来源已核验✅】| permission_mode 框架 | 部分 | 各角色白名单细调 |
| `l5-agent-team/03-merge-agent.md` | 合并代理写入隔离 | 【来源已核验✅】| 分支保护 + CI required checks | 部分 | 写主干权限角色配置 |
| `l5-agent-team/04-scratchpad.md` | Scratchpad 共享空间协议 | 【来源已核验✅】| — | 是 | 文件路径统一约定 |
| `l5-agent-team/05-role-split.md` | 职责拆分方案 | 【来源已核验✅】| — | 是 | 按实际项目拆分 |

---

## 路线 B 执行状态

| 阶段 | 设计 | 骨架 | 激活 | 评审 |
|------|------|------|------|------|
| L1 | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |
| L2 | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |
| L3-03A | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |
| L3-03B-E | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |
| L4 | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |
| L5 | ✅ 完成 | ✅ 完成 | 🔘 未激活 | 🔘 待评审 |

> 当前全五阶段「设计+骨架」已完成（不激活），具备提交专家评审条件。
