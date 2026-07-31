# 架构 / API / DB 设计增强方案 · v0.12（测试矩阵驱动开发 + 测试复利闭环）

> 版本：v0.12 · 重大修订（增量式，承袭 v0.11）
> 目标插件版本：**v0.31.0**（占位；最终以 P4 `npm version` 为准）
> 修订依据：v0.11 全量内容**继续有效**；v0.12 仅记录本次增量修订。
> 触发来源：LT 审查（2026-08-01）—— 单元测试/集成测试缺少测试矩阵设计方法论 + 测试复利闭环缺失
> 参考输入：glaf4-tests 插件（v0.2.3）+ S03 单元测试战役课程
> 评审：架构一致性 / 测试方法论 / 实施可行性三方专家子代理评审（2026-08-01）
>
> **v0.12 修订摘要（相较 v0.11）**：
> - **§40 问题诊断：测试金字塔底层的结构性缺陷**：team-flow 的 TDD Iron Law 是过程纪律（先写测试再写代码），但不是测试设计方法——不告诉 implementer"该测几组输入、边界值在哪、覆盖率够不够"。E2E 层有 AC 四维矩阵（HP/EX/ST/BND），但单元/集成测试层完全依赖 implementer 个人经验。测试产出无复利回写通道——不沉淀到全局台账，下一个 change 无法复用。
> - **§41 test-strategy skill 新增**：封装 10 种 design_method 选择规则（三级分层：基础/扩展/高级）、分层策略（unit/integration/e2e 比例约束）、对抗验证规则（三招）、复杂度分级规则（含圈复杂度校准）。build-executor 通过 `skills: [test-strategy]` 预加载。
> - **§42 test-matrix 产物定义**：execution-contract.md 的附属产物（非独立第 6 产物），12 列字段矩阵 + 候选覆盖台账 + 对抗验证子步骤。独立 `test_matrix_hash` 字段（不纳入 `artifacts_hash`，避免自循环）。
> - **§43 测试复利闭环（test-ledger + test-merge）**：新增 `docs/test-ledger/` 全局测试台账（INDEX.md + baselines/ + patterns/ + changelog/），新增 `tf test-merge` 命令在 closing 阶段回写。注入侧：contract-builder 读取 baselines 增量设计，S1 路由注入 top-5 测试经验。
> - **§44 上下游 skill 改造**：spec-writer（Unit/Integration 标签）、build-executor（按矩阵 TDD + 五步闭环）、code-reviewer（Test Matrix Compliance 审计维度）、release-archivist（Step 2b 矩阵对账）。
> - **§45 guard 维度增强 + 豁免策略**：新增 `test-matrix-complete` 检查维度 + `test_matrix_skipped` 显式跳过 + tweak/hotfix 豁免 + 存量兼容（渐进式启用）。
> - **§46 glaf4-tests 对接方案**：GLAF4 Java 项目路由到 glaf4-tests design stage，保留 12 种 test_kind 精细语义 + 派生 test_tier 粗粒度分类。

---

## 四十、问题诊断：测试金字塔底层的结构性缺陷（v0.31.0）

### 40.0 现状

team-flow 的测试体系分为三层：

| 层 | 工具 | 现状 | 方法论支撑 |
|---|---|---|---|
| **E2E（验收）** | `/e2e` skill + Playwright | ✅ AC 四维矩阵（HP×1 + EX×2 + ST×2 + BND×1）+ 分级覆盖率门禁 | `docs/e2e-integration-design.md` |
| **集成测试** | build-executor TDD | ❌ 无矩阵、无策略、无覆盖率定义 | 仅 TDD Iron Law（过程纪律） |
| **单元测试** | build-executor TDD | ❌ 无等价类、无边界值、无路径覆盖 | 仅 TDD Iron Law（过程纪律） |

### 40.1 根因

TDD Iron Law（Law 2: "No Production Code Without a Failing Test First"）解决的是**"先写测试还是先写代码"**的问题，不是**"该写哪些测试"**的问题。

| TDD 能解决 | TDD 不能解决 |
|---|---|
| ✅ 确保每个实现都有对应测试 | ❌ 确保测试用例覆盖所有等价类 |
| ✅ 防止"以后补测试"的拖延 | ❌ 确保边界值、异常路径被覆盖 |
| ✅ RED→GREEN→REFACTOR 的节奏纪律 | ❌ 跨模块集成场景的测试设计 |
| ✅ implementer 提交 RED/GREEN 证据 | ❌ 决定"这个函数该有几个测试" |

**证据**（全仓库搜索）：
- `equivalence` / `等价类` 关键词：**0 处**
- `test strategy` / `测试策略` 关键词：**0 处**
- `test plan` / `测试计划` 关键词：**0 处**
- `coverage` in build-executor/：**仅 1 处**（reviewer 的一句话 "Coverage could be broader ... are Minor"）

### 40.2 缺失的复利闭环

当前复利体系有三条全局台账：

