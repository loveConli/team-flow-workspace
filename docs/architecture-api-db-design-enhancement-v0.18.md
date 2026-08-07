# 架构 / API / DB 设计增强方案 · v0.18（执行/关闭阶段质量保障闭环补强）

> 版本：v0.18 · 重大修订（增量式，承袭 v0.17）
> 目标插件版本：**v0.43.1**
> 修订依据：workflow-feedback 2026-08-06（vrm4teamflow C2-policy-management 项目，20260806 批 9 条中 6 条缺口）+ LT 决策 2026-08-07
> 决策确认：LT 2026-08-07 决策 ✅
>
> **v0.18 修订摘要（相较 v0.17）**：
> - **§74 closing 代码落地闭环**：release-archivist 新增"代码落地检查"步骤 + `tf deisolate --merge` 增强（dirty/ahead 检查 + 冲突报告）+ worktree 合并规范文档化。
> - **§75 文件存在性双层防护**：build-executor 任务完成前验证（源头）+ code-reviewer 文件存在性审查维度（兜底）。
> - **§76 测试执行可信度**：build-executor wave VERIFY 检查实际执行数量（`tf test record`）+ 测试框架兼容性检查（surefire vs JUnit 5 @Nested）。
> - **§77 spec-writer 产物路径契约**：明确 `specs/<capability>/spec.md` 子目录结构。
>
> **v0.17 修订摘要（相较 v0.16，承袭保留）**：
> - **§72 workflow-start 编排模式修正**：从"一次性安排 + 被动等待"改为"主动串行编排"——workflow-start 在每个 wave 完成后主动 dispatch code-reviewer（v0.39.1 已实施）。
> - **§73 决策落实状态**：本次决策逐条记录。
>
> **v0.16 修订摘要（相较 v0.15，承袭保留）**：
> - **§70 test-merge 五 bug 修复** / **§71 E2E case 记录与复利闭环**（v0.38.0 已实施）。
>
> **v0.15 修订摘要（相较 v0.14，承袭保留）**：
> - **§68 阶段同步与原型版本隔离** / **§69 决策落实状态**（v0.37.0 已实施）。
>
> **v0.14 修订摘要（相较 v0.13，承袭保留）**：
> - **§57-§67** 产品级架构设计（v0.36.0 已实施）。

---

## 七十四、closing 代码落地闭环（v0.43.1）

### 74.1 问题描述

**触发来源**：workflow-feedback 2026-08-06（vrm4teamflow C2-policy-management 项目，20260806-180000-sop-flow + 20260806-180100-sop-flow）

**现象**：
1. C2 完成 executing 阶段后进入 closing，但 closing 仅做了产物归档（arch-merge / test-merge / specs-sync），**代码合并、E2E 验证、主分支编译验证三个步骤全部缺失**——bff 10 commits + ui 3 commits 留在 worktree feature 分支。
2. worktree 合并无标准化流程：主代理临时建议"先 rebase C1 再 rebase C2"，用户手动确认后执行；bff/ui 独立仓库需分别操作；C2 依赖 C1 代码（共享枚举）需按依赖链顺序合并；rebase 遇到 5+1 个冲突需手动解决。

**现状核查（v0.43.1 实施前）**：

| 能力 | 现状 | 证据 |
|------|------|------|
| `tf deisolate` | ✅ 已存在（v0.35.0），支持 `--merge`/`--clean`/`--json` | `scripts/lib/cmd-deisolate.mjs` |
| `tf deisolate --merge` 防护 | ❌ 无 dirty 检查（未提交改动会混入 merge）、无 ahead==0 短路、冲突直接 fail 无报告、不感知依赖链 | `mergeBranch()` L197-206 |
| release-archivist 代码落地 | ❌ Step 1-5b 仅验证产物，无合并/编译步骤 | `skills/release-archivist/SKILL.md` |
| worktree 合并规范 | ❌ 无文档 | — |
| E2E 验证 | ✅ Step 5b 条件触发（v0.38.0），AskUserQuestion 引导 `/e2e` | release-archivist Step 5b |

