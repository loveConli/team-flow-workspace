#!/usr/bin/env bash
# ============================================================================
# eco-evidence-check.sh — ECO 证据闭合校验（CI backstop，等同 eco-gate）
# 报告引用: §10.4 审计总账闭合 / 硬门禁边界表
# 校验: 变更包副作用清单 ↔ 审计事件日志 闭合（last_event_id/ci_id ↔ idempotency_key）
# 默认 SAFE_MODE=1（骨架）；真实 CI 须 SAFE_MODE=0（fail-closed）。
# ============================================================================
set -uo pipefail

SAFE_MODE="${SAFE_MODE:-1}"
STATUS_TRACKER="${STATUS_TRACKER:-requirement/status-tracker.md}"
AUDIT_LOG="${AUDIT_LOG:-memory/audit-log.jsonl}"

FAIL=0
if [ ! -e "$STATUS_TRACKER" ]; then
  echo "[eco-evidence][FAIL] status-tracker 缺失: $STATUS_TRACKER"; FAIL=1
fi
if [ ! -e "$AUDIT_LOG" ]; then
  echo "[eco-evidence][FAIL] 审计日志缺失: $AUDIT_LOG"; FAIL=1
fi
if [ "$FAIL" -ne 0 ]; then
  if [ "$SAFE_MODE" -eq 0 ]; then exit 1; else echo "[WARN] SAFE_MODE=1 仅告警"; exit 0; fi
fi

# ---- 闭合对账（TODO 占位）------------------------------------------------
# 1) 解析 status-tracker 机读块 ci_id / last_event_id
# 2) 在 AUDIT_LOG 中核对对应 idempotency_key 存在且事件闭合（无未决副作用）
# 3) 不一致 → FAIL（SAFE_MODE=0 非零退出）
echo "[eco-evidence] 闭合对账占位待补（提取 ci_id/last_event_id ↔ idempotency_key）"
exit 0
