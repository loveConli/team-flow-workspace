#!/bin/bash
# team-flow v0.16.0 分阶段链式无头测试
# 设计说明（2026-07-25 CC 创建）：
#   claude -p 是单轮模式，orchestrator 全流程无法一次跑完。
#   改为分阶段链式调用：每阶段独立 claude -p，通过 .team-flow/ 状态文件衔接。
#   每阶段结束后验证状态文件更新，再启动下一阶段。
#
# 用法：bash tests/headless-staged-v0.16.0.sh [stage]
#   stage: s2-brainstorm | s2-prototype | s3-plan | s4-split | handoff | feedback | all
#
# 前置条件：bootstrap 已完成（baseline.md 存在），orchestrator S1 已完成（registry.yaml 存在）

set -euo pipefail

PLUGIN_DIR="/Users/litong/Documents/work/code/practice/team-flow-workspace/team-flow"
VRM_DIR="/Users/litong/Documents/work/code/gtmc/vrm"
PRD_REF="/Users/litong/Downloads/数字化需求协同工具_驾驶舱_v4.4（PRD&html原型） 2/数字化需求协同工具 · 驾驶舱 PRD v4.4.md"
TEST_OUTPUT_DIR="/Users/litong/Documents/work/code/practice/team-flow-workspace/tests/output"
STAGE="${1:-all}"

VAGUE_REQUIREMENT="我需要一个管理驾驶舱。目前公司有100多个方针管理事项，散落在Excel、PowerPoint和各种业务系统里。部长每次经营会议都要临时拼凑数据，看不到全貌。我希望能一屏展示所有事项的状态：预算执行到哪了、进度延迟了没有、哪个科室拖后腿了。事项下面还有改善方向和用户故事，需要能下钻到底。"

# 自动决策 + 状态恢复指令
STAGED_PROMPT='你正在无头自动化测试环境中运行 team-flow 工作流。

关键规则：
1. 当需要调用 AskUserQuestion 时，始终选择标记为「推荐」的选项。如果没有推荐标记，选择第一个选项。不要等待用户输入。
2. 如果需要用户确认（如 PRD 冻结、计划确认），视为已确认并继续。
3. 每个阶段完成后，必须更新 .team-flow/ 下的状态文件（orchestrator.yaml 的 phases 状态）。
4. 侦察模式选择 Quick。首版范围选择 P0 全量。
5. 敏感信息用 ${PLACEHOLDER} 替换。

状态恢复：
- 先读取 .team-flow/registry.yaml 确认活跃需求
- 再读取 .team-flow/requirements/<req-id>/orchestrator.yaml 确认当前阶段
- 从当前阶段的下一步继续，不要重复已完成的阶段
- 读取 docs/architecture/baseline.md 和 CONCEPTS.md 作为架构上下文'

timestamp() { date "+%Y%m%d-%H%M%S"; }
log() { echo "[$(timestamp)] $*"; }
stage_header() { echo ""; echo "========================================"; echo "  $1"; echo "========================================"; echo ""; }

run_claude() {
  local prompt="$1"
  local output_file="$2"

  log "启动无头 Claude..."
  log "输出: $output_file"

  cd "$VRM_DIR"
  claude -p "$prompt" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --append-system-prompt "$STAGED_PROMPT" \
    --output-format stream-json \
    --verbose \
    > "$output_file" 2>&1 || true

  log "退出码: $?, 大小: $(wc -c < "$output_file") bytes, 行数: $(wc -l < "$output_file")"
}

check_state() {
  log "检查 orchestrator.yaml 状态..."
  cat "$VRM_DIR/.team-flow/requirements/mgmt-dashboard/orchestrator.yaml" 2>/dev/null | grep -E "status:|workflow_phase:" || echo "无法读取状态"
}

