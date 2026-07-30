# 架构 / API / DB 设计增强方案 · v0.10（制品体系可执行化 + 上下文治理）

> 版本：v0.10 · 重大修订（增量式，承袭 v0.9）
> 目标插件版本：**v0.23.0**（占位；最终以 P4 `npm version` 为准）
> 修订依据：v0.9 全量内容**继续有效**；v0.10 仅记录本次增量修订。
> 触发来源：LT 发起架构设计制品完整性检讨——Bootstrap / architecture-design / arch-merge 三阶段产物链路的全链路差距分析，发现制品被分为"文档层"和"代码层"两个世界，但架构设计的价值恰在两者交叉点。
>
> **v0.10 修订摘要（相较 v0.9）**：
> - **§28 制品体系可执行化**：新增 PHYSICAL-MODEL.md（字段级物理模型）、schema-baseline.sql（完整可执行 DDL）、API-INDEX.md（端点索引）、sql/ 独立可执行制品目录；Bootstrap 增加"成果物导入"环节（优先用户提供既有成果物，兜底确定性提取）；arch-merge 从纯文档幽灵变为完整脚本实现。
> - **§29 上下文治理策略**：INDEX.md 摘要索引 + 物理模型按业务域分段 + 按需加载三层策略，控制架构制品的上下文预算在 ~2K tokens。
> - **§30 代码层强制化**：architecture/*.md 纳入 artifacts_hash；guard.mjs `exploring:specifying` 增加 arch 维度。
> - **§31 api.md 定位调整**：聚焦 Command/Read/Query 分流归属+端点概要（架构路由表），不重复 Swagger 管理的精确 Schema。

---

## 二十八、制品体系可执行化（v0.23.0）

### 28.0 问题诊断（全链路差距分析）

Bootstrap → architecture-design → arch-merge 三阶段制品链路存在**文档层/代码层分裂**：

| 阶段 | 设计承诺 | 代码现实 | 差距等级 |
|------|---------|---------|---------|
| Bootstrap | 架构基线快照 | baseline.md + ARCHITECTURE.md + DATABASE.md（表级概览） | ⚠️ 无 DDL、无字段级物理模型、无 API 端点索引 |
| architecture-design | 增量设计三件套 | templates/ 已创建（v0.22.5 F08），DDL/SQL 嵌在 markdown 代码块中 | ⚠️ DDL/SQL 不可独立执行、不入 artifacts_hash |
| arch-merge | 全局架构回写 | **零代码实现**（8 处文档引用但无脚本、无 CLI 注册） | 🔴 纯文档幽灵 |
| guard | 架构门控 | guard.mjs 无 arch 维度，architecture/*.md 不入 hash | 🔴 可被绕过 |

**根因**：架构设计的方法论层（4A+DDD+CQRS 八框架）完整且精致，但**制品的"可执行性"分层错误**——本应被代码强制的制品放在文档层，本应独立存在的可执行制品被嵌在 markdown 里，本应自动化的闭环操作（arch-merge）完全缺失。

### 28.1 制品体系重构——全局层 + 变更层

#### 28.1.1 全局层（项目级 `docs/architecture/`）

| 产物 | 路径 | 创建时机 | 更新时机 | 性质 |
|------|------|---------|---------|------|
| INDEX.md | `INDEX.md` | Bootstrap B2 | arch-merge | 摘要索引（始终加载） |
| 架构基线 | `ARCHITECTURE.md` | Bootstrap B2 | arch-merge（当前态覆盖+演进日志append） | 设计文档 |
| 数据库物理模型 | `PHYSICAL-MODEL.md` | Bootstrap B2（用户提供优先 / DDL提取兜底） | arch-merge（增量合并变更涉及的表） | 设计文档 |
| DDL 基线 | `schema-baseline.sql` | Bootstrap B2（用户提供优先 / SHOW CREATE TABLE 兜底） | arch-merge（追加新 DDL，保持完整可执行） | **可执行制品** |
| API 端点索引 | `API-INDEX.md` | Bootstrap B2（扫描代码生成） | arch-merge（增量追加） | 设计文档 |
| 领域词汇 | `CONCEPTS.md` | Bootstrap B3 | arch-merge（增量追加） | 设计文档 |
| 项目全景 | `baseline.md` | Bootstrap B1 | 不更新（一次性快照） | 设计文档 |
| 变更脚本归档 | `changelog/ddl/` `changelog/migration/` | arch-merge | arch-merge（追加） | **可执行制品** |

**目录结构**：

```
docs/architecture/
├── INDEX.md                       # 摘要索引（始终加载，~50行）
├── baseline.md                    # 项目全景快照（Bootstrap 一次性）
├── ARCHITECTURE.md                # 架构基线（当前态+演进日志）
├── PHYSICAL-MODEL.md              # 数据库物理模型（字段级完整定义）
├── schema-baseline.sql            # DDL 基线（完整可执行）
├── API-INDEX.md                   # API 端点索引
├── CONCEPTS.md                    # 领域词汇
└── changelog/                     # 变更脚本归档（扁平结构）
    ├── ddl/
    │   ├── 20260528_附件编辑临时表新增路径类型字段.sql
    │   └── 20260615_专家检查表结构重构.sql
    └── migration/
        ├── 20260528_数据修复_xxx.sql
        └── 20260615_历史数据迁移_xxx.sql
```

#### 28.1.2 变更层（`changes/<name>/architecture/`）

| 产物 | 路径 | 性质 | 说明 |
|------|------|------|------|
| DDD 增量 | `architecture.md` | 设计文档 | 聚合/BC/Context Map/CQRS 增量 |
| DB 增量设计 | `database.md` | 设计文档 | 写/读模型变更设计，引用 sql/ 路径 |
| API 增量设计 | `api.md` | 架构意图 | 分流归属+端点概要（§31 详述） |
| SQL 制品 | `sql/ddl/` `sql/migration/` | **可执行制品** | DDL 和迁移脚本统一目录 |

**目录结构**：

```
changes/<name>/architecture/
├── architecture.md                # DDD 增量设计
├── database.md                    # DB 增量设计（引用 sql/ 路径）
├── api.md                         # API 架构意图（§31 定位）
└── sql/                           # 独立可执行 SQL 制品
    ├── ddl/
    │   └── <date>_<desc>.sql      # CREATE/ALTER TABLE
    └── migration/
        └── <date>_<desc>.sql      # 数据迁移（幂等可回滚）
```

### 28.2 PHYSICAL-MODEL.md 格式标准（沿用 VRM 格式）

采用 VRM 项目的"表格+字段级完整列定义"格式（参考 `vrm/doc/03-数据库设计/VRM数据库物理模型.md`，1229 行/45 表）。

**关键格式要素**：

1. **按业务域/限界上下文分组**（§29 上下文治理的基础）
2. 每张表一个 `## 段`，包含：表名行 + 字段表格
3. 字段表格列：`No | 字段名 | 字段ID | NOTN | UNIQ | 属性 | 字节数 | PK | EK | 索引 | 说明`
4. 附录：图例说明 + 通用字段说明 + 枚举字段速查

```markdown
# 数据库物理模型

> 生成时间: YYYY-MM-DD
> 最后更新: change=<change_name>, YYYY-MM-DD

---

## 需求企划域

### 1. 改善方向表 (t_improvement_direction)

| ID | | 表名 | t_improvement_direction | | | | | | | | |
| ---- | ---- | -------------- | ------------ | ---- | ---- | ----------- | ------ | ---- | ---- | ---- | ---- |
| No | 字段名 | 字段ID | NOTN | UNIQ | 属性 | 字节数 | PK | EK | 索引 | 索引 | 说明 |
| 1 | 主键ID | id | N | | bigint | | Y | | | | |
...

---

## 需求判定域
...

---

## 附录：物理模型图例说明
| 标识 | 含义 |
|------|------|
| NOTN | NOT NULL，Y=可为空，N=不可为空 |
| UNIQ | UNIQUE，Y=唯一约束 |
| PK   | Primary Key |
| EK   | External Key（外键） |
| 索引 | 该字段上有索引 |
```

### 28.3 Bootstrap 改造——B2 增加"成果物导入"环节

**B2 Deep 新流程**：

```
B2 Deep 阶段（改造后）：

Step 1: 询问用户是否有既有成果物
  ├── 有 SQL DDL 脚本 → 导入到 docs/architecture/schema-baseline.sql
  ├── 有物理模型文档 → 转换为 docs/architecture/PHYSICAL-MODEL.md（对齐 §28.2 标准格式）
  ├── 有 API 文档/Swagger 导出 → 提取端点生成 docs/architecture/API-INDEX.md
  └── 无既有成果物 → Step 2 兜底

Step 2: 确定性提取（兜底）
  ├── recon-probe.sh 增加 DDL 提取能力
  │   ├── 优先：解析 Entity 类（@Table/@Column/@Id 注解）→ 生成 DDL
  │   ├── 次优：连接数据库 SHOW CREATE TABLE → 生成 DDL
  │   └── 产物：docs/architecture/schema-baseline.sql
  ├── 从 schema-baseline.sql 反向生成 PHYSICAL-MODEL.md
  │   └── 解析 CREATE TABLE → 字段级表格（§28.2 格式）
  └── 扫描 Controller/Router 类 → 生成 API-INDEX.md

Step 3: 生成 INDEX.md（§29 详述）

Step 4: 创建限界上下文目录（如有足够信息）
  └── docs/architecture/<bc-name>/（当前版本不强制，advisory）
```

**优先级原则**：用户既有成果物 > 确定性提取 > LLM 推断。绝不跳过用户提供的成果物直接用 LLM 推断。

### 28.4 arch-merge 脚本实现

**定位**：change 收尾阶段的**脚本化**全局架构回写操作，由 release-archivist 调用 `tf arch-merge` CLI 命令触发。

**脚本路径**：`scripts/lib/arch-merge.mjs`（参考 `prototype-sync.mjs` 193 行的实现模式）

**CLI 注册**：`scripts/team-flow.mjs` 注册 `tf arch-merge <change-name>` 命令

**完整流程**：

```
tf arch-merge <change-name>
│
├─ Step 1: 一致性预检
│  ├── 结构冲突：重复 BC/聚合 key
│  ├── 语义冲突：同义异名（同一字段在不同 change 中命名不一致）
│  └── 跨域一致性：AA 功能 ≥ 1 IA 实体支撑，IA 实体 ≥ 1 AA 功能消费
│  → 预检失败 → 输出报告 + 退出（非零状态码），由 release-archivist 处理
│
├─ Step 2: ARCHITECTURE.md 回写
│  ├── 当前态视图：按 BC/聚合 key 去重取最新（覆盖式）
│  └── 演进日志：append-only（含 change_id + 日期 + 影响范围）
│
├─ Step 3: PHYSICAL-MODEL.md 增量合并
│  ├── 变更涉及的表：字段级增量合并（新增/修改/删除字段）
│  └── 未涉及的表：保持不动（最小变更原则）
│
├─ Step 4: schema-baseline.sql 同步
│  ├── 追加新 DDL（CREATE TABLE / ALTER TABLE）
│  └── 保持完整可执行性（全量 DDL 重新排序确保依赖顺序）
│
├─ Step 5: 变更脚本归档
│  ├── 复制 sql/ddl/*.sql → docs/architecture/changelog/ddl/
│  └── 复制 sql/migration/*.sql → docs/architecture/changelog/migration/
│
├─ Step 6: API-INDEX.md 增量更新
│  ├── 新增端点：追加到对应分流区域（Command/Read/Query）
│  ├── 修改端点：更新对应行
│  └── 删除端点：标记废弃 + change_id
│
├─ Step 7: INDEX.md 更新
│  └── 更新各产物的摘要统计（表数量/端点数量/最后更新 change）
│
└─ Step 8: 单次 git commit（原子性提交）
```

### 28.5 database.md 模板修订（DDL 外置）

v0.22.5 的 `templates/database.md` 中 §3 Schema 变更详情 和 §5 数据迁移脚本 将 DDL/SQL 嵌在 markdown 代码块中。修订为：

```markdown
## 3. Schema 变更详情

### 3.1 DDL 脚本
> 可执行脚本位于 `sql/ddl/` 目录，以下为变更概要。

| 脚本文件 | 操作类型 | 目标表 | 说明 |
|---------|---------|-------|------|
| `sql/ddl/20260715_add_expert_check.sql` | CREATE TABLE | t_expert_check | 新增专家检查表 |
| `sql/ddl/20260715_alter_improvement.sql` | ALTER TABLE | t_improvement_direction | 新增字段 expert_check_round_count |

### 3.2 变更影响
<对现有物理模型的影响说明>

## 5. 数据迁移脚本

> 可执行脚本位于 `sql/migration/` 目录。

| 脚本文件 | 说明 | 幂等性 | 回滚方式 |
|---------|------|-------|---------|
| `sql/migration/20260715_migrate_check_data.sql` | 迁移历史检查数据 | 是 | DROP + 重跑 |
```

---

## 二十九、上下文治理策略（v0.23.0）

### 29.0 问题

VRM 项目 PHYSICAL-MODEL.md 1229 行/45 表 ≈ 4K+ tokens。全局层 6 个文件全量加载轻松超 8K tokens。architecture-design 做增量设计时如果全量加载所有架构基线，上下文预算爆炸。

### 29.1 三层策略

| 层次 | 机制 | 始终加载 | 预算 |
|------|------|---------|------|
| **L1 摘要索引** | INDEX.md | ✅ | ~50 行 / ~500 tokens |
| **L2 业务域分段** | PHYSICAL-MODEL.md 按 BC/域分组 | ❌ 按需 Read 对应段 | 每域 ~200-500 行 / ~1K tokens |
| **L3 变更层组装** | architecture-design 根据五项检查自动加载 | ❌ 按需 | ~500 tokens |

**总预算**：单次 architecture-design 执行 ~2K tokens（L1 + 1-2 个 L2 段 + L3），对比全量 ~10K tokens，**节省 80%**。

### 29.2 INDEX.md 格式

```yaml
# Architecture Index

> 本文件始终加载，各产物按需 Read。

## ARCHITECTURE.md
- 限界上下文: 需求企划 / 需求判定 / 价值回检 / 专家评审 / 基础数据
- 聚合数量: 8
- 最后更新: change=add-expert-review, 2026-07-15
- 读取建议: 按 BC 段落读取

## PHYSICAL-MODEL.md
- 表数量: 45
- 业务域:
  - 需求企划域: t_improvement_direction, t_improvement_user_story, ... (12表)
  - 需求判定域: t_user_story_judgment_snapshot, ... (8表)
  - 价值回检域: t_value_review, t_review_record, ... (5表)
  - 专家评审域: t_expert_check_history, ... (4表)
  - 基础数据域: t_innovation_group, t_department, ... (10表)
  - 系统域: t_sequence_generator, t_export_task, ... (6表)
- 最后更新: change=add-expert-review, 2026-07-15
- 读取建议: 按业务域段落读取

## schema-baseline.sql
- 表数量: 45
- 最后更新: change=add-expert-review, 2026-07-15
- 读取建议: 通常不需加载，DDL 由 sql/ 目录独立管理

## API-INDEX.md
- 端点数量: 87
- 分流统计: Command=32 / Read=28 / Query=27
- 最后更新: change=add-expert-review, 2026-07-15
- 读取建议: 按分流区域读取

## CONCEPTS.md
- 术语数量: 25
- 最后更新: bootstrap, 2026-07-01
```

### 29.3 architecture-design 上下文组装规则

SKILL.md 的 Workflow 集成段新增"上下文加载协议"：

```
architecture-design 执行时的上下文组装：

始终加载：
  1. Read docs/architecture/INDEX.md（~50行摘要）
  2. Read changes/<name>/change-brief.md（如有）
  3. Read changes/<name>/proposal.md（如有）

根据五项检查按需加载：
  4. [聚合变更] → Read PHYSICAL-MODEL.md 对应业务域段落
                  Read ARCHITECTURE.md 对应 BC 段落
  5. [读写模型变更] → Read PHYSICAL-MODEL.md 对应域段落
  6. [API 变更] → Read API-INDEX.md 对应分流区域
  7. [DB schema 变更] → Read schema-baseline.sql 对应表的 DDL
  8. [限界上下文变更] → Read ARCHITECTURE.md 全文（BC 变更需全局视角）

绝不加载：
  - baseline.md（项目全景，arch-design 不需要）
  - 未涉及的业务域段落
  - 历史变更脚本（changelog/）
```

### 29.4 INDEX.md 维护规则

| 事件 | INDEX.md 更新 |
|------|-------------|
| Bootstrap 完成 | 创建 INDEX.md，写入全部产物摘要 |
| arch-merge 完成 | 更新表数量/端点数量/最后更新 change |
| 手工新增表（非 team-flow 流程） | 手工更新 INDEX.md（advisory） |

---

## 三十、代码层强制化（v0.23.0）

### 30.1 architecture/*.md 纳入 artifacts_hash

**现状**：`hash.mjs` 的 `computeArtifactsHash` 只统计 `proposal.md` + `specs/*/spec.md` + `design.md` + `tasks.md`。architecture/*.md 不在统计范围，可被修改而不触发 hash 失效。

**修改**：`hash.mjs` 新增 `architecture/` 目录扫描——统计 `architecture/architecture.md` + `architecture/database.md` + `architecture/api.md`。三个文件全空则不参与 hash（兼容 `arch_design_decision=skipped` 的 change）。

**注意**：`sql/` 目录下的 `.sql` 文件**不**纳入 hash——它们是可执行制品，由版本控制自身保证完整性，不需要 hash 二次校验。

### 30.2 guard.mjs 增加 arch 维度

**现状**：`exploring:specifying` 转换只查 `artifacts-exist`（4+1 产物存在性），不检查架构设计是否完成。

**修改**：在 `exploring:specifying` 守卫中新增 arch 维度：

```
if arch_design_decision == "required":
    check: architecture/architecture.md 存在且非空
    check: architecture/database.md 存在且非空（当 DB schema 变更 = 是）
    check: architecture/api.md 存在且非空（当 API 变更 = 是）
    → 任一缺失 → BLOCK（与 artifacts-exist 同级别阻断）

