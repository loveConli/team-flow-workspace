# Harness 零件叠加路径（L3 Harness · 03E）

> 报告引用: §5  Harness 工程（六组件）/ §5.10 六组件框架 / §11 L3 行「逐层叠加 Harness 零件」
> 定位: Rule → Skill → SubAgent → Workflow → Scripts → MCP，逐层叠加，从简单到复杂。
> 标签: 【来源已核验✅】

## 零件叠加路径（推荐顺序）

> 原则：从最简单、最确定的部分开始，逐步增加复杂度。每叠加一层，验证稳定性后再下一层。

```
Layer 1: Rule（规则）      ──► 最基础，无代码，纯文本约束
  │ 验证: 规则是否被遵守（审计日志检查）
  ▼
Layer 2: Skill（技能）      ──► 封装特定任务的标准化模板
  │ 验证: Skill 是否按模板执行（输出一致性检查）
  ▼
Layer 3: SubAgent（子代理） ──► 独立执行特定任务的 Agent 实例
  │ 验证: 子代理是否完成分配任务（状态机检查）
  ▼
Layer 4: Workflow（工作流） ──► 串联多个 Skill/SubAgent 的流程编排
  │ 验证: 全流程是否按顺序执行（status-tracker 检查）
  ▼
Layer 5: Scripts（脚本）    ──► 调用外部工具/系统的脚本（如生态脚本、本项目的三段 hook）
  │ 验证: 脚本是否正确执行（CI 校验）
  ▼
Layer 6: MCP（模型上下文协议）──► 外部系统集成的标准接口
  │ 验证: MCP 调用是否符合 schema（契约测试）
```

## 每层的定义与示例

### Layer 1: Rule（规则）
- **定义**: 纯文本约束，写入 CLAUDE.md / AGENTS.md / 代码规范文档
- **示例**: "禁止直接 push 到 main"、"所有方法须有 JavaDoc"、"覆盖率 ≥ 80%"
- **验证方式**: 审计日志抽样检查 + CI 静态分析
- **投入**: 最低（无代码，纯文档）
- **收益**: 基础约束，防止低级错误

### Layer 2: Skill（技能）
- **定义**: 封装特定任务的标准化模板和提示词，可复用
- **示例**: `superai-clarify`（需求澄清）、`superai-plan`（技术方案）、`superai-execute`（TDD 实现）
- **验证方式**: Skill 输出格式一致性检查（schema 校验）
- **投入**: 中（模板设计 + 提示词调优）
- **收益**: 标准化输出，减少模型自由发挥的不确定性

### Layer 3: SubAgent（子代理）
- **定义**: 独立执行特定任务的 Agent 实例，有独立的上下文窗口和工具集
- **示例**: 前端 SubAgent（只处理 UI 相关任务）、后端 SubAgent（只处理 API 相关任务）
- **验证方式**: SubAgent 完成任务后由协调者验收（状态机检查）
- **投入**: 高（需要多 Agent 运行时支持）
- **收益**: 并行处理、专业化分工

### Layer 4: Workflow（工作流）
- **定义**: 串联多个 Skill/SubAgent 的流程编排，定义 phase 间的状态转移和门禁
- **示例**: L3 的六阶段纵向闭环（Phase 0→6）就是一个 Workflow
- **验证方式**: status-tracker 状态机检查 + CI 校验
- **投入**: 高（需要状态机引擎）
- **收益**: 端到端自动化、确定性流程

### Layer 5: Scripts（脚本）
- **定义**: 调用外部工具/系统的脚本，如本项目的三段 hook
- **示例**: `pre-push-gate.sh`（PMD + 覆盖率）、`eco-gate.sh`（ECO 校验）、`worktree-create-snapshot.sh`（三线快照）
- **验证方式**: CI 运行脚本 + 脚本单元测试
- **投入**: 中（脚本开发 + 测试）
- **收益**: 与现有工具生态集成、确定性执行

### Layer 6: MCP（模型上下文协议）
- **定义**: 外部系统集成的标准接口，如 Aone API、钉钉 API、Wiki 检索
- **示例**: MCP 工具 `aone_get_workitem`、`dingtalk_get_doc`、`wiki_search`
- **验证方式**: 契约测试（mock 服务端 + 实际调用对比）
- **投入**: 高（需要 MCP 服务器开发/部署）
- **收益**: 标准化外部集成、可复用、可审计

## 当前项目叠加状态

| 层级 | 状态 | 已激活零件 | 待叠加零件 |
|------|------|------------|------------|
| Layer 1: Rule | ✅ | CLAUDE.md / AGENTS.md / SDD 模板 | 更多工程规范 |
| Layer 2: Skill | 🟡 | SDD 模板骨架 | superai-clarify / superai-plan / superai-execute（需填充） |
| Layer 3: SubAgent | 🔘 | — | 前端/后端/测试 SubAgent（L5 阶段） |
| Layer 4: Workflow | 🟡 | 六阶段纵向闭环骨架（L4） | 状态机引擎、工作流引擎 |
| Layer 5: Scripts | 🟡 | pre-push / eco-gate / 三线快照（03A） | 沙箱脚本、成本监控脚本 |
| Layer 6: MCP | 🔘 | — | Aone MCP、钉钉 MCP、Wiki MCP |

> 🟡 = 骨架已产出，未激活；🔘 = 未开始；✅ = 已激活

## 叠加策略建议

1. **先稳固 L1-L2**（Rule + Skill）：SDD 模板和基础规范先跑通
2. **再激活 L3 硬门禁**（Scripts + Workflow 门禁）：pre-push / eco-gate / 三线快照 + status-tracker
3. **后叠加 L4 闭环**（Workflow + 反馈学习）：六阶段纵向闭环 + 自我验收 + 蒸馏
4. **最后扩展 L5 多 Agent**（SubAgent + MCP）：Coordinator-Worker + 外部 MCP 集成

---
> 此文件为**路线图**。真实项目需按实际技术栈、外部系统集成需求、团队规模调整叠加顺序。
> 建议每叠加一层后，运行至少 3 个真实需求验证稳定性，再进入下一层。
