# P2 实施会话提示词

## 使用方式

在新的 Claude Code 会话中，将以下内容作为第一条消息发送：

---

工作目录: /Users/finley/Desktop/AI/teamflow/team-flow-workspace

目标: 执行 ce-brainstorm 证据链补全的 P2 实施（L3 执行阶段）

工作模式:
你（主会话）只做任务编排和进度总结，不要自己执行具体工作。
所有执行操作（写代码、改文件、跑命令等）必须拉起 sub-agent 完成。
你的职责：拆解任务 → 分配给 sub-agent → 验收结果 → 向用户汇报进度。

已完成:
- 设计规划 v0.4 + 6 项修订已通过确认
- 规划文件：docs/plan/ce-brainstorm-evidence-chain-enhancement.md
- L2 任务拆解 v2 已完成，8 个 task 文档已保存

必读文件（按顺序）:
1. docs/plan/ce-brainstorm-evidence-chain-enhancement.md — 设计规划（唯一真相源）
2. docs/plan/evidence-chain-tasks/T1-business-scenarios.md — T1 任务定义
3. docs/plan/evidence-chain-tasks/T2-business-processes.md — T2 任务定义
4. docs/plan/evidence-chain-tasks/T3-evidence-chain-validation.md — T3 任务定义
5. docs/plan/evidence-chain-tasks/T4-skill-md.md — T4 任务定义
6. docs/plan/evidence-chain-tasks/T5-brainstorm-sections.md — T5 任务定义
7. docs/plan/evidence-chain-tasks/T6-prd-mapping.md — T6 任务定义
8. docs/plan/evidence-chain-tasks/T7-synthesis-summary.md — T7 任务定义
9. docs/plan/evidence-chain-tasks/T8-phase0-routing.md — T8 任务定义

执行计划:
1. 读取设计规划和 8 个 task 文档
2. 按批次启动 L3 sub-agent：
   - Batch 1（并行）：T1 + T2 + T3（三个新 reference）
   - Batch 2（串行）：T4（修改 SKILL.md，依赖 Batch 1）
   - Batch 3（并行）：T5 + T6 + T7 + T8（修改四个 reference，依赖 Batch 2）
3. 每个 task 完成后验收（对照 task 文档中的验收标准）
4. 全部完成后执行 P3 代码审查：
   ① git diff --stat 变更清单确认（每个文件改动属于本次迭代范围）
   ② 上下游影响分析（SKILL.md 改了流程 → references/ 是否同步？agent frontmatter 变更 → 子代理行为受影响？）
   ③ 跨文件一致性（命名、术语、版本号、行号引用）
   ④ 设计-代码对齐（实现与设计规划一致）
   ⑤ 横展检查（本次解决的问题是否在类似区域存在同类问题）
   ⑥ 制品链关联校验（制品结构/位置变更时遍历所有引用点）
   P3 审查通过后才进 P4
5. P4 验证：
   ① plugin-validator
   ② skill-reviewer
   ③ check-versions
   ④ npm test

约束:
- 主会话不直接写文件，所有文件创建/修改通过 L3 sub-agent 执行
- 目录使用 requirement/（不是 prd/）
- 状态只有 🔵待确认 / ✅已确认
- 流程分类层级：L1分组 → L2分类 → L3流程 → L4子流程
- 每个版本目录只存增量，台账（ledger.md）存全量且每个 ID 只有一条记录
- Phase 1.5/1.6 确认时只写 business-analysis.md，不更新台账（台账在版本归档时批量写入）
- 活动一览表 9 列（含"执行步骤"）
- 不变更的 13 个 reference 文件不要碰（见设计规划 §8.3）
- doc/active-registry/ 是顶层 doc/ 目录（不是 requirement/doc/）
- P3 代码审查未通过（存在未修复的审查项）→ 不进 P4 验证

跨 Task 一致性检查点:
1. 台账写入时机：T1/T2/T3 中"不更新台账"和"版本归档时批量写入"描述一致
2. 弃用三步骤：T1/T2/T3 中弃用处理描述一致
3. QA 路由模式：T1(QA-1)/T2(QA-2)/T3(QA-4) 的 PASS/FAIL 路由格式一致
4. 状态枚举：只有 🔵/✅
5. 目录路径：统一 requirement/vN/
6. L4 层级：L3 是 L4 集合
7. active-registry：doc/active-registry/（顶层）
8. SKILL.md 引用：Phase→reference 文件名对应

版本信息:
- 当前插件版本：v0.39.0（以 package.json 为准，CLAUDE.md 可能滞后）
- 设计增强方案：v0.16（与 ce-brainstorm 证据链补全无关，不影响本任务）

---
