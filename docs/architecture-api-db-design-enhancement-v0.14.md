# 架构 / API / DB 设计增强方案 · v0.14（产品级架构设计增强：完整闭环 + 全局实际态持续维护）

> 版本：v0.14 · 重大修订（增量式，承袭 v0.13）
> 目标插件版本：**v0.36.0**
> 修订依据：v0.13 全量内容**继续有效**；v0.14 仅记录本次增量修订。
> 触发来源：LT 三句话诉求（2026-08-03）——①plan 之后补产品级整体详细架构设计 ②change 级保留、产品级为输入 ③全局详细架构持续维护；三轮独立评审（4 专家方案评审 + 复利回写评估 + change 级评估 + 旧项目设计）
> 决策确认：LT 2026-08-05 决策 ✅（详见 §67 决策落实状态）
>
> **v0.14 修订摘要（相较 v0.13）**：
> - **§57 总览**：现状三缺口（复利闭环断裂 / 无产品级架构层 / 旧项目无着手路径）+ 三诉求映射到新机制。
> - **§58 设计原则**：四条评审共识（P1 全局=实际态快照=预测态 / P2 机器管结构人管语义 / P3 门禁硬但留逃生舱 / P4 增量有界演进可溯）。
> - **§59 architecture 阶段编排**：S3.5 新阶段 + 场景判定 + skip 物化 + arch-readiness/arch-snapshot 门禁 + arch_baseline 豁免键。
> - **§60 产品级架构文档体系与模板**：三层数据面 + 6 产物模板 + 正向/逆向设计 + 按域分段加载。
> - **§61 变更级架构设计联动**：输入契约扩展 + 五项检查路由分流 + 分工边界 + 防重发明机制。
> - **§62 全局复利回写重构**：arch-merge 从 append 重构为当前态幂等 upsert + 生成式产物 + 冲突预检 + 并发安全 + api-scan。
> - **§63 旧项目适配**：arch_baseline 豁免 + 场景判定 + 逆向重建 + 分层渐进（L0+L1）+ 在途 change 兼容。
> - **§64 实现分层**：v0.36.0 P0 八项 + 后续 P1-P3 深化项。
> - **§65 文档登记**：v0.14 登记点 + Roadmap 待办。
> - **§66 验证方案**：E2E 主线 + Tier1 确定性 fixture 负例。
> - **§67 决策落实状态**（补 v0.13 缺失章节）：本次决策逐条记录。

---

## 五十七、总览：产品级架构设计增强（v0.36.0）

### 57.1 现状三缺口（评估实证）

三轮独立评估（4 专家方案评审 + 复利回写评估 + change 级架构设计评估）确认三个真实缺口：

| 缺口 | 证据链 | 后果 |
|------|--------|------|
| **复利闭环断裂** | arch-merge 的"当前态合并"三步全为 stub：ARCHITECTURE 只 append 演进日志（当前态覆盖不存在）、PHYSICAL-MODEL 正则双重失配零写入（`(CREATE\|ALTER)\s+TABLE` vs 模板 §3.1 行格式）、API-INDEX 只 append footer、DATABASE 零回写 | 全局没有"当前态"→ change 的 As-Is 冻结复制为空 → 每 change 从零设计 → **复利归零**；reviewer A5 拿陈旧基线比对 = **假信心** |
| **无产品级架构层** | plan.md HTD 禁止 API/schema 细节；全局 docs/architecture/ 是瘦锚点；architecture-design 模板以"As-Is 冻结复制"开头不适配从零设计 | 大 PRD 完整架构设计无处承载；BC 边界/聚合所有权由各 change 各自声明 → 多 change 各自发明命名，**防漂移承诺落空** |
| **旧项目无着手路径** | workflow-bootstrap 只产出瘦锚点基线（非详细架构）；存量项目升级无迁移/兼容条款 | 旧项目（已有代码、无完整架构）无法建立产品级架构，新门禁会卡死在途 change |

### 57.2 LT 三诉求 → 新机制映射

| LT 诉求 | 新机制 | 章节 |
|---------|--------|------|
| ① plan 之后做产品级整体详细架构设计（BC/聚合/指令事件/状态迁移图/ER图/时序图） | 新增 `architecture` 阶段（S3.5）+ 产品级架构文档模板（6 产物） | §59、§60 |
| ② change 级保留、产品级为输入依据 | architecture-design 输入契约扩展 + 五项检查路由分流 | §61 |
| ③ 全局详细架构持续维护 | arch-merge 重构（当前态 upsert）+ 三层数据面 + 旧项目适配 | §62、§63 |

### 57.3 整体形态：一条主线 + 三层数据面

