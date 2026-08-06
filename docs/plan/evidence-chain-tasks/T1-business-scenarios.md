# T1: business-scenarios.md

## 基本信息

| 属性 | 值 |
|------|-----|
| Task | T1 |
| 类型 | 新建 |
| 文件 | `team-flow/skills/ce-brainstorm/references/business-scenarios.md` |
| 依赖 | 无 |
| 批次 | Batch 1 |
| 预估行数 | ~140 |

## 设计规划依据

- §5.2 Phase 1.5 业务场景分析
- §4.2 场景详情字段定义（六维结构表）
- §5.7 QA-1 scenario-quality-checker（7 项检查）
- §2.1 弃用处理
- §3.4 台账刷新规则（场景确认后不更新台账）

## 输入

- 设计规划 §5.2 的 Phase 1.5 完整处理流程
- 设计规划 §4.2 的场景详情字段定义（属性表 + 六维结构 + 条目变更历史）
- 设计规划 §5.7 QA-1 的 7 项检查项和输出格式
- 设计规划 §2.1 的弃用处理三步骤
- 设计规划 §3.4 台账刷新规则
- 现有 reference 文件风格参考（如 `grounding.md`）

## 输出内容结构

1. Phase 1.5 触发条件与输入
2. Step 1: 从对话日志提取候选场景
3. Step 2: 对比既有场景（ledger.md 既有归档 + business-analysis.md 本版本）
4. Step 3: 六维结构化（角色/目标/触发/前置/约束/验收）
5. Step 3.5: QA-1 触发与路由（7 项检查 C1-C7，PASS→Step 4，FAIL→返回 Step 3，最多 3 轮）
6. Step 4: 展示与确认（blocking question）
7. 写入规则（确认后写入 business-analysis.md，不更新台账）
8. 弃用处理（ledger 删除 + business-analysis 删除 + active-registry 更新）

## 验收标准

- [ ] 包含 Phase 1.5 完整 Step 1-4 流程
- [ ] 六维结构格式与 §4.2 一致
- [ ] QA-1 的 7 项检查项（C1-C7）全部列出，Error/Warning 级别正确
- [ ] QA-1 路由规则：PASS→Step 4，FAIL→返回 Step 3，最多 3 轮
- [ ] 台账规则：场景确认后只写 business-analysis.md，不更新台账
- [ ] 弃用三步骤完整
- [ ] 状态只有 🔵待确认 / ✅已确认
- [ ] ≤150 行
- [ ] 风格与现有 reference 一致

## 关键约束

- 不写 SKILL.md 已有的 Interaction Rules / Core Principles
- 不定义 QA-1 的完整 prompt，只写触发条件、检查维度、路由规则
- 目录用 `requirement/`
