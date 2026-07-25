# 递归进化自动化评估

> 2026-07-25 CC 基于 v0.16.0 VRM 全流程无头测试经验撰写
> 评估目标：测试→识别问题→修复→重测 的递归循环自动化

## 一、问题定义

team-flow 插件的迭代质量依赖"跑一轮真实流程→发现问题→修复→再跑"的循环。
当前这个循环是人工驱动的（LT 手动触发测试、CC 手动分析结果、LT 确认修复方向）。
目标：将这个循环自动化为**递归进化**——测试发现问题后自动修复、自动重测、直到收敛。

## 二、候选方案评估

### 方案 A：/loop（Claude Code 内置）

**机制**：按固定间隔（默认 10 分钟）重复执行一个 prompt 或 slash command。

**适用性评估**：
- ✅ 简单直接，`/loop 10m /team-flow:e2e-test <project>` 即可
- ✅ 适合"轮询式"场景（等 CI、等部署）
- ❌ **无状态**：每次执行是独立 session，不记得上一轮发现了什么问题、修了什么
- ❌ **无收敛判断**：不知道什么时候该停（所有测试通过）
- ❌ **无修复能力**：只重复执行同一个 prompt，不能根据结果修改代码
- ❌ **间隔固定**：10 分钟间隔对"测试→修复→重测"循环不合适（修复可能需要更长时间）

**结论**：❌ 不适合。/loop 是无状态轮询，不是有状态递归。

### 方案 B：/loop-agent:quickstart（分层循环代理）

**机制**：L0-L3 分层架构：
- L1（甲方监督者）：选择 Profile、委托 L2、验收交付
- L2（乙方规划者）：WBS 拆分、工作流编排、验收审查
- L3（执行者）：执行单个交付任务、产出证据

**适用性评估**：
- ✅ **有状态**：L1 维护全局状态，跨轮次记忆
- ✅ **有收敛判断**：L1 的 Client Acceptance 门控
- ✅ **有修复能力**：L3 可以执行代码修改
- ✅ **分层验收**：L2 Vendor Acceptance Review + L1 Client Acceptance
- ⚠️ **重量级**：L0-L3 四层编排，对"跑测试→改 skill→重跑"场景可能过度设计
- ⚠️ **依赖 loop-agent 插件**：额外依赖，非 team-flow 原生
- ⚠️ **skill 自迭代**：loop-agent 有 `loop-l2-skill-self-iteration-manager`，但面向"skill 黑盒试验+评分"，不面向"全流程 E2E 回归"

**结论**：⚠️ 可行但重量级。适合 team-flow 成熟后（v1.0+）的持续质量保障，当前阶段过度设计。

### 方案 C：Workflow（Claude Code 原生工作流）

**机制**：JavaScript 脚本编排多个 subagent，支持 pipeline/parallel/loop-until 模式。

**适用性评估**：
- ✅ **有状态**：脚本变量跨阶段保持
- ✅ **有收敛判断**：`while (issues.length > 0)` 循环直到无问题
- ✅ **有修复能力**：subagent 可以修改代码
- ✅ **原生**：Claude Code 内置，无额外依赖
- ✅ **灵活**：可以精确编排"测试→分析→修复→重测"的每个步骤
- ✅ **结构化输出**：subagent 用 schema 返回结构化测试结果
- ⚠️ **需要用户显式触发**：Workflow 需要用户 opt-in（"use a workflow"）
- ⚠️ **token 消耗大**：每轮测试+修复可能消耗大量 token

**结论**：✅ **最推荐**。原生、有状态、可编排、可收敛。

### 方案 D：Bash 脚本 + claude -p（当前方案）

**机制**：`headless-staged-v0.16.0.sh` 分阶段调用 `claude -p`。

**适用性评估**：
- ✅ 已验证可行（v0.16.0 VRM 全流程通过）
- ✅ 简单、可控、可调试
- ❌ **无自动修复**：发现问题后需要人工介入
- ❌ **无收敛循环**：跑完就结束，不会自动重测
- ❌ **无结构化分析**：需要人工解析 JSON 输出

**结论**：✅ 当前阶段的实用方案，作为 Workflow 方案的 building block。

## 三、推荐路径

### 短期（v0.17.0）：方案 D（Bash 脚本 skill 化）

已完成：`.claude/skills/team-flow-e2e-test/SKILL.md`

将 `headless-staged-v0.16.0.sh` 的核心逻辑固化为项目级 skill，
支持任意项目的全流程回归测试。人工驱动，但步骤标准化。

### 中期（v1.0.0）：方案 C（Workflow 递归进化）

设计一个 `team-flow-recursive-test` Workflow：

```javascript
// 伪代码
const MAX_ROUNDS = 5;
let round = 0;
let issues = [];

do {
  // Phase 1: 测试（pipeline 各阶段）
  const results = await pipeline(STAGES, runStage, verifyStage);

  // Phase 2: 分析（结构化输出）
  issues = await agent("分析测试结果，列出所有问题", {schema: ISSUE_SCHEMA});

  if (issues.length === 0) break;  // 收敛

  // Phase 3: 修复（并行修复各问题）
  await parallel(issues.map(issue => () =>
    agent(`修复问题: ${issue.description}`, {isolation: 'worktree'})
  ));

  // Phase 4: 验证修复（npm test + check-versions）
  round++;
} while (round < MAX_ROUNDS);

return { rounds: round, remaining_issues: issues };
```

### 长期（v1.x）：方案 B（loop-agent 持续质量保障）

当 team-flow 足够成熟、测试用例足够丰富时，
引入 loop-agent 的 L1-L3 分层架构做持续质量保障：
- L1 定义验收标准（"全流程通过 + 无 P0/P1 问题"）
- L2 拆分测试计划（按模块/阶段/平台）
- L3 执行具体测试任务

## 四、关键约束

1. **修复范围限制**：自动修复只能改 SKILL.md / references / 测试脚本，不能改核心 SOP 设计（需 LT 确认）
2. **收敛保护**：最多 5 轮，防止无限循环
3. **token 预算**：每轮测试约 50K-100K token，5 轮约 250K-500K token
4. **人工门控**：P0 级问题（SOP 设计缺陷）必须升级到人工，不自动修复
5. **幂等性**：每轮测试前清理状态，确保测试环境一致