```
迭代 vN
  S1 路由 → S2 PRD+原型（冻结） → S3 plan（拆分+DAG+技术方向）
  │
  S3.5 产品级架构设计（architecture 阶段）◄──── 新增 §59
  │   入口判定：全新项目=正向设计 / 旧项目首轮=逆向重建 / 已建档+无结构性变更=跳过（物化）
  │   产出：iterations/vN/architecture.md（6 产物，结构级详设，provenance 标注）
  │   评审：产品级架构评审门（PASS 才进 S4）；时序：只写快照不写全局（P1）
  │
  S4 拆分（arch-readiness 门：快照覆盖 change 触及的 BC）
  │
  每个 change（workflow-start 8 态）
  │   exploring→specifying：architecture-design（输入=快照对应 BC 段 + 全局当前态；路由分流；增量设计）
  │   审查：architecture-reviewer → DP-A 人工门
  │   closing：arch-merge 回写全局实际态（当前态 upsert + 生成式产物 + 冲突预检 + 写锁）
  │
  迭代收尾：iterations/vN/ 标 archived → 全局当前态 = 唯一权威
```

三层数据面：

| 层 | 位置 | 内容 | 归属/维护 |
|----|------|------|----------|
| L1 全局当前态（实际落地，唯一权威） | docs/architecture/ | ARCHITECTURE.md 当前态区（marker 区）+ domains/<bc>.md 按域详细页 + PHYSICAL-MODEL.md（从 SQL 生成）+ API-INDEX.md（从 swagger 生成）+ DATABASE.md（生成式禁改）+ INDEX.md（确定性统计） | 脚本（arch-merge）生成 + 语义层 LLM/人工评审 |
| L2 变更级增量 | changes/<id>/architecture/ | 三件套 + sql/，只写 delta | architecture-design 子代理 + reviewer |
| L3 迭代快照 + 演进日志 + changelog | iterations/vN/ + changelog/ | 产品级预测态快照（archived 后退役）+ 演进日志索引表 + 变更脚本归档 | S3.5 产出快照；arch-merge 维护日志旁路 |

---

## 五十八、设计原则（v0.36.0）

> 四条原则是评审共识提炼，是整体方案的地基。任何实现细节不得违背。

### 58.1 P1 全局=实际态，快照=预测态，两者分离

产品级设计（预测态）只写 `iterations/vN/` 快照，不进全局当前态；change 关闭时 arch-merge 回写**实际增量**；迭代收尾快照标 `archived` 退役，全局唯一权威。

**理由**：避免预测污染实际，符合"先验收后贴标签"（架构文档是代码现实的贴标，非代码追随的预言）。这是方案被评审单独点名的**方法论锚点**。

**强制点**：S3.5 产出只写快照；arch-merge 只吃 change 实际增量；快照退役规则写入 SKILL 加载协议（读快照还是读全局由迭代状态判定）。

### 58.2 P2 机器管结构，人/LLM 管语义

结构性回写（当前态 upsert、物理模型、API 索引、DB 生成、冲突预检）走**结构化数据源**（frontmatter/JSON/SQL/swagger），不用正则扫 markdown。marker 代码独占写 + 成对校验 + 抽取 0 结果 abort。语义层（架构评审、五项检查判定、skip 判定）留 LLM + 人工确认门。

**理由**：实证两处正则脆弱——PHYSICAL-MODEL 反引号表名致零写入、`## 2. To-Be` 标题漂移致静默失败（match 失配返回空串、流程继续、`merged:true`）。本仓库已有 frontmatter-schema 强模式（§54 教训），文本手术是对该模式的降级。

### 58.3 P3 门禁硬但留逃生舱

每条硬门禁配：存量豁免键（`arch_baseline`/`schema_version`）+ 显式 skip 出路（物化 + 理由）+ 错误信息给下一步。定义性改动走"架构修订决策门"而非硬阻断。并发回写加锁防 lost update。门禁校验产物**有效性**（provenance/结构非空）而非仅存在性。

**理由**：v0.13 §54 教训"静默降级是最危险的失效模式"；v0.32.2 C1 事件"主代理被门禁逼出绕行"。硬阻断预测（快照）违背演进式架构——聚合边界实施中最常被证伪，必须留逃生舱。

### 58.4 P4 增量有界，演进可溯

产品级做**结构级详设**（BC/聚合/关键事件/状态机/概念 ER/关键时序），契约级细节（每 API schema/每表字段）留给 change 落地时涌现。变更级只写 delta（extend/new/refactor），不重定义。重建/设计产物标 `provenance` + 置信度。

**理由**：落地前全量契约级详设 = 大设计先行（Big Design Up Front），大概率返工；增量有界是防漂移承诺的前提；provenance 使重建产物可追溯、可抽查，杜绝"看着像那么回事"实则失真。

---

## 五十九、architecture 阶段编排（v0.36.0）

### 59.1 阶段定位与命名

- **位置**：S3 plan 之后、S4 拆分之前（S3.5）。
- **命名**：phase id `ARCH`，顶层 `workflow_phase: architecture`（语义 kebab-case）。**不采用编号 S3.5**——S4 内部已有「Step 3.5」（change-brief 落盘，s4-split-validate.md），并存两套"3.5"歧义。
- **固化约定**：新阶段一律用 kebab-case 语义名，历史 workflow_phase 值保留不迁移（避免无价值 churn）。
- **结构**：插入主链 `phases` 数组（S3 与 S4 之间），不用 `custom_phases: []`（那是插件级自定义预留，本阶段是标准主链一环）。

