# T3: evidence-chain-validation.md

## 基本信息

| 属性 | 值 |
|------|-----|
| Task | T3 |
| 类型 | 新建 |
| 文件 | `team-flow/skills/ce-brainstorm/references/evidence-chain-validation.md` |
| 依赖 | 无 |
| 批次 | Batch 1 |
| 预估行数 | ~130 |

## 设计规划依据

- §5.5 Phase 3.6 双向验证
- §5.6 版本归档
- §5.7 QA-4 prd-quality-checker（8 项检查）
- §2.2 复利归档后同步更新

## 输入

- 设计规划 §5.5 五验证维度
- 设计规划 §5.6 版本归档完整流程
- 设计规划 §5.7 QA-4 的 8 项检查项
- 设计规划 §2.2 复利归档同步更新

## 输出内容结构

1. Phase 3.6 触发条件与输入
2. QA-4 触发与路由（8 项检查 C1-C8，Phase 3 后、3.6 前）
3. 五验证维度（V1-V5）详细说明
4. 验证结论与路由（PASS/CONDITIONAL_PASS/FAIL）
5. 版本归档（前置检查 4 项 + 处理 4 步 + 输出）
6. 版本归档后的下游入口（→ ce-plan）

## 验收标准

- [ ] V1-V5 完整列出
- [ ] QA-4 的 8 项检查项（C1-C8）完整
- [ ] 三种结论路由完整
- [ ] 版本归档前置检查 4 项完整
- [ ] 版本归档处理 4 步完整
- [ ] 台账批量写入规则正确
- [ ] 版本归档记录格式完整
- [ ] frontmatter `archived: true` 说明
- [ ] active-registry 更新步骤
- [ ] ≤150 行

## 关键约束

- 版本归档是原子操作
- 版本归档无用户交互
- CONDITIONAL_PASS 允许豁免但需标注
- 复利归档 PRD frontmatter 更新只提触发关系