**根因分析**：

| 根因 | 类型 | 责任方 | 说明 |
|------|------|--------|------|
| closing 定义过窄 | 编排设计 | release-archivist | 只收产物（documents/architecture/test-ledger），不收代码（worktree → master） |
| 合并命令防护不足 | 命令健壮性 | cmd-deisolate.mjs | 无 dirty/ahead 检查、冲突无报告，无法作为标准化步骤被安全调用 |
| 合并规范缺失 | 文档 | — | 依赖链顺序、多仓库策略、冲突处理均无标准 |

### 74.2 改进方案

**P1-52：`tf deisolate --merge` 健壮性增强**

在 `scripts/lib/cmd-deisolate.mjs` 的 `mergeBranch()` 增加三层防护：

1. **合并前 dirty 检查**：worktree 有未提交改动（`git status --porcelain` 非空）→ 默认**阻断合并**并报告未提交文件清单，提示先 commit/stash；`--force` 跳过（供用户已确认场景）。
2. **合并前 ahead==0 短路**：branch 相对目标分支无新 commit → 跳过 merge，报告 `nothing to merge`（幂等，可安全重复调用）。
3. **冲突检测与报告**：`git merge` 失败 → 解析 `git status --porcelain` 的 unmerged 文件（`UU`/`AA`/`DD`）→ 输出冲突文件列表 + 引导"人工解决后 `git add` + `git commit` 完成 merge" → 返回非零 exit code（不静默失败）。目标分支明确：报告显示实际合并目标（`detectMasterBranch` 结果），合并到主仓库当前分支（release-archivist 调用前确保主仓库在 master/main）。

**P1-53：release-archivist 新增 Step 5c 代码落地检查**

在 Step 5b（E2E）之后、Final Checks 之前，新增 **Step 5c: Code Landing（v0.43.1）**：

1. **检测 worktree 状态**：`tf deisolate <change-dir>`（dry-run）→ 检测是否存在 worktree 且有未合并 commit（ahead > 0）。
2. **无 worktree 或无需合并**（hotfix/tweak 直改主分支）→ 跳过，报告 `code landing: N/A（未使用 worktree 隔离）`。
3. **有未合并 commit → AskUserQuestion 确认合并时机**：
   - **A 现在合并**：执行 `tf deisolate <change-dir> --merge`（多仓库逐 repo 合并）→ 合并后执行**主分支编译验证**（`mvn test` / `npm run build` / 项目类型对应命令，exit 0 且非空产物）→ 验证通过 → 记录 `code_merged: true`。
   - **B 暂不合并**：记录 reason（如依赖 change 未先合入），closing 继续（advisory 不阻断——合并时机可能受团队协作节奏约束）。
   - **C 无需合并**：记录 reason（无 worktree 隔离场景）。
4. **依赖链顺序提示**：若 change 依赖其他在途 change（读 change DAG / `change_dag`），提示"依赖 change 需先合入 master 再合并本 change"，避免共享代码（如枚举）被后合入者覆盖。

**P1-54：worktree 合并规范文档化**

新增 `skills/release-archivist/references/worktree-merge.md`，覆盖：
- **合并模式**：`git merge --no-edit`（merge commit），**不采用 rebase**——rebase 重写历史，多仓库 + 依赖链场景复杂度和风险高（冲突需逐 commit 解决、失败难回退）；merge commit 保留真实合并历史、冲突解决一次即可、可安全回退，强壮性优先（见 74.3 决策）。
- **多仓库策略**：bff/ui 独立仓库分别 `tf deisolate --merge`（Case A 布局自动识别）。
- **依赖链顺序**：按 change DAG 依赖序合并（C1 → C2 → C3），共享代码先合入者先落地。
- **冲突处理**：`git merge` 冲突 → 人工介入解决 → `git add` + `git commit` 完成 merge → 主分支编译验证。
- **合并后验证**：主分支编译验证（编译 + 测试），验证失败回退或修复。

