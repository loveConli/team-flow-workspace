# 架构 / API / DB 设计增强方案 · v0.13（测试门禁硬化：证据升级 + 门禁前移）

> 版本：v0.13 · 重大修订（增量式，承袭 v0.12）
> 目标插件版本：**v0.32.0**（实际发布 **v0.32.1**——0.32.0 因打包事故撤回，版本号不可复用，见 CHANGELOG）
> 修订依据：v0.12 全量内容**继续有效**；v0.13 仅记录本次增量修订。
> 触发来源：C1-domain-policy 事件（2026-08-01 v0.31.0 发布当天实战执行，零测试通过全部门禁；2026-08-03 四方证据验证：设计 × 代码 × SOP × 现场）
> 决策确认：LT 2026-08-03 四项决策 ✅（C1 回退补测 / tests-passing 一步到位程序化 / 豁免键 schema 版本标记 / 门禁前移）
>
> **v0.13 修订摘要（相较 v0.12）**：
> - **§47 事件诊断**：v0.31.0 测试门禁三重绕过（豁免键错位 + 声明驱动绕过 + 门禁锚定自述），定性为**设计层缺陷**而非执行层失误；宣布修正 BUG-A 既有政策方向。
> - **§48 豁免键修正**（修订 §45.1/§45.3）：新增 `schema_version` 状态标记；"存量兼容"豁免的键由 **contract 内容**改为 **state 初始化版本**；删除内容型豁免与 hash 空值短路。
> - **§49 门禁前移**（修订 §45.2）：full workflow `approved-for-build→executing` 新增 `test-matrix-ready` 维度——测试准备度在开工前强制，不等 closing 才发现。
> - **§50 tests-passing 证据程序化**（修正 BUG-A）：新增 `tf test record` 命令程序化解析测试 runner 输出写入 `test_result`；guard 只认程序化记录；废除 `dp_6_result` 作为等价证据；total=0 拒绝（关闭空真）。
> - **§51 review 与 hash 链硬化**：`tf execution review` 禁止 base==head（空 diff review 非法）+ receipt 持久化测试统计；修复矩阵 hash 捕获断链（生成后必须 `tf state rebuild`）。
> - **§52 SOP 硬化批次**：contract-builder 补 test-strategy 预加载 + 矩阵生成 MUST + 双向校验；release-archivist 零测试 FAIL 条款；workflow-start 路由归位；doctor 巡检扩展。
> - **§53 实战补救参考**：C1-domain-policy 回退补测操作规程。
> - **§56 C1 workflow-feedback 根因修复**（v0.35.0）：worktree 生命周期管理（tf deisolate）、receipt 保留（revise 不删 reviews/）、refresh-hash 命令、BLOCKED 证据链、上下文水位例外条款。

---

## 四十七、事件诊断：测试门禁的三重绕过（v0.32.0）

### 47.1 事件时间线

| 时间（+0800） | 事件 |
|---|---|
| 2026-08-01 07:48 | v0.31.0「测试矩阵驱动开发」发布（commit `3641c3b`），CHANGELOG 声称全链路实现：contract-builder 生成 test-matrix.md、build-executor 按矩阵 TDD、code-reviewer Step 5b、release-archivist Step 2b、guard `test-matrix-complete`、glaf4-tests 路由 |
| 2026-08-01 15:00–16:51 | C1-domain-policy 在 vrm4teamflow 项目执行完整 workflow（full / SDD 模式）：架构设计（required + PASS_WITH_WARNINGS）→ 规划（10 产物）→ 契约（11 IN / 8 OUT）→ 执行（45 个代码文件，6 Waves）→ 归档 |
| 结果 | **0 个测试文件**通过 executing→closing 全部 7 维 guard；`test_matrix_hash: null`、`test_matrix_skipped: null` 两者皆空却放行 |

### 47.2 四方证据验证结论（设计 × 代码 × SOP × 现场）

| 层 | 合规性 | 结论 |
|---|---|---|
| 代码（v0.31.0 实现） | ✅ 忠实实现 v0.12 | guard 判定逻辑与 §45.1 伪代码逐行对应（连 reason 字符串都一致）；实现仅多加一条"无 contract → PASS"豁免。**问题不在实现走样** |
| 设计（v0.12 条款） | ❌ 三处结构性缺陷 | 见 47.3 RC-1/2/3 —— **主根因** |
| SOP（SKILL.md） | ❌ 纪律全在 prompt 层 | 见 47.4 RC-4 —— 次根因 |
| 执行（C1 会话） | ❌ 未按 SOP + 自述 | 见 47.5 RC-5 —— 放大因素，**不是主根因** |

### 47.3 主根因（设计层）

**RC-1 豁免键错位**（修订对象：§45.1/§45.3）：
"存量兼容"豁免的键是 **contract 内容**（是否含 `## Test Matrix` 段），不是 **change 的创建版本**。内容键无法区分"真存量"与"新版 contract-builder 漏生成矩阵"——渐进式启用条款变成所有新 change 的通用逃生门。C1 是 v0.31.0 发布当天的新 change，精准命中此条放行。

**RC-2 门禁锚错证据**（修订对象：BUG-A 政策）：
`tests-passing` 锚定自述字符串（`test_result`/`dp_6_result` 任一以 `pass` 开头），不锚定客观证据。源头是 BUG-A 判例（`docs/plans/2026-07-07-fix-batch-design.md`）：历史上 `tests-passing` 因无人写 `test_result` 导致所有 change 收不了口，当时选择了**降低门的证据等级**（接受 LLM 自述 `dp_6_result`），而非建立证据产生通道。注释自称"不依赖 AI 记忆"，实际锚定的恰是 AI 自述。

