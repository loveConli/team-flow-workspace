# T4: SKILL.md

## 基本信息

| 属性 | 值 |
|------|-----|
| Task | T4 |
| 类型 | 修改 |
| 文件 | `team-flow/skills/ce-brainstorm/SKILL.md` |
| 依赖 | T1+T2+T3（Batch 1） |
| 批次 | Batch 2 |
| 预估行数 | +80 |

## 设计规划依据

- §5.1-5.7 全部 Phase
- §2.1 状态管理
- §3.1 目录结构
- §8.2 文件变更清单

## 输入

- 设计规划 §5.1-5.7 全部 Phase 定义
- 设计规划 §2.1 状态管理 + 台账规则 + 弃用处理
- 设计规划 §3.1 目录结构
- 当前 SKILL.md

## 输出内容结构（修改点）

1. Phase 1.3 后插入 Phase 1.4（对话日志持久化）
2. Phase 1.4 后插入 Phase 1.5（业务场景分析 + QA-1）→ 引用 `references/business-scenarios.md`
3. Phase 1.5 后插入 Phase 1.6（业务流程分析 + QA-2）→ 引用 `references/business-processes.md`
4. Phase 2.5 更新（QA-3 触发时机 + 引用场景/流程 ID）
5. Phase 3 更新输入（+ledger.md / +dialogue-log.md / +business-analysis.md）
6. Phase 3 后插入 QA-4 + Phase 3.6（双向验证）→ 引用 `references/evidence-chain-validation.md`
7. Phase 3.6 后插入版本归档步骤
8. 制品结构更新（requirement/vN/ 目录说明）
9. 弃用机制说明

## 验收标准

- [ ] Phase 1.4/1.5/1.6/3.6 全部插入，顺序与 §1.2 一致
- [ ] 每个新 Phase 引用对应 reference
- [ ] Phase 3 三个新增输入列出
- [ ] 版本归档步骤在 3.6 后、Phase 4 前
- [ ] 制品结构包含 requirement/vN/
- [ ] 弃用机制说明完整
- [ ] 现有 Phase 内容未被意外修改
- [ ] orchestrated 模式下 3.5 跳过但 1.5/1.6/3.6/版本归档正常

## 关键约束

- Phase 1.5/1.6 有 blocking question
- Phase 3.6 和版本归档是自动化
- 版本归档前置检查不通过则不执行
- 不改变 Core Principles / Interaction Rules
