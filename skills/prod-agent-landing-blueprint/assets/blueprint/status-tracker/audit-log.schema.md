# append-only 审计日志 schema（审计总账底层支撑）

> 报告引用: §9.1 / §10.4 硬门禁边界表 / §10.4 审计总账闭合
> 形态: PostToolUse 记录（覆盖 Write/Edit/Bash/MCP）+ 落项目记忆仓
> 标签: 【来源已核验✅·落地待验证⚠️】（落地依赖项目记忆仓落库位置）

## 一、采集底座
- 唯一规范采集底座 = PostToolUse Hook 统一落盘。
- 覆盖工具：`Write` / `Edit` / `Bash` / `MCP`（原仅记模型输出、漏记 Bash，已补）。
- 同一 `idempotency_key` 重复出现则跳过（幂等）。
- 仅证据；判定在 CI / PreToolUse（非审计日志自身）。

## 二、单行字段（JSONL，一行一事件）
```json
{
  "idempotency_key": "ev-000123",
  "type": "Write|Edit|Bash|MCP",
  "artifact": "src/foo.py",
  "ci_id": "ci-2026-0711-0042",
  "op": "create|update|delete|run",
  "ts": "2026-07-11T16:31:56Z",
  "approver": "LT"
}
```

| 字段 | 含义 |
|------|------|
| `idempotency_key` | 幂等键（与 status-tracker.last_event_id 对齐） |
| `type` | 副作用工具类型 |
| `artifact` | 受影响制品路径 |
| `ci_id` | 关联 CI 标识 |
| `op` | 操作类型 |
| `ts` | ISO8601 时间戳 |
| `approver` | 审批人 |

## 三、闭合规则（§10.4 审计总账闭合）
闭合 = 审计事件日志中本变更包涉及的每条副作用（Write/Edit/Bash/MCP）均有记录、
`idempotency_key` 无重复、且 `CI-ID` 与变更包一致。
- eco-gate 在合并前比对「事件日志条目」与「变更包声称的副作用清单」，任一对不上即阻断。
- 对账机制：CI 每轮读取日志生成「副作用清单快照」，与 status-tracker 声称项交叉验证；差异超阈值即告警。

## 四、落库位置
- 报告定义：落**项目记忆仓**。
- 当前环境：schema 可定义，但项目记忆仓路径/PostToolUse 落盘器待配 → 仅部分可跑。

## 五、格式约定
- append-only：禁止就地修改/删除历史行；修正须追加新行（带 revert/append 语义）。
- 文件建议：`memory/audit-log.jsonl`（路径以项目记忆仓实际布局为准）。