### 74.3 设计决策

| 决策项 | 决策 | 理由 |
|------|------|------|
| 代码落地形态 | release-archivist 确认式步骤（AskUserQuestion），非 guard 硬门禁 | worktree 隔离是可选特性，hotfix/tweak 直改主分支无 worktree；合并时机受团队协作节奏约束，硬门禁会误伤 |
| 合并命令 | 增强现有 `tf deisolate --merge`，不新建命令 | 命令已存在（v0.35.0），能力补全（dirty/ahead/冲突报告）优于另起炉灶 |
| 合并模式 | `git merge`（merge commit），**不 rebase** | 强壮性优先：merge commit 保留真实历史、冲突解决一次、可安全回退；rebase 在多仓库+依赖链场景复杂度与风险不成比例 |
| 编译验证 | release-archivist 步骤内执行，非独立命令 | 编译命令因项目类型而异（mvn/npm），skill 层引导比 CLI 硬编码更适配 |
| E2E | 复用 Step 5b（已覆盖），不重复设计 | v0.38.0 已实现条件触发 E2E 引导 + 4 级判定 |

### 74.4 实现范围

| 改进项 | 修改文件 | 影响范围 |
|------|----------|----------|
| `tf deisolate --merge` 增强 | `scripts/lib/cmd-deisolate.mjs` | mergeBranch() 防护 + 冲突报告 + help 文本 |
| deisolate 测试 | `tests/lib/deisolate.test.mjs`（新增） | dirty/ahead/冲突三场景 |
| release-archivist Step 5c | `skills/release-archivist/SKILL.md` | 新增代码落地检查步骤 |
| 合并规范文档 | `skills/release-archivist/references/worktree-merge.md`（新增） | 文档化 |

### 74.5 验证方案

1. **命令级**：`tf deisolate` 测试覆盖 dirty 阻断 / ahead==0 短路 / 冲突报告三场景（fixture 构造）。
2. **skill 级**：无头测试验证 release-archivist Step 5c 在存在 worktree 时引导合并、无 worktree 时跳过。
3. **回归**：hotfix/tweak（无 worktree）路径不受影响；已有 deisolate dry-run/clean 行为不回归。

---

## 七十五、文件存在性双层防护（v0.43.1）

### 75.1 问题描述

**触发来源**：workflow-feedback 2026-08-06（20260806-180200-agent-quality + 20260806-180300-agent-quality）

**现象**：C2-policy-management 的 build-executor 将 Task 5.4（DeptPolicyImportController）标记 `[x]` 完成但**实际未创建该文件**；code-reviewer 对 W4 做了详细审查（发现 F-02/F-04/F-05）但**未检查文件存在性**；缺口直到 release-archivist closing 验证时才被发现。

**现状核查**：code-reviewer Step 1-6 审查维度（Spec Compliance / Code Quality / Architecture / Test Coverage / Test Matrix / Documentation）**无文件存在性校验**；build-executor SDD 模式任务标记完成无 `test -f` 校验（L177 的完整性检查仅限 inline 模式）。

**根因分析**：

| 根因 | 类型 | 责任方 | 说明 |
|------|------|--------|------|
| 任务状态与产物脱节 | agent 定义 | build-executor | 标记完成与代码创建是独立操作，无原子性保证；长会话上下文衰减 |
| 审查维度不全 | agent 定义 | code-reviewer | 审查 diff 内已有文件质量，未对 tasks.md 声明清单做存在性比对 |

### 75.2 改进方案

**P2-48：build-executor 任务完成前验证（源头）**