**RC-3 声明驱动型绕过**（修订对象：§45.2 门禁矩阵）：
v0.12 全部测试纪律（矩阵 TDD / code-reviewer Step 5b / release-archivist Step 2b / test-merge）以 test-matrix.md 存在为前提，但**无任何门禁强制 contract-builder 生成矩阵**：入口（approved-for-build→executing）四维无测试准备度；closing 的 `test-matrix-complete` 被"未声明即豁免"放行。不声明 → 不考核 → 整链空转。

### 47.4 次根因（SOP 层，RC-4）

1. TDD Iron Law、无矩阵回退规则（implementer-prompt "fall back to standard TDD"）全是 prompt 文本；唯一 PreToolUse hook 只做状态门禁，零代码强制；
2. release-archivist Step 1 "Zero failures = PASS"——0 个测试时"0 失败"**空真成立**；
3. `agents/contract-builder.md` 的 `skills:` 未预加载 test-strategy，但其 SKILL.md 引用 test-strategy §2/§4/§6 生成矩阵——预加载断点；
4. workflow-start routing-rules 的 "Route to glaf4-tests" 段触发主体实为 contract-builder（位置错位），且明文"可选增强，不是必经路径"。

### 47.5 放大因素（执行层，RC-5）

主代理调度未要求测试证据；Wave review 直接 `--verdict pass`（现场证据：6 份 468 字节同秒雷同模板，`base == head == 初始 commit`，即**对空 diff 做 review**）；release-archivist 未实际跑测试套件；DP-6 自述 `"pass: all waves implemented, spec-aligned, design-aligned"`。

**定性原则**：执行层失守是可预期、可复现的——guard 存在的意义就是不依赖 LLM 纪律。把主根因归于执行层等于假设"下次 LLM 会守纪律"。**门禁修对了，纪律差的 LLM 也造不出这个事故。**

### 47.6 附带发现（现场增量问题）

1. 执行计划漏 T3（documented 11 vs planned 10），T3 代码却在计划外写出——计划-执行漂移无门禁发现；
2. C1 全部代码在两个子仓库仅 staged 未 commit；父仓库只有 init + arch-merge——实现代码未进版本控制；
3. 状态引用不存在的产物：`arch_review_report: architecture/auto-review.md` 文件缺失（doctor 未巡检引用完整性）；
4. 状态时间戳异常：`dp_2_timestamp` 晚于 closing 时间（事后编造）；`batches_completed: 0`；
5. **hash 捕获断链**：`test_matrix_hash` 只在 `tf state init`/`rebuild` 计算，矩阵在 bridging（init 之后）才生成——即使合规生成矩阵，不手动 rebuild，hash 永远 null，§45.1 步骤 4 的一致性保护事实失效；
6. 执行报告（2026-08-03 LLM 重构）与现场比对有 10+ 处失真（虚构文件大小/行数/路径/时间戳）——LLM 重构报告必须经现场核对方可采信。

---

## 四十八、豁免键修正：state schema_version 标记（v0.32.0，修订 §45.1/§45.3）

> **LT 决策 ✅ 2026-08-03**：豁免键采用 state schema 版本标记（而非 change 创建时间戳——文件时间戳可被复制/恢复操作污染）。

### 48.1 新字段：schema_version

`state-loader.mjs` BUILTIN_DEFAULTS **不默认包含** `schema_version`（关键设计：字段缺失本身就是"存量"信号）：

```js
// cmd-state.mjs init 分支（仅 init 写入）
if (command === 'init') {
  state.schema_version = 1;   // v0.32.0 起新创建的 change 打戳
  ...
}
```

**打戳规则（防污染）**：
- ✅ 只有 `tf state init`（change 创建）写入 `schema_version`；
- ❌ `tf state rebuild` / `tf doctor` / `tf state set` **一律不得追加**——老 change 即使用新 CLI rebuild 也保持"无字段 = 存量"语义；
- ❌ `schema_version` 不进 SETTABLE_FIELDS（禁止手工设置，防止伪造豁免或伪造受考核身份）。

### 48.2 新字段：test_matrix_skip_reason

显式 skip 必须留痕（配套 §45.4）：

```js
// state-loader.mjs BUILTIN_DEFAULTS 新增
test_matrix_skip_reason: null,   // 显式跳过矩阵的理由（与 test_matrix_skipped=true 配对必填）
// cmd-state.mjs SETTABLE_FIELDS 新增 'test_matrix_skip_reason'
```

### 48.3 修订后的 test-matrix-complete 判定逻辑（替换 §45.1 伪代码）

```text
1. legacy：state 无 schema_version 字段
     → PASS（reason: 'legacy change — initialized before v0.32.0'）
     （保留 §45.1 原步骤 1/2 行为，只针对真存量）
2. 显式跳过：test_matrix_skipped === 'true' AND test_matrix_skip_reason 非空
     → PASS（reason: 附理由）
     （skip=true 但理由为空 → FAIL：'test_matrix_skip_reason required'）
3. 非存量 change 的 contract 必须声明矩阵：
     execution-contract.md 不含 '## Test Matrix' 段
     → FAIL：'non-legacy contract must declare ## Test Matrix —
       回到 bridging 由 contract-builder 补生成，或显式 skip 并说明理由'
     （★ 删除 §45.1 步骤 1 的内容型豁免；删除"无 contract → PASS"）
4. test-matrix.md 不存在或为空 → FAIL（保留 §45.1 步骤 3）
5. stored hash 为 null → FAIL：'test_matrix_hash not recorded —
     矩阵生成后必须运行 tf state rebuild'
     （★ 删除 state.test_matrix_hash && 的空值短路，修复 47.6-5 断链）
6. hash 不一致 → FAIL（保留 §45.1 步骤 4）
7. 全部通过 → PASS
```

### 48.4 §45.3 豁免策略表（修订版）