| 台账 | 位置 | 维护机制 |
|---|---|---|
| 架构台账 | `docs/architecture/` | `tf arch-merge`（closing 强制顺序第 1 步） |
| 经验台账 | `docs/solutions/` | `tf solutions promote`（closing 强制顺序第 3 步） |
| 词汇台账 | `CONCEPTS.md` | ce-compound Phase 2.4 |

**测试产出没有回写通道**——测试结果仅作为 closing 的验证门禁（`test_result: pass`），不沉淀为可复用的全局知识。后果：
- 下一个 change 做相同模块的测试时，无法知道"上次测了什么、哪些是已知的薄弱点"
- 测试矩阵中的 deferred 项（延期测试）没有跨 change 跟踪
- 测试经验（如"这个模块的边界值总是在哪"）只能靠 `docs/solutions/` 的通用经验晋升，没有测试专属的复用机制

### 40.3 两个参考源的方法论对比

| 维度 | glaf4-tests 插件 | S03 单元测试课程 | 互补关系 |
|---|---|---|---|
| **测试矩阵** | 14 字段 JSON schema + 12 种 test_kind + 10 种 design_method | 6 列 Markdown 矩阵 + 角色隔离（design-agent / coding-agent） | glaf4 提供机器可校验的精确 schema，S03 提供人可读的工程实践 |
| **充分性评估** | `check-design-budget.py`（复杂度分级 + pairwise/branch 组合覆盖） | "圈复杂度 M = 判定节点+1，用例数 ≥ M" | glaf4 脚本化，S03 口诀化 |
| **对抗验证** | `concurrency` / `error` / `reject` design_method | KP-A12 对抗验证 Agent（红队思维三招） | glaf4 在矩阵内，S03 独立阶段 |
| **质量门** | `quality-gates.md`（设计/代码/最终三道 gate） | 四约束（行≥80% / 分支≥70% / 每方法1正1反 / 全通过） | glaf4 结构化，S03 数值化 |
| **五步闭环** | 无显式闭环 | 矩阵→生成→运行→对抗→质量门（任何步失败回退上一步） | S03 独有，glaf4 是线性流水线 |
| **Skill 封装** | 各 skill 的 references/ 目录 | KP-UNIT-16 "方法论固化为机器契约"（≤50 行，只写硬规则） | S03 提供封装原则 |
| **复利台账** | `source_candidate_ledger`（矩阵内局部） | 无 | glaf4 独有但仅局部 |
| **分层策略** | unit 三类 / integration 九类（test_kind 枚举） | KP-UNIT-09 "80% unit + 20% integration" | glaf4 精细分类，S03 比例约束 |

**结论**：两个参考源高度互补。team-flow 应取 glaf4 的**结构化精确性**（schema、脚本、台账）+ S03 的**工程实践智慧**（口诀、闭环、对抗验证、Skill 封装原则），融合为 team-flow 原生方案。

---

## 四十一、test-strategy skill 新增（v0.31.0）

### 41.0 设计动机

S03 KP-UNIT-16 核心观点："Skill 封装的终极价值不是'让 AI 更聪明'，而是'让团队的测试标准从口头共识变成机器可执行的契约'。"

当前 build-executor 的 TDD 方法论全部硬编码在 implementer-prompt.md 中。S03 课程指出这是反模式——方法论应封装为独立 Skill，build-executor 通过 `skills:` 预加载。

### 41.1 skill 定义

```yaml
---
name: test-strategy
description: 测试设计方法论 skill——design_method 选择、分层策略、对抗验证、复杂度分级。build-executor 通过 skills: 预加载。
user-invocable: false   # 不直接调用，由 build-executor 预加载
---
```

**SKILL.md 内容（≤50 行硬规则）**：

```markdown
# Test Strategy

## 1. Design Method 选择规则（三级分层）

### 基础级（必选——每个被测目标必须覆盖）
- equivalence: 输入域有有效/无效分类
- boundary: 数字/长度/日期/金额/分页存在边界（6 值法：min-1/min/min+1/max-1/max/max+1）
- error: 业务异常、空值、外部依赖失败

### 扩展级（条件触发）
- path: 方法存在多分支（圈复杂度 M = 判定节点+1，用例数 ≥ M）
- state: 对象状态改变或业务规则依赖状态迁移
- exception: 显式覆盖异常类型/消息/框架异常映射
- reject: 业务拒绝、准入失败、权限拒绝

### 高级（场景触发）
- permission: API 权限、租户、用户上下文
- idempotency: 重复调用、重复消息、补偿逻辑
- concurrency: 锁、事务、异步消息、并发更新
- contract: 跨模块/跨服务接口契约（Feign、MQ 消息格式、领域事件字段）

## 2. 复杂度分级用例数

| 复杂度 | 判据 | 最少用例 |
|--------|------|---------|
| trivial | is_trivial=true（enum/constant/POJO） | ≥3（仅 equivalence + error，boundary 可省） |
| medium | 默认（无判据命中） | ≥5 |
| complex | public_methods>15 或 lines>800 或 圈复杂度>10 或 param_count>6 | ≥7 |

保守默认：事实是估算非实测 → 强制 medium 档(≥5)。

## 3. 分层策略（测试金字塔比例）

- unit（test_tier=unit）：70-80% 的 case
- integration（test_tier=integration）：≤30% 的 case
- e2e：由 e2e skill 独立覆盖，不计入本矩阵

## 4. 对抗验证三招（矩阵生成后必检）

1. 恶意输入：至少 1 个 case 覆盖 null/空串/超大值/特殊字符
2. 并发场景：涉及锁/事务/异步 → 至少 1 个 concurrency case
3. 依赖失败：涉及外部依赖 → 至少 1 个 dependency_failure case（超时/熔断/返回空）

## 5. 自检门口诀

每个方法至少：1 正常 + 1 边界 + 1 异常 + 1 null/空
```