if arch_design_decision == "skipped":
    check: arch_design_reason 非空
    → 缺失 → ADVISORY（不阻断）
```

### 30.3 state-loader / cmd-state 确认

v0.22.5 已修复 `arch_design_decision/reason/timestamp/artifacts` 字段的代码支持（F02+F06）。本版无需额外修改 state-loader.mjs 或 cmd-state.mjs。

---

## 三十一、api.md 定位调整（Swagger 协同，v0.23.0）

### 31.0 背景

项目使用 Swagger 管理 API 精确规格（请求/响应 Schema、错误码、参数定义）。api.md 不应重复 Swagger 的职责。

### 31.1 职责划分

| 维度 | api.md 负责 | Swagger 负责 |
|------|------------|-------------|
| 分流归属 | ✅ Command/Read/Query 归类 | ❌ |
| 阻断测试归属 | ✅ 业务服务 vs 数据服务 | ❌ |
| 端点概要 | ✅ HTTP 方法 + 路径 + 一句话描述 | ✅ 精确 Schema |
| 请求/响应 Schema | ❌ | ✅ 完整定义 |
| 错误码 | ❌ | ✅ 完整定义 |
| 跨域一致性 | ✅ API↔数据实体对齐检查 | ❌ |
| 聚合归属 | ✅ 端点→聚合→BC 映射 | ❌ |

### 31.2 api.md 模板修订

**定位：架构路由表**——告诉开发者端点**为什么存在、属于哪个聚合、是写还是读**。

```markdown
# API 增量设计: <change-name>

