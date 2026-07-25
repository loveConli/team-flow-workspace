#!/bin/bash
# team-flow v0.16.0 无头测试脚本
# 测试目标：VRM 管理驾驶舱项目（模拟 Session 29d058e5 工作流路径）
# 测试范围：v0.15.0 全流程（bootstrap→S4）+ v0.16.0 新 skill（session-handoff / workflow-feedback）
# 用法：bash tests/headless-test-v0.16.0.sh [phase]
#   phase: setup | bootstrap | orchestrator | handoff | feedback | verify | all
#
# 设计说明（2026-07-25 CC 创建）：
#   - 参考 JSONL session 29d058e5 的工作流路径：B1→B5 → S1→S4
#   - 用 --plugin-dir 直接加载 team-flow 源码（绕过插件缓存版本问题）
#   - 用 --append-system-prompt 注入自动决策指令（替代 AskUserQuestion 人工交互）
#   - 分阶段执行，每阶段独立验证，失败不阻断后续阶段

set -euo pipefail

# === 配置 ===
PLUGIN_DIR="/Users/litong/Documents/work/code/practice/team-flow-workspace/team-flow"
VRM_DIR="/Users/litong/Documents/work/code/gtmc/vrm"
TEST_OUTPUT_DIR="/Users/litong/Documents/work/code/practice/team-flow-workspace/tests/output"
PHASE="${1:-all}"

# 模糊需求（模拟用户初始输入，参考 VRM 管理驾驶舱场景）
VAGUE_REQUIREMENT="我需要一个管理驾驶舱。目前公司有100多个方针管理事项，散落在Excel、PowerPoint和各种业务系统里。部长每次经营会议都要临时拼凑数据，看不到全貌。我希望能一屏展示所有事项的状态：预算执行到哪了、进度延迟了没有、哪个科室拖后腿了。事项下面还有改善方向和用户故事，需要能下钻到底。"

# 自动决策系统提示（替代人工交互）
AUTO_DECIDE_PROMPT='你正在无头自动化测试环境中运行 team-flow 工作流。关键规则：
1. 当需要调用 AskUserQuestion 时，始终选择标记为「推荐」的选项。如果没有推荐标记，选择第一个选项。
2. 不要等待用户输入，自主做出合理决策并继续。
3. 如果需要用户确认（如 PRD 冻结、计划确认），视为已确认并继续。
4. 保持工作流状态文件（.team-flow/）的更新。
5. 如果遇到阻断性问题，记录到 .team-flow/feedback/ 并尝试绕过继续。
6. 侦察模式选择 Quick。
7. 工作流入口选择「具体功能需求」。
8. 项目归属选择「VRM 项目内新模块」。
9. 首版范围选择「P0 全量」。
10. 每个阶段完成后，简要汇报产出物路径。'

# === 工具函数 ===
timestamp() { date "+%Y%m%d-%H%M%S"; }
log() { echo "[$(timestamp)] $*"; }
phase_header() { echo ""; echo "========================================"; echo "  $1"; echo "========================================"; echo ""; }

run_claude() {
  local prompt="$1"
  local output_file="$2"
  local extra_args="${3:-}"

  log "启动无头 Claude..."
  log "输出文件: $output_file"

  cd "$VRM_DIR"
  claude -p "$prompt" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --append-system-prompt "$AUTO_DECIDE_PROMPT" \
    --output-format stream-json \
    --verbose \
    $extra_args \
    > "$output_file" 2>&1 || true

  local exit_code=$?
  log "Claude 退出码: $exit_code"
  log "输出大小: $(wc -c < "$output_file") bytes"
}

# === Phase: Setup ===
phase_setup() {
  phase_header "Phase 0: 环境准备"

  mkdir -p "$TEST_OUTPUT_DIR"

  # 清理 VRM 项目的 team-flow 状态（保留项目本身文件）
  log "清理 VRM 项目 team-flow 状态..."
  cd "$VRM_DIR"
  rm -rf .team-flow .workflow-orchestrator.yaml CONCEPTS.md 2>/dev/null || true
  # 注意：不清理 prd/ prototype/ changes/ docs/architecture/（可能是项目本身文件）

  # 验证插件源码
  log "验证 team-flow 插件源码..."
  local version
  version=$(grep '"version"' "$PLUGIN_DIR/plugin.json" | head -1 | sed 's/.*: *"\(.*\)".*/\1/')
  log "team-flow 版本: $version"

  if [[ "$version" != "0.16.0" ]]; then
    log "警告: 期望版本 0.16.0，实际 $version"
  fi

  # 验证 v0.16.0 新 skill 存在
  for skill in session-handoff workflow-feedback; do
    if [[ -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ]]; then
      log "✓ skill/$skill/SKILL.md 存在"
    else
      log "✗ skill/$skill/SKILL.md 缺失!"
      exit 1
    fi
  done

  log "环境准备完成"
}

