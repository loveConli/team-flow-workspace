#!/usr/bin/env bash
# ============================================================================
# gtmc-phase35-check.sh — gtmc Phase3.5 业务流程校准证据（gtmc 专属 overlay）
# 仅 GTMC_PROJECT=true 时由 required-checks.yml 挂载（不进通用默认清单）
# 默认 SAFE_MODE=1；真实 CI 须 SAFE_MODE=0。
# ============================================================================
set -uo pipefail

SAFE_MODE="${SAFE_MODE:-1}"
EVIDENCE="${GTMC_PHASE35_EVIDENCE:-gtmc/phase35-calibration.md}"

if [ ! -e "$EVIDENCE" ]; then
  echo "[gtmc-phase35][FAIL] Phase3.5 校准证据缺失: $EVIDENCE"
  if [ "$SAFE_MODE" -eq 0 ]; then exit 1; else echo "[WARN] SAFE_MODE=1 仅告警"; exit 0; fi
fi

# TODO: 校验证据内容（校准结论/签名/版本）符合 Phase3.5 业务流程定义
echo "[gtmc-phase35] 校准证据存在: $EVIDENCE（内容校验占位待补）"
exit 0
