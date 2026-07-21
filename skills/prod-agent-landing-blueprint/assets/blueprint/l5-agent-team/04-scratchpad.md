# Scratchpad 共享协作空间协议（L5 Agent Team）

> 报告引用: §13 Agent Team / §5.11 设计原则（上下文隔离）
> 定位: 跨工作者共享临时文件空间，作为"共享记忆"弥补工作者间无法直接通信。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L5 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## Scratchpad 定义

> 报告原文："跨工作者共享临时文件空间（/tmp/claude-{uid}/{sanitized-cwd}/{sessionId}/scratchpad/）。特性：无权限提示、持久化跨工作者知识、会话隔离、结构自由。"

| 特性 | 说明 |
|------|------|
| **无权限提示** | 工作者可在 Scratchpad 中自由读写，不受权限模式限制（但仅局限于 Scratchpad 目录） |
| **持久化跨工作者知识** | 一个 Worker 写入的分析结果，其他 Worker 可读取复用 |
| **会话隔离** | 每个会话的 Scratchpad 独立，不跨会话污染 |
| **结构自由** | 无强制格式，Worker 按需组织内容 |

## 目录结构

```
/tmp/claude-{uid}/{sanitized-cwd}/{sessionId}/scratchpad/
├── research/                    # Research 阶段产出
│   ├── worker-a-discovery.md    # Worker A 的代码调查发现
│   ├── worker-b-discovery.md    # Worker B 的代码调查发现
│   └── ...
├── synthesis/                   # Synthesis 阶段产出
│   ├── implementation-spec.md   # Coordinator 编写的实施规格
│   └── task-assignments.json    # 任务分配表
├── implementation/              # Implementation 阶段产出
│   ├── worker-a-changes.json    # Worker A 的变更清单
│   ├── worker-b-changes.json    # Worker B 的变更清单
│   └── ...
├── verification/                # Verification 阶段产出
│   ├── worker-a-test-results.md # Worker A 的测试结果
│   ├── worker-b-test-results.md # Worker B 的测试结果
│   └── issues-found.md          # 发现的问题列表
└── shared/                      # 跨阶段共享信息
    ├── codemap-notes.md         # 代码地图笔记（各 Worker 补充）
    ├── interface-draft.md       # 接口草稿（前后端 Worker 协作）
    └── blockers.md              # 阻塞事项（实时更新）
```

## 使用协议

### Research 阶段
- 各 Worker 并行调查代码库
- 每个 Worker 将自己的发现写入 `research/worker-{id}-discovery.md`
- **禁止**: 在 Research 阶段修改代码文件（只读调查）

### Synthesis 阶段
- Coordinator 读取所有 `research/` 文件
- Coordinator 综合后写入 `synthesis/implementation-spec.md`
- Coordinator 将任务分配写入 `synthesis/task-assignments.json`
- **禁止**: Workers 在 Synthesis 阶段写入（只读等待分配）

### Implementation 阶段
- 各 Worker 按 `task-assignments.json` 执行任务
- 各 Worker 将自己负责文件的变更写入 `implementation/worker-{id}-changes.json`
- 格式: `{"file": "src/...", "changes": [{"line_start": 10, "line_end": 20, "description": "..."}]}`
- **禁止**: Worker 修改不属于自己任务集的文件（冲突防护）

### Verification 阶段
- 各 Worker 测试自己的修改
- 测试结果写入 `verification/worker-{id}-test-results.md`
- 发现的问题写入 `verification/issues-found.md`
- **禁止**: 在 Verification 阶段引入新代码变更（只修复问题）

### 跨阶段共享
- `shared/codemap-notes.md`: 各 Worker 补充代码地图信息（如发现的隐式依赖）
- `shared/interface-draft.md`: 前后端 Worker 协作定义接口契约
- `shared/blockers.md`: 实时更新的阻塞事项，Coordinator 据此调整任务分配

## 与 Worktree 的关系

| 维度 | Scratchpad | Worktree |
|------|------------|----------|
| 目的 | Worker 间通信/共享记忆 | 代码隔离/防污染 |
| 位置 | `/tmp/...`（临时空间） | 项目目录下的独立 Git worktree |
| 持久性 | 会话级（session 结束后清理） | 需求级（feature 分支） |
| 权限 | 无权限提示（自由读写） | 受 Git 权限和 Hook 约束 |
| 内容 | 分析、计划、问题、笔记 | 实际代码变更 |
| 写入时机 | Research/Synthesis/Verification | Implementation |

## 清理策略

- 会话正常结束时：Coordinator 将有价值的内容蒸馏到 `memory/NOTES.md` 或 `wiki/`，然后删除 Scratchpad
- 会话异常结束时：保留 Scratchpad 72 小时供故障排查，然后自动清理
- 单个文件大小限制：≤ 1MB（防止占用过多磁盘）
- 总大小限制：≤ 50MB（超出时自动 compact 最旧文件）

## 冲突避免

| 策略 | 说明 |
|------|------|
| 文件命名空间隔离 | `worker-{id}-{filename}` 避免同名冲突 |
| 写入时段隔离 | Research/Implementation 阶段 Worker 写；Synthesis 阶段 Coordinator 写；Verification 只读 |
| 版本标记 | 每个文件顶部标注版本号和时间戳，读取时检查是否为最新 |
| 合并代理仲裁 | 若发现同一文件被修改，由合并代理或 Coordinator 仲裁 |

---
> 此文件为**协议定义**。真实项目需按实际多 Agent 运行时环境、磁盘配额、清理策略调整。
> Scratchpad 是 L5 多 Agent 协作的基础通信机制，建议先在小范围（2-3 个 Worker）验证后再扩展。