# === Stage: S2 Brainstorm（PRD 编写）===
stage_s2_brainstorm() {
  stage_header "Stage S2a: ce-brainstorm → PRD"
  check_state

  local output="$TEST_OUTPUT_DIR/staged-s2-brainstorm-$(timestamp).json"

  run_claude \
    "继续 /team-flow:workflow-orchestrator 的 S2 阶段。

当前状态：S1 路由已完成（brand-new-requirement → S2），需要确认 S1 并进入 S2。

S2 任务：调用 ce-brainstorm 编写 PRD。

需求描述：
$VAGUE_REQUIREMENT

参考资料（只读，作为 PRD 编写的领域知识参考，不要照搬）：
$PRD_REF

要求：
1. 先读取 .team-flow/ 状态文件确认当前位置
2. 确认 S1 路由（将 s1.status 改为 completed）
3. 读取 baseline.md 和 CONCEPTS.md 作为架构上下文
4. 读取上面的 PRD 参考文件了解业务领域（方针管理事项、改善方向、用户故事、红线预算流、绿线进度流）
5. 调用 ce-brainstorm 产出 prd/v1/prd.md
6. PRD 完成后更新 orchestrator.yaml（s2.status: active, prd_version: v1）
7. 汇报 PRD 产出路径和关键内容摘要" \
    "$output"

  # 验证
  if [[ -f "$VRM_DIR/prd/v1/prd.md" ]]; then
    log "✓ PRD 已生成: prd/v1/prd.md ($(wc -c < "$VRM_DIR/prd/v1/prd.md") bytes)"
  else
    log "✗ PRD 缺失"
  fi
  check_state
}

# === Stage: S2 Prototype（原型 + 评审 + 冻结）===
stage_s2_prototype() {
  stage_header "Stage S2b: prototype → 评审 → 冻结"
  check_state

  local output="$TEST_OUTPUT_DIR/staged-s2-prototype-$(timestamp).json"

  run_claude \
    "继续 /team-flow:workflow-orchestrator 的 S2 阶段（原型部分）。

当前状态：S2 PRD 已编写（prd/v1/prd.md），需要产出原型并冻结 PRD。

任务：
1. 读取 .team-flow/ 状态确认当前在 S2
2. 读取 prd/v1/prd.md 了解需求
3. 调用 prototype skill 产出原型（prototype/ 下的 HTML 文件）
4. 原型完成后，视为自动评审通过（无头模式跳过 prototype-reviewer）
5. 冻结 PRD（frozen_downstream），更新 prd.md frontmatter
6. 更新 orchestrator.yaml（s2.status: completed）
7. 汇报原型产出路径" \
    "$output"

  # 验证
  local html_count
  html_count=$(find "$VRM_DIR/prototype" -name "*.html" -newer "$VRM_DIR/.team-flow/registry.yaml" 2>/dev/null | wc -l)
  if [[ "$html_count" -gt 0 ]]; then
    log "✓ 新原型 HTML: $html_count 个"
  else
    log "⚠ 未检测到新原型 HTML（可能复用已有原型）"
  fi
  check_state
}

# === Stage: S3 Plan ===
stage_s3_plan() {
  stage_header "Stage S3: ce-plan → plan.md"
  check_state

  local output="$TEST_OUTPUT_DIR/staged-s3-plan-$(timestamp).json"

  run_claude \
    "继续 /team-flow:workflow-orchestrator 的 S3 阶段。

当前状态：S2 已完成（PRD 冻结 + 原型），进入 S3 计划阶段。

任务：
1. 读取 .team-flow/ 状态确认 S2 completed
2. 更新 orchestrator.yaml（workflow_phase: s3-planning, s3.status: active）
3. 读取 prd/v1/prd.md 和 baseline.md
4. 调用 ce-plan（模式：一人公司模式，由 orchestrator 指定）产出 prd/v1/plan.md
5. plan.md 包含：change 拆分（scope+依赖+优先级+复杂度）、依赖 DAG、技术方向、风险与里程碑
6. 注意：plan.md 不包含接口清单/字段定义（那是变更级 spec-writer 的职责）
7. 更新 orchestrator.yaml（s3.status: completed）
8. 汇报 plan.md 产出路径和 change 拆分摘要" \
    "$output"

  # 验证
  if [[ -f "$VRM_DIR/prd/v1/plan.md" ]]; then
    log "✓ Plan 已生成: prd/v1/plan.md ($(wc -c < "$VRM_DIR/prd/v1/plan.md") bytes)"
    log "  change 拆分:"
    grep -E "^##.*[Cc]hange|^###.*C[0-9]" "$VRM_DIR/prd/v1/plan.md" 2>/dev/null | head -10
  else
    log "✗ Plan 缺失"
  fi
  check_state
}

