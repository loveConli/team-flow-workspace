# 文档维护规范

> 本文件从 CLAUDE.md 抽取（2026-07-25），按需加载。
> 插件迭代 P4 同步阶段必须参照本文件。

## 迭代同步清单

每次 team-flow 版本迭代（含 skill 新增/修改/删除、SOP 变更、产物结构变更、CLI 命令变更），**必须**按以下清单同步更新相关文件。遗漏任何一项视为迭代未完成。

| 变更类型                      | 必须更新的文件                                                                                                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **新增/删除 skill**           | ① 设计增强方案（新增版本文件或修订当前版本） ② `team-flow/AGENTS.md` Skills 索引表 ③ `team-flow/README.md` 能力列表 ④ `CLAUDE.md` skills 表 ⑤ `team-flow/plugin.json` description 中的 skill 计数 |
| **修改 skill 内容**（涉及能力描述变化） | ① `team-flow/AGENTS.md`（能力概览） ② 设计增强方案（如涉及 SOP/产物/集成规则变化）                                                                                                        |
| **SOP 变更**                | ① 设计增强方案（第三节 SOP 图） ② `team-flow/AGENTS.md`（标准工作流） ③ `CLAUDE.md`（工作流 SOP）                                                                                        |
| **产物结构变更**                | ① 设计增强方案（第四节产物结构） ② `team-flow/AGENTS.md`（全局产物结构） ③ `CLAUDE.md`（全局产物结构）                                                                                          |
| **CLI 命令变更**              | ① `team-flow/AGENTS.md`（Commands） ② `CLAUDE.md`（常用开发命令） ③ 设计增强方案（如涉及新脚本，第十一节）                                                                                    |
| **版本号变更**                 | ① `team-flow/package.json` ② `team-flow/plugin.json` ③ `team-flow/README.md` ④ `CLAUDE.md` ⑤ 所有 SKILL.md 中的 `npx --package spec-superflow@x.y.z` 版本引用            |
| **设计升级 / 新待办发现**          | ① `docs/roadmap-and-todos.md` Roadmap（更新里程碑） ② `docs/roadmap-and-todos.md` 待办列表（追加条目）                                                                                                            |
| **待办完成实施**                | ① `docs/roadmap-and-todos.md` 待办列表（状态改 ✅，注明完成版本/日期） ② `docs/roadmap-and-todos.md` Roadmap（对应里程碑标记 ✅）                                                                                             |

## 一致性校验要求

`npm run check-versions` 应扩展为同时校验以下一致性（当前仅校验版本号）：

1. **版本号一致性**（现有）：package.json / plugin.json / README / 各 SKILL.md
2. **skill 计数一致性**（待扩展）：plugin.json description / README / AGENTS.md / CLAUDE.md 中的 skill 数量 vs 实际 `skills/` 目录数
3. **npx 版本引用一致性**（待扩展）：所有 SKILL.md 中的 `spec-superflow@x.y.z` 应与当前 package.json version 一致