# === Phase: Bootstrap ===
phase_bootstrap() {
  phase_header "Phase 1: Bootstrap（B1→B5）"

  local output="$TEST_OUTPUT_DIR/phase1-bootstrap-$(timestamp).json"

  run_claude \
    "请对当前项目执行 /team-flow:workflow-bootstrap 初始化。使用 Quick 侦察模式。完成后汇报基线文件路径和路径判断结果。" \
    "$output"

  # 验证 bootstrap 产出（B4 定义：mkdir -p prd/ prototype/ docs/architecture/ docs/solutions/ changes/）
  # 注意：.team-flow/ 由 orchestrator S1 创建，不属于 bootstrap 产物（2026-07-25 修正误判）
  log "验证 bootstrap 产出..."
  local pass=true

  for f in docs/architecture/baseline.md CONCEPTS.md; do
    if [[ -f "$VRM_DIR/$f" ]]; then
      log "✓ $f 已生成"
    else
      log "✗ $f 缺失"
      pass=false
    fi
  done

  for d in prd prototype docs/architecture docs/solutions changes; do
    if [[ -d "$VRM_DIR/$d" ]]; then
      log "✓ $d/ 目录存在"
    else
      log "✗ $d/ 目录缺失"
      pass=false
    fi
  done

  $pass && log "Phase 1 PASSED" || log "Phase 1 FAILED"
}

# === Phase: Orchestrator 全流程（S1→S4）===
phase_orchestrator() {
  phase_header "Phase 2: Orchestrator 全流程（S1→S4）"

  local output="$TEST_OUTPUT_DIR/phase2-orchestrator-$(timestamp).json"

  run_claude \
    "请执行 /team-flow:workflow-orchestrator 处理以下需求：

$VAGUE_REQUIREMENT

请从 S1 路径路由开始，完成 S2（PRD + 原型）、S3（计划）、S4（拆分验证与分发）全流程。每个阶段完成后简要汇报产出物。" \
    "$output"

  # 验证 orchestrator 产出
  log "验证 orchestrator 产出..."
  local pass=true

  # S1: 状态文件
  if [[ -f "$VRM_DIR/.team-flow/registry.yaml" ]]; then
    log "✓ registry.yaml 已创建"
  else
    log "✗ registry.yaml 缺失"
    pass=false
  fi

  # S2: PRD
  local prd_found=false
  for f in "$VRM_DIR"/prd/v*/prd.md; do
    if [[ -f "$f" ]]; then
      log "✓ PRD 已生成: $f"
      prd_found=true
    fi
  done
  $prd_found || { log "✗ PRD 缺失"; pass=false; }

  # S2: 原型
  if [[ -d "$VRM_DIR/prototype" ]] && ls "$VRM_DIR/prototype/"*.html >/dev/null 2>&1; then
    log "✓ 原型 HTML 已生成"
  else
    log "⚠ 原型 HTML 未检测到（可能使用已有原型）"
  fi

  # S3: Plan
  local plan_found=false
  for f in "$VRM_DIR"/prd/v*/plan.md; do
    if [[ -f "$f" ]]; then
      log "✓ Plan 已生成: $f"
      plan_found=true
    fi
  done
  $plan_found || { log "✗ Plan 缺失"; pass=false; }

  # S4: Changes
  if [[ -d "$VRM_DIR/changes" ]] && ls -d "$VRM_DIR/changes/"*/ >/dev/null 2>&1; then
    local change_count
    change_count=$(ls -d "$VRM_DIR/changes/"*/ 2>/dev/null | wc -l)
    log "✓ Changes 已创建: $change_count 个"
  else
    log "⚠ Changes 目录未检测到"
  fi

  $pass && log "Phase 2 PASSED" || log "Phase 2 FAILED"
}