## 1. As-Is 基线（冻结复制）
> 从 API-INDEX.md 复制相关端点到此处

## 2. To-Be 增量设计

### 2.1 Command API（改状态）
| 端点 | 方法 | 聚合 | 事务边界 | 说明 |
|------|------|------|---------|------|
| /api/expert-check | POST | ExpertCheck | t_expert_check_history 事务 | 提交专家检查结果 |

### 2.2 Read API（有逻辑不改状态）
| 端点 | 方法 | 聚合 | 数据来源 | 说明 |
|------|------|------|---------|------|
| /api/improvement/{id}/check-history | GET | ExpertCheck | t_expert_check_history + JOIN | 查询检查履历 |

### 2.3 Query API（纯查询）
| 端点 | 方法 | 查询模型 | 阻断测试 | 说明 |
|------|------|---------|---------|------|
| /api/dashboard/expert-stats | GET | ExpertStatsView | 阻断=继续 → 数据服务 | 专家统计看板 |

## 3. 跨域一致性检查
> API 端点与数据实体对齐检查

## 4. 演进日志
```

---

## 三十二、配置管理与 Skill 降级逻辑补强（v0.26.0）

> 来源：workflow-feedback 2026-07-29（VRM 项目 SOP 流程反馈）
> 目标插件版本：**v0.26.0**

### 32.1 config-loader 查找顺序优化（P2）

#### 32.1.1 问题现状

当前 `config-loader.mjs` 的查找顺序为：
1. 项目根目录（`startDir/team-flow.config.json`）
2. git 根目录（`gitRoot/team-flow.config.json`）
3. home 目录（`~/team-flow.config.json`）

**问题**：配置文件直接放在项目根目录，与其他项目配置文件混杂，不符合"team-flow 相关配置集中管理"原则。

#### 32.1.2 改进方案

修改 `findConfigFile` 函数，将 `.team-flow/team-flow.config.json` 加入查找路径（**优先于项目根目录**）：

```
新查找顺序：
1. .team-flow/team-flow.config.json（startDir 下）
2. team-flow.config.json（startDir 下，兼容旧路径）
3. git 根目录
4. home 目录
```

**理由**：`.team-flow/` 是 team-flow 的专属目录，已有 `registry.yaml`、`requirements/`、`feedback/` 等结构，配置文件理应归属此处。

#### 32.1.3 涉及文件

| 文件 | 修改内容 |
|------|---------|
| `scripts/lib/config-loader.mjs` | `findConfigFile` 函数增加 `.team-flow/` 路径查找 |
| `scripts/lib/config-loader.test.mjs` | 新增测试用例验证 `.team-flow/` 路径优先级 |

---

### 32.2 ce-brainstorm Phase 0.0 降级逻辑补强（P1）

#### 32.2.1 问题现状

ce-brainstorm Phase 0.0 直接运行 `tf runtime config --get prd.template`，存在以下问题：

| 问题 | 影响 |
|------|------|
| 未检查 `tf` CLI 是否可用 | 命令失败后无降级处理 |
| 未按 SKILL.md 定义的降级逻辑执行 | 跳过用户选择，自行决定 |
| 在 skill 目录写入文件 | 违反"不修改 skill 源码目录"原则 |

#### 32.2.2 改进方案

**2.2.2.1 Phase 0.0 增加 tf CLI 可用性检查**

```markdown
**Resolve PRD template — MANDATORY STEP, DO NOT SKIP.**