```yaml
phases:
  - { id: S1, status: completed, ... }
  - { id: S2, status: completed, ... }
  - { id: S3, status: completed, ... }
  - { id: ARCH, name: 产品级架构设计, workflow_phase: architecture,
      status: pending, skip: 迭代无结构性变更,
      artifacts: [docs/architecture/iterations/vN/architecture.md] }
  - { id: S4, status: pending, ... }
```

**代码现实**：phases/workflow_phase 完全由 LLM 按文档约定维护，无代码校验 → 插入新阶段零代码改动；重规划绿区已允许 stage-insertion（state-model.md:157）。可选加固是 guard check（见 §59.4）。

### 59.2 场景判定（入口三态）

S3.5 入口判定（写入 state-model.md + s3-plan-pipeline.md，由编排器 + 用户确认）：

| 场景 | 判定输入 | S3.5 模式 |
|------|---------|----------|
| S0 全新项目 | 无代码库 | 正向设计（首轮不可跳过） |
| S1 存量代码+无基线 | 有 src/，无 baseline.md | 先 workflow-bootstrap B1-B5 → 逆向重建 |
| S2 存量+瘦锚点 | baseline.md + ARCHITECTURE 无 BC/聚合层 | 逆向重建（深化，不做 B1 机械侦察） |
| S3 存量+跑过迭代 | baseline + changes/ + prd/vN/，无 arch_baseline | 逆向重建（首轮强制） |
| S4 已有产品级架构 | arch_baseline 已打戳 + iterations/ | 正向设计（正轨） |

**skip 条件**（复用现有 `skipped` 状态，须**物化**）：迭代无结构性变更（纯 bugfix/重构/不新增 BC 或聚合/不改变聚合边界或全局契约）。判定者 = **编排器 + 用户确认**（非 LLM 自判，防 §54 绕过教训）。**skip 必须物化**：写入 `iterations/vN/` 占位（含 skipped 标记 + 理由），guard 才放行——否则 hotfix/快速通道 change 会卡在 arch-readiness 上（v0.32.2 C1 死锁链同类）。

**时间盒 + 深度分层**：S3.5 时间盒 ≤1 天；非触及 BC 只维护锚点行（不进详设），触及 BC 才做按域深化（见 §60.4）。

### 59.3 输入输出契约

**输入**（S3.5 读取）：prd/vN/prd.md（frozen_downstream）+ prd/vN/plan.md（高阶技术设计段）+ prototype/ + docs/architecture/baseline.md（S1 注入）+ CONCEPTS.md（领域词汇）+ 现有全局基线（旧项目）。

**输出**：
- `docs/architecture/iterations/vN/architecture.md`（6 产物权威快照，预测态，provenance 标注）
- 产品级评审 verdict（§60.5）
- **不触发全局覆盖写**（P1：预测态不进实际态）

### 59.4 门禁与豁免

| 门禁 | 挂点 | 校验 | 豁免 |
|------|------|------|------|
| 产品级评审门 | S3.5→S4 | architecture-reviewer product 视角 PASS（§60.5） | skip 时仍要物化标记 |
| arch-readiness | S4 拆分 | iterations/vN/ 快照覆盖 change 触及的 BC | `arch_baseline` 缺失 → WARN 不 FAIL |
| arch-snapshot | executing→closing | 本轮快照已落盘（"先快照后回写"强制化） | 在途 change legacy 豁免 |

**arch_baseline 豁免键**（复刻 v0.13 §48.1 schema_version 防污染模式）：
- 位置：`.team-flow/arch-state.json`（项目级状态；架构阶段是产品/迭代级，不放 change 的 `.team-flow.yaml`）
- 内容：`{ arch_baseline: "v0", established_at, mode: "reconstruction" | "design", snapshot_root: "iterations/", baseline_prd_ref }`
- 防污染：仅 `tf arch init` 写入；`tf state set`/rebuild/doctor 一律不得追加（缺失 = 存量信号）
- 判定：`arch_baseline == null` → arch-readiness/arch-snapshot 均 PASS + WARN（reason: 'project architecture baseline not established — S3.5 reconstruction pending'）

**guard 实现**：新增 `scripts/guard/checks/arch-gate-exemptions.mjs`（共享豁免判定模块，仿 test-gate-exemptions.mjs）；`arch-readiness` 挂 `exploring:specifying`（与 arch-design 并列），`arch-snapshot` 挂 `executing:closing`（先于 arch-merge）。

---

## 六十、产品级架构文档体系与模板（v0.36.0）

### 60.1 存放：docs/architecture/ 三层升级

