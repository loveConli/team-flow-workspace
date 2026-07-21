#!/usr/bin/env bash
# ============================================================================
# eco-gate.sh — ECO 双闭环确定性执行器 (PreToolUse Hook, 非 skill)
# 报告引用: §10.4 硬门禁边界表 / §10.4 确定性执行器 eco-gate
# 形态: PreToolUse deny（Bash git:*）+ CI required status check 读证据
# 约束: 不可为 PostToolUse / Stop / skill（skill 仅用于 WAITING_USER 人工判定路径）
# matcher: Bash(git:*) / git push —— 阻断未过 ECO 校验的 push/merge
# ----------------------------------------------------------------------------
# 退出码: 0 = 放行; 2 = deny(阻断)  [Claude Code PreToolUse 约定 exit 2 拒绝]
# 前置资产依赖: PreToolUse Hook 体系(Claude Code) + 架构注册表 + status-tracker 可读
# 当前环境: 否（需 Claude Code 环境 + settings.json 挂载）；SAFE_MODE=1 可空跑
# 缺什么: ECO 校验逻辑、status-tracker 路径、变更包副作用清单规范、架构注册表
# 标签: 【来源已核验✅·落地待验证⚠️】
# ----------------------------------------------------------------------------
# 评审 P0-A 门禁硬卡标注:
#  - 真实环境必须把 SAFE_MODE 置 0（fail-closed），**不能长期 warn-only**。
#  - 采纳插件「依赖缺失即非零退出」反绕过技巧：本门禁在硬依赖缺失
#    （status-tracker / ECO_TEST_REPORT / 架构注册表）时**从告警改为非零失败**。
#  - 插件 fail-closed 可作模板（参见 artifact-chain-assistant 的 hooks 行为）。
# ============================================================================
set -uo pipefail

SAFE_MODE="${SAFE_MODE:-1}"

# ---- 读取 PreToolUse 传入的 tool_input (stdin JSON) --------------------------
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:"//;s/"$//')"

# ---- 仅对 git push / merge / gh pr merge 触发 ECO 校验 -----------------------
if ! printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+(push|merge)|gh[[:space:]]+pr[[:space:]]+merge'; then
  exit 0   # 非推送/合并命令，放行
fi

echo "[eco-gate] 检测到推送/合并命令，执行 ECO 双闭环校验..."

# ---- ECO 校验项（占位，真实环境补全）----------------------------------------
# 1) CI diff 干净（无禁止变更，如直接改聚合根而不走 ECO）
# 2) 测试报告存在 (ECO_TEST_REPORT)
# 3) 证据清单完整: status-tracker 的 last_event_id / ci_id 已填，
#    且「事件日志条目」与「变更包声称的副作用清单」对账一致（§10.4 审计总账闭合）
ECO_TEST_REPORT="${ECO_TEST_REPORT:-}"
STATUS_TRACKER="${STATUS_TRACKER:-requirement/status-tracker.md}"
ARCH_REGISTRY="${ARCH_REGISTRY:-arch-registry/module-map.json}"   # 架构注册表（硬依赖之一）

# ---- 硬依赖（反绕过：缺失即非零失败）--------------------------------------
# 评审 P0-A：status-tracker / ECO_TEST_REPORT / 架构注册表 为**硬依赖**，
# 任一缺失即视为门禁失败。SAFE_MODE=0（真实）直接 deny（exit 2）；
# SAFE_MODE=1 骨架仅告警占位，但 FAIL 已置位，落地时必须置 0 才会非零退出。
FAIL=0
if [ -z "$ECO_TEST_REPORT" ] || [ ! -e "$ECO_TEST_REPORT" ]; then
  echo "[eco-gate][FAIL] 硬依赖缺失：测试报告 ($ECO_TEST_REPORT) → 非零失败（反绕过）"
  FAIL=1
fi
if [ ! -e "$STATUS_TRACKER" ]; then
  echo "[eco-gate][FAIL] 硬依赖缺失：status-tracker ($STATUS_TRACKER) → 非零失败（反绕过）"
  FAIL=1
fi
if [ ! -e "$ARCH_REGISTRY" ]; then
  echo "[eco-gate][FAIL] 硬依赖缺失：架构注册表 ($ARCH_REGISTRY) → 非零失败（反绕过）"
  FAIL=1
fi
# TODO: 解析 status-tracker 的 ci_id / last_event_id；与审计事件日志 idempotency_key 对账
# TODO(P0-A): 硬依赖缺失在 SAFE_MODE=0 必须 exit 2，不得退化为告警旁路

if [ "$FAIL" -ne 0 ]; then
  if [ "$SAFE_MODE" -eq 0 ]; then
    echo "[eco-gate] ❌ ECO 校验未通过，deny (exit 2)"
    echo "        需人工判定项请进入 WAITING_USER（由 eco-gate skill 辅助判定，不可作阻断器）"
    exit 2   # deny
  else
    echo "[eco-gate] ⚠️ ECO 校验发现问题（SAFE_MODE=1 仅告警，未阻断）"
    exit 0
  fi
fi

echo "[eco-gate] ✅ ECO 校验通过，放行推送/合并"
exit 0
