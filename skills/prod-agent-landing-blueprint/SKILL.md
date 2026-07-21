---
name: prod-agent-landing-blueprint
description: 产研端到端 Agent 落地蓝图生成器。当用户要基于调研报告/方法论落地一个端到端 Agent 工程（如"帮我基于 XX 报告落地产研/客服/XX 端到端 Agent 蓝图""给我一套带门禁和人工门的 Agent 开发工程骨架"），或需要含双真相源/门禁硬卡/六人工门/L4-L5 契约 stub/单仓化 monorepo 的 Agent 治理脚手架时触发。默认以 artifact-graph + artifact-chain-assistant 作 L1-L3 地基（submodule 锁 commit，开箱复用）。不适用于纯业务 Agent 运行时实现、单次提示词优化、或非 Agent 工程的软件项目脚手架。
---

# 产研端到端 Agent 落地蓝图生成器

将本次验证过的「产研端到端 Agent」五阶段落地蓝图（L1 提示词 → L2 上下文 → L3 Harness → L4 Loop → L5 Agent Team）固化为**可复用模板库 + 落地 SOP**。本技能产出的是「造 Agent 的工程骨架与治理规范」，不是能直接回答用户的 Agent 运行时。

## 何时触发
- 用户说类似："帮我基于《XX 报告》落地产研/客服/XX 端到端 Agent 蓝图""给我一套带门禁、人工门、L4-L5 stub 的 Agent 开发工程骨架"。
- 需要含双真相源、门禁硬卡、六人工门、单仓化 monorepo 的 Agent 工程脚手架。

## 默认地基（已验证，开箱复用）
- `artifact-graph`（结构/追溯/版本真相源引擎，Apache-2.0，Node≥22）——作 `engines/artifact-graph/` submodule，**钉死 commit**。
- `artifact-chain-assistant`（插件 v0.2.0，含 CLARIFY/薄适配入图）——作 `plugins/artifact-chain-assistant/` submodule，**钉死 commit**。
- 两者未发版，必须 submodule 锁 commit 防漂移。
- 不绑定业务：客服/产研/其他场景复用同一套地基，仅填充各自的业务 artifact。

## 落地流程

### 步骤 0：复制蓝图模板
将本技能的 `assets/blueprint/` 复制到目标单仓的 `product/blueprint/`：
```bash
cp -r assets/blueprint/ <your-repo>/product/blueprint/
```
模板含 36 文件：五阶段骨架、gates/、ci/、status-tracker/、degradation-channels.md、单仓化约定、scripts/（CI 最小框架）。

### 步骤 1：对齐 3 决策（确认门 A）
与用户确认，避免后期返工：
1. **采纳地基**：是否用 artifact-graph+assistant 作 L1-L3 地基（引擎+插件两层都留）？
2. **配比口径**：CLARIFY+原型「默认最轻、证据驱动加重」——轻指仪式/类型从轻，**不指门禁强度**。
3. **L4/L5 优先级**：前期是否只留 TODO stub 不实现？

### 步骤 2：召四专家并行评审（确认门 B）
并发召集四角色审阅蓝图并汇总：
- **知识库/L2 专家**：双真相源是否覆盖需求流程态七字段；CLARIFY 是否薄适配入图。
- **Agent 架构/L4-L5 专家**：L4/L5 stub 契约是否充分（MAX_CYCLES/熔断/独立 Judge/Builder 覆盖清单）。
- **工程化/L3 专家**：门禁是否 fail-closed、降级通道是否坐实、单仓化减负。
- **产品/落地/配比专家**：配比口径与 catalog 是否冲突、是否缺人工门、课程线 profile。

### 步骤 3：LT 拍板改造范围（确认门 C）
汇总专家意见 → 用户决策落地优先级与剔除项（如本次剔除 ima 知识库集成桥）。

