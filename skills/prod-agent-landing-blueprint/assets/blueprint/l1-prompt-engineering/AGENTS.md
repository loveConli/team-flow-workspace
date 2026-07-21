# AGENTS.md — 面向 Agents 的持久提示层骨架

> 报告引用: §3 / §5.10 六组件之 AGENTS.md（Codex 等价物）
> 定位: 面向 Agents 的 README。Codex 的 AGENTS.md 是 Claude 的 CLAUDE.md 的等价物。
> 分层加载: ~/.codex/AGENTS.md → 仓库根目录 → 子目录级
> 标签: 【来源已核验✅】

## 仓库结构与关键目录（按实际项目修改）
- **代码目录**: `[SRC_DIR]`
- **测试目录**: `[TEST_DIR]`
- **设计文档目录**: `design/`（含 plan.md / spec.md）
- **需求上下文目录**: `requirement/`（含 status-tracker.md，**需求流程态真相源**；与 artifact-graph（结构/追溯/版本真相源）并存，不互相替代）
- **长期 wiki 目录**: `docs/wiki/`（稳定业务知识，master 分支）
- **项目记忆目录**: `memory/`（过程材料：CR 评论、验收记录、自恢复日志）

## 如何运行项目（按实际项目修改）
- **开发环境启动**: `[RUN_CMD]`
- **构建**: `[BUILD_CMD]`
- **测试**: `[TEST_CMD]`
- **Lint**: `[LINT_CMD]`
- **覆盖率**: `[COVERAGE_CMD]`（输出路径须与 CI 对齐）

## 工程规范与 PR 期望（按实际项目修改）
- **SDD 三文档**: 每个需求须产出 `spec.md` → `plan.md` → `tasks.md`（见 `l1-prompt-engineering/sdd-templates/`）
- **质量门禁**: pre-push gate（PMD + 覆盖率）→ eco-gate（ECO 校验）→ CI required checks（全量）
- **分支保护**: `main/master/release` 禁止直接 push；合并须经 CI green
- **合并代理**: 所有主干写入由合并代理执行（见 `l5-agent-team/03-merge-agent.md`），冲突抛 WAITING_USER

## 约束与禁止模式（按实际项目修改）
- ❌ 无 spec.md 即开始实现
- ❌ 无 plan.md 即开始编码
- ❌ 无测试的代码变更 push 到受保护分支
- ❌ 修改聚合根（限界上下文核心实体）不走 ECO 闭环（变更包冻结 + 三线快照 + 审计总账闭合）
- ❌ Agent 直接 `git push` 到 `main`（须过 eco-gate PreToolUse deny）

## 完成标准与验证步骤（按实际项目修改）
1. 需求澄清 → 人工确认 → 状态机 `CLARIFYING` → `DESIGNING`
2. 技术方案 → CR 确认 → 状态机 `DESIGNING` → `IMPLEMENTING`
3. 实现 → TDD（先测试后代码）→ pre-push gate → 状态机 `IMPLEMENTING` → `TESTING`
4. 测试 → CI green → eco-gate 校验 → 状态机 `TESTING` → `REVIEWING`
5. 评审 → 所有 CR 评论 resolve → 状态机 `REVIEWING` → `VERIFYING`
6. 验证 → 人工确认 → 状态机 `VERIFYING` → `RELEASING`
7. 发布 → 观察期无异常 → 结项蒸馏 → 状态机 `RELEASING` → `CLOSED`

## 角色定位（按实际项目修改）
- **Agent 当前角色**: 单 Agent 全栈（后续演进为 Agent Team：前端/后端/测试 + 协调者）
- **权限模式**: `default`（交互式开发，危险操作需确认）或 `acceptEdits`（自动化脚本）
- **上下文策略**: 五种策展（Retrieve/Reduce/Isolate/Compact/Permission），见 `l2-context-engineering/01-strategies.md`

---
> 此文件为**骨架**。真实项目需按实际仓库结构、构建命令、工程规范填充。
> 建议与 CLAUDE.md 保持同步，但面向 Codex/Agent 视角。