# === Stage: S4 Split ===
stage_s4_split() {
  stage_header "Stage S4: 拆分验证与分发"
  check_state

  local output="$TEST_OUTPUT_DIR/staged-s4-split-$(timestamp).json"

  run_claude \
    "继续 /team-flow:workflow-orchestrator 的 S4 阶段。

当前状态：S3 已完成（plan.md 含 change 拆分），进入 S4 拆分验证与分发。

任务：
1. 读取 .team-flow/ 状态确认 S3 completed
2. 读取 prd/v1/plan.md 中的 change 拆分
3. 为每个 change 创建 changes/<change-id>/ 目录和 .spec-superflow.yaml 状态文件
4. 更新 orchestrator.yaml（s4.status: completed, workflow_phase: s4-distribution）
5. 汇报创建的 change 目录清单" \
    "$output"

  # 验证（只看测试期间新创建的 change）
  local new_changes
  new_changes=$(find "$VRM_DIR/changes" -name ".spec-superflow.yaml" -newer "$VRM_DIR/.team-flow/registry.yaml" 2>/dev/null | wc -l)
  log "本次测试新创建 change: $new_changes 个"
  check_state
}

# === Stage: session-handoff ===
stage_handoff() {
  stage_header "Stage: session-handoff（v0.16.0 新 skill）"

  local output="$TEST_OUTPUT_DIR/staged-handoff-$(timestamp).json"

  run_claude \
    "请执行 /team-flow:session-handoff 下一步继续 change 级实施（spec-writer → build-executor）。

注意：这是测试 session-handoff skill 的触发和产出。请生成交接文档到 .team-flow/handoffs/。" \
    "$output"

  # 验证
  if [[ -d "$VRM_DIR/.team-flow/handoffs" ]] && ls "$VRM_DIR/.team-flow/handoffs/"*.md >/dev/null 2>&1; then
    local hf
    hf=$(ls -t "$VRM_DIR/.team-flow/handoffs/"*.md 2>/dev/null | head -1)
    log "✓ 交接文档: $hf ($(wc -c < "$hf") bytes)"
    for section in "工作流状态" "本次会话进度" "建议 Skills" "关键产物引用"; do
      grep -q "$section" "$hf" 2>/dev/null && log "  ✓ 含「$section」" || log "  ⚠ 缺「$section」"
    done
  else
    log "✗ 交接文档缺失"
  fi
}

# === Stage: workflow-feedback ===
stage_feedback() {
  stage_header "Stage: workflow-feedback（v0.16.0 新 skill）"

  local output="$TEST_OUTPUT_DIR/staged-feedback-$(timestamp).json"

  run_claude \
    "请执行 /team-flow:workflow-feedback 记录以下工作流问题：

问题：在 S2 阶段，prototype skill 被触发后，主代理直接 Write 了原型 HTML 文件，没有通过 prototype-builder 子代理。这违反了 v0.15.0 的「主代理只编排不实施」原则。

--category agent-quality --severity P1" \
    "$output"

  # 验证
  if [[ -d "$VRM_DIR/.team-flow/feedback" ]] && ls "$VRM_DIR/.team-flow/feedback/"*.md >/dev/null 2>&1; then
    local fb
    fb=$(ls -t "$VRM_DIR/.team-flow/feedback/"*.md 2>/dev/null | head -1)
    log "✓ 问题记录: $fb ($(wc -c < "$fb") bytes)"
    grep -q "type: workflow-feedback" "$fb" 2>/dev/null && log "  ✓ frontmatter 正确" || log "  ⚠ frontmatter 异常"
  else
    log "✗ 问题记录缺失"
  fi
}

# === 主流程 ===
mkdir -p "$TEST_OUTPUT_DIR"
log "分阶段链式测试开始 | 阶段: $STAGE"

case "$STAGE" in
  s2-brainstorm)  stage_s2_brainstorm ;;
  s2-prototype)   stage_s2_prototype ;;
  s3-plan)        stage_s3_plan ;;
  s4-split)       stage_s4_split ;;
  handoff)        stage_handoff ;;
  feedback)       stage_feedback ;;
  all)
    stage_s2_brainstorm
    stage_s2_prototype
    stage_s3_plan
    stage_s4_split
    stage_handoff
    stage_feedback
    ;;
  *)
    echo "用法: $0 [s2-brainstorm|s2-prototype|s3-plan|s4-split|handoff|feedback|all]"
    exit 1
    ;;
esac

log "测试完成"