build-executor SDD 模式任务标记完成前增加验证（TDD 五步之 checkpoint 步骤内）：
1. **Create 任务**：目标文件必须存在且非空（`test -s <path>`）。
2. **Modify 任务**：目标文件必须有变更（相对 wave base 的 `git diff --name-only` 包含该文件）。
3. 验证失败 → 不标记完成，先补创建/修改；标记完成与文件存在性绑定，杜绝"标记完成但文件缺失"。

**P2-49：code-reviewer 文件存在性审查维度（兜底）**

code-reviewer Step 2（Spec Compliance）之前新增前置检查：
1. 读 `tasks.md` 当前 wave 范围的 `## File Structure`（Create/Modify 清单）。
2. **Create 文件必须存在且非空** → 缺失标 **Critical finding**（`missing-file`）。
3. **Modify 文件必须有 diff**（相对 wave base）→ 无变更标 **Critical finding**（`no-change`）。
4. 存在性校验是 spec-compliance 的前置——文件都不存在，谈不上合规。

### 75.3 设计决策

| 决策项 | 决策 | 理由 |
|------|------|------|
| 防护层级 | build-executor 源头 + code-reviewer 兜底双层 | 源头防标记失真（P2-48），兜底防审查盲区（P2-49），双层互锁 |
| 校验强度 | 缺失标 Critical（阻断 verdict） | 文件不存在是硬缺口，与 spec 违规同级，不允许 PASS |

### 75.4 实现范围

| 改进项 | 修改文件 | 影响范围 |
|------|----------|----------|
| 任务完成前验证 | `skills/build-executor/SKILL.md` | checkpoint 步骤增加文件存在性验证 |
| 文件存在性维度 | `skills/code-reviewer/SKILL.md`、`skills/code-reviewer/code-reviewer-prompt.md` | 新增前置检查 + 审查维度 |

### 75.5 验证方案

无头测试/实证探针：构造"声明 Create 但文件缺失"的 change，验证 build-executor 不标记完成、code-reviewer 报 Critical `missing-file`。

---

## 七十六、测试执行可信度（v0.43.1）

### 76.1 问题描述

**触发来源**：workflow-feedback 2026-08-06（20260806-180500-artifact-quality）

**现象**：C2 的 build-executor 使用 JUnit 5 `@Nested` 组织测试，但 maven-surefire-plugin 2.22.2 不支持 `@Nested` 自动发现——86 个非 E2E 用例仅 31 个（36%）实际执行，64% 从未运行。build-executor 报告 "91 tests pass" 但大部分测试从未执行，测试覆盖率虚高。

**现状核查**：build-executor wave VERIFY 步骤只看 BUILD SUCCESS，不解析 `Tests run: N` 实际执行数量；无测试基础设施兼容性检查。`tf test record`（v0.32.1）已能程序化解析 maven-surefire XML 获取真实执行数，但未被 wave VERIFY 用作数量对账。

### 76.2 改进方案

**P1-55：wave VERIFY 检查实际执行测试数量**

build-executor 每个 wave 的 VERIFY 步骤：
1. 运行测试套件后，用 `tf test record <change-dir> --from <runner-output>`（或解析 `Tests run: N`）获取**实际执行数量**。
2. 对照 test-matrix 当前 wave 覆盖的用例数：实际执行数明显低于预期（<70%）→ **警告 + 调查**（@Nested 静默跳过、测试未被发现、编译期跳过等），不满足则不得报告 "N tests pass"。
3. 报告改为引用实际执行数（`Tests run: N`），而非 BUILD SUCCESS 或编译通过数量。

**P1-56：测试框架兼容性检查**

build-executor 首个 wave 开始前检测项目测试基础设施：
1. **Java 项目**：读 `pom.xml` 的 maven-surefire-plugin 版本 + JUnit 版本。
2. **兼容性判断**：surefire < 2.22.2 且测试计划含 JUnit 5 `@Nested` → 警告"@Nested 自动发现不兼容，建议 flatten 测试类或升级 surefire"。
3. **沉淀 conventions**：检测结果写入 `.team-flow/conventions/`（项目级测试基础设施约束），供后续 change 复用，避免每个 change 重复踩坑。