产品级详细架构的规范家在 `docs/architecture/`，升级为三层（§57.3 数据面）。`iterations/vN/` 快照同时满足"基于迭代版本 vN"的诉求 1，且是 L1 的预测态来源。

### 60.2 产品级架构文档模板（6 产物）

`iterations/vN/architecture.md` 骨架：

````markdown
---
iteration_version: v1
provenance: forward-designed        # 或 reverse-engineered / mixed
---
# 产品级架构设计 · 迭代 vN

## 1 限界上下文（Context Map）
| 上下文 | 职责(一句话) | 依赖 | 关系类型 | 语言边界/关键术语 |
```mermaid flowchart LR```

## 2 聚合注册表
| 聚合ID | 上下文 | 根实体 | 值对象 | 核心行为 | 关键不变量 | 事务边界 | 状态机锚点 |
## 2.2 聚合→表映射        | 聚合 | 表集合 | 读模型 |
## 2.3 聚合大小自检       # >5 实体提示拆分

## 3 指令与事件识别
## 3.1 指令表             | 指令 | 触发方 | 目标聚合 | Command/Read/Query | 结果事件 |
## 3.2 事件表             | 事件 | 类型(领域/集成/外部) | 源聚合/上下文 | 触发 | 携带数据 | 消费方 | 投影读模型 |
## 3.3 事件流图           # mermaid，事件→指令级联链（saga/process manager）
## 3.4 读模型投影清单     | 读模型 | 投影来源事件 | 更新方式(同步/异步) |

## 4 聚合状态迁移
## 4.1 {聚合} stateDiagram-v2
## 4.2 状态表             | 状态 | 触发(Command/Event) | 触发源上下文 | 目标状态 | guard 不变量 |

## 5 数据模型 / ER（概念级）
## 5.1 聚合边界 erDiagram    # 同聚合表圈在一起，标注聚合根表；跨聚合外键标"引用非事务内"
## 5.2 实体表              | 实体 | 关键字段 | 所属聚合 | 写/读模型 |

## 6 应用时序（关键用例）
## 6.1 用例索引           | 用例 | 图文件 | 涉及聚合/上下文 |
## 6.2 {用例} sequenceDiagram

