# 五种策展策略配置（L2 上下文工程）

> 报告引用: §4 上下文工程 / §5.10 六组件之上下文工程
> 定位: 五种策展策略 = ① Retrieve + ② Reduce + ③ Isolate + ④ Compact + ⑤ Permission
> 工程归属: L2 上下文工程（动态上下文策展）
> 标签: 【来源已核验✅】

## ① Retrieve（即时检索 / 渐进式披露）

> 不预处理所有相关数据塞进上下文，Agent 维护轻量标识符（文件路径、存储查询、网页链接），运行时用工具动态加载。

**配置要点**:
- 工具白名单: `glob` / `grep` / `ls` / `Read`（动态发现文件）
- 混合策略: Claude Code 先加载 `CLAUDE.md`，再用 `glob/grep` 即时检索
- 数据标识符: 文件路径、Aone 工单号、钉钉文档链接、wiki 查询语句
- 触发规则: 每个新会话开始时自动执行一次检索（加载当前需求相关文件列表）

**占位（待填充）**:
- `[AONE_API_ENDPOINT]`：Aone 工单调用的 API endpoint
- `[DINGTALK_API_ENDPOINT]`：钉钉文档 API
- `[WIKI_SEARCH_ENDPOINT]`：Wiki 检索接口
- `[CODEMAP_PATH]`：codemap 文件路径（长期业务知识索引）

## ② Reduce（保持精简而有效）

> 系统提示、工具、示例、消息历史——每个维度都应深思熟虑保持最少。

**配置要点**:
- 系统提示长度: ≤ 800 tokens（或项目自定义阈值）
- 工具集最小化: 每个会话仅加载该 phase 所需的工具（见 `skill-dispatch-rule.md`）
- Few-shot 示例: 3-5 个，覆盖常见场景，避免边界情况堆砌
- 消息历史压缩: 超过 20 轮对话自动触发 `/compact`（见 `03-session-management.md`）

## ③ Isolate（上下文隔离）

> 各 Agent 独立上下文窗口，避免 Agent 间的 context rot 互相污染。

**配置要点**:
- 单 Agent 模式: 每会话一个独立上下文窗口（默认）
- 多 Agent 模式（L5）: 每个 Worker 独立上下文窗口；协调者仅接收摘要（不接收原始上下文）
- 跨会话隔离: `/clear` 彻底清空上下文；`workflow-check` 重新加载 status-tracker 机读块
- 文件隔离: 工作者在独立 worktree 中执行（见 `gates/worktree-create-snapshot.sh`）

## ④ Compact（压缩）

> 对话临近上限时：摘要内容 → 用摘要重启。高保真蒸馏：保留架构决策、未解决 bug、实现细节，丢弃过程性对话。

**配置要点**:
- 压缩触发阈值: 上下文剩余 token ≤ 2000（或项目自定义）
- 压缩策略: `content-only`（保留内容，丢弃对话格式）→ `summary`（AI 摘要）→ `high-fidelity-distill`（保留架构决策、未解决 bug、实现细节）
- 重启策略: 压缩后生成 `NOTES.md` 写入会话记忆，新会话加载 NOTES.md 继续
- 最轻触碰: 工具结果清除（丢弃深层历史中的原始工具输出），只保留结论

## ⑤ Permission（结构化笔记 / Agent 记忆）

> Agent 定期将笔记持久化到上下文窗口外的记忆（如 NOTES.md、待办列表、记忆工具 beta）。后续拉回。

**配置要点**:
- 持久化文件: `NOTES.md`（待办列表、当前 block 原因、关键决策）
- 记忆仓库: `memory/NOTES.md`（项目记忆仓库，feature 分支）
- 拉回策略: 每次会话启动时 `workflow-check` 读取 NOTES.md 的最近 N 行
- 持久化触发: 每 10 轮对话或每次 `BLOCKED`/`WAITING_USER` 时自动写入
- 格式: Markdown 列表，带时间戳和状态标记（`- [ ] 待办... | 2026-07-11`）

## 策展策略综合调度

```
会话启动 → ① Retrieve（加载 CLAUDE.md + 动态检索需求相关文件）
        → ⑤ Permission（拉回 NOTES.md 记忆）
        → ② Reduce（精简到当前 phase 所需工具+示例）
执行中   → ③ Isolate（各任务/Worker 独立上下文）
临近上限 → ④ Compact（压缩 + 高保真蒸馏 → NOTES.md）
        → ⑤ Permission（新会话拉回蒸馏后的 NOTES.md）
```

---
> 此文件为**配置骨架**。真实项目需按实际数据源 endpoint、token 阈值、压缩策略填充。
> 建议将策展策略配置纳入版本控制，作为 L2 层基础设施统一管理。