### 76.3 设计决策

| 决策项 | 决策 | 理由 |
|------|------|------|
| 数量来源 | `tf test record` 程序化解析（真实执行数） | v0.32.1 已有程序化证据通道，与 tests-passing 门禁凭证一致，不引入手工上报 |
| 阈值 | 实际执行 < 70% 预期 → 警告+调查 | 平衡"静默跳过必须被发现"与"非 @Nested 场景数量正常" |
| 沉淀方式 | conventions 记录 | 复用 v0.11 §33 项目级规范机制，跨 change 生效 |

### 76.4 实现范围

| 改进项 | 修改文件 | 影响范围 |
|------|----------|----------|
| VERIFY 数量检查 | `skills/build-executor/SKILL.md` | VERIFY 步骤增加实际执行数量对账 |
| 框架兼容性检查 | `skills/build-executor/SKILL.md` + `skills/build-executor/references/implementer-prompt.md` | 首个 wave 前置检查 + conventions 沉淀 |

### 76.5 验证方案

1. 无头测试/实证探针：构造 surefire 2.22.2 + @Nested 的 fixture，验证 build-executor 检测到不兼容并警告。
2. 数量对账：构造 "Tests run: 31 / 预期 86" 的 runner 输出，验证 VERIFY 警告覆盖率虚高。

---

## 七十七、spec-writer 产物路径契约（v0.43.1）

### 77.1 问题描述

**触发来源**：workflow-feedback 2026-08-06（20260806-180400-artifact-quality）

**现象**：C2 的 spec-writer 生成 `specs/capability-cascade-selection.md`（flat 文件），但验证器期望 `specs/capability-cascade-selection/spec.md`（子目录结构）。`tf validate` 报 `Invalid spec path`，需额外一轮修复。

**现状核查**：spec-writer SKILL.md 的 `## specs/` 段只写 "Every requirement must be testable"，**无子目录路径契约**——这是产物格式未契约化的直接根因。

### 77.2 改进方案

**P2-50：spec-writer SKILL.md 明确子目录结构**

在 `## specs/` 段补路径契约：
- 每个 capability 一个子目录：`specs/<capability>/spec.md`
- **禁止** flat 文件：`specs/<capability>.md` 是错误的（`tf validate` 会拒绝）
- 示例：`specs/capability-cascade-selection/spec.md`

### 77.3 设计决策

| 决策项 | 决策 | 理由 |
|------|------|------|
| 契约化位置 | SKILL.md Artifact Roles `specs/` 段 | 产物格式契约是 spec-writer 的 HOW，属于 skill 文档 |

### 77.4 实现范围

| 改进项 | 修改文件 | 影响范围 |
|------|----------|----------|
| 路径契约 | `skills/spec-writer/SKILL.md` | `## specs/` 段补子目录结构说明 |

### 77.5 验证方案

无头测试/实证探针：dispatch spec-writer 子代理，验证产出 `specs/<capability>/spec.md` 子目录结构、`tf validate` 通过。

---

## 七十八、决策落实状态（v0.18）

| 决策点 | 决策 | 目标版本 | 状态 |
|---|---|---|---|
| 代码落地形态 | release-archivist 确认式步骤 + `tf deisolate --merge` 增强 | v0.43.1 | ✅ 已实施 |
| 合并模式 | merge commit（不 rebase） | v0.43.1 | ✅ 已实施 |
| 文件存在性 | build-executor 源头 + code-reviewer 兜底双层 | v0.43.1 | ✅ 已实施 |
| 测试数量 | `tf test record` 真实执行数对账 | v0.43.1 | ✅ 已实施 |
| 框架兼容性 | 首 wave 前置检查 + conventions 沉淀 | v0.43.1 | ✅ 已实施 |
| spec 路径 | `specs/<capability>/spec.md` 契约化 | v0.43.1 | ✅ 已实施 |
