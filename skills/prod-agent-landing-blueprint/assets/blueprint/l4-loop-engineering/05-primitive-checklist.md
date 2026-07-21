# Loop 六原语五前提检查表（L4 Loop）

> 报告引用: §6  Loop 工程 / §6.2 六阶段纵向闭环 / §5.10 六组件框架
> 定位: 验证每个 Agent 闭环是否具备 Loop 六原语和五前提。可用作 Agent 上线前的检查清单。
> 标签: 【来源已核验✅】
> 📌 **TODO / deferred（评审 P0-D）**：L4 **前期不实现**，本文件仅为「设计+骨架（不激活）」。硬约束锚点见包根 `design-contract-stub.md`，关键词：`MAX_CYCLES` / `熔断` / `独立 Judge` / `Builder 覆盖清单`。任何内容不得伪装成「已实现」。

## 六原语检查表

| # | 原语 | 英文 | 定义 | 报告出处 | 检查项 | 状态 |
|---|------|------|------|----------|--------|------|
| 1 | 指令 | instruction | Agent 该做什么 | L1 提示词工程 | [ ] CLAUDE.md 或 AGENTS.md 已定义清晰的指令 | 🔘 |
| 2 | 工具 | tools | Agent 能用什么 | L3 Harness（权限系统） | [ ] 工具白名单已配置（最小权限原则） | 🔘 |
| 3 | 上下文 | context | Agent 看到什么信息 | L2 上下文工程 | [ ] 五种策展策略已配置（Retrieve/Reduce/Isolate/Compact/Permission） | 🔘 |
| 4 | 记忆 | memory | Agent 记住什么 | L2 上下文 + L4 Loop（反馈学习） | [ ] NOTES.md 结构化笔记已启用 | 🔘 |
| 5 | 终止 | termination | Agent 何时停止 | L3 Harness（max_turns）+ L4 Loop（停止条件） | [ ] max_turns 已配置（防无限循环） | 🔘 |
| 6 | 评估 | evaluation | Agent 如何判断完成 | L4 Loop（自我验收） | [ ] 自我验收多层机制已配置（Layer 1-4） | 🔘 |

## 五前提检查表

| # | 前提 | 定义 | 报告出处 | 检查项 | 状态 |
|---|------|------|----------|--------|------|
| 1 | 清晰触发器 | 明确什么条件启动循环 | L1 提示词（skill 调度逻辑） | [ ] Skill 触发条件已定义（见 skill-dispatch-rule.md） | 🔘 |
| 2 | 可信上下文 | 上下文必须可靠且高信号 | L2 上下文工程 | [ ] 策展策略已激活（非全量加载） | 🔘 |
| 3 | 受控执行器 | 执行必须在约束范围内 | L3 Harness（权限 + 沙箱） | [ ] 权限模式已配置（非 default/bypass 滥用） | 🔘 |
| 4 | 可验证结果 | 结果必须有客观判据 | L4 Loop（自我验收） | [ ] 验收标准已定义（测试/覆盖率/人工确认） | 🔘 |
| 5 | 明确停止条件 | 必须知道何时停止循环 | L3 Harness（max_turns）+ L4 Loop（验收通过） | [ ] 停止条件已定义（验收通过/人工终止/max_turns） | 🔘 |

## 检查方法

### 逐项检查
1. 阅读 `CLAUDE.md` / `AGENTS.md` → 确认指令清晰、无歧义
2. 检查 `l3-harness-engineering/03B-permission-framework.md` → 确认权限模式配置合理
3. 检查 `l2-context-engineering/01-strategies.md` → 确认策展策略已配置
4. 检查 `memory/NOTES.md` → 确认结构化笔记正在使用
5. 检查 `CLAUDE.md` 或环境变量 → 确认 max_turns 已设置（建议 50-100 轮）
6. 检查 `l4-loop-engineering/02-self-acceptance.md` → 确认验收多层机制已配置
7. 检查 `l1-prompt-engineering/skill-dispatch-rule.md` → 确认 Skill 触发条件清晰
8. 检查静态分析结果 → 确认策展策略有效（非全量加载）
9. 检查权限审计日志 → 确认无 default/bypass 滥用
10. 检查测试覆盖率报告 → 确认有客观判据
11. 检查会话日志 → 确认 Agent 能在合理轮数内停止

