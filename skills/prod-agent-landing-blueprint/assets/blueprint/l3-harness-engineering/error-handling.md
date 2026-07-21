# 错误处理与恢复（L3 Harness 通用）

> 报告引用: §5  Harness 工程（六组件中的「成本监控与错误处理」）/ §6.9 反馈原则（尽早纠偏、信任但验证）
> 定位: 建立统一的错误处理、告警、恢复机制，确保 Agent 出错时不失控、不丢失进度。
> 标签: 【来源已核验✅】

## 错误分类与处理策略

| 错误类型 | 定义 | 自动处理 | 人工介入 | 成本影响 |
|----------|------|----------|----------|----------|
| **临时错误** | API 超时、网络抖动、服务短暂不可用 | 指数退避重试（max 3次） | 重试失败后 BLOCKED | 低（重试 token） |
| **逻辑错误** | Agent 理解偏差、代码逻辑错误 | 记录到 NOTES.md，标记 REVISING | 人工审查后修正 | 中（重新实现 token） |
| **权限错误** | Agent 尝试越权操作（如 bypass 模式外的 push） | PreToolUse deny 阻断 | 审查权限配置 | 低（阻断无执行） |
| **上下文错误** | 上下文不足/过满、信息丢失 | 自动 Retrieve / Compact | 若仍不足则 WAITING_USER | 中（检索 token） |
| **致命错误** | 系统崩溃、数据丢失、不可恢复状态 | 立即停止会话，BLOCKED | 紧急人工介入 | 高（可能需重做） |
| **成本超标** | 单次会话/需求级成本超过阈值 | 自动 compact / 强制停止 | 审查策展策略/需求拆分 | 高（已消耗 token） |

## 错误处理流程

```
错误发生
  │
  ├─ 临时错误 ──► 重试（指数退避）──► 成功？──► 是：继续 / 否：BLOCKED
  │
  ├─ 逻辑错误 ──► 记录到 NOTES.md ──► 状态 REVISING ──► 人工审查 ──► 修正
  │
  ├─ 权限错误 ──► PreToolUse deny ──► 记录 audit-log ──► BLOCKED
  │
  ├─ 上下文错误 ──► 自动 Retrieve/Compact ──► 恢复？──► 是：继续 / 否：WAITING_USER
  │
  └─ 致命/成本错误 ──► 立即停止 ──► BLOCKED ──► 紧急人工介入
```

## 告警通道配置（骨架）

| 通道 | 用途 | 触发条件 | 当前状态 |
|------|------|----------|----------|
| **Slack/飞书** | 实时告警（WARN/ERROR/CRITICAL） | 权限错误、成本超标、致命错误 | 待配置 `[WEBHOOK_URL]` |
| **邮件** | 每日/每周汇总报告 | 成本汇总、审计闭合率、确定性评分 | 待配置 `[SMTP_CONFIG]` |
| **Aone/钉钉** | 工单级告警（与产研流程集成） | BLOCKED 状态变更、WAITING_USER 超时 | 待配置 `[AONE_WEBHOOK]` |

## 恢复机制

1. **会话级恢复**: `status-tracker.md` + `NOTES.md` + `audit-log.jsonl` 三件套保证崩溃后恢复
2. **任务级恢复**: `tasks.md` 中每个任务独立，失败后可单独重试
3. **需求级恢复**: `spec.md` / `plan.md` 作为基线，任何时候可从 `DESIGNING` 重新开始
4. **全局恢复**: `CLAUDE.md` / `AGENTS.md` 作为持久提示层，跨需求不变

## 错误日志格式

```json
{
  "error_id": "err-20260711-001",
  "type": "Temporary|Logic|Permission|Context|Fatal|Cost",
  "phase": "IMPLEMENTING",
  "task_id": "T-003",
  "message": "API timeout after 3 retries",
  "stack_trace": "...",
  "recovery_action": "RETRY|BLOCKED|WAITING_USER",
  "cost_at_failure_usd": 2.5,
  "timestamp": "2026-07-11T17:32:19Z",
  "session_id": "sess-uuid"
}
```

---
> 此文件为**处理骨架**。真实项目需按实际告警通道（Slack/飞书/邮件）、阈值配置填充。
> 建议将错误处理流程纳入团队 On-call 手册，确保 BLOCKED/CRITICAL 级别有人响应。
