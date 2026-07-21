# 合并代理（Merge Agent）— 唯一主干写入方（L5 Agent Team）

> 报告引用: §13 Agent Team / §5.11 设计原则（并行读者单一写者）/ §8.3 合并回主干 / §10.4 eco-gate
> 定位: 作为唯一主干写入方，在 worktree 验证通过后执行结构化合并，不解析语义、冲突抛 WAITING_USER。
> 与 Coordinator 边界: Coordinator 仅编排（分配/汇总），不持写主干权限；合并代理是独立进程/角色，仅合并阶段激活。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L5 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 合并代理的职责

1. **结构化合并**: 在 worktree 验证通过后，执行 `requirement/`、wiki 仓按字段对齐合并，代码仓走 PR + CI required checks
2. **不解析语义**: 合并代理不解析代码语义、不处理逻辑冲突，仅执行结构化合并操作
3. **冲突抛 WAITING_USER**: 遇到无法自动合并的冲突时，抛 WAITING_USER 由人工解决
4. **CI 校验触发**: 合并前触发 CI 校验（读 ECO 证据 + 审计总账），green 才合并

## 合并流程

```
验证通过（VERIFYING → RELEASING）
  │
  ▼
合并代理激活（仅此时赋予 bypass 权限）
  │
  ├─ 步骤1: 在独立 worktree 中拉取最新主干
  │
  ├─ 步骤2: 将 Worker 的 feature 分支变更应用至 worktree
  │         （不 push，只在本地 worktree 验证）
  │
  ├─ 步骤3: 运行 CI 校验（deterministic checks + eco-evidence + audit-closure）
  │         （与 required-checks.yml 对齐）
  │
  ├─ 步骤4: 检查审计总账闭合
  │         （比对 event-log 与变更包副作用清单）
  │
  ├─ 步骤5: 检查 eco-gate 证据
  │         （status-tracker.ci_id / last_event_id 与 audit-log 对账）
  │
  ├─ 步骤6: 结构化合并
  │   ├─ requirement/ 目录：按字段对齐合并（spec/plan/tasks/status-tracker）
  │   ├─ wiki 仓：稳定知识蒸馏后按字段对齐合并
  │   └─ 代码仓：走 PR + CI required checks（非直接 push）
  │
  ├─ 步骤7: 若冲突 → 抛 WAITING_USER（人工解决冲突）
  │
  └─ 步骤8: 合并完成后 → 休眠合并代理（撤销 bypass 权限）
  │
  ▼
RELEASING → 观察期 → CLOSED
```

## 合并代理的权限边界

| 操作 | 允许？ | 说明 |
|------|--------|------|
| `git pull` 主干 | ✅ | 拉取最新主干基线 |
| `git merge` feature 分支 | ✅ | 在 worktree 中验证合并 |
| `git push` 主干 | ✅ | 仅 CI green 后，须过 eco-gate |
| 修改代码文件 | ❌ | 不解析语义，冲突抛 WAITING_USER |
| 修改 `CLAUDE.md` / `AGENTS.md` | ❌ | 持久提示层变更须走独立变更流程 |
| 修改 `status-tracker.md` | ❌ | 状态机由 workflow-check 维护 |
| 调用 Skill | ❌ | 合并代理不调用 Skill |
| 调用 MCP（除 CI API） | ❌ | 仅允许查询 CI 状态 |

## 冲突处理策略

| 冲突类型 | 处理方式 | 决策者 |
|----------|----------|--------|
| 代码行级冲突（git merge 冲突） | 抛 WAITING_USER | 人工解决 |
| 文件级冲突（同一文件被多个 Worker 修改） | Coordinator 仲裁 → 重分配 | Coordinator |
| 架构级冲突（聚合根/限界上下文变更冲突） | 抛 WAITING_USER + CCB/ARB 审查 | 架构委员会 |
| 配置冲突（同 key 不同 value） | schema 校验 → 抛 WAITING_USER | 人工确认 |
| requirement/ 字段冲突 | 按字段对齐合并（时间戳优先） | 合并代理（结构化） |

## 与 CI 的协同

- 合并代理在步骤3-5 完全依赖 CI 运行结果
- CI 运行 `required-checks.yml` 中的三个 job：
  - `deterministic-checks`: PMD + 覆盖率
  - `eco-gate-evidence`: 变更包副作用清单 ↔ 审计事件日志 闭合
  - `audit-log-present`: append-only 审计日志 闭合
- 对于 gtmc 项目，额外运行 `gtmc-overlay`：P3.5 校准 + A-5.16 终验

## 与 eco-gate 的协同

- 合并代理的 `git push` 同样经过 `eco-gate.sh` 的 PreToolUse deny
- 合并代理的 push 命令: `git push origin main`
- eco-gate 检查: status-tracker.ci_id 存在、last_event_id 与 audit-log 对账一致、ECO 测试报告存在
- 任一检查失败 → deny（exit 2）→ 合并代理休眠 → WAITING_USER

## 合并代理激活/休眠机制

| 状态 | 触发条件 | 权限 | 说明 |
|------|----------|------|------|
| 休眠 | 默认状态 | 无权限 | 不持有任何工具或权限 |
| 激活 | `VERIFYING` → `RELEASING` 转换时 | `bypass`（但白名单极度受限） | 仅允许合并相关操作 |
| 强制休眠 | 合并完成后或 30 分钟超时 | 撤销所有权限 | 防止权限残留 |

---
> 此文件为**合并代理定义**。真实项目需按实际代码合并策略、CI 配置、冲突解决流程填充。
> 合并代理是 L5 的关键安全角色，建议由专人/专用环境执行，不与其他 Agent 共享运行时。