### 自动检查脚本（骨架）

```bash
#!/bin/bash
# loop-primitive-check.sh — 六原语五前提自动检查

echo "=== Loop 六原语五前提自动检查 ==="

# 检查1: 指令（instruction）
if [ -f "CLAUDE.md" ] || [ -f "AGENTS.md" ]; then
  echo "✅ 指令层: CLAUDE.md 或 AGENTS.md 存在"
else
  echo "❌ 指令层: CLAUDE.md 和 AGENTS.md 均缺失"
  FAIL=1
fi

# 检查2: 工具（tools）
if [ -f "l3-harness-engineering/03B-permission-framework.md" ]; then
  echo "✅ 工具层: 权限框架已配置"
else
  echo "❌ 工具层: 权限框架未配置"
  FAIL=1
fi

# 检查3: 上下文（context）
if [ -f "l2-context-engineering/01-strategies.md" ]; then
  echo "✅ 上下文层: 策展策略已配置"
else
  echo "❌ 上下文层: 策展策略未配置"
  FAIL=1
fi

# 检查4: 记忆（memory）
if [ -f "memory/NOTES.md" ]; then
  echo "✅ 记忆层: NOTES.md 存在"
else
  echo "⚠️ 记忆层: NOTES.md 不存在（建议创建）"
fi

# 检查5: 终止（termination）
if grep -q "max_turns" "CLAUDE.md" 2>/dev/null || [ -n "$MAX_TURNS" ]; then
  echo "✅ 终止层: max_turns 已配置"
else
  echo "⚠️ 终止层: max_turns 未配置（建议设置 50-100）"
fi

# 检查6: 评估（evaluation）
if [ -f "l4-loop-engineering/02-self-acceptance.md" ]; then
  echo "✅ 评估层: 自我验收机制已配置"
else
  echo "❌ 评估层: 自我验收机制未配置"
  FAIL=1
fi

# 前提1: 清晰触发器
if [ -f "l1-prompt-engineering/skill-dispatch-rule.md" ]; then
  echo "✅ 前提1: Skill 触发条件已定义"
else
  echo "❌ 前提1: Skill 触发条件未定义"
  FAIL=1
fi

# 前提2: 可信上下文
if grep -q "Retrieve" "l2-context-engineering/01-strategies.md" 2>/dev/null; then
  echo "✅ 前提2: 策展策略包含 Retrieve（非全量加载）"
else
  echo "⚠️ 前提2: 建议配置 Retrieve 策展策略"
fi

# 前提3: 受控执行器
if grep -q "permission_mode" "l3-harness-engineering/03B-permission-framework.md" 2>/dev/null; then
  echo "✅ 前提3: 权限模式已配置"
else
  echo "❌ 前提3: 权限模式未配置"
  FAIL=1
fi

# 前提4: 可验证结果
if grep -q "coverage" "l4-loop-engineering/02-self-acceptance.md" 2>/dev/null; then
  echo "✅ 前提4: 验收标准包含可验证判据"
else
  echo "⚠️ 前提4: 建议增加可验证判据"
fi

# 前提5: 明确停止条件
if grep -q "停止" "CLAUDE.md" 2>/dev/null || grep -q "验收通过" "l4-loop-engineering/02-self-acceptance.md" 2>/dev/null; then
  echo "✅ 前提5: 停止条件已定义"
else
  echo "⚠️ 前提5: 建议明确定义停止条件"
fi

if [ "$FAIL" = "1" ]; then
  echo "
❌ 检查未通过，请先补齐缺失项"
  exit 1
else
  echo "
✅ Loop 六原语五前提检查通过"
  exit 0
fi
```

## 检查频率

| 场景 | 频率 | 触发者 |
|------|------|--------|
| 新需求启动前 | 每次 | workflow-check（自动） |
| 新 Agent/Skill 上线前 | 每次 | CI required checks（自动） |
| 季度审视 | 每季度 | 人工审查 |
| 架构变更后 | 每次 | CCB/ARB 审查 |

---
> 此文件为**检查清单**。真实项目需按实际技术栈、团队规模调整检查项和阈值。
> 建议将 `loop-primitive-check.sh` 纳入 CI，每个新 Agent 上线前自动执行。