1. **检查 tf CLI 是否可用**：运行 `which tf`
   - ✅ 可用：继续执行 `tf runtime config --get prd.template`
   - ❌ 不可用：走降级逻辑（见下方）

2. **降级逻辑（tf 不可用时）**：
   - 通知用户：`tf` 命令不可用，将使用默认配置
   - **询问用户**：默认模板 or 自定义路径？
     - 默认模板：使用 skill 内置 `templates/prd.md`
     - 自定义路径：验证文件存在，在项目工作区记录配置
   - 在 `.team-flow/templates/` 目录创建/使用模板（绝不在 skill 目录写入）
   - **维护配置文件**：在 `.team-flow/team-flow.config.json` 中记录配置（如文件不存在则创建）
```

**2.2.2.2 增加 guardrail：禁止写入 skill 目录**

在 Phase 0.0 开头增加显式 guardrail：

```markdown
> **⛔ GUARDRAIL：禁止写入 skill 源码目录**
>
> 项目级制品（PRD 模板、配置文件等）只在**项目工作区**创建/修改：
> - 模板文件：`.team-flow/templates/`
> - 配置文件：`.team-flow/team-flow.config.json`
>
> **绝不写入 skill 源码目录**（`skills/ce-brainstorm/` 等）。
```

#### 32.2.3 涉及文件

| 文件 | 修改内容 |
|------|---------|
| `skills/ce-brainstorm/SKILL.md` | Phase 0.0 增加 tf CLI 检查 + 降级逻辑 + guardrail |
| `skills/ce-brainstorm/references/phase0-routing.md` | 同步更新降级逻辑说明 |

---

### 32.3 配置文件迁移

#### 32.3.1 当前项目迁移

将当前项目的 `team-flow.config.json` 从项目根目录迁移到 `.team-flow/team-flow.config.json`。

#### 32.3.2 新项目默认路径

新项目创建时，默认配置文件路径为 `.team-flow/team-flow.config.json`。

---

## 实施计划

### 优先级排序

| 优先级 | 修改项 | 涉及文件 | 说明 |
|--------|-------|---------|------|
| **P0** | §30 代码层强制化 | hash.mjs + guard.mjs | 最小改动、最大约束力 |
| **P0** | §28.5 database.md 模板修订 | templates/database.md | DDL 外置引用 |
| **P0** | §31 api.md 模板修订 | templates/api.md + SKILL.md | 定位调整 |
| **P1** | §28.4 arch-merge 脚本 | scripts/lib/arch-merge.mjs + team-flow.mjs | 完整实现 |
| **P1** | §28.3 Bootstrap 改造 | workflow-bootstrap/SKILL.md + recon-probe.sh | 成果物导入+DDL提取 |
| **P1** | §29 INDEX.md + 物理模型 | 新增 INDEX.md 模板 + PHYSICAL-MODEL.md 模板 | 上下文治理 |
| **P2** | §28.2 PHYSICAL-MODEL 模板 | templates/physical-model.md | VRM 格式标准化 |
| **P2** | 下游消费同步 | spec-writer/build-executor SKILL.md | 输入源更新 |

### 下游消费同步清单

arch-design 产出变为"文档+可执行制品"双轨后，下游 skill 的输入源需同步更新：

| 下游 skill | 当前输入 | 新增输入 |
|-----------|---------|---------|
| spec-writer | architecture/*.md | + sql/ 路径引用 |
| build-executor | tasks.md + design.md | + sql/ddl/*.sql（直接执行） |
| code-reviewer | specs + design | + api.md 跨域一致性段 |
| release-archivist | architecture/*.md | + `tf arch-merge` CLI 调用 |

---

## 三十三、workflow-orchestrator S4 阶段强制化（v0.27.0）

### 33.0 问题诊断（2026-07-29 feedback 批量分析）

vrm4teamflow 项目在执行 S3→S4 过渡时，暴露 4 个关联问题（1 P0 + 1 P1 + 2 P2），根因均指向 **orchestrator SKILL.md 的 S4 阶段设计缺陷**：

| 编号 | 问题 | 严重性 | 现象 | 根因 |
|------|------|--------|------|------|
| P0-1 | S4 跳过必选门禁 | P0 | change-split-auditor 未执行、tf state init 未执行、CLAUDE.md 替代 change-brief.md、change_dag 格式错误 | agent 未读取 `references/s4-split-validate.md`，凭"常识"执行 |
| P1-1 | change 制品格式错误 | P1 | CLAUDE.md 替代 change-brief.md，内容含文件清单（越界） | 同上 |
| P2-1 | 状态不一致 | P2 | orchestrator.yaml 顶层 workflow_phase 未同步更新 | SKILL.md 未明确阶段转换原子性操作 |
| P2-2 | plan.md 编号混乱 | P2 | change 合并后 §1.1 与 §4 引用不对应 | 合并操作后缺乏同步更新机制 |

**共同根因**：SKILL.md S4 节正文描述过于简略（仅 2 段概述），关键规范全在 `references/s4-split-validate.md` 中，agent 容易跳过 references 直接凭既有知识执行。这与 S2 节已有 `⛔ MANDATORY` 指令形成对比——S2 的模式有效，S4 缺乏此机制。

### 33.1 改进方案

#### 33.1.1 S4 正文强制化（类比 S2 模式）

在 SKILL.md S4 节正文开头增加：

```markdown
**⛔ MANDATORY：执行S4阶段前，必须先读取 `references/s4-split-validate.md`**
```

此指令为 **硬约束**，agent 必须在执行任何 S4 步骤前读取完整参考文档。

#### 33.1.2 S4 步骤 checklist 化

将 S4 的 5 个核心步骤以 checklist 形式写入正文（而非仅在 references 中）：

```markdown
**S4 步骤清单（必须按顺序执行，不可跳过）**：

