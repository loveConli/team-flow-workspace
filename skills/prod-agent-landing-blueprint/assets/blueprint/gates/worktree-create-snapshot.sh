#!/usr/bin/env bash
# ============================================================================
# worktree-create-snapshot.sh — 三线快照 WorktreeCreate hook (骨架)
# 报告引用: §8.3 / §10.4 硬门禁边界表 / §10.4 变更前基线快照时机
# 形态: WorktreeCreate hook（exit ≠ 0 中止创建）；先快照后干活
# 三线 = 需求基线 / 配置基线 / 测试基线（冻结变更前基线，供升级后比对）
# WAITING_USER: 若任一基线未就绪 → 中止创建，提示补齐基线再快照
# ----------------------------------------------------------------------------
# 前置资产依赖: Git hook 配置 + 三线基线文件 + 架构注册表(配置基线来源)
# 当前环境: 否（sandbox 无真实 requirement/ 与架构注册表）；SAFE_MODE=1 可空跑
# 缺什么: REQ_BASELINE/CFG_BASELINE/TEST_BASELINE 真实路径、架构注册表
# 标签: 【落地待验证⚠️】
# ----------------------------------------------------------------------------
# 评审 P0-A 标注: 真实环境必须把 SAFE_MODE 置 0（fail-closed），基线缺失即中止
#           创建（exit 1），**不能长期 warn-only**；插件 fail-closed 可作模板。
# ============================================================================
set -uo pipefail

WORKTREE_PATH="${1:-}"
if [ -z "$WORKTREE_PATH" ]; then
  echo "[three-line-snapshot] 用法: $0 <worktree-path>"; exit 2
fi

# ---- 三线基线路径（真实环境必填；骨架默认占位）------------------------------
REQ_BASELINE="${REQ_BASELINE:-requirement/status-tracker.md}"   # 需求基线
CFG_BASELINE="${CFG_BASELINE:-arch-registry/module-map.json}"    # 配置基线(来自架构注册表)
TEST_BASELINE="${TEST_BASELINE:-tests/}"                        # 测试基线

SAFE_MODE="${SAFE_MODE:-1}"
SNAP_FILE="${WORKTREE_PATH}/.three-line-snapshot.json"

# ---- 校验三线基线就绪 --------------------------------------------------------
missing=0
for f in "$REQ_BASELINE" "$CFG_BASELINE" "$TEST_BASELINE"; do
  if [ ! -e "$f" ]; then
    echo "[three-line-snapshot][WAITING_USER] 基线未就绪: $f —— 请先补齐基线再创建 worktree"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  if [ "$SAFE_MODE" -eq 0 ]; then
    echo "[three-line-snapshot] ❌ 基线缺失，中止 worktree 创建 (exit 1)"
    exit 1   # 中止创建
  else
    echo "[three-line-snapshot] ⚠️ 基线缺失但 SAFE_MODE=1 → 仅告警，未中止（骨架空跑）"
  fi
fi

# ---- 捕获三线快照（变更前基线，防污染）--------------------------------------
git_rev=$(git rev-parse HEAD 2>/dev/null || echo "no-git")
req_hash=$(sha256sum "$REQ_BASELINE" 2>/dev/null | cut -d' ' -f1 || echo "n/a")
cfg_hash=$(sha256sum "$CFG_BASELINE" 2>/dev/null | cut -d' ' -f1 || echo "n/a")
tst_hash=$(sha256sum "$TEST_BASELINE" 2>/dev/null | cut -d' ' -f1 || echo "n/a")

cat > "$SNAP_FILE" <<EOF
{
  "snapshot_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_rev": "$git_rev",
  "requirement_baseline": {"path": "$REQ_BASELINE", "sha256": "$req_hash"},
  "config_baseline":      {"path": "$CFG_BASELINE", "sha256": "$cfg_hash"},
  "test_baseline":        {"path": "$TEST_BASELINE", "sha256": "$tst_hash"},
  "note": "变更前冻结基线，供升级后 ECO 比对"
}
EOF

echo "[three-line-snapshot] ✅ 三线快照已写入 $SNAP_FILE"
exit 0
