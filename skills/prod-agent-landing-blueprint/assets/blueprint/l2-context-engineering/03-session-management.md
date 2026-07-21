# 会话管理规范（L2 上下文工程）

> 报告引用: §4 上下文工程 / §5.10 六组件 / §6.2 阶段0 上下文组织
> 定位: 配置会话管理（`/clear`、`/compact`、分段式任务）。维持上下文窗口高效利用。
> 标签: 【来源已核验✅】

## 会话生命周期管理

### 1. 会话启动（每次新对话）
- 自动执行: `workflow-check` 只读读取 `requirement/status-tracker.md` 机读块
- 自动加载: `CLAUDE.md` / `AGENTS.md`（持久提示层）
- 自动检索: 当前需求相关文件列表（`glob` / `grep`）
- 自动拉回: `NOTES.md` 最近 20 行（结构化笔记）
- 状态确认: 检查当前 `phase` / `state` / `blocked_reason`，若 `BLOCKED` 则暂停并提示

### 2. 会话中（正常运行）
- 每 10 轮对话: 自动检查上下文剩余 token
- 若剩余 ≤ 2000 tokens: 触发 `/compact`（高保真蒸馏 → NOTES.md）
- 若状态变更（如 `IMPLEMENTING` → `TESTING`）: 更新 `status-tracker.md` 机读块
- 若触发 `WAITING_USER` / `BLOCKED`: 写入 `NOTES.md` 并暂停会话

### 3. 会话结束（正常完成或中断）
- 自动写入: `NOTES.md` 当前会话摘要（关键决策、未完成项、下一步）
- 自动写入: `audit-log.jsonl` 本次会话的副作用（PostToolUse 覆盖 Write/Edit/Bash/MCP）
- 自动更新: `status-tracker.md` 机读块（若 phase/state 有变更）
- 若未 `CLOSED` 状态: 提醒用户「当前需求未结项，下次会话将自动恢复」

### 4. 会话恢复（崩溃/断线后）
- 读取: `status-tracker.md` 获取当前 phase/state
- 读取: `NOTES.md` 获取上次会话摘要和未完成项
- 读取: `audit-log.jsonl` 获取最近 10 条副作用（确认上次执行到什么位置）
- 重建上下文: 按 `phase` 重新加载该阶段所需的文件和工具
- 不丢失: 通过 status-tracker + NOTES.md + audit-log 三件套保证会话恢复不丢失进度

## 分段式任务策略

> 对于长需求，将大任务拆分为多个会话，每个会话处理一个子任务。

| 分段策略 | 触发条件 | 交接机制 |
|----------|----------|----------|
| 按 Phase 分段 | 每完成一个 Phase（如 `DESIGNING` → `IMPLEMENTING`） | status-tracker 更新 + NOTES.md 摘要 |
| 按任务分段 | 每完成 tasks.md 中的一个任务 | tasks.md 状态更新 + audit-log 记录 |
| 按时间分段 | 单次会话超过 2 小时 | 自动 compact + 提示用户保存上下文 |
| 按 token 分段 | 上下文剩余 ≤ 2000 tokens | 自动 compact + 生成 NOTES.md 续写提示 |

## 命令参考

| 命令 | 用途 | 安全提示 |
|------|------|----------|
| `/clear` | 清空当前上下文窗口（不丢失记忆） | 执行前自动写入 NOTES.md |
| `/compact` | 压缩上下文（高保真蒸馏） | 执行后生成 NOTES.md 续写提示 |
| `/compact --summary` | 仅摘要，不保留详细实现 | 用于快速重启，不保留实现细节 |
| `/status` | 读取 status-tracker 当前状态 | 只读，不修改 |
| `/audit` | 读取最近 10 条审计日志 | 只读，不修改 |

## 约束 vs 信息型上下文区分（见 `04-constraint-vs-info.md`）

- **约束型上下文**（必须遵守的规则）: 加载在系统提示层（CLAUDE.md / AGENTS.md），不随会话压缩丢失
- **信息型上下文**（可变的事实信息）: 加载在会话层（动态检索、NOTES.md），可压缩/更新

---
> 此文件为**规范**。真实项目需按实际会话时长、token 阈值、分段策略调整。
> 建议将会话管理规范纳入团队操作手册，确保所有 Agent 会话一致执行。