### 步骤 4：分批改写蓝图（落地已验证模式）
按以下口径改写，不另起架构：
- **K1 双真相源**：`status-tracker`=需求流程态真相源（七字段）；`artifact-graph`=结构/追溯/版本真相源。两者并存、不互相替代；唯一写入方=合并代理/LT；pre-push 一致性校验。
- **K2 配比**：基础六类型（feature/scenario/decision/design/test/e2e_test）**始终启用（非谈判项）**；扩展类型零默认，证据驱动启用。
- **P0-A 门禁硬卡**：真实环境 `SAFE_MODE=0`（fail-closed）；硬依赖（status-tracker/ECO_TEST_REPORT/架构注册表）缺失即非零退出（反绕过）。
- **P0-B CLARIFY 落地**：`/ltflow clarify` 入口 + fast-path（单文件/需求明确/小改动跳过 Grill Me）+ 能查的不问 + 重大分叉人拍板 + 薄适配入图。
- **P0-C 六人工门**：A 实现授权（DESIGNING→IMPLEMENTING 必过人）/ B 发布 / C ECO 升级 / D 越权高成本 / E 知识蒸馏 / F L4 熔断决策。标注人工 PAUSE 不得自动越。
- **P0-D L4/L5 契约 stub**：前期不实现，留 `design-contract-stub.md` 钉死硬约束（MAX_CYCLES=6 / 独立 Judge 剔 Builder 覆盖清单 / /goal 独立模型终态 / version-lock append-only+SHA256 / 合并代理下沉 L4）；各 l4/l5 文件顶部标 TODO/deferred。

### 步骤 5：单仓化 monorepo + submodule（确认门 D）
落地依赖三 Git 仓（artifact-graph 引擎 / artifact-chain-assistant 插件 / 自建主仓）合并为单仓：
- `engines/artifact-graph/`、`plugins/artifact-chain-assistant/` 作 submodule 钉死 commit。
- `product/` 含 code/memory/wiki（报告 L2 三仓库的目录隔离，与 monorepo 不冲突）+ blueprint/。
- 主仓单 CI 跑 `ci/required-checks.yml`。

### 步骤 6：补 CI backstop 脚本（按需）
`ci/required-checks.yml` 引用 `scripts/` 下 5 个最小框架（check-coverage / eco-evidence / audit-closure / gtmc-phase35 / gtmc-a516）。真实项目须补全解析器，并在 Branch Protection 注册为 required status checks，设 `SAFE_MODE=0`。

## 核心已验证模式速查
| 模式 | 要点 |
|------|------|
| 双真相源 | status-tracker（流程态）≠ artifact-graph（结构/版本）；并存不替代 |
| 配比 | 基础六类型常驻 + 扩展零默认（证据驱动） |
| 门禁 | SAFE_MODE=0 fail-closed；硬依赖缺失即非零 |
| 人工门 | 六道：进实现/发布/ECO/越权/蒸馏/熔断必过人 |
| L4/L5 | 前期只留 stub；关键词 MAX_CYCLES / 熔断 / 独立 Judge / Builder 覆盖清单 |
| 单仓化 | monorepo + submodule 锁 commit（solo 减负） |

## 工作流示例

**示例 1：本次产研落地（原项目）**
输入："基于《产研端到端Agent深度调研报告》落地五阶段工程"
→ 复制蓝图 → 对齐 3 决策（采纳地基/配比认可/L4L5 留 TODO）→ 四专家评审 → 剔除 ima 桥 → 落地 K1/K2/P0-A~D → 单仓化 submodule → 补 CI。产出 36 文件治理工程。

**示例 2：复刻客服 Agent**
输入："按产研蓝图落地客服端到端 Agent"
→ 同样复制蓝图（保留 artifact-graph 地基）→ 把"产研"语义换"客服"（FAQ/订单接口契约/wiki）→ 走同一 SOP。省掉重搭门禁/人工门/L4-stub，仅填业务 artifact。

## 确认门汇总
- **A** 3 决策对齐（步骤 1）
- **B** 四专家评审启动（步骤 2）
- **C** 改造范围拍板（步骤 3）
- **D** 单仓化方式（步骤 5，本次选 submodule 锁 commit）

## 不适用边界
- 不是 Agent 运行时实现，仅产工程骨架/规范。
- 不适用于纯提示词优化、单次脚本生成、非 Agent 工程的普通软件脚手架。
- 上游 artifact-graph/assistant 未发版；更换地基需解耦双真相源集成（见 K1）。
