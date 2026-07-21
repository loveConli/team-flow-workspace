#!/usr/bin/env bash
# ============================================================================
# pre-push-gate.sh  —  git pre-push quality gate (确定性硬卡骨架)
# 报告引用: §5.2 / §8 Pipeline / §10.4 硬门禁边界表
# 形态: git pre-push hook（确定性）+ 分支保护 + CI required checks
# 约束: 仅确定性检查，不含 LLM CR
# ----------------------------------------------------------------------------
# 安装(真实环境): cp 此文件到 .git/hooks/pre-push && chmod +x
# 前置资产依赖:
#   - Git hook 配置（本脚本即 hook 本体）
#   - PMD/覆盖率工具（项目自带，需提供 PMD_CMD / COVERAGE_CMD）
#   - 分支保护 + CI required checks（本地 hook 被绕过时的 backstop）
# 当前环境: 否（sandbox 无真实仓库/工具）；SAFE_MODE=1 下可空跑验证流程
# 缺什么: 项目级 PMD_CMD、COVERAGE_CMD、COVERAGE_MIN、真实 git 仓库
# 标签: 【来源已核验✅·落地待验证⚠️】
# ----------------------------------------------------------------------------
# 评审 P0-A 门禁硬卡标注:
#  - 真实环境必须把 SAFE_MODE 置 0（fail-closed），**不能长期 warn-only**。
#  - 插件 fail-closed 可作模板（artifact-chain-assistant 的 hooks 行为）。
# ----------------------------------------------------------------------------
# 评审 K1 补充: 新增「流程态 ↔ version-lock 一致性」校验（见检查4）。
# ============================================================================
set -uo pipefail

# ---- 可配置项（真实环境必填；骨架默认空 → 触发 warn）-------------------------
PMD_CMD="${PMD_CMD:-}"                 # 例: pmd check -d src -R ruleset.xml
COVERAGE_CMD="${COVERAGE_CMD:-}"       # 例: ./mvnw test jacoco:report
COVERAGE_MIN="${COVERAGE_MIN:-80}"     # 覆盖率下限(%)
GATE_TARGET_BRANCHES="${GATE_TARGET_BRANCHES:-main master release}"  # 仅对这些目标分支硬卡

# ---- 安全模式 ----------------------------------------------------------------
# SAFE_MODE=1 (默认, 骨架): 检查失败只 warn，不阻断 push（便于空跑/审阅）
# SAFE_MODE=0 (真实)    : 检查失败 exit 1 拒绝 push（硬卡 / fail-closed）
# 评审 P0-A: 真实环境 SAFE_MODE 必须置 0，不可长期 warn-only。
SAFE_MODE="${SAFE_MODE:-1}"

# ---- 读取 pre-push 标准输入: <local-ref> <local-sha> <remote-ref> <remote-sha> --
FAIL=0
while read -r local_ref local_sha remote_ref remote_sha; do
  # 删除分支 (sha 全 0) 跳过
  if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
    continue
  fi

  # 仅对受保护目标分支做硬卡
  target="${remote_ref##refs/heads/}"
  if ! echo " $GATE_TARGET_BRANCHES " | grep -q " $target "; then
    echo "[pre-push-gate] 跳过非受保护分支: $target"
    continue
  fi

  echo "[pre-push-gate] 对 $target 执行确定性质量门..."

  # ---- 检查1: 静态分析 (PMD) -------------------------------------------------
  if [ -z "$PMD_CMD" ]; then
    echo "[pre-push-gate][WARN] PMD_CMD 未配置 → 骨架占位，未执行静态分析"
  else
    echo "[pre-push-gate] 运行静态分析: $PMD_CMD"
    if ! eval "$PMD_CMD"; then FAIL=1; fi
  fi

  # ---- 检查2: 单元测试覆盖率 -------------------------------------------------
  if [ -z "$COVERAGE_CMD" ]; then
    echo "[pre-push-gate][WARN] COVERAGE_CMD 未配置 → 骨架占位，未执行覆盖率检查"
  else
    echo "[pre-push-gate] 运行覆盖率: $COVERAGE_CMD (下限 ${COVERAGE_MIN}%)"
    if ! eval "$COVERAGE_CMD"; then FAIL=1; fi
    # TODO: 解析覆盖率报告并与 COVERAGE_MIN 比对（项目格式相关）
  fi

  # ---- 检查3(占位): 禁止直接 push 到受保护分支已由分支保护兜底 --------------
  # 此处仅作本地防御；真正拦截靠「分支保护 + CI required checks」

  # ---- 检查4(K1): 流程态 ↔ version-lock 一致性 ---------------------------
  # status-tracker 七字段「需求流程态」与 artifact-graph version-lock「结构/版本态」
  # 须对账一致（同一变更包的状态、版本、副作用挂账一致）。不一致即 FAIL。
  STATUS_TRACKER_PP="${STATUS_TRACKER:-requirement/status-tracker.md}"
  VERSION_LOCK_PP="${VERSION_LOCK:-artifacts/traceability-version-lock.json}"
  if [ ! -e "$STATUS_TRACKER_PP" ] || [ ! -e "$VERSION_LOCK_PP" ]; then
    echo "[pre-push-gate][WARN] 一致性校验跳过：status-tracker($STATUS_TRACKER_PP) 或 version-lock($VERSION_LOCK_PP) 缺失"
  else
    echo "[pre-push-gate] 校验 流程态 ↔ version-lock 一致性（占位，待补解析器）"
    # TODO: 解析 status-tracker.phase/state 与 version-lock 的版本/副作用挂账，
    #       比对同一变更包是否一致；不一致 FAIL=1（SAFE_MODE=0 时非零退出）。
  fi
done

# ---- 结论 --------------------------------------------------------------------
if [ "$FAIL" -ne 0 ]; then
  if [ "$SAFE_MODE" -eq 0 ]; then
    echo "[pre-push-gate] ❌ 质量门未通过，拒绝 push（SAFE_MODE=0 硬卡）"
    exit 1
  else
    echo "[pre-push-gate] ⚠️ 质量门发现问题（SAFE_MODE=1 仅告警，未阻断）"
    echo "[pre-push-gate]    真实落地请将 SAFE_MODE=0 并设置 PMD_CMD/COVERAGE_CMD"
    exit 0
  fi
fi

echo "[pre-push-gate] ✅ 确定性质量门通过"
exit 0
