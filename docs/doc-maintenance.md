# 文档维护规范

> 本文件从 CLAUDE.md 抽取（2026-07-25），按需加载。
> **更新说明（2026-07-25）**：同步清单已由 pre-commit hook 自动化，本文件保留校验规则说明。

## 自动化同步（pre-commit hook）

版本一致性检查和修复已由 `pre-commit hook` 自动完成：

- **触发时机**：每次 `git commit` 时自动运行
- **自动修复**：skill 计数 + npx 引用
- **手动检查**：`npm run check-versions`
- **修复模式**：`npm run check-versions -- --fix`
- **绕过方式**：`git commit --no-verify`（仅限紧急情况）

## 手动维护事项（版本发布时）

以下事项需要在**版本发布时**手动处理：

| 事项 | 操作 |
|------|------|
| **设计增强方案** | 重大设计变更时创建新版本文件（如 v0.8 → v0.9） |
| **Roadmap 更新** | 更新里程碑状态（✅ + 完成版本/日期） |
| **待办列表** | 完成的待办标记 ✅ + 日期，新增待办追加行 |
| **CHANGELOG.md** | 记录本版本的变更内容 |

## 一致性校验规则

`npm run check-versions` 校验以下一致性：

1. **版本号一致性**：package.json / plugin.json / README / 各 SKILL.md
2. **skill 计数一致性**：plugin.json description / README / AGENTS.md 中的 skill 数量 vs 实际 `skills/` 目录数
3. **npx 版本引用一致性**：所有 SKILL.md 和 references/*.md 中的 `spec-superflow@x.y.z` 应与当前 package.json version 一致

## 变更类型与处理方式

| 变更类型 | 自动处理 | 手动处理 |
|---------|---------|---------|
| **版本号变更** | ✅ hook 检查 | `npm version` 触发 |
| **新增/删除 skill** | ✅ hook 更新计数 | 更新 AGENTS.md Skills 索引表（能力描述） |
| **npx 引用过期** | ✅ hook 自动修复 | — |
| **SOP/产物结构变更** | — | 更新设计增强方案 + AGENTS.md |
| **设计升级** | — | 创建新版本设计文档 |
