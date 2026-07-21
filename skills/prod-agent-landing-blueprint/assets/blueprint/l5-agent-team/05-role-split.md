# Agent Team 职责拆分方案（L5 Agent Team）

> 报告引用: §13 Agent Team / §5.11 Harness 设计原则 / §10.1 场景路由
> 定位: 从单 Agent 走向 Agent Team，按独立判断/产物/并行/责任隔离需要拆分，不按流程步骤机械切分。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L5 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 拆分原则（报告原文）

> 报告原文："不按流程步骤机械切分，看独立判断/产物/并行/责任隔离需要。"

| 拆分维度 | 说明 | 示例 |
|----------|------|------|
| **独立判断** | 该角色需要独立的技术判断，不受其他角色干扰 | 前端技术选型 vs 后端架构决策 |
| **独立产物** | 该角色产出的制品可独立交付、独立验证 | 前端 UI 组件 vs 后端 API |
| **并行能力** | 该角色的工作可与其他角色并行执行 | 前端开发可与后端开发并行 |
| **责任隔离** | 该角色的责任边界清晰，不与其他角色重叠 | 测试质量责任独立于开发 |

## 推荐角色拆分

### 核心拆分（最小可行 Agent Team）

| 角色 | 职责 | 工具集 | Worktree | 权限模式 |
|------|------|--------|----------|----------|
| **Coordinator** | 任务分配、结果综合、状态同步、冲突仲裁 | 4 个编排工具 | 无（只读报告） | `plan` |
| **前端 Worker** | UI/UX 实现、前端测试、前端代码审查 | Full（前端工具集） | 独立 worktree | `default`/`acceptEdits` |
| **后端 Worker** | API/服务实现、数据库变更、后端测试 | Full（后端工具集） | 独立 worktree | `default`/`acceptEdits` |
| **测试 Worker** | 测试用例设计、自动化测试、回归测试 | Full（测试工具集） | 独立 worktree | `default`（测试不改代码）|
| **合并代理** | 唯一主干写入方、CI 校验触发 | 仅合并相关工具 | 验证 worktree | `bypass`（极度受限）|

### 扩展拆分（按需增加）

| 角色 | 拆分触发条件 | 职责 | 工具集 |
|------|-------------|------|--------|
| **PD Agent** | 上游纳入 | 生成 PRD 与验收标准 | Read/Write（文档），无代码权限 |
| **数据专家 Agent** | 数据相关需求 | 数据模型设计、SQL/ETL | Full（数据工具集） |
| **运维 Agent** | 部署/配置变更需求 | 配置管理、部署脚本 | Simple（Bash/Read） |
| **安全 Agent** | 安全审查需求 | 代码安全扫描、漏洞检测 | `plan`（只读审查） |

### 拆分决策树

```
需求进入
  │
  ├─ 单一技术栈（纯前端或纯后端）──► 单 Worker + Coordinator（精简模式）
  │
  ├─ 前后端分离 ──► 前端 Worker + 后端 Worker + Coordinator
  │
  ├─ 需要独立测试 ──► + 测试 Worker
  │
  ├─ 需要数据变更 ──► + 数据专家 Worker
  │
  ├─ 需要配置/部署 ──► + 运维 Worker
  │
  └─ 需要安全审查 ──► + 安全 Worker（plan 模式，只读审查）
```

## 各角色的详细职责

### PD Agent（上游）
- **何时激活**: 需求进入时（Phase 0 之前）
- **职责**: 生成 PRD（产品需求文档）、定义验收标准、回答业务问题
- **产出**: PRD.md、验收标准清单
- **工具**: Read/Write（文档工具）、WebSearch（竞品调研）
- **不持有**: 代码读写权限、Git 权限
- **与 Coordinator 关系**: PD Agent 产出 PRD → Coordinator 接收并拆解为技术任务

### 前端 Worker
- **何时激活**: Phase 3（实现阶段）
- **职责**: UI/UX 实现、前端组件开发、前端测试（Jest/Cypress）、前端代码审查
- **独占文件集**: `src/components/`, `src/pages/`, `public/`, `tests/frontend/`
- **与后端 Worker 协作**: 通过 `scratchpad/shared/interface-draft.md` 定义 API 契约
- **质量门**: 前端 pre-push gate（ESLint + 覆盖率）