- [ ] **Step 1: 拆分质量审计**（必选门禁）
  - 调用 `change-split-auditor` agent
  - verdict = PASS 是后续步骤的硬前置条件
  - verdict = FAIL → 回退 S3，不可绕过

- [ ] **Step 2: 反馈环路检查点**
  - 依赖图是否可执行？粒度是否合理？
  - 否 → 回退 S3

- [ ] **Step 3: 创建 change 脚手架**
  - 为每个 change 执行 `tf state init`
  - 验证 `.team-flow.yaml` 已创建

- [ ] **Step 3.5: 落盘 change-brief.md**
  - 为每个 change 写 frontmattered change-brief.md
  - 验证文件存在且格式正确

- [ ] **Step 4: 写入 change_dag**
  - 更新 orchestrator.yaml 的 change_dag 字段

- [ ] **Step 5: 分发**
  - 告知用户执行顺序建议
```

#### 33.1.3 S4 完成校验

S4 标记完成前，必须执行以下校验（可作为 agent 自查或 guard 检查）：

```markdown
**S4 完成校验（必须全部通过）**：

1. ✅ change-split-auditor verdict = PASS（审计报告已生成）
2. ✅ 所有 change 目录存在于 `changes/` 下（非 `.team-flow/`）
3. ✅ 每个 change 目录包含 `.team-flow.yaml`（`tf state init` 已执行）
4. ✅ 每个 change 目录包含 `change-brief.md`（含 YAML frontmatter）
5. ✅ orchestrator.yaml 的 `change_dag` 已填充（格式正确）
6. ✅ orchestrator.yaml 顶层 `workflow_phase` 已更新为 `s4_split`（单一真相源）
```

#### 33.1.4 workflow_phase 单一真相源

明确 `orchestrator.yaml` 顶层 `workflow_phase` 为唯一真相源：

```markdown
**workflow_phase 同步规则**：