### 41.2 references/ 目录

```
skills/test-strategy/
├── SKILL.md                    # ≤50 行硬规则（上文）
└── references/
    ├── design-methods-detail.md   # 10+1 种 design_method 的详细说明 + 触发条件 + 示例
    ├── complexity-grading.md      # 复杂度分级详细规则 + 圈复杂度计算方法
    └── adversarial-patterns.md    # 对抗验证详细模式 + 常见攻击向量
```

### 41.3 与 build-executor 的关系

```
agents/build-executor.md
  frontmatter:
    skills: [build-executor, test-strategy]  # ← 新增 test-strategy 预加载
```

build-executor 的 SKILL.md 引用 test-strategy skill 作为测试设计方法论来源，不在 implementer-prompt.md 中硬编码方法论。

---

## 四十二、test-matrix 产物定义（v0.31.0）

### 42.0 产物定位

test-matrix.md 是 `execution-contract.md` 的**附属产物**（类比 `architecture/` 目录），**不是独立的第 6 个核心产物**。

| 维度 | 独立核心产物（proposal/specs/design/tasks/contract） | test-matrix（附属产物） |
|------|---|---|
| 纳入 `artifacts_hash` | ✅ 是 | ❌ 否（独立 `test_matrix_hash`） |
| 修改触发 contract stale | ✅ 是 | ❌ 否（避免自循环） |
| guard 检查 | `artifacts-exist` | `test-matrix-complete`（独立维度） |
| 创建者 | spec-writer / contract-builder | contract-builder |
| 消费者 | build-executor / code-reviewer | build-executor / code-reviewer / test-merge |

### 42.1 产物结构

```markdown
# Test Matrix — {change-name}

## Summary
- Total cases: {N}
- Modules covered: {N}
- Unit cases: {N} ({percent}%)
- Integration cases: {N} ({percent}%)
- Deferred items: {N}
- Matrix revision: 1

## Candidate Coverage Ledger

| candidate | category | decision | case_ids | reason |
|---|---|---|---|---|
| OrderService.createOrder | service | covered | OS-01~OS-07 | — |
| PaymentGateway.charge | external_api | deferred | — | 外部 API 本期不集成 |
| ErrorCode enum | enum | not_applicable | — | 纯常量，无业务逻辑 |

## Cases

### {module-name}

| case_id | behavior | design_method | input | expected | test_kind | test_tier | mock | work_mode | test_file | test_method_name | run_command |
|---|---|---|---|---|---|---|---|---|---|---|---|
| OS-01 | 正常下单 | equivalence | 有效订单 | 订单创建成功 | mockito_unit | unit | OrderRepo, InventoryService | TDD | OrderServiceTest.java | shouldCreateOrder | mvn test -pl order -Dtest=OrderServiceTest#shouldCreateOrder |
| OS-02 | 库存不足拒绝 | reject | 库存=0 | 抛 InsufficientStockException | mockito_unit | unit | OrderRepo, InventoryService | TDD | OrderServiceTest.java | shouldRejectWhenOutOfStock | mvn test -pl order -Dtest=OrderServiceTest#shouldRejectWhenOutOfStock |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

## Adversarial Cases

| case_id | behavior | design_method | input | expected | test_kind | test_tier | mock | work_mode | test_file | test_method_name | run_command |
|---|---|---|---|---|---|---|---|---|---|---|---|
| OS-A1 | SQL 注入防护 | error | 恶意字符串 `' OR 1=1 --` | 输入校验拒绝 | mockito_unit | unit | — | TDD | OrderServiceTest.java | shouldRejectSqlInjection | ... |

## Deferred Items

