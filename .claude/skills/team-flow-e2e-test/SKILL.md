---
name: team-flow-e2e-test
description: >
  team-flow 工作流端到端自动化测试（node 结构化 runner + 测试矩阵驱动，v0.31.0 重构）。
  两层架构：Tier1 确定性层（直调 tf CLI + guard 门禁断言，进 CI，零 LLM 成本，覆盖 v0.29.1+
  状态机/14 guard 维度/tf isolate/agent 注册/test-matrix-complete）；Tier2 LLM 层（claude -p
  驱动真实工作流阶段，行为级断言，opt-in local-only）。测试目标用基线归档解压隔离，全程不碰活工作区。
  当需要验证 team-flow 插件版本升级后的工作流完整性、回归测试、或针对性单阶段验证时使用。
  不适用于：单个 skill 的单元测试（直接 claude -p 调用即可）、需人工交互的流程验证。
argument-hint: "[--tier 1|2|all] [--case <case_id>]"
---

# team-flow E2E 自动化测试

对 team-flow 工作流做端到端自动化测试。**测试代码在 `team-flow/tests/e2e/`**，测试矩阵在
`team-flow/tests/e2e/test-matrix.md`（复用 `skills/test-strategy` 方法论适配到工作流行为）。

## When to Use

- team-flow 插件版本升级后的回归测试（验证 v0.29.1+ 的 change 级机制）
- 针对性单阶段验证（架构门控 / spec-writer dispatch / tf isolate / 状态转换 …）
- 新 skill / 新 guard 维度添加后的触发与阻断验证

## When NOT to Use

- 单个 skill 的单元测试（直接 `claude -p "/team-flow:<skill>"`）
- 需人工交互的流程验证（无头模式自动确认，无法回答真实 AskUserQuestion）

## 两层架构

| 层 | 驱动 | 特征 | 运行 |
|---|---|---|---|
| **Tier1 确定性** | 直调 `tf` CLI + guard，合成 fixture 设态断言 | 快、零 LLM 成本、确定性、进 CI | `npm run test:e2e` |
| **Tier2 LLM** | `claude -p` 驱动真实阶段，stream-json 行为级断言 | 慢、贵、概率性、opt-in local-only | `npm run test:e2e:llm` |

**oracle 原则**：用插件自带门禁（`tf runtime guard check --json` / `tf validate` / `tf state get` /
`tf execution show --json` / `checkChangeStates`）作断言源，替代 grep 文件 + Claude 自评。
Tier2 只断**状态字段 / 文件存在 / 机械计算值 / stream-json 行为事件**（如 subagent dispatch、
FINAL VERDICT、目录树快照零 diff），不断内容质量。

## 快速开始

```bash
cd team-flow

# Tier1：确定性回归（默认，进 CI；合成 fixture，无需基线归档/插件同步）
npm run test:e2e

# Tier2：LLM 工作流测试（opt-in，local-only），三步前置：
npm run test:e2e:baseline      # ① 一次性把 vrm4teamflow 全量压缩为冻结基线归档
npm run test:e2e:plugin-sync   # ② 从 GitHub update 插件到被测版本 + 校验已安装版本
npm run test:e2e:llm           # ③ TF_E2E_LLM=1 串行跑 workflow/*.test.mjs（--test-concurrency=1）
```

## 测试隔离（基线归档，不碰活工作区）

- **冻结基线**：`npm run test:e2e:baseline` 把当前 vrm4teamflow 全量压缩为
  `tests/e2e/baseline/vrm4teamflow-baseline.tar.gz`（含 .git）。源/归档路径可用
  `TF_E2E_VRM` / `TF_E2E_BASELINE` 覆盖。
- **每用例解压**：Tier2 每个用例解压归档到独立 `mkdtemp` 副本，测完 `rm -rf`——**全程不碰活工作区**，
  彻底解耦日常使用污染（helpers/workspace.mjs）。
- **插件同步**：插件经 GitHub 安装/更新。测前 `test:e2e:plugin-sync` update 到被测版本并校验
  （`TF_E2E_PLUGIN_UPDATE_CMD` / `TF_E2E_VERSION` 可覆盖）。默认测 GitHub 安装的发布产物；
  保留 `--plugin-dir <local>` 旁路供发布前本地调试。

## Tier2 风控四件套（claude-driver.mjs）

1. `--test-concurrency=1`：串行，避免多 claude 并发烧钱 + API 429。
2. 单用例超时（默认 15min）：超时 kill + fail + 归档 JSONL。
3. 预算熔断：累计 `total_cost_usd` 超 `TF_E2E_BUDGET_USD`（默认 50）中止后续。
4. `--max-turns 40` + 检测 `stop_reason==='max_turns'` 显式 fail；缺 result 行（崩溃/截断）→ fail。

## 测试矩阵

`tests/e2e/test-matrix.md`：design_method 工作流映射（state/contract/reject/idempotency/…）+
复杂度分级 + 对抗验证三招 + 候选覆盖台账（v0.29.1+ 行为 → covered/deferred）+ Tier1/Tier2 用例表。
**与 docs/test-ledger/ 解耦**（那是应用代码测试台账），但**工作流行为层覆盖 v0.12 新行为**
（contract-builder 产 test-matrix.md、test_matrix_hash、guard test-matrix-complete）。

## 自动决策 Prompt（AUTO_DECIDE）

所有 Tier2 阶段共用 `--append-system-prompt`（实现见 `tests/e2e/helpers/prompts.mjs`）：
AskUserQuestion 选「推荐」（无推荐选第一个）；用户确认（PRD 冻结/DP-A/DP-3）视为已确认；
侦察选 Quick；敏感信息用 `${PLACEHOLDER}`；阻断记 feedback 并绕过；结尾标注 `FINAL VERDICT`；
状态恢复先读 `.team-flow/registry.yaml` + `orchestrator.yaml` 从当前阶段续跑。

## 已知限制

| 限制 | 说明 | 处理 |
|------|------|------|
| `--verbose` 硬前置 | print 模式 stream-json 必须带 `--verbose`，否则 CLI 拒绝启动 | runner 已强制带（旧 bash 脚本 7 处漏写，已废弃） |
| guard/validate 依赖 dist | schema-valid 维度 + tf validate 需 `dist/index.js` | 确保已构建（dist 已随仓库提交） |
| DP-0/DP-A 人工门 | 无头靠自动确认，测的是门控机制触发而非人的判断 | 断言状态字段落盘，不断判断质量 |
| 实事求是/串行/SendMessage 复用 | LLM 行为，概率性 | 弱信号/时序/dispatch 计数断言，非确定性硬断言 |
| Tier2 依赖活环境 | 需 claude + 基线归档 + 插件已更新 | opt-in local-only，不进 CI |

## Guardrails

- **零污染**：测试只在解压副本上跑，绝不直接修改活工作区 vrm4teamflow。
- **安全边界**：`--dangerously-skip-permissions` 仅在隔离副本内使用，绝不对真实项目跑。
- **清理 best-effort**：临时副本清理失败不掩盖用例真实断言结果。

## 历史脚本（已废弃）

`tests/headless-test-v0.16.0.sh` / `tests/headless-staged-v0.16.0.sh` 是 v0.16.0 时代的 bash 原型
（仅产品级 happy path、grep 断言、`|| true` 吞失败、无隔离、`--verbose` 漏写），已被本 node runner
取代，仅作历史参考。递归进化评估见 `references/recursive-evolution.md`。
