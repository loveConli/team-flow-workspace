# 工具集隔离与权限矩阵（L5 Agent Team）

> 报告引用: §13 Agent Team / §5.4 权限系统 / §5.11 Harness 设计原则
> 定位: 定义协调者、工作者、合并代理三角色的工具白名单与权限边界，确保"Orchestrator ≠ Implementer"和"并行读者单一写者"。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L5 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 三角色权限矩阵

### 协调者（Coordinator）

| 工具 | 权限 | 说明 |
|------|------|------|
| Agent Tool | ✅ 允许 | 创建/分配任务给 Worker |
| TaskStop Tool | ✅ 允许 | 停止 Worker 任务 |
| SendMessage Tool | ✅ 允许 | 向 Worker 发送消息 |
| Structured Output Tool | ✅ 允许 | 生成结构化输出 |
| Read | ❌ 禁止 | 协调者不读原始代码 |
| Write | ❌ 禁止 | 协调者不写文件 |
| Edit | ❌ 禁止 | 协调者不改代码 |
| Bash | ❌ 禁止 | 协调者不执行命令 |
| Grep/Glob | ❌ 禁止 | 协调者不直接搜索代码库 |
| WebSearch | ❌ 禁止 | 协调者不直接检索 |
| Skill | ❌ 禁止 | 协调者不直接调用 Skill（通过 Worker 代理） |
| MCP | ❌ 禁止 | 协调者不直接调用外部系统 |
| Git Push/Pull | ❌ 禁止 | 任何 Git 操作由 Worker 或合并代理执行 |

**permission_mode**: `plan`（只读，但协调者甚至不读代码，只读 Worker 报告）

### 工作者（Worker）

| 工具 | 权限 | 说明 |
|------|------|------|
| Read | ✅ 允许 | 读取代码、文档、配置 |
| Write | ✅ 允许 | 写入新文件 |
| Edit | ✅ 允许 | 修改现有文件 |
| Bash | ✅ 允许 | 执行命令（在沙箱内） |
| Grep | ✅ 允许 | 代码内搜索 |
| Glob | ✅ 允许 | 文件列表检索 |
| WebSearch | ✅ 允许 | 外部信息检索 |
| Skill | ✅ 允许 | 调用标准 Skill |
| MCP | ✅ 允许 | 调用外部系统 |
| Agent Tool | ❌ 禁止 | 排除管理工具 |
| TaskStop Tool | ❌ 禁止 | 排除管理工具 |
| SendMessage Tool | ✅ 允许 | 仅用于向 Coordinator 报告 |
| Structured Output Tool | ✅ 允许 | 生成报告和产出 |
| Git Push | ❌ 禁止 | Worker 只推 feature 分支（须过 eco-gate） |
| Git Merge | ❌ 禁止 | 合并由合并代理执行 |
| Write 主干 | ❌ 禁止 | 任何主干写入由合并代理执行 |

**permission_mode**: `default`（交互式）或 `acceptEdits`（自动化场景，危险操作仍需确认）

### 合并代理（Merge Agent）

| 工具 | 权限 | 说明 |
|------|------|------|
| Read | ✅ 允许 | 读取验证结果、审计日志 |
| Write | ✅ 允许 | 仅允许写入主干（在 worktree 验证通过后） |
| Edit | ✅ 允许 | 仅允许修改主干文件（结构化合并） |
| Bash | ✅ 允许 | 仅 `git merge` / `git push`（须过 eco-gate） |
| Git Pull | ✅ 允许 | 拉取最新主干 |
| Git Merge | ✅ 允许 | 执行合并（须 CI green） |
| Git Push | ✅ 允许 | 推送到主干（须过 eco-gate） |
| CI API | ✅ 允许 | 查询 CI 状态 |
| Write 其他文件 | ❌ 禁止 | 不执行非合并代码修改 |
| Read 原始代码 | ❌ 禁止 | 不读原始实现（只读验证结果） |
| Skill | ❌ 禁止 | 不调用 Skill |
| MCP | ❌ 禁止 | 不调用外部系统（除 CI API） |

**permission_mode**: `bypass`（仅合并阶段，权限极度受限）

## 权限动态调整规则

| 场景 | 协调者 | 工作者 | 合并代理 |
|------|--------|--------|----------|
| 需求澄清（Phase 1） | `plan` | `default` | 未激活 |
| 技术方案（Phase 2） | `plan` | `default` | 未激活 |
| 实现（Phase 3） | `plan` | `acceptEdits`（自动化 coding） | 未激活 |
| 测试（Phase 4） | `plan` | `default` | 未激活 |
| 评审（Phase 5） | `plan` | `plan`（只读审查） | 未激活 |
| 验证通过 → 合并 | `plan` | `plan` | `bypass`（仅此时激活） |
| 合并完成后 | `plan` | `default` | 休眠 |

## 越权检测与阻断

| 越权行为 | 检测方式 | 阻断机制 | 告警 |
|----------|----------|----------|------|
| 协调者尝试 Read/Write/Edit/Bash | PreToolUse Hook（工具调用审计） | deny + 记录 audit-log | 实时告警 |
| 工作者尝试 Agent Tool/TaskStop | PreToolUse Hook | deny + 记录 audit-log | 实时告警 |
| 工作者直接 push 到主干 | PreToolUse deny（Bash git:*） | deny（exit 2） | 实时告警 |
| 合并代理在非合并阶段 activated | 状态机检查（status-tracker phase） | deny + BLOCKED | 实时告警 |
| 合并代理尝试非合并文件写入 | 文件路径白名单检查 | deny + 记录 audit-log | 实时告警 |

## 权限审计

- 每次工具调用均记录到 `audit-log.jsonl`（PostToolUse 覆盖 Write/Edit/Bash/MCP + 所有工具）
- 审计字段增加 `role: "Coordinator|Worker|MergeAgent"`
- 每月审查越权事件，更新白名单和权限策略

---
> 此文件为**权限定义**。真实项目需按实际多 Agent 运行时环境、安全策略细调白名单。
> 建议将权限矩阵纳入版本控制，每次角色变更须 CR 确认。