| workflow | test-matrix-complete | 豁免判据 |
|---|---|---|
| full | ✅ 考核 | 仅两种豁免：① legacy（无 schema_version）② 显式 skip（附理由） |
| hotfix | ❌ 豁免 | 维持 §45.3（紧急修复，不挂维度） |
| tweak | ❌ 豁免 | 维持 §45.3（微调变更，不挂维度） |

---

## 四十九、门禁前移：test-matrix-ready 维度（v0.32.0，修订 §45.2）

> **LT 决策 ✅ 2026-08-03**：approved-for-build→executing 新增测试准备度门禁（门禁前移）。C1 教训：缺陷在 closing 才暴露时，45 个文件已写完，补救成本最大。

### 49.1 guard 矩阵更新

```js
// guard.mjs TRANSITION_CHECKS（full）
'approved-for-build:executing': [
  'artifacts-exist', 'contract-fresh', 'dp-gate-passed',
  'execution-plan-ready',
  'test-matrix-ready',   // ← 新增
],
// hotfix / tweak 不挂（沿用 §45.3 豁免体系：紧急/微调不要求矩阵）
```

### 49.2 test-matrix-ready 判定逻辑（scripts/guard/checks/test-matrix-ready.mjs）

```text
1. legacy（无 schema_version）→ PASS
2. hotfix/tweak workflow → PASS（防御性；矩阵本不挂这两个 workflow）
3. test_matrix_skipped === 'true' AND skip_reason 非空 → PASS
4. test-matrix.md 存在且非空 AND contract 含 '## Test Matrix' 段 → PASS
5. 否则 → FAIL：'进入 executing 前必须完成测试矩阵：
     ① 回到 bridging 让 contract-builder 生成 test-matrix.md，或
     ② tf state set <dir> test_matrix_skipped true + test_matrix_skip_reason "<理由>"'
```

**与 test-matrix-complete 的分工**：`test-matrix-ready`（入口）保证"带着矩阵开工"；`test-matrix-complete`（出口）保证"矩阵没被偷改 + skip 留痕"。两者共用 legacy/skip 豁免语义，判定函数抽共享模块避免漂移。

---

## 五十、tests-passing 证据程序化：tf test record（v0.32.0，修正 BUG-A）

> **LT 决策 ✅ 2026-08-03**：一步到位程序化——guard 只认程序写入的结构化记录，彻底摆脱自述。跨项目 runner 适配工作量接受；非标 runner 的合法出路是显式 skip（可审计），不是手工自述。

### 50.1 新 CLI 命令：tf test record

```text
用法：
  tf test record <change-dir> --from <report-file> [--runner auto|maven-surefire|jest|pytest]
  tf test record <change-dir> --stdin [--runner ...]

行为：
  1. 解析 runner 输出（--runner auto 按内容特征识别）：
     - maven-surefire：匹配 "Tests run: N, Failures: F, Errors: E, Skipped: S"
       （surefire txt 汇总行，多模块取合计；亦支持 surefire XML 报告目录 --from <dir>）
     - jest：--json 输出（numTotalTests / numPassedTests / numFailedTests）
     - pytest：terminal summary（"N passed, F failed, S skipped"）
  2. 计算 verdict：failed + errors == 0 AND total > 0 → pass，否则 fail
  3. 写入状态（程序独占，不经过 SETTABLE_FIELDS 手工通道）：
     test_result: "pass: total=42 passed=42 failed=0 skipped=0 runner=maven-surefire recorded-by=tf-test-record ts=2026-08-03T10:00:00Z"
     （fail 时前缀 "fail:"，guard 自然拒绝）
  4. 原始证据摘录落盘：.superpowers/test-evidence/<ts>.txt
     （追加字段 test_evidence_path 指向该文件，doctor 巡检存在性）
  5. 解析失败 → 明确报错并列出支持的 runner；不提供 --manual 自述通道（见 50.4）
```

**扩展性**：runner 解析器独立模块 `scripts/lib/test-record-parsers/`（每 runner 一个文件 + 注册表），新增 runner 不动主流程。

### 50.2 修订后的 tests-passing 判定逻辑（替换 tests-passing.mjs）

```text
1. legacy（无 schema_version）→ 保留既有行为（test_result/dp_6_result 任一 pass 前缀）
     （向后兼容真存量，BUG-A 通道仅对存量开放）
2. test_matrix_skipped === 'true' AND skip_reason 非空 → PASS（显式决策，可审计）
3. test_result 匹配结构化格式：
     ^pass: .*total=(\d+) .*failed=(\d+) .*recorded-by=tf-test-record
   AND failed == 0 AND total > 0 → PASS
4. 其余一切情形 → FAIL，引导信息：
     '请运行项目测试套件并用 tf test record 记录结果；
      确无自动化测试的 change 必须显式 test_matrix_skipped=true 并说明理由'
```

**三项废除/关闭**：
- ❌ 废除 `dp_6_result` 作为 tests-passing 等价证据（BUG-A 政策修正；dp_6 仍是决策点记录，但不再是门禁信号）；
- ❌ 关闭空真：`total=0` 一律 FAIL（除非 skip/legacy）；
- ❌ 废除手工 `tf state set test_result`：`test_result` 从 SETTABLE_FIELDS 移除（仅 `tf test record` 与 legacy 兼容读）。

### 50.3 release-archivist 流程对接（修订 SKILL.md Step 1）

```text
Step 1（修订）：
  1. 运行项目全量测试套件（mvn test / npm test / ...）
  2. tf test record <dir> --from <输出文件>   ← 程序化写入 test_result
  3. 零测试文件（find 无测试）→ 不得写 pass：
     要么补测试，要么显式 skip（test_matrix_skipped=true + 理由）并经 DP-6 记录
     （★ "Zero failures = PASS" 修订为 "Zero failures AND total > 0 = PASS"）
```

