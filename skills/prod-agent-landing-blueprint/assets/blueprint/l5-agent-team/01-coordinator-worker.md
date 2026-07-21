# Coordinator-Worker 架构（L5 Agent Team）

> 报告引用: §13 Agent Team / §5.11 Harness 设计原则（Orchestrator ≠ Implementer、并行读者单一写者）
> 定位: 中心化多智能体编排方案。协调者仅负责任务分配与结果综合，不是执行者。
> 与 Fork 模式互斥：Coordinator 激活时自动禁用 Fork。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L5 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 架构概览

```
                    ┌──────────────┐
                    │   PD Agent     │  上游：生成 PRD 与验收标准
                    │（非团队内部）    │
                    └──────┬───────┘
                           │ PRD + 验收标准
                           ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Coordinator  │◄───│  Worker A    │    │  Worker B    │
│  （协调者）     │    │（前端 Agent）  │    │（后端 Agent）  │
│              │    │              │    │              │
│ - 任务分配    │───►│ - 读/写/执行  │    │ - 读/写/执行  │
│ - 结果综合    │◄───┤ - 测试        │    │ - 测试        │
│ - 状态同步    │    │ - 报告进展    │    │ - 报告进展    │
│ - 冲突仲裁    │    └──────────────┘    └──────────────┘
└──────┬───────┘           │                    │
       │                   ▼                    ▼
       │           ┌──────────────┐    ┌──────────────┐
       │           │  Worker C      │    │  其他 Worker   │
       │           │（测试 Agent）  │    │（数据/运维...）│
       │           └──────────────┘    └──────────────┘
       │
       │ 接口契约对齐
       ▼
┌──────────────┐
│  Merge Agent   │  唯一主干写入方（合并代理）
│（合并代理）     │  - 在 worktree 验证后执行结构化合并
└──────────────┘
```

## 协调者（Coordinator）

### 核心职责
1. **任务分配**: 将需求拆解为子任务，分配给合适的 Worker
2. **结果综合**: 收集各 Worker 的结果，综合为最终产出
3. **状态同步**: 维护全局 status-tracker，同步各 Worker 的 phase/state
4. **冲突仲裁**: 当 Worker 间出现冲突（如同一文件修改）时，仲裁或抛 WAITING_USER

### 工具集（仅 4 个核心编排工具）

> 报告原文："协调者专属工具仅 4 个核心编排工具，明确无 Read/Write/Edit/Bash 等执行工具——协调者不执行。"

| 工具 | 功能 | 权限 |
|------|------|------|
| **Agent Tool** | 创建/分配任务给 Worker | `plan`（只读，不执行） |
| **TaskStop Tool** | 停止某个 Worker 的任务 | `plan`（管理权限） |
| **SendMessage Tool** | 向 Worker 发送消息/指令 | `plan`（通信权限） |
| **Structured Output Tool** | 生成结构化输出（如任务分配表、进度报告） | `plan`（输出权限） |

### 禁止工具
- ❌ Read（不读原始代码）
- ❌ Write/Edit（不写文件）
- ❌ Bash（不执行命令）
- ❌ Grep/Glob（不直接搜索代码库）
- ❌ WebSearch（不直接检索）
- ❌ Skill（不直接调用 Skill）
- ❌ MCP（不直接调用外部系统）

### 上下文策略
- 协调者只看摘要（Reduce 策略），不看原始代码
- 通过 Workers 的报告了解进展，不直接查看实现细节
- 避免上下文被 Worker 的执行细节污染

## 工作者（Worker）

### 核心职责
1. **具体执行**: 按 Coordinator 分配的任务执行（读/写/测试）
2. **进度报告**: 定期向 Coordinator 报告进展和遇到的问题
3. **独立验证**: 在独立 worktree 中执行，不污染主干

### 工具集（执行白名单）

> 报告原文："工作者工具集拥有执行权（Read/Write/Edit/Bash/Grep/Glob/WebSearch/Skill/MCP 等），排除管理工具。"

| 工具类别 | 具体工具 | 说明 |
|----------|----------|------|
| 文件操作 | Read, Write, Edit | 基本读写 |
| 搜索 | Grep, Glob, WebSearch | 代码和外部信息检索 |
| 执行 | Bash | 脚本执行（在沙箱内） |
| 技能 | Skill | 调用标准 Skill（clarify/plan/execute 等） |
| 外部 | MCP | 调用外部系统（Aone/钉钉/监控） |
| 禁止 | Agent Tool, TaskStop Tool | 排除管理工具（保留给 Coordinator） |

### 两种工作模式

| 模式 | 工具 | 适用场景 |
|------|------|----------|
| **Simple** | Bash, Read, Edit | CI/CD 场景、简单脚本任务 |
| **Full** | 全部白名单工具 | 复杂开发任务、需要全量工具的场景 |

默认: `acceptEdits` 权限模式（自动化脚本场景）

## 四阶段标准任务工作流

> 报告原文四阶段标准任务工作流。

| 阶段 | 执行者 | 动作 | 产出 | 写入位置 |
|------|--------|------|------|----------|
| **Research** | Workers（并行） | 调查代码库、发现文件 | Scratchpad 分析文档 | Scratchpad 共享空间 |
| **Synthesis** | Coordinator | 阅读发现、消化理解、编写实施规格 | 实施规格文档（含具体路径/行号） | 发送给 Workers |
| **Implementation** | Workers | 按规格精确修改（写任务独占文件集） | 代码变更 | 各 Worker 的 worktree |
| **Verification** | Workers | 测试修改正确性 | 测试结果/问题列表 | Scratchpad + 报告 Coordinator |

## 与 Fork 模式对比

| 维度 | Coordinator-Worker | Fork（去中心化） |
|------|-------------------|------------------|
| 架构 | 中心化 | 去中心化 |
| 上下文共享 | 工作者只看分配任务 | 所有子智能体继承完整父上下文 |
| 通信 | 协调者中转/Scratchpad | 无直接通信 |
| 任务分配 | 显式分配精确控制 | 隐式并行各自独立 |
| 缓存效率 | 不共享缓存前缀 | 字节级共享高效 |
| 适用 | 需协调的复杂多步骤 | 独立并行调查/搜索 |
| 故障恢复 | 协调者重新分配 | 主智能体收失败通知后决定 |
| 当前阶段 | 推荐（L5 阶段） | 暂不推荐（后续可扩展） |

## 关键设计约束

1. **Orchestrator ≠ Implementer**: 协调者不执行，避免上下文被污染
2. **并行读者单一写者**: Workers 可并行读取，写需独占（通过 worktree 隔离）
3. **上下文隔离**: 各 Worker 独立上下文窗口，避免 context rot 互相污染
4. **冲突处理**: Worker 间冲突由 Coordinator 仲裁，或抛 WAITING_USER

## 激活条件

| 前提 | 状态 | 说明 |
|------|------|------|
| L4 Loop 跑通 | 待激活 | 六阶段闭环须在单 Agent 上跑通，证明流程可行 |
| 多 Agent 运行时环境 | 待配置 | Claude Code / Codex 须支持多 Agent 会话 |
| Scratchpad 共享空间 | 待配置 | `/tmp/claude-{uid}/.../scratchpad/` 须可访问 |
| 合并代理就绪 | 待配置 | 合并代理的角色和权限须定义清楚 |

---
> 此文件为**架构定义**。真实项目需按实际多 Agent 运行时环境、团队规模、任务类型调整。
> 建议先在 1 个简单需求上（如纯前端或纯后端）试点 Coordinator-Worker，再扩展到全团队。