# === Phase: session-handoff（v0.16.0 新 skill）===
phase_handoff() {
  phase_header "Phase 3: session-handoff（v0.16.0）"

  local output="$TEST_OUTPUT_DIR/phase3-handoff-$(timestamp).json"

  run_claude \
    "请执行 /team-flow:session-handoff 下一步继续 S3 计划阶段，完成 change 拆分和实施。

注意：这是测试 session-handoff skill 的触发和产出。请生成交接文档。" \
    "$output"

  # 验证 handoff 产出
  log "验证 session-handoff 产出..."
  local pass=true

  if [[ -d "$VRM_DIR/.team-flow/handoffs" ]] && ls "$VRM_DIR/.team-flow/handoffs/"*.md >/dev/null 2>&1; then
    local handoff_file
    handoff_file=$(ls -t "$VRM_DIR/.team-flow/handoffs/"*.md 2>/dev/null | head -1)
    log "✓ 交接文档已生成: $handoff_file"

    # 检查文档结构（应包含关键节）
    for section in "工作流状态" "本次会话进度" "建议 Skills" "关键产物引用"; do
      if grep -q "$section" "$handoff_file" 2>/dev/null; then
        log "  ✓ 包含「$section」节"
      else
        log "  ⚠ 缺少「$section」节"
      fi
    done
  else
    log "✗ 交接文档缺失（.team-flow/handoffs/ 无 .md 文件）"
    pass=false
  fi

  $pass && log "Phase 3 PASSED" || log "Phase 3 FAILED"
}

# === Phase: workflow-feedback（v0.16.0 新 skill）===
phase_feedback() {
  phase_header "Phase 4: workflow-feedback（v0.16.0）"

  local output="$TEST_OUTPUT_DIR/phase4-feedback-$(timestamp).json"

  run_claude \
    "请执行 /team-flow:workflow-feedback 记录以下工作流问题：

问题：在 S2 阶段，prototype skill 被触发后，主代理直接 Write 了原型 HTML 文件，没有通过 prototype-builder 子代理。这违反了 v0.15.0 的「主代理只编排不实施」原则。

--category agent-quality --severity P1" \
    "$output"

  # 验证 feedback 产出
  log "验证 workflow-feedback 产出..."
  local pass=true

  if [[ -d "$VRM_DIR/.team-flow/feedback" ]] && ls "$VRM_DIR/.team-flow/feedback/"*.md >/dev/null 2>&1; then
    local feedback_file
    feedback_file=$(ls -t "$VRM_DIR/.team-flow/feedback/"*.md 2>/dev/null | head -1)
    log "✓ 问题记录已生成: $feedback_file"

    # 检查 frontmatter
    if grep -q "type: workflow-feedback" "$feedback_file" 2>/dev/null; then
      log "  ✓ frontmatter type 正确"
    else
      log "  ⚠ frontmatter type 缺失或不正确"
    fi

    if grep -q "category:" "$feedback_file" 2>/dev/null; then
      log "  ✓ 包含 category 字段"
    else
      log "  ⚠ 缺少 category 字段"
    fi
  else
    log "✗ 问题记录缺失（.team-flow/feedback/ 无 .md 文件）"
    pass=false
  fi

  $pass && log "Phase 4 PASSED" || log "Phase 4 FAILED"
}

# === Phase: Verify（汇总验证）===
phase_verify() {
  phase_header "Phase 5: 汇总验证"

  log "=== 产物清单 ==="
  cd "$VRM_DIR"

  echo ""
  echo "--- .team-flow/ 状态目录 ---"
  find .team-flow -type f 2>/dev/null | sort || echo "(不存在)"

  echo ""
  echo "--- prd/ 产出 ---"
  find prd -type f -name "*.md" 2>/dev/null | sort || echo "(不存在)"

  echo ""
  echo "--- prototype/ 产出 ---"
  find prototype -type f -name "*.html" 2>/dev/null | head -10 || echo "(不存在)"

  echo ""
  echo "--- changes/ 产出 ---"
  ls -d changes/*/ 2>/dev/null || echo "(不存在)"

  echo ""
  echo "--- 基线文件 ---"
  for f in docs/architecture/baseline.md CONCEPTS.md; do
    [[ -f "$f" ]] && echo "✓ $f" || echo "✗ $f"
  done

  echo ""
  log "=== 测试输出文件 ==="
  ls -lh "$TEST_OUTPUT_DIR/" 2>/dev/null || echo "(无输出)"

  echo ""
  log "汇总验证完成"
}

# === 主流程 ===
log "team-flow v0.16.0 无头测试开始"
log "测试阶段: $PHASE"
log "插件目录: $PLUGIN_DIR"
log "目标项目: $VRM_DIR"

case "$PHASE" in
  setup)       phase_setup ;;
  bootstrap)   phase_bootstrap ;;
  orchestrator) phase_orchestrator ;;
  handoff)     phase_handoff ;;
  feedback)    phase_feedback ;;
  verify)      phase_verify ;;
  all)
    phase_setup
    phase_bootstrap
    phase_orchestrator
    phase_handoff
    phase_feedback
    phase_verify
    ;;
  *)
    echo "用法: $0 [setup|bootstrap|orchestrator|handoff|feedback|verify|all]"
    exit 1
    ;;
esac

log "测试完成"
