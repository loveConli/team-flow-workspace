#!/usr/bin/env bash
# ============================================================================
# check-coverage.sh — 覆盖率门禁（CI backstop，等同 pre-push 检查2）
# 报告引用: §8 Pipeline / §10.4 硬门禁边界表
# 形态: CI required status check（本地 hook 被绕过时的 backstop）
# 默认 SAFE_MODE=1（骨架可空跑）；真实 CI 须设 SAFE_MODE=0（fail-closed）。
# 注: 覆盖率解析器为 TODO 占位，须按真实项目格式（jacoco/xml/lcov）补全后才真生效。
# ============================================================================
set -uo pipefail

COVERAGE_MIN="${COVERAGE_MIN:-80}"
COVERAGE_REPORT="${COVERAGE_REPORT:-coverage/report.txt}"
SAFE_MODE="${SAFE_MODE:-1}"

# ---- 硬依赖（缺失即非零失败，反绕过）-------------------------------------
if [ ! -e "$COVERAGE_REPORT" ]; then
  echo "[check-coverage][FAIL] 覆盖率报告缺失: $COVERAGE_REPORT"
  if [ "$SAFE_MODE" -eq 0 ]; then exit 1; else echo "[WARN] SAFE_MODE=1 仅告警"; exit 0; fi
fi

# ---- 解析覆盖率数值（TODO 占位：项目格式相关）---------------------------
# 例: jacoco → xml 中 <counter type="INSTRUCTION" missed=.. covered=..>
#      lcov  → grep '^LF:' / '^LH:'
# COVERAGE_VAL="$(parse_coverage "$COVERAGE_REPORT")"
COVERAGE_VAL=""
if [ -z "$COVERAGE_VAL" ]; then
  echo "[check-coverage][WARN] 覆盖率解析器未实现（TODO 占位）→ 须补全解析逻辑"
  if [ "$SAFE_MODE" -eq 0 ]; then
    echo "[check-coverage] ❌ 真实环境 SAFE_MODE=0 下解析器缺失=门禁失效，须先补全"
    exit 1
  fi
  exit 0
fi

# ---- 比对下限（TODO 占位）-----------------------------------------------
# awk -v v="$COVERAGE_VAL" -v m="$COVERAGE_MIN" 'BEGIN{exit !(v+0 >= m+0)}'
echo "[check-coverage] 覆盖率 ${COVERAGE_VAL}% >= 下限 ${COVERAGE_MIN}% ? (比对占位待补)"
exit 0