## 7 跨域一致性检查      # F2 双对齐 + 语义统一 + F3 变更分叉级联
## 8 DDD 反模式自检      # 5 项：贫血模型/聚合过大/实体滥用/表驱动聚合/事件命名
## 演进日志             | 版本 | 日期 | 变更摘要 |
```
````

**结构约束**（P4 + 分段加载的物理前提）：
- §1-2 厚锚点：每行一句话，不展开细节；细节全部下沉 `domains/<bc>.md` 按域详细页与 `diagrams/`。
- 所有小节挂稳定 anchor id；marker 注释 `<!-- arch:current-state:begin/end -->` 是 arch-merge 覆盖写的替换边界（**marker 只由代码写，不由 LLM 写**，§62）。
- 事件命名规范 `OrderPlaced`/`PaymentCaptured`（名词+过去式动词），全系统一致。
- 显式声明："事件用于变更通知与投影驱动，**不引入事件溯源持久化**"。

**按域详细页** `domains/<bc>.md` 骨架：职责与依赖 / 聚合明细（根实体/值对象/不变量）/ 指令与事件（本域）/ 状态迁移图 / 数据片段（ER 局部）/ 应用时序（本域用例）/ 对外契约（防腐层/共享内核）。单文件 ≤1500 token（超出继续拆子页）。

### 60.3 执行流程（S3.5 内部 8 步，复用现有方法论）

| 步 | 动作 | 方法论（复用现有） | 产出 |
|----|------|-------------------|------|
| 0 | 输入梳理 | 读 PRD 功能清单 + plan 技术方向 + prototype + CONCEPTS + 现有基线 | 功能域→候选业务能力映射 |
| 1 | 限界上下文识别 | 功能域分组 + 词汇聚类 + 活动对象矩阵（ch04，重叠>70% 合并） | Context Map：BC 表 + 关系图（6 关系类型）+ 语言边界术语表 |
| 2 | 聚合识别 | 聚合四要素（ch04）+ 活动对象矩阵 | 聚合注册表（§60.2 §2） |
| 3 | 指令与事件识别 | CQRS 指令分流（ch05：Command/Read/Query + 阻断测试）+ 事件三类 | 指令表 + 事件表 + 事件流图 + 读模型投影清单 |
| 4 | 聚合状态迁移 | 聚合根=状态机守卫（Vernon） | stateDiagram + 状态表（含触发源上下文、guard 不变量） |
| 5 | 数据模型/ER（概念级） | 从聚合映射持久化（IA）+ CQRS 写读分区 | 聚合边界 ER + 实体表 + 聚合→表映射表 |
| 6 | 应用时序（关键用例） | AA→TA 编排（4A） | 关键用例 Top-N 跨聚合时序图 + 用例索引 |
| 7 | 跨域一致性检查 | F2 双对齐（AA≥1 IA 实体）+ 语义统一 + F3 变更分叉级联 | 一致性检查表 |
| 8 | 反模式自检 + 评审 | DDD 反模式清单 + 产品级评审门 | 自检清单 + 评审 verdict |

**顺序纪律**：聚合在前、ER 在后（ER 是派生产物，禁止先画 ER 再定聚合）；BC 边界/聚合所有权/全局契约是**产品级唯一事实源**（聚合注册表），变更级只引用。

### 60.4 按域分段加载（适配 ~2K token 硬预算）

architecture-design 上下文加载协议改三段式：

| 段 | 内容 | 预算 |
|----|------|------|
| ① 索引层 | baseline 摘要 + ARCHITECTURE.md §1-2 厚锚点 + INDEX.md | ~400-600 |
| ② 按域加载（按需） | change 触及的 domains/<ctx>.md（+相关 sequence/erd 片段） | ~800-1400 |
| ③ 变更增量 | changes/<id>/ 增量 + 相关 changelog | ~200-400 |

约束：单次装载 ≤2K token；跨多域一次只装载一个域文件逐域分步；锚点/域页 token 预算加**自动化校验**（镜像 frontmatter-lint 模式，进 npm test）——不靠 LLM 自律。

### 60.5 产品级评审门

复用 architecture-reviewer（A1-A6 扩展 product 视角）：

| 维度 | 校验 |
|------|------|
| A1 | 结构完备（6 产物章节存在 + marker/锚点可解析，机械预检） |
| A2 | SQL/结构有效（机械 grep） |
| A3 | 跨域一致性（AA↔IA 双对齐） |
| A4 | 与 PRD 功能清单覆盖映射（F001_P0 逐条 → BC/聚合/API） |
| A5 | 与全局基线一致性（旧项目：reconstruction 产物 vs 现状代码） |
| A6 | conventions 合规 |

≤3 轮修复循环 + 收敛检测，PASS 才进 S4。

---

## 六十一、变更级架构设计联动（v0.36.0）

### 61.1 输入契约扩展（architecture-design SKILL.md）

- **输入清单**（:66-71）：新增 `docs/architecture/iterations/vN/architecture.md`（主输入，产品级决策权威）+ 全局当前态（已落地部分）。
- **上下文加载协议**（:166-183）：改 §60.4 三段式。
- **增量 SOP**（ch06:31-37）：步骤重排为"识别触及上下文 → 装载产品级当前态对应域 → 产出变更增量 → 标注引用基线"。

### 61.2 产品级 vs 变更级分工边界

| 维度 | 产品级（S3.5，迭代级） | 变更级（architecture-design，change 级） |
|------|------------------------|------------------------------------------|
| 范围 | 全系统结构与全局契约 | 本 change 增量细节 |
| 限界上下文/聚合 | 定义与边界（注册表唯一事实源） | 只引用，不重定义 |
| 指令/事件 | 全局事件流、跨上下文契约 | 本 change 新增/修改的指令与事件 |
| 状态迁移 | 聚合完整状态机 | 本 change 涉及的状态/迁移增量 |
| ER/时序 | 全局概念 ER、关键应用时序 | 本 change 涉及的表字段/用例时序 |

### 61.3 五项检查路由分流

change 级五项检查（聚合/BC/读写模型/API/DB schema 变更）增加**路由分流**：

- 触及**产品级决策**（BC 边界变更/聚合所有权变更/全局契约变更）→ 引用快照 + 走**架构修订决策门**（不硬阻断，显式确认 + 登记 deviation，P3）。
- 仅 **change 内实现细节**（字段/端点/状态增量）→ 增量设计，不触发产品级变更。

**防重发明硬校验**：变更级聚合动作限三类——`extend`（既有聚合加字段/指令/事件/状态）、`new`（新增聚合，flag 登记待产品级晋升）、`refactor`（需决策门）；arch-merge 冲突预检 TODO3（delta 出现已注册聚合 id 的定义性改动 → 阻断 + 提示转产品级）。

### 61.4 架构演进单元粒度

结构性变更（BC 边界/聚合所有权）走决策门**按迭代粒度**晋升（避免 per-change 微 delta 刷屏产品级文档）；微增量（加可空列/参数）change 级自由放行。

---

## 六十二、全局复利回写重构（v0.36.0）

> 评估结论：现状复利闭环不成立（§57.1 缺口 1）。本版将 arch-merge 从"append 演进日志"**重构**为"当前态幂等 upsert + 生成式产物 + 冲突预检 + 并发安全"。这是整个"增量设计 + 复利回写"模型成立的前提，**P0-5 优先级最高**。

### 62.1 当前态幂等 upsert（替代 append）

- arch-merge 核心重构：按 BC/聚合 key 定位既有定义 → 存在则覆盖、不存在则追加（幂等，重复运行一致）。
- 演进日志收敛为"索引表 + 指向 changelog/"旁路；去重 key 用 **changeName 唯一锚**（非版本号——不同 change 可能同版本号，按版本去重会误删）。
- 全局当前态**按构造 = 所有已合并实际增量的投影**（arch-merge 重生成），非原地编辑。
- 首轮特例：首个 change 关闭时全局 = "v1 快照 + 已落地标注"（表/聚合标 `[已落地]`/`[设计中]`），v2 起走纯增量回写。

### 62.2 生成式产物（P2 机器管结构）

| 产物 | 生成方式 | 现状 | 修复 |
|------|---------|------|------|
| DATABASE.md | 从 schema-baseline.sql + PHYSICAL-MODEL.md + changelog/ 再生成 | 零回写 | 生成式禁改（文件头标 generated），构造上消除漂移 |
| PHYSICAL-MODEL.md | 从 schema-baseline.sql 反向生成 | stub（正则双重失配零写入） | 采纳 v0.10 §28.2 反向生成路径（字段级，DDL 为事实源） |
| API-INDEX.md | 从 swagger/OpenAPI 生成（api.md 已声明 `api_contract_manager: swagger`）+ 扫描已关闭 change 的 api.md | stub（空骨架） | api-scan.mjs（§62.4） |
| INDEX.md | 确定性统计：表数解析 schema-baseline、端点数扫描 changes、BC 数解析当前态 | 垃圾进垃圾出（统计 0） | 统计源改确定性产物 |

**数据源优先级**：`schema-baseline.sql（实际）> PHYSICAL-MODEL（增量合并）> 快照（设计）`；"v1 设计有但 baseline 无"的表 → 标"未落地"而非删除。

### 62.3 冲突预检（落地 3 TODO）

| 检查 | 检测 | 阻断行为 |
|------|------|---------|
| TODO1 端点冲突 | 两 delta 同 method+path 且契约不同 | 阻断输出冲突清单 |
| TODO2 字段冲突 | 同 table.column 类型不一致 | 阻断 |
| TODO3 聚合重定义 | 变更级 delta 定义已注册聚合 id | 阻断 + 提示转产品级 |

**仲裁协议**：阻断 → 人工仲裁或 cross-change-consistency-checker 出报告 → 回 S3.5 调快照。微增量（加可空列/参数）自由放行。

### 62.4 api-scan.mjs（新增）

- 输入：已关闭 change 的 `changes/**/api.md` + `domains/*` API 段 + schema-baseline.sql。
- 输出：API-INDEX.md（方法/路径/摘要/来源/版本），含重复端点标记。
- **保护**：扫描范围**限定已关闭 change**（在途半成品不得入全局）；重建结果为空 → **拒绝覆盖**（防历史手工端点被抹）。

### 62.5 并发安全 + 健壮性（P2/P3 硬门禁，先于 6 步补强）

| 硬门禁 | 实现 |
|--------|------|
| 抽取 0 结果 abort | 正则/结构化抽取失配 → 显式报错 + 禁止写盘（绝不允许空串继续合并返回 `merged:true`） |
| marker 成对校验 | marker 用容忍空白正则定位；begin/end 恰各一个，缺失/重复 → 硬失败；写后自检区外逐字节未变，失败回滚 |
| 全局写锁 | `docs/architecture/.arch-merge.lock`（mkdir 原子语义），拿不到锁等待/失败，串行化 |
| 白名单 git add | arch-merge 只 add 本次 touch 文件；检测到 docs/architecture/ 其他脏文件 → 告警/拒绝 |
| 确定性 fixture 测试 | Tier1 无 LLM 测试（§66） |

---

## 六十三、旧项目适配（v0.36.0）

### 63.1 豁免键：arch_baseline

完全复刻 v0.13 §48.1 schema_version 防污染规则（§59.4）。`arch_baseline` 缺失本身 = "存量"信号，只有 `tf arch init` 在重建完成时打戳，不进可手改通道。

### 63.2 逆向重建（复用既有链路，不重建机制）

- **复用**：recon-probe.sh（--ddl-out schema-baseline.sql）+ codebase-recon-analyst（modules/data-model/api-surface）。
- **新增（轻量）**：`arch-reverse-analyst` 子代理（学 codebase-recon-analyst 的 recon_json + root 入参 + 结构化交接契约），补 BC/状态/指令事件维度。
- **差异标注**：frontmatter `provenance: reverse-engineered`（重建）/ `forward-designed`（正向）/ `mixed`（渐进域深化）；逐条目标注来源（代码路径/文档/DDL/用户确认）；置信度 high/medium/low。

### 63.3 分层渐进（推荐，非一次性全量）

| 策略 | 成本 | 准确性 | 阻塞交付 | 适用 |
|------|------|--------|---------|------|
| 一次性全量 | 高 | 低（大系统 LLM 推断 BC 易失真） | 高 | 小系统 |
| **分层渐进（推荐）** | 中 | 中→高（渐进收敛） | 低 | 通用 |

- **L0 骨架（必做，首轮不可跳过的落地形态）**：候选 BC 列表 + 模块依赖图 + 聚合根候选 + API 表面总览；明确不做完整状态迁移/指令事件/时序图（留 L1）；规模 ~1-2K token。
- **L1 按域深化（渐进）**：每个 change 触及某 BC 时"先逆向读码理解现状 → 再正向设计 To-Be"（provenance: mixed）；每轮迭代结束将本域现状快照到 iterations/vN/。
- **规模阈值**：模块<10 且 LOC<2万 → 可一次性全量；否则强制 L0+L1（阈值可配置）。

### 63.4 在途 change 兼容

| 在途 change 类型 | arch-readiness | arch-snapshot |
|-----------------|----------------|---------------|
| 升级前创建（无 schema_version） | PASS（legacy） | PASS（legacy） |
| 升级后新建但项目重建未完成（arch_baseline null） | PASS + WARN | PASS + WARN |
| 正常（arch_baseline 已打戳） | 正常考核 | 正常考核 |

**在途 change 不需要逆向重建输入**：其架构是 change 级正向设计，已有 changes/<name>/architecture/；closing 以"当前实现实际态"回写（快照缺失时直接以 change 产物作为该域实际态，快照后补为 v0）。

### 63.5 衔接

重建基线快照 = `iterations/v0/`（Reconstruction Baseline，与 PRD 版本解耦，映射记在 arch-state.json 的 baseline_prd_ref），第一个真实迭代 v1。`tf arch init` 打戳后进入 design 模式，复利接管正常闭环。

---

## 六十四、实现分层与版本范围（v0.36.0）

### 64.1 P0 八项（本次全做）

| # | 内容 | 落点 |
|---|------|------|
| P0-1 | architecture 阶段编排 + 场景判定 + skip 物化 + arch-readiness/arch-snapshot 门禁 + arch_baseline 豁免 | state-model.md、s3-plan-pipeline.md、guard/checks/arch-gate-exemptions.mjs、s1-path-router.md、feedback-loops.md、handoff-template.md |
| P0-2 | 产品级架构文档模板（6 产物 + 结构级详设 + 结构化 frontmatter + marker/锚点 + 按域分段加载） | 新建 references/s3.5-architecture-template.md、s3.5-loading-protocol.md |
| P0-3 | S3.5 SOP（8 步）+ 产品级评审门（architecture-reviewer product 视角）+ owner 命名 | 新建 references/s3.5-product-architecture.md、architecture-design SKILL.md |
| P0-4 | 变更级输入联动 + 五项检查路由分流 + spec-writer 交叉核对 | architecture-design/SKILL.md、ch06、s4-split-validate.md、spec-writer |
| P0-5 | arch-merge 重构（§62 全部） | arch-merge.mjs、新建 scripts/lib/api-scan.mjs |
| P0-6 | 旧项目逆向重建：arch-reverse-analyst + recon-probe 扩展 + provenance/置信度 | workflow-bootstrap references、新建 arch-reverse-analyst.md |
| P0-7 | v0.14 文档 + Roadmap 登记 + CLAUDE.md/design-doc-system.md | docs/ |
| P0-8 | E2E + Tier1 确定性 fixture 测试 + token 预算校验 | tests/ |

**P0-5 优先级最高**（评估共识：它是整个模型成立的前提）；P0-5 内部先补 4 硬门禁（§62.5）再重构。

### 64.2 后续深化（P1-P3，本次不做）

- **P1**：事件风暴方法论（事件来源矩阵、聚合不变量反推启发式）；BC 依赖环检测工具化（图论校验）。
- **P2**：ER/时序图工具化（接 pretty-mermaid/archify + 漂移检测）；arch-merge 语义冲突增强（聚合不变量级冲突）。
- **P3**：全局 API 消费者影响扫描。

---

## 六十五、文档登记与 Roadmap（v0.36.0）

### 65.1 v0.14 登记点

- `docs/design-doc-system.md`：版本表新增 v0.14；设计文档类型新增「产品级架构设计文档」（6 产物模板）。
- `CLAUDE.md`：工作流阶段列表加 architecture 阶段；三层维护约定；arch_baseline 豁免；权威版本指针 v0.13 → v0.14。
- `state-model.md`：phases 约定（ARCH 插入点）、skip 物化条件、workflow_phase 命名约定。

### 65.2 Roadmap 待办

| ID | 待办 | 优先级 | 版本 | 来源 |
|----|------|--------|------|------|
| v0.36.0 | 产品级架构设计增强（P0 八项） | P0 | v0.36.0 | LT 三诉求 2026-08-03 / v0.14 |
| P1-48 | 事件风暴方法论（事件来源矩阵/不变量反推） | P1 | v0.36.0+ | v0.14 §64.2 |
| P1-49 | BC 依赖环检测工具化 | P1 | v0.36.0+ | v0.14 §64.2 |
| P2-46 | ER/时序图自动渲染 + 漂移检测 | P2 | v0.36.0+ | v0.14 §64.2 |
| P2-47 | arch-merge 语义冲突增强（聚合不变量） | P2 | v0.36.0+ | v0.14 §64.2 |
| P3-13 | 全局 API 消费者影响扫描 | P3 | — | v0.14 §64.2 |

**登记前核实**：roadmap P1-15（架构设计显式编排 v0.9 §26）标 🔲 待实施但 CLAUDE.md 记载 v0.22.5+/v0.23.0 已贯通——需先对齐状态再登记新条目，避免语义重叠。

---

## 六十六、验证方案（v0.36.0）

小型示例 PRD（如"订单状态跟踪增强"）走通主线 + 旧项目场景：

1. S3.5 正向设计 → 断言 6 产物章节/锚点/marker 完备、frontmatter 结构化、token 预算达标
2. 产品级评审门 PASS → S4 arch-readiness PASS
3. change 内 architecture-design → 三段式加载，断言 delta 只写增量、聚合 id 来自注册表、无重定义
4. change closing → arch-merge：断言当前态 upsert 幂等（双跑一致）、marker 区替换区外保留、DATABASE 无漂移、API-INDEX 含新端点、日志去重（changeName 锚）
5. 冲突用例（同端点/同字段/重定义聚合）→ 阻断出清单 + 仲裁
6. 旧项目场景：无 baseline 项目 → 逆向重建 L0 骨架 → arch_baseline 豁免 → 在途 change 不阻塞
7. 并发用例：双 change 并行 closing → 写锁串行化，无 lost update
8. **Tier1 确定性 fixture 负例**（无 LLM）：标题漂移/反引号表名/无 marker/双 marker/同 change 双跑/双 change 并发/首轮无 baseline——断言 arch-merge 确定性行为（abort/替换/去重/锁定）
9. 回归：npm test + check-versions + team-flow-e2e-test Tier1（state-machine 断言含 architecture 阶段可达）

---

## 六十七、决策落实状态（v0.14）

> 补 v0.13 缺失的决策追踪章节。每条决策的落实状态由后续版本在实施时更新。

| 决策点 | 决策 | 落实版本 | 状态 |
|--------|------|---------|------|
| 回写时序 | 产品级设计只写 iterations/vN/ 快照，不立即写全局；change 关闭回写实际增量；迭代收尾快照退役、全局唯一权威（P1） | v0.36.0 | 待实施 |
| 实现范围 | v0.36.0 两类全做（流程文档类 + 工程类 P0 八项） | v0.36.0 | 待实施 |
| DATABASE.md 维护 | 自动生成（generated 禁改），从 schema-baseline + PHYSICAL-MODEL + changelog 再生成 | v0.36.0 | 待实施 |
| 文档位置 | docs/architecture/ 三层升级（L1 当前态 / L2 变更增量 / L3 迭代快照+日志） | v0.36.0 | 待实施 |
| 阶段命名 | `architecture` 语义名（弃 S3.5，避免与 S4 Step 3.5 冲突） | v0.36.0 | 待实施 |
| 详设深度 | 产品级结构级详设（BC/聚合/关键事件/状态机/概念 ER/关键时序）；契约级细节留 change 落地涌现 | v0.36.0 | 待实施 |
| 架构演进单元粒度 | 结构性变更走决策门按迭代晋升；微增量 change 级自由放行 | v0.36.0 | 待实施 |
| arch_baseline 存放 | `.team-flow/arch-state.json`（项目级，独立于 change 状态） | v0.36.0 | 待实施 |
| 旧项目规模阈值 | 模块<10 且 LOC<2万 可一次性全量，否则 L0+L1 渐进（可配置） | v0.36.0 | 待实施 |

---

## 兼容性与风险

| 风险 | 缓解 |
|------|------|
| 正则/marker 脆弱致全局架构悄悄腐烂 | P2/P3：结构化数据源 + 抽取 0 结果 abort + marker 成对校验 + 确定性 fixture 测试 |
| 多 change 并行 closing 互相覆盖 | 全局写锁 + 白名单 git add + 幂等 upsert |
| 硬阻断预测态违背演进式架构 | 定义性改动 → 架构修订决策门（不阻断，显式确认 + 登记 deviation） |
| 旧项目升级被新门禁卡死 | arch_baseline 豁免键（WARN 不 FAIL）+ 在途 change legacy 豁免 + L0 骨架渐进 |
| 快照与全局双权威混乱 | P1：快照标 status（designing/in-flight/superseded）+ 勘误表；迭代收尾退役；加载协议按迭代状态读 |
| 产品级详设返工 | P4：结构级详设做全、契约级细节留 change 涌现（变化驱动重画） |
| 事件引入后读模型更新无定义 | §60.2 §3.4 读模型投影清单 + 显式"不引入事件溯源"声明 |
| token 预算失守 | 按域分段加载 + 锚点/域页 token 预算自动化校验（进 npm test） |
| 历史 workflow_phase 值 | 不迁移（仅约定向前 kebab-case 语义名），避免无价值 churn |
