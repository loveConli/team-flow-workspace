---
name: team-flow-e2e-test
description: >
  team-flow 工作流全流程端到端无头测试。用 claude -p（print 模式）+ --resume 链式接续，
  对目标项目执行 Bootstrap→S1→S2→S3→S4 全流程 + v0.16.0 新 skill（session-handoff/workflow-feedback）验证。
  当需要验证 team-flow 插件版本升级后的工作流完整性、回归测试、或新 skill 触发验证时使用。
  不适用于：单个 skill 的单元测试（直接 claude -p 调用即可）、交互式流程验证（需人工参与）。
argument-hint: "[目标项目路径] [--phase bootstrap|s2|s3|s4|handoff|feedback|all] [--resume <session-id>]"
---

# team-flow E2E 无头测试

对目标项目执行 team-flow 全流程无头测试，验证工作流完整性。

## When to Use

- team-flow 插件版本升级后的回归测试
- 新 skill 添加后的触发验证
- 工作流 SOP 变更后的全流程验证
- LT 要求"跑一轮测试"时

## When NOT to Use

- 单个 skill 的单元测试（直接 `claude -p "/team-flow:<skill>"` 即可）
- 需要人工交互的流程验证（无头模式无法回答 AskUserQuestion）
- 目标项目无代码库（bootstrap 需要代码库侦察）

## 核心原理

`claude -p`（print 模式）是单轮请求-响应，orchestrator 全流程无法一次跑完。
解决方案：**分阶段链式调用 + `--resume` 接续**。

```
claude -p "bootstrap"     → session-A（B1→B5，产出 baseline.md）
claude -p "orchestrator"  → session-B（S1 路由，产出 registry.yaml）
claude -p "s2 brainstorm" → session-C（可能停在交互点）
claude -p --resume C      → session-C'（模拟用户回答，接续写 PRD）
claude -p "s3 plan"       → session-D（产出 plan.md）
claude -p "s4 split"      → session-E（产出 changes/）
claude -p "handoff"       → session-F（产出 .team-flow/handoffs/）
claude -p "feedback"      → session-G（产出 .team-flow/feedback/）
```

每阶段通过 `.team-flow/` 状态文件衔接（orchestrator.yaml 的 phases 状态）。

## 执行步骤

### Step 0: 环境准备

```bash
PLUGIN_DIR="<team-flow 插件源码路径>"
TARGET_DIR="<目标项目路径>"
OUTPUT_DIR="<测试输出路径>"

# 清理目标项目的 team-flow 状态（保留项目本身文件）
cd "$TARGET_DIR"
rm -rf .team-flow .workflow-orchestrator.yaml CONCEPTS.md

# 验证插件版本
grep '"version"' "$PLUGIN_DIR/plugin.json"
```

### Step 1: Bootstrap（B1→B5）

```bash
cd "$TARGET_DIR"
claude -p "请对当前项目执行 /team-flow:workflow-bootstrap 初始化。使用 Quick 侦察模式。" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/bootstrap.json" 2>&1
```

**验证**：`baseline.md` + `ARCHITECTURE.md` + `CONCEPTS.md` + 目录结构存在。

### Step 2: Orchestrator S1→S2

```bash
claude -p "执行 /team-flow:workflow-orchestrator 处理需求：<模糊需求描述>。从 S1 开始。" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/orchestrator.json" 2>&1
```

**验证**：`registry.yaml` + `orchestrator.yaml` 存在，s1.status=completed。

### Step 3: S2 Brainstorm（可能需要 --resume）

首次调用可能停在方案选择交互点。提取 session_id 后用 `--resume` 接续：

```bash
# 提取 session_id
SESSION_ID=$(grep -o '"session_id":"[^"]*"' "$OUTPUT_DIR/s2.json" | head -1 | cut -d'"' -f4)

# 模拟用户回答，接续
claude -p --resume "$SESSION_ID" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  "选推荐方案，直接写 PRD 到 prd/v1/prd.md。写完冻结 PRD。" \
  --output-format stream-json \
  > "$OUTPUT_DIR/s2-resume.json" 2>&1
```

