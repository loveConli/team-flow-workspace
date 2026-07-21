#!/usr/bin/env bash
# ============================================================================
# gtmc-a516-check.sh — gtmc A-5.16 用户手册终验签署件（gtmc 专属 overlay）
# 仅 GTMC_PROJECT=true 时由 required-checks.yml 挂载。默认 SAFE_MODE=1；真实 CI 须 SAFE_MODE=0。
# ============================================================================
set -uo pipefail

SAFE_MODE="${SAFE_MODE:-1}"
EVIDENCE="${GTMC_A516_EVIDENCE:-gtmc/a516-final-signoff.md}"

if [ ! -e "$EVIDENCE" ]; then
  echo "[gtmc-a516][FAIL] A-5.16 用户手册终验签署件缺失: $EVIDENCE"
  if [ "$SAFE_MODE" -eq 0 ]; then exit 1; else echo "[WARN] SAFE_MODE=1 仅告警"; exit 0; fi
fi

# TODO: 校验签署件含终验签名/日期/版本，匹配 A-5.16 规范
echo "[gtmc-a516] 终验签署件存在: $EVIDENCE（内容校验占位待补）"
exit 0