| case_id | behavior | design_method | reason | deferred_since |
|---|---|---|---|---|
| OS-D1 | 重复下单幂等性 | idempotency | 需要 MQ mock，本期不集成 | 2026-08-01 |
```

### 42.2 字段定义（12 列）

| 字段 | 类型 | 必填 | 说明 | 来源 |
|---|---|---|---|---|
| `case_id` | string | ✅ | 全局唯一：`{module}-{method}-{design_method}-{seq}` | glaf4 |
| `behavior` | string | ✅ | 测试意图（中文描述，含 display_name 功能） | S03 + glaf4 |
| `design_method` | enum | ✅ | 11 种方法之一（含 contract） | glaf4 |
| `input` | string | ✅ | 测试输入描述 | S03 |
| `expected` | string | ✅ | 期望输出 | S03 |
| `test_kind` | enum | ✅ | 12+ 种精细分类（语言相关） | glaf4 |
| `test_tier` | enum | ✅ | unit / integration / e2e（派生，语言无关） | team-flow 新增 |
| `mock` | string | ✅ | 需 Mock 对象列表 | S03 |
| `work_mode` | enum | ✅ | TDD / CHARACTERIZATION / REGRESSION | glaf4 |
| `test_file` | string | ✅ | 测试文件路径（write-stage 写入锚点） | glaf4 |
| `test_method_name` | string | ✅ | 测试方法名（与 @Test 一一对应） | glaf4 |
| `run_command` | string | ✅ | 运行命令（validate-stage 执行依据） | glaf4 |

**work_mode 关联字段**（在矩阵头部或 case 级别声明）：
- `expected_red`：对象 `{should_be_red, reason, failure_point}`（TDD 模式必填）
- `production_change_allowed`：boolean（CHARACTERIZATION 模式默认 false）
- `current_behavior_note`：string（CHARACTERIZATION 模式必填）

### 42.3 schema 强制覆盖规则

1. `cases` 必须包含至少 1 个 `design_method ∈ {boundary, equivalence}` 的 case
2. `cases` 必须包含至少 1 个 `design_method ∈ {error, exception, reject}` 的 case
3. `complexity_tier=trivial` 时降级：允许只覆盖 equivalence + error（不强制 boundary），error 可仅为 null/空值处理
4. 对抗验证段必须存在（至少含恶意输入 / 并发 / 依赖失败三类之一，视目标而定）

### 42.4 test_kind 精细语义 + test_tier 派生

```
test_kind（精细字段，语言相关）          test_tier（派生字段，语言无关）
├─ pure_unit                          → unit
├─ mockito_unit                       → unit
├─ spring_assisted_unit               → unit
├─ api_mockmvc_standalone             → integration
├─ api_mockmvc_slice                  → integration
├─ api_mockmvc_boot                   → integration
├─ service_social                     → integration
├─ repository_h2                      → integration
├─ rabbitmq_social                    → integration
├─ redis_social                       → integration
├─ external_api_stub                  → integration
├─ test_infrastructure                → integration
└─ vitest_unit / vue_test_utils_mount → unit（非 Java 扩展）
```

**设计原则**：`test_kind` 保留精细语义供 write-stage 路由到正确的编写模板；`test_tier` 用于粗粒度统计和 CI 分级。

### 42.5 hash 机制

`state-loader.mjs` BUILTIN_DEFAULTS 新增：
```js
test_matrix_hash: null    // SHA256 of test-matrix.md
```

`hash.mjs` 新增 `computeTestMatrixHash(changeDir)` 函数——仅对 `test-matrix.md` 单文件做 SHA256。

**不纳入 `artifacts_hash`**：避免修改 test-matrix → contract stale → 回退 bridging → 重新生成 test-matrix 的自循环。

### 42.6 对抗验证子步骤

在 contract-builder 生成 test-matrix.md 后、进入 build-executor 前，执行对抗验证回检：

```
test-matrix.md 生成
  → adversarial-review:
    1. 扫描矩阵：每个涉及用户输入的模块是否有恶意输入 case？
    2. 扫描矩阵：涉及并发/锁/事务的模块是否有 concurrency case？
    3. 扫描矩阵：涉及外部依赖的模块是否有 dependency_failure case？
    → 缺失 → 追加 adversarial case 到 test-matrix.md
    → 所有检查通过 → 矩阵冻结
```

### 42.7 上下文窗口预算控制

test-matrix.md 采用**摘要 + 按需读取**模式：

- **第一段 `## Summary`**（~10 行）：统计行（总 case 数 / 模块数 / 覆盖率 / deferred 数）
- **后续段落按模块分组**：build-executor 按 wave 对应的 task 按需 Read 相关模块段落
- **code-reviewer**：同理，按 wave 按需读取
- **contract-builder**：只读 Summary 段 + 当前 change 相关 capability 段落

---

## 四十三、测试复利闭环（test-ledger + test-merge）（v0.31.0）

### 43.0 新增全局台账：docs/test-ledger/

```
docs/test-ledger/
├── INDEX.md                # L1 轻量索引（≤200 行硬上限）
├── baselines/              # L2 模块测试基线（每模块一份，累积式）
│   ├── order-service.md
│   ├── payment-gateway.md
│   └── ...
├── patterns/               # L2 可复用测试模式
│   ├── boundary-6value-for-date-fields.md
│   └── ...
└── changelog/              # L2 change 级测试履历归档
    └── add-order-discount.md
```