- **单一真相源**：`orchestrator.yaml` 顶层 `workflow_phase` 字段
- **阶段转换时**：必须同步更新顶层 `workflow_phase` + 对应 phase 子节点的 `status`
- **registry.yaml**：引用 `orchestrator.yaml` 的 `workflow_phase`，不独立维护
```

#### 33.1.5 change-brief.md 规范强调

在 S4 正文增加 change-brief 的必要字段和反模式说明：

```markdown
**change-brief.md 规范**：

**必要字段（YAML frontmatter）**：
- `upstream_source`: orchestrator | manual | null
- `upstream_req_id`: 对应 requirement ID
- `upstream_plan_ref`: 对应 plan.md 路径
- `upstream_change_id`: 对应 change_dag.id
- `plan_hash`: sha256:<plan.md 摘要>

**内容段**：
- Scope（功能级）
- 约束
- AC 列表（取自 auditor 报告 Dim1 覆盖矩阵）
- 全局技术方向（指针，非完整设计）
- PRD & plan 引用

**⛔ 反模式（禁止）**：
- 使用 CLAUDE.md 替代 change-brief.md
- 在 change-brief 中写完整文件清单（这是 spec-writer 的职责）
- 省略 YAML frontmatter
```

### 33.2 影响范围

| 修改项 | 涉及文件 | 说明 |
|--------|---------|------|
| S4 正文强制化 | `skills/workflow-orchestrator/SKILL.md` | 增加 MANDATORY 指令 + checklist + 校验 + 规范 |
| 设计文档 | 本文件 | 记录改进决策 |

### 33.3 验证标准

- [ ] SKILL.md S4 节包含 `⛔ MANDATORY` 指令
- [ ] S4 步骤 checklist 清晰列出 6 个步骤
- [ ] S4 完成校验清单包含 6 项检查
- [ ] workflow_phase 单一真相源规则明确
- [ ] change-brief.md 规范和反模式说明完整

---

## 三十四、npx 10.x 兼容性修复（v0.27.0）

### 34.0 问题诊断（2026-07-29 feedback P0）

vrm4teamflow 项目在执行 S4 阶段时，所有 `npx --yes --package @xulthekl/team-flow@0.26.1 tf <subcommand>` 调用均失败，返回 `Unknown command: "tf"`。

**根因**：
1. **npx 10.x 行为变更**：Node 22 自带 npm 10.9.x，npx 10.x 对 `--package @scope/pkg bin-name` 的解析逻辑与旧版本不同
2. **package 名与 bin 名不一致**：`@xulthekl/team-flow` → `tf`，npx 无法正确关联
3. **影响范围极广**：整个 team-flow 插件的所有 skill/agent 都用此模式调用 CLI

**复现条件**：
- Node 22（npm 10.9.x / npx 10.x）
- 未全局安装 `@xulthekl/team-flow`
- 执行 `npx --yes --package @xulthekl/team-flow@0.26.1 tf --help`

### 34.1 解决方案

#### 34.1.1 方案对比

| 方案 | 描述 | 优点 | 缺点 | 选择 |
|------|------|------|------|------|
| A | 全局安装 + session-start hook 自动同步 | 最简洁，版本自动同步 | 需要全局安装 | ✅ 采用 |
| B | npx fallback 逻辑 | 兼容性好 | 改动量大（105处） | ❌ |
| C | node 直接执行 + 缓存解包 | 不依赖 npx | 需要解包缓存 | ❌ |
| D | 发布独立 CLI 包 | 包更小、npx 更可靠 | 需要额外维护 | ❌ 长期方案 |

#### 34.1.2 最终方案：全局安装 + session-start hook 自动同步

**机制**：
```
plugin 发布时：
    开发团队在 plugin.json 中写入 { "version": "0.27.0" }
        ↓