### 50.4 设计决策记录

| 决策点 | 决策 | 理由 |
|---|---|---|
| 非标 runner 出路 | 显式 skip（附理由），不提供手工自述 | 手工通道 = RC-2 复发；skip 可审计、可巡检、可追责 |
| 存量兼容 | 无 schema_version 的 change 完全保留旧行为 | 渐进式启用，不阻断进行中的存量 change（真正的渐进，键正确） |
| dp_6_result 去证据化 | dp_6 保留为决策记录，退出门禁 | 决策点是人审裁决，不是客观证据；两者解耦 |

---

## 五十一、review 与 hash 链硬化（v0.32.0）

### 51.1 execution review：禁止空 diff

`execution-plan.mjs` validateReviewRange 增加：

```js
if (base === head) throw new Error(
  'review range is empty (base === head) — head must contain new commits over base; ' +
  '先把本 wave 的实现 commit 再 review');
```

（C1 现场：6 个 receipt 全部 base==head==初始 commit，review 对空 diff 进行。此修订同时强制"每 wave 落 commit"的纪律。）

### 51.2 receipt 持久化测试统计（证据记录，不硬阻断）

```text
tf execution review <dir> --wave W1 --base <sha> --head <sha> --report <path> --verdict pass \
  [--tests-total N --tests-passed N --tests-failed N]
```

- receipt 新增可选字段 `tests: {total, passed, failed}`；
- `execution-reviews-passed` guard **不因单 wave total=0 而 FAIL**（避免 BUG-A 式过严死锁——DDL/纯前端脚手架类 wave 可能合理无测试）；统计只作证据沉淀，硬门禁在入口（§49）与 closing（§50）；
- release-archivist Step 2b 与 DP-6 报告消费这些统计。

### 51.3 矩阵 hash 捕获接线（修复 47.6-5 断链）

- contract-builder SOP（§52 B1）：生成 test-matrix.md 后**必须** `tf state rebuild`（rebuild 重算 test_matrix_hash；**不追加 schema_version**，见 48.1）；
- `tf validate` 增加警告：test-matrix.md 存在但 stored hash 为 null 或不一致 → 提示 rebuild；
- guard 侧的兜底已在 §48.3 步骤 5（hash=null → FAIL 并引导 rebuild）。

---

## 五十二、SOP 硬化批次（v0.32.0）

### B1 contract-builder（矩阵生成强制化）

1. `agents/contract-builder.md` frontmatter `skills: [contract-builder, test-strategy]`（修复 47.4-3 预加载断点）；
2. SKILL.md "Test Matrix Generation" 由建议级升 **MUST**（full workflow）；生成后运行 `tf state rebuild`；
3. `tf validate` 双向互锁：full 模式 contract 含 `## Test Matrix` 段 ↔ test-matrix.md 存在非空，任一缺失 → FAIL。

### B2 release-archivist（零测试条款 + 程序化记录）

1. Step 1 修订如 §50.3（0 测试 ≠ PASS；test_result 只经 tf test record 写入）；
2. Step 2b 修订：test-matrix.md 不存在时，legacy → SKIP（保留），**非 legacy → FAIL**（删除静默 SKIP）；
3. closing 顺序中 test-merge 前置条件同步（无矩阵且非 legacy 不得 closing）。

### B3 workflow-start（路由归位 + 必产声明）

1. routing-rules.md "Route to glaf4-tests" 段：明确触发主体是 **bridging 阶段的 contract-builder**（或迁移至 contract-builder references，workflow-start 只留一行指针）；
2. Route to build-executor 段补充：full 模式进入 executing 前 guard 含 `test-matrix-ready`，FAIL 时的两条出路（回 bridging 补矩阵 / 显式 skip）；
3. "返回即验证"门（build-executor）：SDD/full 模式子代理返回的 diff 中无任何测试文件 → BLOCK，SendMessage 回原子代理要求按矩阵/TDD 补齐。

### B4 doctor 巡检扩展

1. 产物引用完整性：`arch_review_report`、receipt `report` 路径、`test_evidence_path` 指向的文件必须存在（C1 现场：引用了不存在的 auto-review.md）；
2. `test_matrix_skipped=true` 必须有 `test_matrix_skip_reason`；
3. DP 时间戳顺序 sanity（dp_N_timestamp 不得晚于 last_transition 之后补写的异常模式，警告级）。

### B5 报告生成纪律（47.6-6 教训）

LLM 重构的执行报告（JSONL 分析产物）**必须经现场核对**（文件存在性、大小、状态字段）后方可作为证据引用；报告模板增加"未现场核对项"标注区。落点：team-flow-e2e-test skill 与 session-handoff 报告约定（文档级，不做代码门禁）。

---

## 五十三、实战补救参考：C1-domain-policy（vrm4teamflow 工作区执行）

> **LT 决策 ✅ 2026-08-03**：C1 走"回退状态补测试"路径。

**C-1（立即，防丢失）**：bff-btit-vrm / ui-btit-vrm 两个子仓库 staged 代码全部 commit。

**C-2（状态回退）**：
```bash
tf state set <C1-dir> state executing          # 补救性回退（closing→executing 非正常转换，记录理由）
tf state set <C1-dir> test_result ""           # 清除自述证据
tf state set <C1-dir> dp_6_result ""           # 清除自述 DP-6
tf state set <C1-dir> dp_7_result ""           # 归档确认作废，重做
# spec_merged 保留 true（specs 已真实同步，重跑 closing 时 spec-merge 幂等）
```
在 decision-point-audit.md 补记回退理由与授权（LT 2026-08-03）。