### 43.1 INDEX.md 格式

```markdown
# Test Ledger Index

> Auto-generated by `tf test-merge`. Do not edit manually.

**Modules**: 12 | **Total Cases**: 87 | **Deferred**: 5 | **Last Updated**: 2026-08-01

| module | test_tier_breakdown | case_count | deferred | last_change | last_date | coverage_status |
|---|---|---|---|---|---|---|
| OrderService | unit:5, integration:3 | 8 | 1(idempotency) | add-order-discount | 2026-08-01 | ✅ baseline |
| PaymentGateway | unit:2, integration:4 | 6 | 2(concurrency, timeout) | add-order-discount | 2026-08-01 | ⚠️ partial |
| UserService | unit:8 | 8 | 0 | add-user-profile | 2026-07-15 | ✅ baseline |
```

**coverage_status 三态**：
- `✅ baseline`：模块有完整的测试基线（unit + integration）
- `⚠️ partial`：部分覆盖（有 deferred 项）
- `⏭️ not_applicable`：标记为不需要测试（纯日志/POJO 等）

### 43.2 baselines/{module}.md 格式（双视图）

```markdown
# OrderService Test Baseline

> schema_version: 1
> last_updated_by_change: add-order-discount
> last_updated: 2026-08-01

## Current Cases（当前态 — 覆盖式）

| case_id | behavior | design_method | test_kind | test_tier | work_mode | test_file | test_method_name | source_change |
|---|---|---|---|---|---|---|---|---|
| OS-createOrder-equivalence-01 | 正常下单 | equivalence | mockito_unit | unit | TDD | OrderServiceTest.java | shouldCreateOrder | add-order-discount |
| OS-createOrder-boundary-01 | 金额边界(0.01) | boundary | mockito_unit | unit | TDD | OrderServiceTest.java | shouldHandleMinAmount | add-order-discount |

## Deferred Items

| case_id | behavior | design_method | reason | deferred_since |
|---|---|---|---|---|
| OS-createOrder-idempotency-01 | 重复下单幂等性 | idempotency | 需要 MQ mock | add-order-discount |

## Evolution Log（append-only）

- **2026-08-01** [add-order-discount]: 新增 7 case, defer 1, 覆盖 equivalence/boundary/error/reject/concurrency
```

### 43.3 `tf test-merge` 命令

**位置**：`scripts/lib/test-merge.mjs`（预估 ~380 行，复用 arch-merge 骨架）

**6 步流程**：

```
1. preCheck — 校验 test-matrix.md 存在且非空
2. mergeBaselines — 从 test-matrix.md 按模块提取 case，增量合并到 baselines/{module}.md
   - 读取 delta 声明（added/modified/removed_case_ids）
   - 三方合并：base(main) + delta(change) + current(baseline)
   - 冲突处理：同一 case_id 被两个 change 修改 → 保留两者 + 标记 merge-conflict advisory
3. resolveDeferred — 新 case 覆盖了旧 deferred 项 → 从 Deferred Items 移除
4. appendChangelog — 归档 test-matrix.md → changelog/{change-id}.md
5. rewriteIndex — 统计模块数/case 数/deferred 数，重写 INDEX.md
6. gitCommit — 单次原子提交
```

### 43.4 closing 强制顺序更新

```
arch-merge → prototype-sync → test-merge → compound promotion
     ↓              ↓              ↓              ↓
docs/architecture/  prototype/  docs/test-ledger/  docs/solutions/
```

`test-merge` 插入在 `prototype-sync` 之后、`compound promotion` 之前——测试回写先于经验晋升（经验晋升可能引用测试结果）。

### 43.5 注入侧：下游复用

#### contract-builder 注入

```
contract-builder 启动
  ├─ 读取 docs/test-ledger/INDEX.md → 获取相关模块的测试覆盖概览
  ├─ 读取 docs/test-ledger/baselines/{module}.md → 获取已有 case，避免重复设计
  ├─ 读取 baselines/{module}.md → Deferred Items → 评估本次是否可解决
  └─ tf test-ledger inject --module <m> → 输出摘要供矩阵生成参考
```

#### S1 路由注入

```
workflow-orchestrator S1
  └─ 读取 docs/test-ledger/INDEX.md → 注入 coverage_status=partial 的模块列表
     → 新 change 涉及这些模块时，提示"有未解决的 deferred 测试项"
```

### 43.6 跨 change 冲突解决（三层防冲突）

1. **case_id 全局唯一**：格式 `{module}-{method}-{design_method}-{seq}`（如 `OS-createOrder-boundary-01`）
2. **delta 声明**：每个 change 的 test-matrix.md 必须声明 `added_case_ids` / `modified_case_ids` / `removed_case_ids`（不允许全量重写）
3. **三方合并**：以 main 分支的 baseline 为 base，当前 change 的 delta 为 one side，当前 baseline 为 other side
   - 冲突规则：同一 case_id 被两个 change 修改 → 保留两者（标记 advisory）
   - 一方删除另一方修改 → 保留修改方（保守策略）

