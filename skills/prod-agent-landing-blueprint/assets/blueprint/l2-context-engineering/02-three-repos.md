# 三仓库记忆生命周期（L2 上下文工程）

> 报告引用: §4 上下文工程 / §5.10 六组件 / §6.2 阶段0 上下文组织 / §6 反馈学习层
> 定位: 材料进入项目记忆 → 结项审视 → 稳定知识蒸馏回长期 wiki → 反复流程问题变 skill/prompt 改进候选 → 一次性材料留归档。
> 标签: 【来源已核验✅】

## 三仓库定义

| 仓库 | 分支规则 | 内容 | 生命周期 | 访问频率 |
|------|----------|------|----------|----------|
| **代码仓库** | 需求拉 feature 分支 | 代码事实、实现产物 | 需求生命周期（feature 分支） | 高 |
| **项目记忆仓库** | 需求拉 feature 分支（过程材料先入此处） | 当前需求的过程材料——CR 评论、验收记录、自恢复日志、NOTES.md | 需求生命周期（feature 分支）→ 结项后蒸馏 | 中 |
| **长期 wiki 仓库** | 始终在 master | 稳定业务知识——LLM Wiki、codemap、架构决策、接口契约 | 永久（主分支） | 低（但高价值） |

## 生命周期流转图

```
需求进入
  │
  ▼
[代码仓库] ← 代码变更（feature 分支）
  │
  ▼
[项目记忆仓库] ← 过程材料（CR 评论、验收记录、自恢复日志、NOTES.md）
  │
  ▼ 结项审视（RELEASING → CLOSED）
  ├─ 稳定知识 ───────► [长期 wiki 仓库]（master 分支，永久保留）
  │                    （LLM Wiki、codemap、架构决策、接口契约）
  │
  ├─ 反复流程问题 ───► skill/prompt 改进候选（见 feedback-learning-layer.md）
  │                    （更新 AGENTS.md、CLAUDE.md、Skill 模板）
  │
  └─ 一次性材料 ─────► 归档（留在项目记忆仓库，标记归档）
                       （不再活跃，可检索但不可修改）
```

## 目录结构建议

```
# 代码仓库（feature 分支）
project-code/
├── src/               # 源码
├── tests/             # 测试
└── ...

# 项目记忆仓库（feature 分支）
project-memory/
├── requirement/
│   ├── status-tracker.md    # 需求流程态真相源（L1，与 artifact-graph version-lock 并存，不互相替代）
│   ├── spec.md              # 需求规格
│   ├── plan.md              # 技术方案
│   └── tasks.md             # 任务分解
├── memory/
│   ├── NOTES.md             # 结构化笔记（Agent 记忆）
│   ├── audit-log.jsonl      # append-only 审计日志（L3）
│   ├── cr-comments.md       # CR 评论记录
│   └── acceptance-log.md    # 验收记录
├── design/
│   └── ...                  # 设计文档
└── three-line-snapshot.json # 三线快照（L3）

# 长期 wiki 仓库（master 分支）
project-wiki/
├── codemap.md               # 代码地图（架构决策、关键路径）
├── llm-wiki.md              # LLM 业务知识（领域术语、业务规则）
├── interface-contracts.md   # 接口契约（跨团队/跨服务）
└── architecture-decisions/  # 架构决策记录（ADR）
```

## 关键规则

1. **长期 wiki 只进不出**: 稳定知识一旦蒸馏进入长期 wiki，**不得在原 feature 分支修改**。如需修正，走新的需求流程（新 feature 分支）→ 结项审视 → 更新 wiki。
2. **避免噪声污染**: 过程材料（CR 评论、临时日志）**不得**直接写入长期 wiki。必须经过结项审视的蒸馏过滤。
3. **版本控制**: 三仓库均纳入 Git 版本控制。长期 wiki 的 master 分支受保护（仅合并代理可写入）。
4. **检索策略**: 长期 wiki 用 `Retrieve` 策略加载（轻量标识符）；项目记忆用 `Permission` 策略加载（结构化笔记）；代码仓库用 `Reduce` 策略加载（按需读取）。

## 蒸馏触发条件

- 状态机 `RELEASING` → `CLOSED` 时自动触发
- 由 `superai-finish` skill 编排
- 人工审查后执行（WAITING_USER 确认）

---
---

## 落地仓结构：单仓化 monorepo + git submodule（评审 P1 · 已决策 ✅）

> **决策（LT 2026-07-12 拍板，方式一）**：落地方案依赖的 **3 个 Git 仓**合并为**单一 monorepo**，用 `git submodule` 锁 commit 隔离上游未发版依赖，降低 solo（一人创业）维护负担。

### 概念澄清（两种「三仓库」勿混）
- **报告 L2 的「三仓库」** = `code/` `memory/` `wiki/` 项目记忆架构（见上「三仓库定义」）。在本方案中作为主仓 `product/` 内的**目录隔离**，与 monorepo 不矛盾。
- **本节的「三仓库 solo 简化」** = 落地方案依赖的 **3 个 Git 仓**：
  1. `artifact-graph`（结构/追溯/版本引擎，外部开源，未发版）
  2. `artifact-chain-assistant`（插件 v0.2.0，外部开源，未发版）
  3. 自建落地主仓（本 36 文件 blueprint + CI + gates + status-tracker + degradation-channels）
- ⚠️ 订正：原评估段落曾把两者混为一谈（把 code/memory/wiki 当成待简化的三 Git 仓），此处订正。

### monorepo 目录结构
```
landing-monorepo/                # 单一 Git 仓（主仓，单 CI / 单 clone）
├── .gitmodules                 # submodule 锁 commit 声明
├── engines/
│   └── artifact-graph/         # submodule → 钉死某 commit（结构/追溯/版本真相源）
├── plugins/
│   └── artifact-chain-assistant/  # submodule → 钉死某 commit（插件层，CLARIFY/薄适配入图）
└── product/                    # 自建落地主仓内容
    ├── code/                   # = 报告 code 仓（feature 分支，源码/实现）
    ├── memory/                 # = 报告 memory 仓（feature 分支，status-tracker/audit-log/过程材料）
    ├── wiki/                   # = 报告 wiki 仓（master，稳定知识，只进不出）
    ├── blueprint/             # 本 36 文件五阶段蓝图
    ├── ci/  gates/  status-tracker/  degradation-channels.md
    └── ...
```

### submodule 锁 commit 纪律（评审 P1）
- 上游两仓**未发版**，必须 `git submodule` 精确钉死 commit（`commit = <sha>`），**禁止**跟随 `main` 漂移。
- 上游补丁升级：走人工评估（人工门 **C** ECO 升级评估门），升级前改 `.gitmodules` 的 commit 并记录 changelog。
- 主仓单 CI 统一跑 `ci/required-checks.yml`（pre-push / eco-gate / 审计 backstop 全在单仓内）。
- 追溯保留：`artifact-graph` 作为 submodule 仍保留其 `traceability-version-lock.json` 的 SHA256 哈希链（见 `design-contract-stub.md` §4）。

> 此简化不改变「三仓库生命周期 / 长期 wiki 只进不出 / 蒸馏触发条件」等既有规则，仅改变**物理存储形态**为单仓 + 目录隔离 + submodule 锁 commit。

> 此文件为**结构约定**。真实项目需按实际仓库地址、分支命名规则、目录布局填充。
> 建议将单仓化结构纳入团队 Onboarding 文档，作为 L2 层基础设施统一管理。