**验证**：`prd/v1/prd.md` 存在，frontmatter 含 `frozen: true`。

### Step 4: S3 Plan

```bash
claude -p "继续 orchestrator S3。读取 prd/v1/prd.md，调用 ce-plan（一人公司模式）产出 plan.md。" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/s3.json" 2>&1
```

**验证**：`prd/v1/plan.md` 存在，含 change 拆分和 DAG。

### Step 5: S4 Split

```bash
claude -p "继续 orchestrator S4。读取 plan.md 的 change 拆分，创建 changes/<name>/ 目录和 .spec-superflow.yaml。" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/s4.json" 2>&1
```

**验证**：`changes/` 下各 change 目录存在，每个含 `.spec-superflow.yaml`（state: exploring）。
**注意**：change 目录必须在项目根 `changes/<name>/`，不是 `.team-flow/changes/`（见 s4-split-validate.md:35）。

### Step 6: session-handoff（v0.16.0）

```bash
claude -p "执行 /team-flow:session-handoff 下一步继续 change 级实施。" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/handoff.json" 2>&1
```

**验证**：`.team-flow/handoffs/*.md` 存在，含 10 节结构（工作流状态/进度/建议Skills/产物引用/脱敏声明）。

### Step 7: workflow-feedback（v0.16.0）

```bash
claude -p "执行 /team-flow:workflow-feedback 记录问题：<问题描述> --category <分类> --severity <P0-P3>" \
  --plugin-dir "$PLUGIN_DIR" \
  --dangerously-skip-permissions \
  --append-system-prompt "$AUTO_DECIDE" \
  --output-format stream-json \
  > "$OUTPUT_DIR/feedback.json" 2>&1
```

**验证**：`.team-flow/feedback/*.md` 存在，frontmatter 含 type/category/severity/status。

## 自动决策 Prompt（AUTO_DECIDE）

所有阶段共用的 `--append-system-prompt`：

```
你正在无头自动化测试环境中运行 team-flow 工作流。关键规则：
1. 当需要 AskUserQuestion 时，选择标记为「推荐」的选项。无推荐则选第一个。不要等待用户输入。
2. 如果需要用户确认（PRD 冻结、计划确认），视为已确认并继续。
3. 每阶段完成后更新 .team-flow/ 状态文件。
4. 侦察模式选 Quick。首版范围选 P0 全量。
5. 敏感信息用 ${PLACEHOLDER} 替换。
状态恢复：先读 .team-flow/registry.yaml 和 orchestrator.yaml，从当前阶段的下一步继续。
```

## 已知限制

| 限制 | 说明 | 解决方案 |
|------|------|---------|
| ce-brainstorm 停在方案选择 | 多轮交互 skill 在 -p 模式下阻断 | `--resume` 接续 |
| S3 grounding 耗时 | verify-before-claiming 导致 ~9min 代码扫描 | 对已有 baseline 的项目可跳过 |
| S4 可能跳过审计 | 无头 Claude 标注 skipped-plan-inline | 测试后检查 split_audit 字段 |
| change 目录位置 | 无头 Claude 可能误放 .team-flow/changes/ | 验证时检查 changes/ 而非 .team-flow/changes/ |

## 递归进化自动化（评估结论）

详见 `references/recursive-evolution.md`。

## Guardrails

- **不修改源代码**：测试只产出文档和状态文件，不修改目标项目的源代码
- **清理优先**：每次测试前清理 .team-flow/ 状态，避免残留干扰
- **超时保护**：每阶段设置 `--max-turns`（建议 30）防止无限循环
- **输出归档**：所有 JSON 输出保存到 `$OUTPUT_DIR/`，便于事后分析

## Success Output

测试完成后输出：
1. 各阶段通过/失败状态表
2. 产出物清单（文件路径 + 大小）
3. 发现的问题清单（可直接转为 workflow-feedback 或 CLAUDE.md 待办）
4. 耗时统计（每阶段 duration_ms）