### 43.7 与现有复利体系的关系

| 维度 | test-ledger（测试台账） | solutions（经验台账） | architecture（架构台账） |
|---|---|---|---|
| **定位** | 记录"测了什么" | 记录"踩了什么坑" | 记录"设计了什么" |
| **维护方式** | test-merge（closing 回写） | solutions promote（closing 晋升） | arch-merge（closing 回写） |
| **注入时机** | contract-builder + S1 | S1 路由 + spec-writer | architecture-design |
| **强制顺序位置** | 第 3 步 | 第 4 步 | 第 1 步 |
| **淘汰规则** | 无（持续累积） | 150 行上限 | 当前态覆盖 + 演进日志追加 |

---

## 四十四、上下游 skill 改造（v0.31.0）

### 44.1 spec-writer 上游扩展

**新增可选标签**（在 spec 的 `#### Scenario:` 下）：

```markdown
#### Scenario: 正常下单
  WHEN 用户提交有效订单
  THEN 系统创建订单并扣减库存

  ##### Unit:（单元测试维度 — 新增，OPTIONAL）
  - 输入等价类：有效订单 / 无效订单（空商品/零金额/超库存）
  - 边界值：金额 0.01 / 999999.99 / 库存 0 / 库存恰好等于订单数量

  ##### Integration:（集成测试维度 — 新增，OPTIONAL）
  - 跨模块：OrderService → InventoryService（扣库存）
  - 事务边界：下单 + 扣库存必须在同一事务内
```

**设计约束**：
- 标签为 **OPTIONAL**（与现有 Exception/State/Boundary 一致），缺失不影响 spec 校验
- contract-builder 阶段可从中提取矩阵骨架，但不强制要求 spec 作者填写
- 标签内容供 test-matrix 生成时参考，不被 hash 追踪

### 44.2 build-executor 改造

#### implementer-prompt.md 增强

**修改前**：
```
Write tests (following TDD if task says to)
```

**修改后**：
```
Read test-matrix.md for this task's module section.
For each case in the matrix (work_mode=TDD):
  1. RED: write failing test matching case_id + test_method_name, confirm failure
  2. GREEN: implement minimum code to pass
  3. REFACTOR: clean up, suite stays green
  4. Report TDD Evidence: RED command + failure output, GREEN command + pass output

For each case (work_mode=CHARACTERIZATION):
  1. Write test capturing current behavior (do NOT change production code)
  2. Report: current_behavior_note + test output

For each case (work_mode=REGRESSION):
  1. Write failing test reproducing the defect
  2. Fix, confirm green
  3. Report: defect reproduction + fix evidence

After all cases: self-check matrix coverage = passed cases / total cases in matrix.
```

#### 五步闭环（S03 KP-UNIT-17）

```
① 矩阵生成 → ② TDD 执行 → ③ 运行验证 → ④ 对抗验证 → ⑤ 质量门检查
       ↑              |            |             |            |
       └──────────────┴────────────┴─────────────┴────────────┘
                     任何步骤发现矩阵不合理 → 回退到 bridging
                     （闭环上限 2 次，防止死循环）
```

**回退规则**：
- 步骤 ③ 发现 expected_red 与实际不符 → 回退到 ① 修改矩阵
- 步骤 ④ 对抗验证发现遗漏 case → 回退到 ① 追加 case
- 步骤 ⑤ 覆盖率不达标 → 回退到 ① 补充 case
- 回退次数上限 2 次，超过则 Escalation Rules → 回退到 bridging 重新生成

#### "两不原则"嵌入 Phase Guard（cmd-inject.mjs）

```
executing 阶段 Phase Guard 新增：
⛔ 禁止：AI 同时写生产代码和测试（必须先 RED 再 GREEN）
⛔ 禁止：在 RED 阶段跳过失败确认直接写 GREEN
```

### 44.3 code-reviewer 改造

**新增审查维度**：Test Matrix Compliance（与现有 Testing 维度并列）

```
## Test Matrix Compliance（新增）

1. 读取 test-matrix.md，逐 case 核对：
   - 每个 case 是否有对应的测试实现（test_file + test_method_name 匹配）
   - 测试断言是否与矩阵的「期望输出」一致
   - design_method 是否匹配（矩阵要求 boundary 的 case 不能用 happy-path 测试冒充）

2. 覆盖率计算：
   - 矩阵覆盖率 = 已实现 case 数 / 矩阵总 case 数
   - 矩阵覆盖率 < 100% → Critical finding (test-matrix-gap)

3. 候选覆盖台账审计：
   - 台账中 decision=deferred 的项是否有合理理由
   - 台账中 decision=covered 的项是否真的有对应测试

4. 分层比例检查：
   - unit case 占比是否在 70-80%
   - integration case 占比是否 ≤30%
```

**裁决影响**：
- Test Matrix Compliance 的 Critical finding → 整体 verdict = FAIL
- 与现有 Spec Compliance 同级（Spec 违规永远是 Critical，矩阵缺失也永远是 Critical）

