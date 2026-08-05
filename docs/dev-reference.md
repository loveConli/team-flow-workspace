# 开发参考

> 本文件从 CLAUDE.md 抽取（2026-07-25），按需加载。

## 常用开发命令

```bash
# 在 team-flow/ 目录下执行
cd team-flow

# 构建
npm run build

# 运行测试
npm test

# 验证产物
npm run validate

# 检查版本一致性
npm run check-versions

# v0.11.0 新增 CLI 命令
ssf prototype-sync <change-dir> [--source <path>]   # UX 增量回写全局 prototype/
ssf solutions index-gen                              # 重建复利索引
ssf solutions inject --phase <p> --domain <d>        # 阶段感知注入（top-5）
ssf solutions capture --phase <p> --domain <d> --type <t> --severity <s> --summary <text>  # 捕获经验
ssf solutions promote <change-dir>                   # change→product 晋升

# v0.37.0 新增 CLI 命令（tf 前缀）
tf publish <--prd|--arch|--changes <dir>|--all> [--push] [--dry-run]   # 阶段产物白名单提交 + 可选推送（§68.3）
tf prototype branch <prd-vN>                         # 原型版本 worktree 创建/复用（隔离 + 团队拉取，§68.4）
tf prototype deisolate <prd-vN> [--merge] [--clean]  # 版本收尾：merge 回主干 + 清理（§68.4）
```

## 全局产物结构

```
.team-flow/        状态文件（v0.15.0，原 .workflow-orchestrator.yaml 迁入）
  ├── registry.yaml             # 需求注册表（多需求并行 + active_requirement）
  ├── requirements/<req-id>/orchestrator.yaml  # 每需求产品级编排状态
  ├── handoffs/                 # 会话交接文档（v0.16.0，session-handoff 产出，.gitignore）
  └── feedback/                 # 工作流问题记录（v0.16.0，workflow-feedback 产出，git 跟踪）
changes/<name>/    变更级工作目录（S4 创建，项目根下，不是 .team-flow/changes/）
  ├── proposal.md / design.md / tasks.md / specs/ / execution-contract.md
  ├── .spec-superflow.yaml      # 变更级状态（v1.0.0 改名 .team-flow.yaml）
  └── .superpowers/sdd/         # 执行 overlay（plan/checkpoints/handoffs/reviews）
prd/               PRD + 实施方案 + 原型审查记录（v1→v2，分支隔离）
  └── vN/
      ├── prd.md              # 业务要件（ce-brainstorm 产出）
      ├── plan.md             # 实施方案（ce-plan 产出，产品级策略）
      ├── prototype-review.md # 原型审查记录（PRD 内循环产出）
      ├── prototype-auto-review.md # 原型自动评审报告（prototype-reviewer agent 产出）
      └── prd-completeness-review.md # PRD 完整性评审报告（prd-completeness-reviewer 产出）
prototype/         全局原型（UI 契约真相源，git 分支隔离）
docs/
  ├── architecture/  全局架构锚点（ARCHITECTURE.md / DATABASE.md / <bc>/）
  └── solutions/     复利经验库（v0.11.0，三层索引）
      ├── INDEX.md   # L1 轻量索引（≤150行）
      └── prd/ plan/ prototype/ spec/ build/ review/ cross-phase/
specs/<cap>/       每变更设计/任务/契约 + learnings.md（候选晋升）
STRATEGY.md        策略文档
CONCEPTS.md        领域词汇
```

## 配置

项目根 `spec-superflow.config.json` 可注入扩展字段：

```json
{
  "prd.template": ".team-flow/prd.template.md",
  "prototype.designSystem": "prototype/design-system.md",
  "prototype.entry": "prototype/index.html"
}
```