### 后端 Worker
- **何时激活**: Phase 3（实现阶段）
- **职责**: API 实现、服务逻辑、数据库变更（Flyway/Liquibase）、后端测试（JUnit/pytest）
- **独占文件集**: `src/api/`, `src/service/`, `src/repository/`, `migrations/`, `tests/backend/`
- **与前端 Worker 协作**: 通过 `scratchpad/shared/interface-draft.md` 定义 API 契约
- **质量门**: 后端 pre-push gate（PMD + 覆盖率 + 配置 schema 校验）

### 测试 Worker
- **何时激活**: Phase 3-5（实现到验收）
- **职责**: 测试用例设计（正例/反例/边界）、自动化测试执行、回归测试、验收验证
- **独占文件集**: `tests/`, `e2e/`, `performance/`
- **与开发 Worker 关系**: 测试 Worker 可读取开发 Worker 的代码，但不直接修改（发现 bug 后报告给 Coordinator，由对应 Worker 修复）
- **质量门**: 全量测试通过 + 回归测试通过

### 数据专家 Worker
- **何时激活**: 数据相关需求
- **职责**: 数据模型设计、SQL/ETL 脚本、数据质量校验
- **独占文件集**: `db/`, `etl/`, `data-quality/`
- **质量门**: 数据 schema 校验 + ETL 测试通过

### 运维 Worker
- **何时激活**: 部署/配置变更需求
- **职责**: 配置文件变更、部署脚本、环境验证
- **独占文件集**: `ops/`, `config/`, `deploy/`
- **质量门**: 配置 schema 校验 + 部署验证

## 共享长期 wiki 与各自维护视角

> 报告原文："共享长期 wiki，各自维护视角——所有 Agent 共享业务知识保证一致，各拆自己 requirements/plan，队长对齐接口契约。"

| 知识类型 | 共享仓库 | 各角色维护视角 |
|----------|----------|--------------|
| 业务知识 | 长期 wiki（master） | 各角色按需读取，不修改 |
| 代码地图 | 长期 wiki（master） | 各角色补充自己领域的 codemap |
| 接口契约 | Scratchpad + 长期 wiki | 前后端 Worker 协作定义，最终写入 wiki |
| 工程规范 | 长期 wiki（master） | Coordinator 统一维护，各角色遵循 |
| 需求文档 | 项目记忆（feature） | PD Agent/Coordinator 维护 |
| 技术方案 | 项目记忆（feature） | 各 Worker 维护自己的 plan.md |

## 拆分后的协作流程

```
Phase 0: 上下文组织
  PD Agent 生成 PRD ──► Coordinator 接收
  │
Phase 1: 需求澄清
  Coordinator 拆解需求 ──► 各 Worker 并行 clarifying（如需要）
  │
Phase 2: 技术方案
  各 Worker 并行写 plan.md ──► Coordinator 对齐接口契约 ──► CR 确认
  │
Phase 3: 实现
  各 Worker 并行实现（独立 worktree）──► Scratchpad 共享接口契约和阻塞项
  │
Phase 4: 协同反馈
  Coordinator 收集 CR 评论 ──► 分配给对应 Worker ──► resolve
  │
Phase 5: 验收验证
  测试 Worker 执行全量测试 ──► Coordinator 汇总结果 ──► 人工确认
  │
Phase 6: 发布与结项
  合并代理执行合并 ──► 各 Worker 与 Coordinator 共同完成结项蒸馏
```

## 激活条件

| 前提 | 状态 | 说明 |
|------|------|------|
| L4 Loop 跑通 | 待激活 | 单 Agent 六阶段闭环须证明可行 |
| 多 Agent 运行时 | 待配置 | 须支持并行 Agent 会话 |
| 接口契约定义 | 待填充 | 前后端/各 Worker 间须有明确的接口契约 |
| 独占文件集划分 | 待填充 | 各 Worker 的文件边界须清晰定义 |
| 合并代理就绪 | 待配置 | 合并代理的角色和权限须就绪 |

---
> 此文件为**拆分方案**。真实项目需按实际团队规模、技术栈、需求类型调整角色和职责。
> 建议从「Coordinator + 前端/后端 Worker」最小三角色开始试点，验证协作流畅后再扩展测试/数据/运维角色。