### 44.4 release-archivist 改造

**新增 Step 2b：Test Matrix Reconciliation**（条件触发）

```
Step 2b: Test Matrix Reconciliation (conditional)
  IF test-matrix.md exists:
    - 统计: 总 case 数 / 已实现数 / 已通过数
    - 检查: 候选覆盖台账中是否有 decision=deferred 且无合理理由的项
    - 检查: 复杂度分级用例数是否满足 (trivial≥3/medium≥5/complex≥7)
    - Verdict:
      - 矩阵覆盖率 = 100% 且所有 case 通过 → PASS
      - 矩阵覆盖率 ≥ 90% 且有合理 deferred → CONDITIONAL (WARN)
      - 矩阵覆盖率 < 90% 或存在未解释的缺口 → FAIL
  ELSE:
    - SKIP (存量 change 兼容)
```

**报告中新增行**：
```
| Test Matrix | PASS/FAIL/WARN/SKIP | [reconciliation summary] |
```

---

## 四十五、guard 维度增强 + 豁免策略（v0.31.0）

### 45.1 新增 `test-matrix-complete` 检查维度

**文件**：`scripts/guard/checks/test-matrix-complete.mjs`（预估 ~40 行）

**检查逻辑**：

```js
function checkTestMatrixComplete(changeDir) {
  // 1. 存量兼容：execution-contract.md 无 "## Test Matrix" 段 → PASS
  const contract = readContract(changeDir);
  if (!contract.includes('## Test Matrix')) {
    return { pass: true, reason: 'legacy contract — no test matrix section' };
  }

  // 2. 显式跳过：test_matrix_skipped === 'true' → PASS
  const state = readState(changeDir);
  if (state.test_matrix_skipped === 'true') {
    return { pass: true, reason: 'explicitly skipped via test_matrix_skipped' };
  }

  // 3. test-matrix.md 存在且非空
  const matrixPath = path.join(changeDir, 'test-matrix.md');
  if (!fs.existsSync(matrixPath) || fs.statSync(matrixPath).size === 0) {
    return { pass: false, failures: ['test-matrix.md is missing or empty'] };
  }

  // 4. test_matrix_hash 一致性
  const computed = computeTestMatrixHash(changeDir);
  if (state.test_matrix_hash && state.test_matrix_hash !== computed) {
    return { pass: false, failures: ['test-matrix.md has been modified since last hash — run tf state rebuild'] };
  }

  return { pass: true };
}
```

### 45.2 guard 矩阵更新

```js
// guard.mjs — TRANSITION_CHECKS 修改
'executing:closing': [
  'tasks-complete', 'tests-passing', 'specs-merged',
  'execution-plan-ready', 'execution-reviews-passed', 'compound-captured',
  'test-matrix-complete'  // ← 新增（仅 full 路径）
]

// WORKFLOW_TRANSITION_CHECKS — tweak 不变（保持 3 维度）
WORKFLOW_TRANSITION_CHECKS.tweak['executing:closing']:
  ['tasks-complete', 'tests-passing', 'specs-merged']

// WORKFLOW_TRANSITION_CHECKS — hotfix 新增定义（排除 test-matrix-complete）
WORKFLOW_TRANSITION_CHECKS.hotfix['executing:closing']:
  ['tasks-complete', 'tests-passing', 'specs-merged',
   'execution-plan-ready', 'execution-reviews-passed', 'compound-captured']
```

### 45.3 豁免策略总结

| workflow | test-matrix-complete | 理由 |
|---|---|---|
| **full** | ✅ 考核 | 完整开发流程需要测试矩阵 |
| **hotfix** | ❌ 豁免 | 紧急修复，测试纪律靠 TDD Iron Law 保证 |
| **tweak** | ❌ 豁免 | 微调类变更，不值得做矩阵 |
| **显式跳过** | `test_matrix_skipped: true` | 纯文档/配置变更等无测试需求的 change |
| **存量兼容** | contract 无 `## Test Matrix` 段 | 渐进式启用，不阻断已有 change |

### 45.4 state-loader.mjs 更新

BUILTIN_DEFAULTS 新增：
```js
test_matrix_hash: null,      // SHA256 of test-matrix.md
test_matrix_skipped: null,   // 'true' 表示显式跳过
```

cmd-state.mjs SETTABLE_FIELDS 新增：
```js
'test_matrix_skipped'  // 用户可手动设置
```

---

## 四十六、glaf4-tests 对接方案（v0.31.0）

### 46.0 对接模式

当 change 的项目技术栈是 GLAF4 Java（Spring Boot / JUnit 5 / Mockito）时，contract-builder 可将 test-matrix 生成委托给 glaf4-tests 的 design stage。