用户安装 plugin：
    plugin.json 随 plugin 一起部署到 .cursor/ 或 .claude/ 目录
        ↓
session-start hook：
    读取 plugin.json 的 version
    与本地 tf --version 比较
    不一致 → 自动执行 npm install -g @xulthekl/team-flow@0.27.0
        ↓
✅ 版本自动同步，用户零干预
```

**优势**：
- **简洁**：所有 skill/agent 调用简化为 `tf <subcommand>`（105 处替换）
- **自动同步**：session-start hook 自动检查并更新版本
- **零手动操作**：用户无需记住更新命令
- **版本一致**：plugin 版本与 CLI 版本始终匹配

**实现细节**：
1. **版本来源**：plugin.json 的 `version` 字段（plugin 发布时写入）
2. **检查时机**：session-start hook（每次 session 开始时自动执行）
3. **更新方式**：`npm install -g @xulthekl/team-flow@X.Y.Z`（自动执行）
4. **调用格式**：`tf <subcommand>`（全局安装后直接可用）

### 34.2 影响范围

| 修改项 | 涉及文件 | 数量 | 说明 |
|--------|---------|------|------|
| session-start hook | `hooks/session-start` | 1 处 | 添加版本检查和自动同步逻辑 |
| CLI 调用替换 | `skills/**/*.md` | ~105 处 | 批量替换 `npx ... tf` 为 `tf` |
| 设计文档 | 本文件 | 1 处 | 记录改进决策 |

### 34.3 验证标准

- [ ] session-start hook 自动检查版本并同步
- [ ] `tf --help` 正常输出（全局安装后）
- [ ] `tf state init changes/test/` 正常执行
- [ ] 所有 skill/agent 中的 CLI 调用已替换为 `tf <subcommand>`
- [ ] 版本号已同步到所有文件

---

## 第二十章决策落实状态——新增条目

| 序号 | 决策 | 本版落实 |
|------|------|---------|
| 16 | 架构制品可执行化 | §28 sql/ 独立目录 + schema-baseline.sql + PHYSICAL-MODEL.md |
| 17 | arch-merge 脚本化 | §28.4 完整脚本实现 + CLI 注册 |
| 18 | 上下文治理 | §29 INDEX.md + 按域分段 + 按需加载 |
| 19 | API 定位调整 | §31 架构路由表 + Swagger 协同 |
| 20 | npx 10.x 兼容性修复 | §34 node 直接执行 + 缓存解包 |
