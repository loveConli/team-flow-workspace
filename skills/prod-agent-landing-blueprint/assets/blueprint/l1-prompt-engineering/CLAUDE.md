# CLAUDE.md — 持久提示层骨架

> 报告引用: §3 / §5.10 六组件之 AGENTS.md（同源原理）
> 定位: Claude 每次会话开始时自动读取的特殊文件，提供它无法从代码推断的持久上下文。
> 分层加载: ~/.claude/CLAUDE.md → ./CLAUDE.md → ./CLAUDE.local.md → 父/子目录级
> 标签: 【来源已核验✅】

## 项目概览（请按真实项目修改）
- **项目名称**: `[PROJECT_NAME]`
- **技术栈**: `[TECH_STACK]`（例: Java 21 + Spring Boot + MySQL + Redis）
- **构建工具**: `[BUILD_TOOL]`（例: Maven, Gradle, npm, yarn）
- **运行命令**: `[RUN_CMD]`（例: `mvn spring-boot:run`, `npm run dev`）
- **测试命令**: `[TEST_CMD]`（例: `mvn test`, `npm test`）
- **Lint/格式化**: `[LINT_CMD]`（例: `mvn pmd:check`, `npm run lint`）

## 仓库结构（按实际项目修改）
```
├── src/               # 主要源码
├── tests/             # 测试
├── design/            # 设计文档
├── requirement/       # 需求上下文（Agent 产研流程专用）
├── docs/              # 长期 wiki（稳定业务知识）
└── .three-line-snapshot.json  # 三线快照（需求/配置/测试基线）
```

## 工程规范与约束（按实际项目修改）
- **代码风格**: `[CODING_STYLE]`（例: Google Java Style, Airbnb ESLint）
- **分支模型**: `[BRANCH_MODEL]`（例: Git Flow, Trunk-based）
- **PR 期望**: 所有 PR 须通过 `pre-push quality gate` + `CI required checks` + `eco-gate` ECO 校验
- **禁止模式**: ❌ 直接 push 到 `main/master/release`；❌ 无测试覆盖的代码变更；❌ 修改聚合根不走 ECO 闭环
- **完成标准**: 代码变更须附带测试 + 文档更新 + 审计日志（PostToolUse 覆盖 Write/Edit/Bash/MCP）

## 验证步骤（按实际项目修改）
1. `make build` 或 `[BUILD_CMD]` 编译通过
2. `make test` 或 `[TEST_CMD]` 测试通过且覆盖率 ≥ 阈值
3. `make lint` 或 `[LINT_CMD]` 静态分析通过
4. 变更写入 `requirement/status-tracker.md` 机读块，CI 可读取

## 角色与上下文（按实际项目修改）
- **项目类型**: 产研端到端 Agent 落地项目
- **Agent 模式**: 当前为单 Agent（后续演进为 Agent Team）
- **Harness 层级**: 当前 L3（L4 Loop 谨慎试点中）
- **上下文策展策略**: 见 `l2-context-engineering/01-strategies.md`

---
> 此文件为**骨架**。真实项目需按实际目录结构、构建命令、工程规范填充。
> 建议按团队统一维护，放入 Git 共享。
