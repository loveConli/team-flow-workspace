#!/usr/bin/env bash
# ============================================================================
# audit-closure-check.sh — 审计日志 append-only 闭合校验（CI backstop）
# 报告引用: §10.4 审计总账 / append-only 日志
# 校验: 每行合法 JSON + prev_hash 链连续 + 末行无后续写（防篡改）
# 默认 SAFE_MODE=1（骨架）；真实 CI 须 SAFE_MODE=0（fail-closed）。
# ============================================================================
set -uo pipefail

SAFE_MODE="${SAFE_MODE:-1}"
AUDIT_LOG="${AUDIT_LOG:-memory/audit-log.jsonl}"

if [ ! -e "$AUDIT_LOG" ]; then
  echo "[audit-closure][FAIL] 审计日志缺失: $AUDIT_LOG"
  if [ "$SAFE_MODE" -eq 0 ]; then exit 1; else echo "[WARN] SAFE_MODE=1 仅告警"; exit 0; fi
fi

# ---- append-only 闭合校验（TODO 占位）------------------------------------
# 1) 逐行 json 合法性（jq empty）
# 2) prev_hash 链：每行 prev_hash == 上一行 hash（SHA256 链）
# 3) 末行之后无新增写（无 truncate+append 痕迹）
echo "[audit-closure] append-only 闭合校验占位待补（prev_hash 链 + JSON 合法性）"
exit 0