**C-3（glaf4-tests 流水线补测）**：vrm4teamflow 是 GLAF4 Java 项目，按 glaf4 规范执行：
```text
glaf4-tests-inspect（项目体检）
  → glaf4-tests-design（DomainPolicy 模块测试矩阵：DomainService/FieldConfig/AppService/
     ImportService/ExportBo/Repository，equivalence+boundary+error 基础级必选 + 对抗三招）
  → tf test-matrix-export <glaf4 matrix.json> <C1-dir>/test-matrix.md
  → tf state rebuild（捕获 test_matrix_hash）
  → glaf4-tests-write-unit / write-integration（按矩阵 TDD 补测）
  → mvn test（全绿）
  → tf test record <C1-dir> --from <surefire 输出>   ← 若 v0.32 未发布则先按 v0.31 格式记录，发布后重录
```

**C-4（重做 review 与 closing）**：以真实 commit 区间重做 6 个 Wave review（base≠head + 测试统计）→ release-archivist 重跑五步验证 → DP-6（附真实测试输出）→ guard check executing→closing → DP-7。

**C-5（状态失真修复）**：auto-review.md 补齐（或清空 arch_review_report 引用并说明）；dp_6_timestamp 补真实值；T3 计划漂移在 tasks.md 补记。

**时序建议**：C-1 立即执行（独立于插件版本）；C-2~C-5 建议在 v0.32.0 落地后执行——用新门禁验证补救过程本身（v0.32 的首个实战回归），同时避免在旧门禁上再走一遍自述通道。

---

## 五十四、skills 注入静默失效：frontmatter YAML 合法性事件（v0.33.0）

> **LT 决策 ✅ 2026-08-03**：description 精简单句 + 删除 `<example>` 块；不 patch 本地缓存，只走正式发布后验证。

### 54.1 事件

C1 补救流程（vrm4teamflow 工作区，2026-08-03）发现：dispatch `team-flow:spec-writer` 时子代理上下文 `skill_content` 附件为 0——SKILL.md 全文未注入，子代理产出缺失 delta headers / Scenario 块的首版产物。本机复现（Claude Code 2.1.220 + plugin 0.32.2）确认现象不依赖工作区与插件版本。

### 54.2 证据链（四轮实证 + 对照组）