```
contract-builder
  ├─ 检测项目技术栈
  │   ├─ GLAF4 Java → 提示用户可调用 glaf4-test:glaf4-tests 做精细矩阵设计
  │   │   └─ 产出: test-matrix.json (glaf4 格式) → 转换为 test-matrix.md (team-flow 格式)
  │   └─ 其他技术栈 → contract-builder 自己生成 test-matrix.md
  └─ test-matrix.md 纳入 change 产物
```

### 46.1 格式转换

**glaf4 → team-flow 映射**（保留全部 14 字段 + 包装 team_flow_context）：

| glaf4 test_kind | team-flow test_kind | test_tier（派生） |
|---|---|---|
| pure_unit / mockito_unit / spring_assisted_unit | 保持原名 | unit |
| api_mockmvc_standalone / slice / boot | 保持原名 | integration |
| service_social / repository_h2 / rabbitmq_social / redis_social | 保持原名 | integration |
| external_api_stub / test_infrastructure | 保持原名 | integration |

**转换脚本**：`scripts/lib/test-matrix-export.mjs`（预估 ~120 行）
- 读取 glaf4 的 `test-matrix.json`
- 增加 `team_flow_context` 块（含 change_id / batch_id / closing_stage / ledger_ref）
- 输出 team-flow 格式的 `test-matrix.md`

### 46.2 路由协议

在 `routing-rules.md` 新增路由段：

```
## Route to glaf4-tests (v0.31.0 §46)

触发条件：project_type == glaf4-java AND contract-builder 需要生成 test-matrix
协议：
1. 提示用户：是否调用 glaf4-test:glaf4-tests 做精细测试矩阵设计？
2. 用户同意 → 调用 glaf4-test:glaf4-tests-design
3. glaf4-tests-validate 校验矩阵完整性
4. test-matrix-export.mjs 转换为 team-flow 格式
5. 用户确认（轻量版 DP-A）
```

**设计决策**：glaf4-tests 对接为**可选增强**，不是必经路径。非 GLAF4 项目使用 team-flow 内置的 test-strategy skill 即可。

---

## 待办列表（v0.31.0 新增）

| 编号 | 待办 | 状态 | 版本 | 来源 |
|------|------|------|------|------|
| P1-33 | 新增 `skills/test-strategy/SKILL.md` + references/（10+1 种 design_method + 分层策略 + 对抗验证 + 复杂度分级） | 🔲 待实施 | v0.31.0 | §41 |
| P1-34 | spec-writer SKILL.md 增加 Unit/Integration 可选标签 | 🔲 待实施 | v0.31.0 | §44.1 |
| P2-27 | 定义 test-matrix.md 格式规范（12 列 + schema 强制覆盖 + 对抗验证段） | 🔲 待实施 | v0.31.0 | §42 |
| P2-28 | contract-builder SKILL.md 改造：生成 test-matrix.md 附属产物 + 注入 test-ledger baselines | 🔲 待实施 | v0.31.0 | §42 + §43.5 |
| P2-29 | hash.mjs 新增 computeTestMatrixHash + state-loader 新增 test_matrix_hash / test_matrix_skipped 字段 | 🔲 待实施 | v0.31.0 | §42.5 + §45.4 |
| P1-35 | build-executor implementer-prompt.md 增强：按矩阵 TDD + 五步闭环 + 两不原则 | 🔲 待实施 | v0.31.0 | §44.2 |
| P1-36 | code-reviewer SKILL.md + prompt 增强：Test Matrix Compliance 审查维度 | 🔲 待实施 | v0.31.0 | §44.3 |
| P1-37 | release-archivist SKILL.md 增加 Step 2b Test Matrix Reconciliation（条件触发） | 🔲 待实施 | v0.31.0 | §44.4 |
| P2-30 | scripts/guard/checks/test-matrix-complete.mjs 新增 + guard.mjs 矩阵更新 + 豁免策略 | 🔲 待实施 | v0.31.0 | §45 |
| P2-31 | scripts/lib/test-merge.mjs 新增（6 步流程 + 三方合并 + INDEX 重写） | 🔲 待实施 | v0.31.0 | §43.3 |
| P2-32 | docs/test-ledger/ 目录结构定义 + INDEX.md / baselines/ / patterns/ / changelog/ 格式规范 | 🔲 待实施 | v0.31.0 | §43.1-43.2 |
| P2-33 | test-ledger 注入机制：contract-builder + S1 路由 | 🔲 待实施 | v0.31.0 | §43.5 |
| P3-6 | scripts/lib/test-matrix-export.mjs（glaf4 格式转换） | 🔲 待实施 | v0.31.0 | §46.1 |
| P3-7 | routing-rules.md 新增 glaf4-tests 路由段 | 🔲 待实施 | v0.31.0 | §46.2 |
| P3-8 | build-executor agents 声明 `skills: [build-executor, test-strategy]` 预加载 | 🔲 待实施 | v0.31.0 | §41.3 |
| P2-26 | validator 补 WHEN/THEN 结构校验（B4 降级：需专项夹具防回归） | 🔲 待实施 | v0.31.0 | v0.30.0 §39.2 降级项（延续） |
