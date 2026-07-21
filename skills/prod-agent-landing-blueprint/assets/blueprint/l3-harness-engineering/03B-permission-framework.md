# 权限框架（L3 Harness · 03B）

> 报告引用: §5.4 权限系统 / §5.11 Harness 设计原则（最小权限原则）/ §13 Agent Team
> 定位: 实施最小权限原则（四种 permission_mode），为 Agent、skill、工具分配最小必要权限。
> 标签: 【来源已核验✅】

## 四种 Permission Mode（报告原文精确提取）

| 模式 | 定义 | 适用场景 | 风险等级 |
|------|------|----------|----------|
| **default** | 危险操作需确认（交互式开发） | 开发者交互式使用 Claude Code | 低——人在环路中审批 |
| **acceptEdits** | 自动接受文件编辑（自动化脚本） | 自动化脚本、CI/CD 流程 | 中——编辑自动执行，危险操作仍需确认 |
| **plan** | 只读模式，不执行修改（代码分析/审查） | 代码审查、架构分析、安全审计 | 极低——只读无任何修改能力 |
| **bypass** | 跳过所有权限检查（完全自动化） | 完全信任的自动化环境（如沙箱内 CI） | 高——无任何审批机制，慎用 |

## 角色-权限映射（按 §13 Agent Team + §5.11 设计）

| 角色 | permission_mode | 工具白名单 | 禁止工具 | 说明 |
|------|----------------|------------|----------|------|
| **协调者（Coordinator）** | `plan` | Read, SendMessage, StructuredOutput | Write, Edit, Bash, MCP, Read/Write of 主干 | 协调者仅编排，不执行。不持任何写权限。 |
| **工作者（Worker）** | `default` / `acceptEdits` | Read, Write, Edit, Bash, Grep, Glob, WebSearch, Skill, MCP | 管理工具（TaskStop, Agent Tool） | 工作者有执行权。默认危险操作需确认；自动化场景可 acceptEdits。 |
| **合并代理（Merge Agent）** | `bypass`（仅合并阶段） | Write（仅特定文件）, Bash（git merge/CI触发） | 沙箱外执行、非合并文件写入 | 合并阶段唯一写主干方。权限极度受限，仅允许合并操作。 |
| **eco-gate（确定性执行器）** | `bypass` | 无（PreToolUse 级阻断器） | 不适用 | 非 Agent/Skill，是 Hook 级阻断器。不可为 skill。 |
| **workflow-check** | `plan` | Read（只读 status-tracker） | Write, Edit, Bash | 只读读取器，不修改任何文件。 |

## 权限叠加规则

1. **基础权限 ≤ 角色权限**: 任何 Agent 的实际权限 = min(基础 permission_mode, 角色权限)
2. **工具白名单优先于黑名单**: 显式白名单内的工具允许；不在白名单内的工具默认 deny
3. **阶段权限动态调整**: 不同 phase 可动态调整同一 Agent 的权限（如 `DESIGNING` 阶段 Worker 为 `plan`，`IMPLEMENTING` 阶段切换为 `default`）
4. **危险操作双重确认**: 即使 `acceptEdits`，以下操作仍需确认：
   - `git push` 到受保护分支
   - 修改 `requirement/status-tracker.md` 机读块
   - 删除或修改 `CLAUDE.md` / `AGENTS.md`
   - 任何 `bypass` 模式的操作（须审批人签名）

## 权限审计

- 每次权限变更（模式切换、白名单调整）须记录到 `audit-log.jsonl`
- 字段: `{"type": "Permission", "artifact": "permission_mode_change", "old": "...", "new": "...", "approver": "..."}`
- 权限变更须经过 `WAITING_USER` 审批（不能自动切换）

## Hook 级权限注解

| Hook | 权限边界 | 说明 |
|------|----------|------|
| PreToolUse | deny `Bash(git:*)` / `git push` | 阻断未过 ECO 校验的 push |
| PostToolUse | record Write/Edit/Bash/MCP | 仅记录，不拦截 |
| Stop | warn（8次后强制覆盖） | 仅软兜底，不能作唯一保障 |

---
> 此文件为**骨架**。真实项目需按实际团队角色、工具集、安全策略填充白名单。
> 建议将权限矩阵纳入版本控制，作为安全审计基线。