| # | 实证 | 结果 |
|---|------|------|
| 1 | 诊断探针 dispatch spec-writer，子代理上下文自查 | 无 SKILL.md 内容；skills 清单仅一行描述 |
| 2 | 二轮探针 | 手工 Skill 工具调用可加载（自加载通道存在）；预加载为 0 |
| 3 | 行为探针（问规则语义而非字符串匹配） | agent .md 正文**有**注入（逐字背出 FINAL VERDICT / Artifact Ownership）；tools 限制**未**生效（子代理实际持有 117 工具含全部 MCP） |
| 4 | PyYAML 严格解析 15 个 agent frontmatter | 15/15 全部非法（"while scanning a simple key"） |
| 对照 | glaf4-test assess-worker（合法 YAML frontmatter，同机同会话） | SKILL.md 全文注入 ✅ |
| 佐证 | 官方文档 [sub-agents](https://code.claude.com/docs/en/sub-agents) | "Preloaded skills: full content of any skill named in the agent's skills field" |

### 54.3 根因

全部 team-flow agent .md 的 frontmatter 是**非法 YAML**：`description: >-` 块标量内部顶格书写 `<example>`，缩进断裂导致文档非法。Claude Code 对非法 frontmatter 采取**静默降级**：正文按 `---` 边界切分保留，元数据整体丢弃——

- `skills:` 预加载被静默丢弃（无任何警告）
- `tools:` 限制失效 → 回退全量工具
- description 回退泛化标签（registry 显示 "Agent from team-flow plugin"）
- name 取自文件名

该机制非 Claude Code bug：官方文档与二进制字符串均确认 `skills:` 是受支持字段，合法 frontmatter 的 glaf4 对照组注入正常。属产物侧缺陷——Anthropic 官方 plugin-dev 插件同样写法同样中招（registry 显示泛化标签），说明官方示例本身诱导了该写法。

**横展扫描**：`e2e` / `test-strategy` 两个 SKILL.md 的 description 含裸 `: `，同为非法 YAML；templates/ 与多 IDE 目录无中招副本。

### 54.4 影响面

- 9 个声明 `skills:` 的 agent 自诞生起从未获得 SKILL.md 方法论（"写法 2 预加载"全程空转，CLAUDE.md 的确定性断言从未被实证）；v0.32.1 的 contract-builder test-strategy 预加载修复同样未生效
- tools 限制未生效：子代理握有全量 MCP 工具（修复后收紧为声明集，属行为变更）
- C1 的 spec 首版格式缺陷、历史上子代理产出偏离方法论，部分根源于此

### 54.5 修复（v0.33.0）

1. **15 个 agent description 单句化**：删除 `<example>` 块，学 glaf4 写法（LT 决策）；`skills:` 保持裸名（与 glaf4 实证成功写法一致）
2. **2 个 SKILL.md frontmatter 修复**：description 加引号消解裸冒号（e2e / test-strategy）
3. **长效门禁**：`tests/lib/frontmatter-lint.test.mjs`（js-yaml 严格解析全部 agents/skills/commands frontmatter + 必填字段断言 + `skills:` 引用必须解析到真实 `skills/<name>/SKILL.md`），进 `npm test`（P3 门禁），杜绝复发
4. **验证方式**：不 patch 本地缓存；正式发布 + marketplace 更新后，在实际流程中验证注入生效（LT 决策）

### 54.6 教训

- **机制断言必须实证**："写法 2 确定性 100%" 写入 CLAUDE.md 时从未做过实证探针。今后任何"通道/机制有效"的断言，落笔同时必须附一次实证（dispatch → 行为探针）
- **静默降级是最危险的失效模式**：无警告、无报错、流程全绿，缺陷存活了整个插件生命周期。门禁要校验"产物有效性"，不能只校验"产物存在性"
- **LLM 内省探针有假阴性**：精确字符串匹配的内省不可靠（前两轮探针误判"正文未注入"），行为探针（问规则语义、要求复述独有规则）才是可靠方法

## 五十五、测试能力增强：conventions 机制 + glaf4-test 通用能力吸收（v0.34.0）

### 55.1 背景

team-flow 当前的测试能力（test-strategy、build-executor TDD 铁律、test-matrix 机制、guard 门禁）已形成完整闭环，但存在两个缺口：

1. **组合覆盖声明缺失**：glaf4-test 有 `combination_coverage` 机制（pairwise/branch），team-flow 无对应设计
2. **测试质量规则缺失**：glaf4-test 有 ~50 条生成后质量扫描规则，team-flow 无对应参考
3. **conventions 机制缺失**：Java 项目的测试规范（JUnit 5 + Mockito、Spring Boot 测试模式）没有标准化注入通道

### 55.2 设计决策

**核心原则**：TDD 纪律必须在 team-flow 的编排层（build-executor）自行保障，不能委托给 glaf4-test。

**理由**：glaf4-test 的 TDD 实现存在架构级差距：
- RED 是声明式的（声明 `expected_red`，不实际运行测试看到失败）
- REFACTOR 完全缺失
- 多 Worker 架构割裂 TDD 紧凑循环
- validate 不检查 TDD 执行顺序

**职责划分**：

| 能力 | 负责方 | 理由 |
|------|--------|------|
| TDD 执行（RED→GREEN→REFACTOR） | team-flow build-executor | 必须保持紧凑循环 |
| 测试设计（test-matrix 生成） | team-flow contract-builder | 通用方法论，已对齐 |
| 测试代码生成 | team-flow implementer 子代理 | 通过 conventions 注入技术栈规范 |
| 测试验证 | team-flow tf test record | 通用 runner 支持 |

### 55.3 能力吸收策略

**可吸收（通用能力）**：

| 优先级 | 能力 | 来源 | 收益 |
|--------|------|------|------|
| P0 | 组合覆盖声明 | glaf4-test combination_coverage | 填补覆盖盲区 |
| P1 | 测试质量规则（16 条通用） | glaf4-test scan-generated-tests.py | 提升审查质量 |
| P1 | failure 分类法（6 类） | glaf4-test analyze-surefire-failures.py | 结构化诊断 |
| P2 | 社交测试契约 | glaf4-test social-test-contracts.md | 集成测试方法论 |
| P2 | 测试隔离分级 | glaf4-test h2-rabbitmq-redis.md | 隔离策略分层 |

**不可吸收（Java 专用）**：
- test_kind 12 枚举 → 通过 test-matrix-export.mjs 桥接
- MockMvc/H2/Redis/RabbitMQ 测试模式 → 通过 conventions 注入
- Spring 合同检查 → 通过 glaf4-test 外部管线路由
- GLAF4 框架契约 → 通过 glaf4-test 外部管线路由

### 55.4 conventions 机制设计

**核心原则**：
1. plugin 内置默认 conventions（符合 glaf4-test 要求）
2. 版本化管理（conventions 带版本号，支持更新检查）
3. 分层设计（默认层 + 项目层）
4. 更新通知（team-flow 更新时检查 conventions 版本）

**目录结构**：
```
team-flow/
├── templates/conventions/                    # plugin 内置模板
│   ├── _manifest.json                        # 模板清单
│   ├── glaf4-compliant/
│   │   ├── java-testing.md                   # Java 测试规范（glaf4-test 兼容）
│   │   └── spring-patterns.md                # Spring Boot 测试规范（glaf4-test 兼容）
│   ├── js-testing.md                         # JavaScript 测试规范
│   └── python-testing.md                     # Python 测试规范

项目根目录/
├── .team-flow/
│   ├── conventions/                          # 项目 conventions（从 plugin 复制，可自定义）
│   │   ├── java-testing.md
│   │   ├── spring-patterns.md
│   │   └── .versions.json                    # 版本信息
│   └── team-flow.config.json                 # conventions 路径映射
```

**生成时机**：workflow-bootstrap B1.5 阶段（新增）
- 存量项目：自动识别技术栈，生成 conventions
- 全新项目：交互式引导用户选择技术栈，生成 conventions + 项目骨架

**更新机制**：
- workflow-start S1 阶段检查 conventions 版本
- 比较 plugin 内置版本与项目版本
- 提示用户更新（支持合并/覆盖/保持三种选项）

### 55.5 产出清单

**新增文件**：
- `templates/conventions/_manifest.json` — 模板清单
- `templates/conventions/glaf4-compliant/java-testing.md` — Java 测试规范（glaf4-test 兼容）
- `templates/conventions/glaf4-compliant/spring-patterns.md` — Spring Boot 测试规范（glaf4-test 兼容）
- `templates/conventions/js-testing.md` — JavaScript 测试规范
- `templates/conventions/python-testing.md` — Python 测试规范
- `scripts/lib/conventions-generator.mjs` — conventions 生成器脚本
- `tests/lib/conventions-generator.test.mjs` — 测试文件（15 个测试）
- `skills/test-strategy/references/test-quality-rules.md` — 16 条通用规则
- `skills/test-strategy/references/integration-test-contracts.md` — 5 种契约类型
- `skills/test-strategy/references/integration-test-isolation.md` — 4 级隔离策略

**修改文件**：
- `skills/test-strategy/SKILL.md` — 增加 §8 组合覆盖声明
- `scripts/lib/test-record.mjs` — 增加 classifyFailure 函数（6 类失败分类）
- `skills/workflow-bootstrap/SKILL.md` — 增加 B1.5 阶段（Conventions Generator）

### 55.6 与 glaf4-test 的关系

**集成点**：
- `test-matrix-export.mjs`：将 glaf4-test 的 test-matrix.json 转换为 team-flow 的 test-matrix.md
- conventions 注入：Java 项目的测试规范通过 conventions 注入到 implementer 子代理
- 外部管线路由：存量 Java 项目的测试补全可路由到 glaf4-test 的完整流水线

**不集成的部分**：
- TDD 执行：由 team-flow build-executor 保障
- test_kind 12 枚举：通过桥接脚本转换
- GLAF4 框架专用规范：不纳入 team-flow

### 55.7 验证

- **测试**：571/571 通过（含 15 个新增 conventions-generator 测试）
- **版本一致性**：check-versions ✅
- **npm 发布**：@xulthekl/team-flow@0.34.0 ✅

---

## 待办列表（v0.32.0+ 新增）

| 编号 | 待办 | 状态 | 版本 | 来源 |
|------|------|------|------|------|
| P1-39 | state schema_version：init 打戳 + rebuild/doctor/set 禁追加 + 不进 SETTABLE_FIELDS | ✅ v0.32.1（2026-08-03） | v0.32.0 | §48.1 |
| P1-40 | test-matrix-complete 重构：legacy/skip 双豁免 + 内容型豁免删除 + hash null 短路删除 + skip_reason 必填 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §48.2-48.4 |
| P1-41 | test-matrix-ready 新增：approved-for-build→executing（full）+ 共享豁免判定模块 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §49 |
| P1-42 | tf test record 命令 + test-record-parsers（maven-surefire/jest/pytest）+ test_evidence_path | ✅ v0.32.1（2026-08-03） | v0.32.0 | §50.1 |
| P1-43 | tests-passing 重构：结构化格式解析 + dp_6_result 去证据化 + total=0 拒绝 + test_result 移出 SETTABLE_FIELDS | ✅ v0.32.1（2026-08-03） | v0.32.0 | §50.2 |
| P2-34 | execution review 硬化：base≠head + receipt tests 统计字段 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §51.1-51.2 |
| P2-35 | hash 接线：contract-builder SOP rebuild 步骤 + tf validate 矩阵 hash 警告 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §51.3 |
| P2-36 | contract-builder：agent 补 test-strategy 预加载 + 矩阵 MUST + validate 双向互锁 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §52 B1 |
| P2-37 | release-archivist：零测试条款 + tf test record 对接 + Step 2b 非 legacy FAIL | ✅ v0.32.1（2026-08-03） | v0.32.0 | §52 B2 |
| P2-38 | workflow-start：glaf4-tests 路由归位 + test-matrix-ready 引导 + build-executor 返回验证补测试文件检查 | ✅ v0.32.1（2026-08-03） | v0.32.0 | §52 B3 |
| P2-39 | doctor 巡检扩展：产物引用完整性 + skip_reason 配对 + DP 时间戳 sanity | ✅ v0.32.1（2026-08-03） | v0.32.0 | §52 B4 |
| P3-9 | 报告生成纪律：LLM 重构报告现场核对标注区（文档级） | ✅ v0.32.1（2026-08-03） | v0.32.0 | §52 B5 |
| P3-10 | exploring→specifying 门禁时序优化（artifacts-exist 移出该转换，消除鸡生蛋死锁） | ✅ v0.32.2（2026-08-03） | v0.32.0+ | C1 报告 §8.3 |
| P1-44 | pre-tool-use-guard 产物区豁免（change 目录产物写入放行 + macOS /private 路径归一化） | ✅ v0.32.2（2026-08-03） | v0.32.0+ | C1 死锁链环 1 |
| P2-40 | cmd-version hooks 版本同步修复（pattern 后缀通配防腐化 + 双位置同步 + major 硬编码修复） | ✅ v0.32.2（2026-08-03） | v0.32.0+ | npm version 链中断 |
| P1-45 | §54 frontmatter YAML 合法性事件设计写回 | ✅ v0.33.0（2026-08-03） | v0.33.0 | §54 |
| P2-41 | 15 agent description 单句化（删 `<example>`）+ e2e/test-strategy SKILL.md frontmatter 修复，恢复 skills: 注入 | ✅ v0.33.0（2026-08-03） | v0.33.0 | §54.5 |
| P3-12 | frontmatter-lint 长效门禁（js-yaml 严格解析 + 必填字段 + skills 引用解析，进 npm test） | ✅ v0.33.0（2026-08-03） | v0.33.0 | §54.5 |
| P0-10 | 组合覆盖声明（test-strategy §8：pairwise/branch 声明 + 对账规则） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.3 |
| P1-46 | 测试质量规则（16 条通用规则，从 glaf4-test 抽取） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.3 |
| P1-47 | failure 分类法（classifyFailure：6 类失败分类） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.3 |
| P2-42 | 社交测试契约（5 种契约类型：入口/协作者/数据/中间件/清理） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.3 |
| P2-43 | 测试隔离分级（4 级隔离策略：L1 进程内/L2 事务/L3 手动清理/L4 无隔离） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.3 |
| P2-44 | conventions 机制（plugin 内置模板 + conventions-generator + 版本管理 + 更新检查） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.4 |
| P2-45 | workflow-bootstrap B1.5 阶段（Conventions Generator：存量项目自动识别 + 全新项目交互式引导） | ✅ v0.34.0（2026-08-04） | v0.34.0 | §55.4 |

## 兼容性与风险

| 风险 | 缓解 |
|---|---|
| BUG-A 式死锁复发（门禁过严收不了口） | 每条硬门禁都有显式 skip 出路（附理由、可巡检）；错误信息给出下一步操作；存量 change（无 schema_version）完全保留旧行为 |
| 进行中的 change 升级后被卡 | 豁免键 = init 打戳：升级前创建的 change 无 schema_version → 一律按 legacy 放行；升级后新建的 change 才受考核（真正的渐进式启用） |
| 非标 runner 项目 | 解析器注册表可扩展；当下合法出路 = 显式 skip + 理由（可审计），不提供手工自述（防 RC-2 复发） |
| hotfix 紧急通道被门禁拖慢 | test-matrix-ready/test-matrix-complete 均不挂 hotfix/tweak（沿用 §45.3） |
| v0.33.0 行为变更：frontmatter 修复后 tools 限制开始生效，子代理失去未声明的 MCP 工具 | 属恢复声明设计；若某 agent 确需 MCP 工具，须在其 frontmatter `tools:` 显式声明（lint 门禁保障 frontmatter 始终可解析） |
| conventions 更新冲突：用户自定义 conventions 后 plugin 更新 | 提供合并/覆盖/保持三种选项；.versions.json 记录 customized 状态 |
| 全新项目引导过于复杂 | 提供合理默认值（Java → Maven → JUnit 5 + Mockito → Spring Boot），减少交互步骤 |
| glaf4-test 规范变更导致 conventions 过时 | 版本化管理 + 自动更新检查；workflow-start S1 阶段提示用户 |
| Java 专用规则污染通用框架 | 通过 conventions 注入，不硬编码进 test-strategy；glaf4-compliant 模板独立存放 |

---

## 五十六、C1 workflow-feedback 根因修复（v0.35.0）

> 来源：vrm4teamflow `.team-flow/feedback/20260805-*`（6 条 feedback，3P1 + 3P2）
> 交叉验证：4 个独立专家验证，16/16 断言通过 + 3 处修正
> 目标插件版本：**v0.35.0**

### 56.1 问题全景

| 聚类 | Feedback | 严重度 | 根因 |
|------|----------|--------|------|
| A. worktree 生命周期断裂 | P1-1 | P1 | `tf isolate` 只创建不清理，closing 流程无 deisolate/merge-back |
| B. receipt 被 revise 误杀 | P1-2 + P2-2 | P1 | `writePlan` 在 revision/hash 变化时 `rmSync(reviews/)`，无 keep-receipts |
| C. BLOCKED 归因无证据链 | P1-3 + P1-4 | P1 | build-executor BLOCKED 报告自由文本 + 上下文腐化 |
| D. test-merge 自调用 bug | P2-1 | P2 | `test-merge.mjs:537` main() 无参自调用崩溃 |

### 56.2 修复方案

**D1 test-merge bug**：`test-merge.mjs:537` → `run()` + `import.meta.url` 守卫（参考 conventions-generator.mjs）。

**B1 revise 保留 reviews/**：`execution-plan.mjs:55-58` 的 `rmSync(paths.reviews, ...)` 改为仅删除 recommendation receipt。`readCurrentReview` 已有 plan_hash/plan_revision 校验（+ report 存活再校验），旧 receipt 自动失效但不丢证据。

**B2 refresh-hash 命令**：新增 `tf execution refresh-hash`——只更新 plan 的 artifacts_hash/contract_hash，不升 revision、不清 receipts。`execution-plan.mjs` 导出 `refreshPlanHash()`。

**B3 stale 报错增强**：`validatePlan` 报错信息附 hash 前缀（plan: xxx…, current: yyy…）。

**A1 deisolate 命令**：新建 `cmd-deisolate.mjs`，支持 dry-run/merge/clean，识别 Case A（多仓库工作区 .worktrees/）和 Case B（单仓库 ../<repo>-<name>）。

**A2 closing deisolate**：`release-archivist/SKILL.md` Post-Verification 增加 Worktree Deisolation advisory 步骤。

**C1 BLOCKED 证据链**：`build-executor.md` Structured Output Contract 增加 `blocker.category/root_cause/evidence/attempted_fixes` 结构化格式。BLOCKED 无证据 = FAIL。

**C2 上下文水位**：§37 原子代理协议增加例外——transcript >2MB 或 token >200 万时允许启动新代理替代恢复（需完整交接文档）。

**C3 glaf4-test 优先**：build-executor Red Lines 增加环境问题处理指引——禁止 guess-and-check，优先走 test-strategy skill。

### 56.3 交叉验证修正

| 原分析不准确 | 修正 |
|-------------|------|
| 因果链："design.md 变化 → receipt 被删"（暗示自动） | 修正：design.md 变化 → plan stale → review 拒绝 → 用户被迫 revise → revise 时 rmSync 才触发 |
| rmSync 触发条件描述为"revision 变化" | 修正：`revision !== OR hash !==`，plan.hash 覆盖整个 plan 对象（waves/recommendation 等），不仅是 artifacts |
| 修复方案：`pathToFileURL(process.argv[1]).href` | 修正：项目已有模式 `file://${process.argv[1]}`（conventions-generator.mjs:507） |

### 56.4 涉及文件

| 文件 | 操作 |
|------|------|
| `scripts/lib/test-merge.mjs` | Edit: 第 537-540 行 |
| `scripts/lib/execution-plan.mjs` | Edit: writePlan + validatePlan + refreshPlanHash 导出 |
| `scripts/lib/cmd-execution.mjs` | Edit: 新增 refresh-hash 子命令 |
| `scripts/lib/cmd-deisolate.mjs` | **New** |
| `scripts/team-flow.mjs` | Edit: 注册 deisolate + HELP |
| `skills/release-archivist/SKILL.md` | Edit: Post-Verification deisolate |
| `agents/build-executor.md` | Edit: BLOCKED 证据链 + glaf4-test 优先 |
| `skills/workflow-start/SKILL.md` | Edit: §37 水位例外 |
| `skills/workflow-start/references/routing-rules.md` | Edit: §37 水位例外 |
| `tests/lib/execution-plan.test.mjs` | Edit: stale 断言改 startsWith |
