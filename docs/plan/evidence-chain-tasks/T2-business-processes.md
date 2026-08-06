# T2: business-processes.md

## 基本信息

| 属性 | 值 |
|------|-----|
| Task | T2 |
| 类型 | 新建 |
| 文件 | `team-flow/skills/ce-brainstorm/references/business-processes.md` |
| 依赖 | 无 |
| 批次 | Batch 1 |
| 预估行数 | ~160 |

## 设计规划依据

- §5.3 Phase 1.6 业务流程分析
- §4.2/§4.3 流程详情字段定义 + BP-001 完整示例
- §5.7 QA-2 process-quality-checker（9 项检查）
- §3.4 台账刷新规则
- §4.4 增量行为说明

## 输入

- 设计规划 §5.3 的 Phase 1.6 完整处理流程
- 设计规划 §4.2 的三种输出形式定义
- 设计规划 §4.3 的 BP-001 完整示例
- 设计规划 §5.7 QA-2 的 9 项检查项
- 现有 reference 文件风格参考

## 输出内容结构

1. Phase 1.6 触发条件与输入
2. Step 1: 从场景推导流程（BPMN 思维）
3. Step 2: 对比既有流程（ledger.md + business-analysis.md）
4. Step 3: 结构化输出（L1-L4 分类 + mermaid 流程图 + 活动一览表 9 列）
5. Step 4: 反向引用更新（写入 business-analysis.md，不入台账）
6. Step 4.5: QA-2 触发与路由（9 项检查 C1-C9）
7. Step 5: 展示与确认（blocking question）
8. 写入规则（不更新台账）
9. 弃用处理
10. 活动一览表格式规范（9 列缺一不可）

## 验收标准

- [ ] Phase 1.6 完整 Step 1-5 流程
- [ ] L1-L4 层级关系正确（L3 是 L4 集合）
- [ ] 三种输出形式完整
- [ ] 活动一览表 9 列（含"执行步骤"）
- [ ] QA-2 的 9 项检查项（C1-C9）全部列出
- [ ] 反向引用规则完整
- [ ] 台账规则与 §3.4 一致
- [ ] ≤150 行（或 ≤170 行）

## 关键约束

- 活动一览表 9 列是硬约束
- L4 是最小记录单位
- mermaid 必须按角色泳道分区
- 异常处理覆盖所有异常分支
