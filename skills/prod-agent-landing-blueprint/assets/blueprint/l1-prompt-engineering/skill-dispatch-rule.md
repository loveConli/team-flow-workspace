# Skill 调度规则骨架（L1 提示词工程）

> 报告引用: §3 提示词工程 / §5.10 六组件 / §6.2 六阶段纵向闭环（每阶段对应 Skill）
> 定位: 定义 Skill 的触发条件、调度逻辑、上下文加载策略。将关键指令从「每次手动输入」变为「自动加载、始终生效」的工程化基础设施。
> 标签: 【来源已核验✅】

## 一、Skill 注册表

> 项目级 Skill 注册表。每个 Skill 含：名称、触发条件、优先级、权限模式、产出物。

| Skill 名称 | 触发条件 | 优先级 | 权限模式 | 产出物 | 工程归属 |
|------------|----------|--------|----------|--------|----------|
| superai-clarify | 新需求进入（spec.md 存在但未确认） | 高 | `default` | requirements 文档 | L1 提示词 + L3 Harness（确认门） |
| superai-plan | requirements 已确认 | 高 | `default` | plan.md | L1 提示词 + L3 Harness（CR门） + L2 上下文 |
| superai-execute | plan.md 已确认 | 高 | `acceptEdits` | 代码变更 + 测试 | L3 Harness（硬卡口） + L1 提示词（TDD） |
| superai-aone | CR 评论 / milestone 回刷 | 中 | `default` | resolved CR 评论 | L4 Loop + L3 Harness |
| superai-finish | 验收通过（RELEASING → CLOSED） | 低 | `plan` | closeout raw log + 蒸馏产物 | L4 Loop（反馈学习） |
| eco-gate | git push/merge 触发 | 最高 | `bypass`（确定性执行器） | deny/放行 | L3 Harness（不可为 skill） |
| workflow-check | 每次会话启动 | 最高 | `plan` | 只读读取 status-tracker | L3 Harness |
| scope-classifier | 变更触发升级评估 | 高 | `plan` | 升级路由判定 | L3 Harness（依赖架构注册表） |

## 一（补）、superai-clarify SKILL 规格要点（评审 P0-B）

> 交互层入口：`/ltflow clarify`（经 `where-am-i` 分诊后路由）。本规格补「模糊想法 → 明确」的轻量化落地。

### 1. fast-path 阈值（跳过 Grill Me 直接进 DESIGNING 轻量 design）
满足以下**任一**条件 → 跳过 Grill Me，直接进入 `CLARIFYING → DESIGNING` 出**轻量 `design` 制品**：
- **单文件改动**：影响面 ≤ 1 个文件 / 极小 diff；
- **需求明确**：spec 或用户意图清晰、无歧义；
- **改动量 < 阈值**：如 ≤ 20 行 / 单一函数级。
不满足 → 走完整 **Grill Me**（遵循「能查的不问」，只问真歧义 + 重大分叉带推荐答案）。

### 2. 「能查的不问」判定规则
- **不问**：读代码库（`glob`/`grep`/`Read`）+ 读知识库（wiki / codemap / artifact-graph 制品图）可确定的事实——现有接口签名、字段含义、既有约定、历史决策。
- **才问**：仅①**真歧义**（多解且各解影响显著不同）+ ②**重大技术分叉**（架构/技术选型/外部依赖，影响面大）。
- **问法**：每个问题**带推荐答案**（默认推荐项 + 1-2 备选），降低人负担。

### 3. 重大技术分叉人拍板清单（须 LT 人工确认，不得 AI 自决 → `WAITING_USER`）
- 架构/分层选型（单体 vs 微服务、同步 vs 异步）；
- 外部依赖引入（新第三方库 / SDK / 服务）；
- 数据模型/存储选型（SQL vs NoSQL、ORM 选型）；
- 付费 / 权限 / 合规相关变更（对应人工门 **D**）；
- 与既有聚合根/限界上下文冲突的改动。
→ 落入 `WAITING_USER`，由 LT 拍板后继续；不得 AI 自决。

### 4. CLARIFY → 制品图薄适配（评审 K1 双真相源）
- Grill Me 结论**直接落制品**：`feature` / `scenario` / `decision`（artifact-graph 核心六类型，**始终启用**）。
- 或：`clarify.md` 在 `CLARIFYING → DESIGNING` 迁移时 **promote 为 `feature` 制品并注册追溯**（`related_*` frontmatter + traceability comment + `version-lock` 记版本）。
- 轻量 `design` 同样走 artifact-graph：`design` 为核心类型，`validate` / `version-lock` 已可用（见 `prototype-stage-integration.md`）。

### 5. 教学 profile 适配（评审 P1 · 不含 ima 桥）
- **无代码库阶段（课程/教学）**：仅 `CLARIFY` + 轻 `design`（不强制实现/测试）；基础六类型中按需启用 `feature`/`decision`/`scenario`，不必全开。
- **实训阶段**：基础六类型（`feature/scenario/decision/design/test/e2e_test`）**始终启用（非谈判项）**。
- **fast-path 默认开**：教学场景默认开启 fast-path，降低学生负担。
- **课程版 review-checklist**：复用项目本地 review skill 机制（如 `templates/core/*/review-checklist.md`），课程可覆盖为教学版清单。

### 6. 「轻」的口径（评审 K2）
「默认最轻、证据驱动加重」的「轻」= **仪式/类型从轻**（如少开扩展类型、fast-path 默认开），**不指门禁强度**——`eco-gate` / `pre-push` / `CI required checks` 同样硬卡（fail-closed，见 P0-A）。

## 二、调度规则

1. **优先级规则**: `eco-gate` > `workflow-check` > `scope-classifier` > `superai-clarify` > `superai-plan` > `superai-execute` > `superai-aone` > `superai-finish`
2. **状态机驱动**: 每个 Skill 的触发由 status-tracker 的 `phase` 和 `state` 决定。不可跨 phase 触发。
3. **权限边界**:
   - 协调者（Coordinator）：仅可调度 `superai-clarify`/`superai-plan`/`superai-aone`/`superai-finish`（不执行）
   - 工作者（Worker）：可执行 `superai-execute`/`superai-clarify`/`superai-plan`（有读写权限）
   - 合并代理：仅在 `VERIFYING` → `RELEASING` 阶段激活，权限 `bypass` 但仅用于合并操作
4. **不可覆盖**: `eco-gate` 和 `workflow-check` 为确定性执行器，**不可被 skill 替代**，不可被模型忽略。

## 三、上下文加载策略

- 每次会话启动时：`workflow-check` 只读读取 `requirement/status-tracker.md` 机读块
- `superai-clarify` 加载：spec.md + 长期 wiki（codemap）+ 业务知识
- `superai-plan` 加载：requirements + 架构注册表 + 配置 schema（superai-tjx / superai-mt）
- `superai-execute` 加载：plan.md + tasks.md + 上下文快照（三线快照）
- `superai-finish` 加载：全项目记忆 + 审计日志 + 稳定知识（用于蒸馏）

## 四、降级策略

- 若 Skill 触发条件未满足（如 spec.md 缺失）：进入 `WAITING_USER`，不阻塞后续流程
- 若 Skill 执行失败（如 API 调用失败）：`BLOCKED`，记录 `blocked_reason`，人工介入
- 若 scope-classifier 因架构注册表缺失降级：人工兜底 + 限期补基建

---
> 此文件为**骨架**。真实项目需按实际 Skill 集合、触发条件、权限配置填充。
> 建议将 Skill 注册表与 CI/CD 集成，自动校验 Skill 版本与权限白名单。
