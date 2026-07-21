# 降级通道汇总（针对【落地待验证⚠️】项，不阻塞主链路）

> 报告引用: §10.1.1 / §10.4（P0-1 / P0-4 补强）/ 标签体系说明
> 原则: 凡标注「落地待验证⚠️」者，执行依赖 P0 级前置资产（Git hook + 分支保护 + CI required checks + 架构注册表）；
>       缺失则走降级通道，主链路（pre-push 确定性检查 + CI required checks）照常推进。

> 🔴 **CI backstop 前置条件（评审 P0-A / P1，已更新 2026-07-12）**：本包 `ci/required-checks.yml` 引用的 5 个脚本已落地**最小可用框架**（位于 `scripts/`，含硬依赖缺失即非零退出反绕过）。覆盖率解析 / 闭合对账 / 审计 hash 链 / gtmc 内容校验仍属 TODO 占位，须按真实项目格式补全解析器。**仍须**将这些 job 在 Branch Protection 注册为 required status checks（并设置 `SAFE_MODE=0`），本地 Hook 被绕过时的 CI backstop 方能真正「兜得住」——否则降级通道仍近似空壳。详见 `ci/required-checks.yml` 顶部注记。

## 1. 架构注册表缺失（聚合根→文件映射 / 发布态架构制品目录 / 跨组织消费方依赖图）
- 影响: `scope-classifier` 精度下降，升级路由判定退化。
- 降级: 走「人工兜底」（§10.1.1 缺失期降级方案）；scope-classifier 精度下降须**限期补基建**。
- 不阻塞: 主链路门禁仍按现状运行，仅 scope 判定降级为人工。

## 2. 三层影响面枚举 · 隐式层
- 影响: 隐式层（非显式代码依赖）无法自动枚举。
- 降级: 隐式层**须人工兜底**（§10.4 P0-4 补强）。

## 3. 跨域契约一致性校验 + 消费方确认
- 影响: 跨组织消费方依赖图缺失时无法自动校验。
- 降级: 改由**人工确认 fallback**（消费方人工 sign-off）。

## 4. Hook 被绕过（Codex --dangerously-bypass-hook-trust / 站外 CI / gh pr merge）
- 影响: 本地 Hook（pre-push / eco-gate / 三线快照）被绕过。
- 降级（实为 backstop，非降级）: **CI required status checks** 是最终硬门禁，任何站外合并都须过 CI。
- 设计对应: 本包三道门禁均「本地 Hook + CI backstop」双保险。

## 5. 三线快照缺失（WorktreeCreate hook 未就绪）
- 影响: 无法冻结变更前基线，升级后 ECO 比对无基线。
- 降级: 升级后比对降级为**人工比对**（凭 status-tracker + 手动 diff）。

## 6. status-tracker 落地依赖 Hook 配置
- 影响: 未配 workflow-check 读取器时，无法自动只读读取机读块。
- 降级: 降级为**人工读取** status-tracker；不阻断流程。

## 7. eco-gate 不可为 skill / PostToolUse / Stop
- 约束: 阻断只能由 PreToolUse deny + CI 完成；skill 仅用于 WAITING_USER **人工判定路径**。
- 降级: 需人工判定项进入 WAITING_USER，由 eco-gate skill 辅助判定（不作阻断器）。

---
> 降级非放弃：所有降级通道均标注「须限期补 P0 前置资产」，补完后自动退出降级、恢复全自动门禁。
