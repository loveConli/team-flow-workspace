# Roadmap 与待办列表

> 本文件从 CLAUDE.md 抽取（2026-07-25），按需加载。
> **维护规则**：每次设计升级或版本迭代时更新；完成实施的里程碑标记 ✅ 并注明完成版本。
> **每次迭代必须检查本列表。**

## 已完成里程碑

| 版本         | 里程碑                                                                | 状态  |
| ---------- | ------------------------------------------------------------------ | --- |
| v0.3       | 原型能力并入、四方专家会审、设计增强方案 v0.3                                          | ✅   |
| v0.5       | 原型内循环修正、产品级编排层、ce-plan 收窄、复利贯穿机制                                   | ✅   |
| v0.6（设计文档） | 既有项目接入层（workflow-bootstrap）、SOP 补 bootstrap 层                      | ✅   |
| v0.10.0    | E2E skill（AC 驱动 Playwright 测试）                                     | ✅   |
| v0.11.0    | workflow-orchestrator + workflow-bootstrap + e2e 集成、复利 CLI 命令、三层索引 | ✅   |
| v0.12.0    | 治理债务清理：身份命名统一、AGENTS.md 同步、版本号硬编码修复、skill 计数全链路一致、check-versions 扩展 | ✅ 2026-07-24 |
| v0.13.0    | 渐进式披露 + Agent 化：ce-compound/ce-plan 拆分、code-reviewer/bug-investigator agent 化、13 skill 补 references | ✅ 2026-07-24 |
| v0.15.0    | subagent 编排下沉 + 多需求状态治理 + PRD/Plan 规范修复（设计增强方案 v0.8）；3 新 agent、recon-probe.sh、prototype 内部编排器、冻结措辞 BUG 修复 | ✅ 2026-07-25 |
| v0.16.0    | 会话交接 + 工作流反馈（设计增强方案 v0.8 §21）；2 新 skill（session-handoff/workflow-feedback）、6 个 references、release-archivist 收尾联动、P2-5 既有测试修复（421/421） | ✅ 2026-07-25 |
| v0.17.0    | S4 路径修复（spec_dir→change_dir + 横展）+ S4 审计必选门禁 + P2-6 原型升级研究（open-design 方法论 + 19 项缺口 + 三波路线图）；421/421 测试全过 | ✅ 2026-07-25 |
| v0.18.0    | 原型生成体系升级 Wave 1+2：种子模板+骨架库+craft 五件套+P0/P1/P2 checklist+reviewer craft 4 席 rubric+env-scout direction-picker+architect token 四层模型+guard 脚本 | ✅ 2026-07-25 |
| v0.19.0    | Design-System 独立化：新增 design-system skill（23 skills）+ 用户主导交互创建（预填推荐+确认）+ 预览画廊 + 存储迁移 .team-flow/design-system/（base+变体）+ prototype 生态路径重构 | ✅ 2026-07-25 |
| v0.20.0    | 工作流反馈三件套落地（设计增强方案 v0.8 §22）：P1-13 产出型子代理质量闸门（产物落盘硬闸门+大产出分片+主代理交接后校验，builder/env-scout）+ P2-11 编排层完成通知等待范式（禁 TaskOutput 轮询）+ P2-12 S1 路由新增「原型补跑/重跑」第 7 入口；横展 .cursor-plugin 描述对齐（17→23）；421/421 测试全过 | ✅ 2026-07-25 |
| v0.21.0    | 子代理决策点 SendMessage stop-and-resume 交互协议（设计 §22.1.1 转采纳 + §18.1.2 修订，P1-14）：子代理发问即停 → 主代理 task-notification 代问用户 → 回传自动 resume 续跑；请求-应答匹配纪律 + 子代理应答校验；完成 P1-13 的 SendMessage 子项；横展修 AGENTS.md Skills 索引缺 design-system 行（W1）；LT 实证（Session d6801ab4）；421/421 + plugin-validator PASS | ✅ 2026-07-25 |
| v0.24.0    | 复利工程强制化补强（5项P0-P2修复）：① hooks 旧名修复（spec-superflow→team-flow，恢复状态机编辑守卫）② compound-captured guard 维度（executing:closing 强制 learnings.md 或显式 skip）③ Bootstrap DDL 提取（recon-probe.sh 三策略：SQL文件/Java Entity/占位兜底）④ Bootstrap 模板初始化（B2 Step 0 从 architecture-design/templates/ 复制 5 个模板）⑤ solutions 脚本测试覆盖（29 个新测试，capture/inject/promote/index-gen 从 0%→100%）；457/457 测试全过 | ✅ 2026-07-28 |
| v0.24.1    | prototype skill 体系补强（5项P0-P2修复）：① design-system-architect.md 重复维护→迁移指针 ② Open Design 命名歧义消解（GUI工具 vs 开源方法论）③ prototype-sync 从 SOP 升级为 release-archivist closing 自动触发+执行校验 ④ 新增交互原型/线框图方法论（零依赖适配）⑤ C 端骨架扩展（6 个新 section + CSS + 节奏表）；来源：baoyu-design vs open-design 深度评估 | ✅ 2026-07-28 |
| v0.25.0    | brainstorm profile 机制 + PRD 模板交互式选择（3 新增+4 改动）：① 新增 templates/prd-brainstorm-profile.md（核心维度7项+扩展维度6项+反例边界7项+正/反示例）② Phase 0 模板解析改为 MANDATORY STEP+AskUserQuestion 强制交 ③ Phase 2 新增 profile 驱动方案探索（替代 mechanism/product shape）④ config-loader DEFAULTS 增加 prd.template 默认值 ⑤ orchestrated 模式明确仅跳过 Phase 3.5；来源：workflow-feedback P1+P2（2026-07-29） | ✅ 2026-07-29 |
| v0.25.1    | P1-9 三个 SKILL.md 渐进式披露拆分：ce-proof(346→88) + ce-brainstorm(458→122) + ce-ideate(402→85)，提取 9 个 reference 文件，SKILL.md 只保留骨架 + Phase 摘要 + reference 引用指针；457/457 测试全过 | ✅ 2026-07-29 |

## 规划中里程碑

| 版本      | 里程碑                 | 核心内容                                                                                                                                                          | 状态                    |
| ------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| v1.0.0  | **成熟版**             | ① 触发词去重（分层触发域，方案C） ② PreToolUse hook 执行期状态守护 ③ "ce-" 前缀正名（保留+文档化，方案C） ④ 设计增强方案 v1.0 全量定稿 ⑤ orchestrator 设计优化（反馈环路+增量入口） | 🔲 进行中（①②③已完成，④⑤待实施；⑥身份统一提前至 v0.23.0 ✅） |
| v0.16.0+ | **原型生成体系升级**       | 学习 open-design 方法论，升级 prototype 设计能力。研究 ✅ v0.17.0；Wave 1+2 ✅ v0.18.0（合并实施）；Wave 3 待反馈决策 | ✅ Wave 1+2 已完成 |
| v1.x    | **项目级差异化配置**       | 工作流编排 + 原型设计系统支持项目级差异化配置；配置优先级：项目级 > plugin 内置默认 | 🔲 规划中 |

## 待办列表

> 发现新待办时追加（注明优先级和来源）；完成实施后将状态改为 ✅ 并注明完成版本/日期；已废弃的待办标记 🗑️ 并注明原因。

### P0（阻断级，下一版本必须完成）

| ID   | 待办                                                                         | 状态           | 目标版本    | 备注                 |
| ---- | -------------------------------------------------------------------------- | ------------ | ------- | ------------------ |
| P0-1 | AGENTS.md 同步到 v0.11.0：补 3 skill 到索引（17→20）；更新 SOP；补复利系统；更新状态机描述            | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审    |
| P0-2 | 修复 2 处 `spec-superflow@0.10.2` → `@0.11.0`                                 | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审    |
| P0-3 | plugin.json description "17 skills" → "20 skills"（含 .claude-plugin/ 副本）    | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审    |
| P0-4 | 身份命名关系文档化：AGENTS.md 新增"身份与依赖关系"节，明确 team-flow（插件）包含 spec-superflow（npm 底座） | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审 C1 |
| P0-5 | check-version-consistency.mjs 扩展：skill 计数校验 + npx 版本引用校验（正向+负向测试通过）        | ✅ 2026-07-24 | v0.12.0 | 来源：文档维护规范          |

### P1（重要，两个版本内完成）

| ID    | 待办                                                                                                                                                                             | 状态           | 目标版本    | 备注                                                                |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------ | ------- | ----------------------------------------------------------------- |
| P1-1  | ce-compound SKILL.md 拆分：850行→114行，新建 7 个 reference 文件                                                                                                                          | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 C4                                                |
| P1-2  | ce-plan SKILL.md 拆分：837行→114行，新建 9 个 reference 文件                                                                                                                              | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 C4                                                |
| P1-3  | code-reviewer agent 创建（只读审查员，tools: Read/Bash/Grep/Glob，171行）                                                                                                                  | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 W2                                                |
| P1-4  | bug-investigator agent 创建（自主调查员，tools: Read/Bash/Grep/Glob/Write，180行）                                                                                                         | ✅ 2026-07-24 | v0.13.0 | 来源：v0.11.0 设计评审 W2                                                |
| P1-5  | README.md 同步：七套能力 20 skills + SOP + 产物结构                                                                                                                                       | ✅ 2026-07-24 | v0.12.0 | 来源：v0.11.0 设计评审                                                   |
| P1-6  | 身份统一：`spec-superflow` 全部改为 `team-flow`（含 npm 包名、CLI 前缀 `ssf`→`tf`、`.spec-superflow.yaml`→`.team-flow.yaml`、所有 SKILL.md/脚本中的 npx 引用及底层命令）                                       | ✅ 2026-07-27       | v0.22.4  | **第一阶段（产品级状态文件迁 `.team-flow/`）✅ v0.15.0**；**第二阶段（npm 包名/CLI/npx/变更级 `.spec-superflow.yaml`→`.team-flow.yaml`）✅ v0.22.3**，721 处引用全量迁移；**第三阶段（npm 包 scope 化 `@xulthekl/team-flow`）✅ v0.22.4**，179 处引用更新 + npm 发布成功 |
| P1-7  | orchestrator v2 设计优化：① 反馈环路 ② 增量入口 ③ 原型循环上提 ④ 原型自动评审 ⑤ S4 拆分质量自检 ⑥ S5 多 change 必选化 ⑦ description 改为"描述能力" | ✅ 2026-07-24 | v1.0.0  | v0.7 设计+四方会审+P2 实施+P3 review 全流程完成         |
| P1-8  | subagent 拆分规划：明确各阶段子代理分工，编排层只负责编排                                                                                                                         | 🔲 部分落地       | v1.0.0  | **§18.1 交接协议 + bootstrap/prototype/brainstorm 执行下沉 ✅ v0.15.0**；剩余 kickoff-context-assembler / replan-analyst / compound-moment-detector 待实施 |
| P1-9  | ce-brainstorm / ce-ideate / ce-proof SKILL.md 拆分到 references/（415/402/346行→≤150行）                                                                                                             | ✅ 2026-07-29 | v0.25.1 | ce-proof(346→88) + ce-brainstorm(458→122) + ce-ideate(402→85)，提取 9 个 reference 文件 |
| P1-10 | 新增 `session-handoff` + `workflow-feedback` skill。设计见 v0.8 §21 | ✅ 2026-07-25 | v0.16.0 | P1-P5 全流程完成 |
| P1-11 | 原型 Wave 1：scaffold 升级（template.html + layouts.md 骨架库）+ craft 五件套 + P0/P1/P2 checklist 注入 builder/reviewer | ✅ 2026-07-25 | v0.18.0 | 来源：P2-6 升级提案 |
| P1-12 | 原型 Wave 2：token 四层模型 + reviewer rubric 扩展 + direction-picker + guard 脚本 | ✅ 2026-07-25 | v0.18.0 | 来源：P2-6 升级提案（Wave 1+2 合并实施） |
| P1-13 | 产出型子代理质量闸门（横展全部产出型 agent，prototype-builder 首发）：① 产物落盘硬闸门——声明的 deliverable 文件已 `Write` 落盘且非空，否则禁止返回 `done`，改返回带 `blockers` 的非终态 ② 决策点/阻断点不结束、先经 `SendMessage` 反馈主代理（推广为 team-flow 全部子代理统一交互协议；子代理不能阻塞提问，由主代理自决或 `AskUserQuestion`）③ 大产出默认分片（先 Write 主体骨架 → Edit 分段追加数据层/渲染层，规避单次 Write 截断与预算峰值）④ 主代理交接后强制 `ls`/`test -f` 校验入口文件存在且非空再派 reviewer，缺失则 resume builder | ✅ 2026-07-25 | v0.20.0 | 来源：workflow-feedback 2026-07-25（VRM mgmt-dashboard S2，agent-quality，反馈级 P1） |
| P1-14 | 子代理决策点 SendMessage stop-and-resume 交互协议（**完成 P1-13 的 SendMessage 子项**）：子代理（无 AskUserQuestion）决策点经 `SendMessage(to: main)` 发问即停 → 主代理收 `task-notification` 代问用户 → 回传自动 resume 续跑；主代理维护请求-应答匹配纪律 + 子代理应答校验；修订 §18.1.2（不引入常驻 agent team 不变，结构化返回仍为终态主协议）。落点 prototype-builder/env-scout + prototype orchestration-flow（主代理中继）+ AGENTS.md | ✅ 2026-07-25 | v0.21.0 | 来源：LT 实证（Session d6801ab4）+ workflow-feedback agent-quality 改进建议2 |
| P1-15 | 架构设计显式编排与产物独立化（v0.9 §26）：① workflow-start 路由表增加 architecture-design 子代理调用（exploring→specifying 之间） ② architecture-design 判断+执行一体化 SOP + 结构化输出契约 ③ 产出目录从 `specs/<cap>/` 提升为独立 `architecture/` ④ spec-writer Required Inputs 增加 `architecture/` 读取 ⑤ workflow-start 合理性确认机制 + yaml 字段 + 硬阻断 ⑥ hotfix/tweak 不豁免 | 🔲 待实施 | v0.23.0 | 来源：LT+CC 讨论（2026-07-27） |

### P2（改善，按节奏推进）

| ID   | 待办                                                                                           | 状态                | 目标版本    | 备注                                                       |
| ---- | -------------------------------------------------------------------------------------------- | ----------------- | ------- | -------------------------------------------------------- |
| P2-1 | 触发词去重：分层触发域（方案C）                                        | ✅ 2026-07-24      | v1.0.0  | 方案C：产品级收敛到orchestrator，步骤级保留受限独立触发    |
| P2-2 | PreToolUse hook 执行期状态守护（14/14 测试通过，~22ms）                                              | ✅ 2026-07-24      | v1.0.0  | 来源：v0.11.0 设计评审 W5                                       |
| P2-3 | 13 个 skill 补 references/ | ✅ 2026-07-24      | v0.13.0 | 来源：v0.11.0 设计评审 W1                                       |
| P2-4 | 动态重规划机制调研                           | ✅ 调研完成 2026-07-24 | v1.0.0+ | 设计已写入 v0.7 §17.9 |
| P2-5 | 修复 10 个既有测试失败 + 27 处 npx 版本漂移 | ✅ 2026-07-25 | v0.16.0 | 421/421 全过 |
| P2-6 | 原型生成体系升级：学习 open-design | ✅ 研究完成 2026-07-25 | v0.17.0 | 升级提案见 `docs/prototype-upgrade-proposal.md`；Wave 1/2 已追加为 P1 待办 |
| P2-7 | 项目级差异化配置体系 | 🔲 规划中 | v1.x | 现有 config 注入为基础 |
| P2-8 | S4 change 目录位置修复：① `state-model.md:50-51` 误写 `specs/change-1/` → `changes/change-1/` ② S4 SKILL.md 强化路径约束 + spec_dir→change_dir 重命名 + 横展 cross-change-consistency-checker | ✅ 2026-07-25 | v0.17.0 | 来源：v0.16.0 无头测试 |
| P2-9 | S4 拆分审计不可跳过：明确 change-split-auditor 为必选步骤（必选门禁 + Guardrails + AGENTS.md/README.md 同步） | ✅ 2026-07-25 | v0.17.0 | 来源：v0.16.0 无头测试 |
| P2-10 | 无头测试框架 skill 化（已完成 `.claude/skills/team-flow-e2e-test/`） | ✅ 2026-07-25 | v0.17.0 | 来源：LT 指示 |
| P2-11 | 编排层低消耗等待范式：派发后台子代理后**依赖完成通知（`<task-notification>`）再行动**，禁止反复 `TaskOutput(block=true)` 阻塞轮询（超时返回会倾泻完整子代理 transcript，撑爆主上下文、抵消"主代理只编排"的轻上下文优势）；确需中途观察用 `block=false` 轻量查询。明文进 workflow-orchestrator / prototype 等编排 skill。（harness 层"TaskOutput 对 local_agent 超时不倾泻转录、只返末态摘要+文件路径"另向 Claude Code 反馈，非 team-flow 可控） | ✅ 2026-07-25 | v0.20.0 | 来源：workflow-feedback 2026-07-25（VRM mgmt-dashboard S2，performance，反馈级 P2） |
| P2-12 | S1 路由表新增第 7 种入口「**原型补跑/重跑**」：触发条件（PRD 已冻结 `frozen_downstream` ∧ `prototype/` 缺失/为空，或用户显式要求重做原型）→ **部分重入 S2 原型循环**（S2 步骤 2 判断→3 原型循环→4 冻结），PRD 不修改、保留有效的 S3 plan / S4 changes、闭环后恢复原 phase；`replan_log` 记录往返。同步改 ① SKILL.md「增量入口」路由表补第 7 行 ② `s1-path-router.md` 补「PRD 冻结 ∧ prototype 缺失/需重做」判据分支（与重新计划/续版区分）③ `state-model.md` 补部分重入冻结语义与状态转换规则 | ✅ 2026-07-25 | v0.20.0 | 来源：workflow-feedback 2026-07-25（VRM mgmt-dashboard S1，sop-flow，反馈级 P2） |
| P2-13 | references/ 版本引用漂移清理 + check-versions 扫描盲区扩展：① 清理 references/ 下陈旧 `spec-superflow@0.15.0/@0.16.0` npx 引用（27+3 处，分布 release-archivist / workflow-orchestrator s2/s4/s5 / workflow-start / build-executor）至当前版本 ② `check-version-consistency.mjs` 扫描范围从顶层 SKILL.md 扩展到 `references/**`，杜绝再漂移 | 🔲 待实施 | v1.0.0 | 来源：v0.21.0 plugin-validator W2（门禁盲区横展） |
| P2-14 | pre-commit hook 同步范围扩展：将 `.claude-plugin/marketplace.json` 的 skill/agent 计数描述纳入 pre-commit 自动同步（当前仅覆盖 plugin.json / AGENTS.md / README.md，marketplace.json 在 17→23 skills 扩容时漏同步，v0.22.0 P3 验证发现并手动修正文本，但自动化同步规则未补） | 🔲 待实施 | v0.22.0+ | 来源：v0.22.0 plugin-validator 横展 |
| P2-15 | change-brief frontmatter schema 对齐：v0.22.0 E2E 测试发现无头 Claude 落盘 brief 时未写入 `upstream_source: orchestrator` 字段，导致 workflow-start DP-0 继承判定伪代码中 `brief 存在 AND upstream_source == orchestrator` 条件不满足、走 else 手动路径而非继承分支。建议修正：① workflow-start 判定逻辑改为"brief 存在即继承"（不依赖字段值，更贴合 CC 自己写的'以 brief 存在为主信号'设计意图）或 ② s4-split-validate.md brief 模板强制含 upstream_source 字段。CC 倾向方案①。**v0.22.5 进展**：新增 `templates/change-brief.md` 标准模板（含 `upstream_source` 字段），部分解决方案②；但 workflow-start 判定逻辑仍检查字段值，方案①未实施 | 🟡 部分完成 | v0.22.5+ | 来源：v0.22.0 E2E 测试（VRM S3→S4 重跑发现）；v0.22.5 制品链评审 F07 |

### P3（低优先级，时机成熟再做）

| ID   | 待办                                           | 状态           | 目标版本   | 备注                                               |
| ---- | -------------------------------------------- | ------------ | ------ | ------------------------------------------------ |
| P3-1 | "ce-" 前缀正名：保留 ce- + README 命名约定文档化（方案C） | ✅ 2026-07-24 | v1.0.0 | 改 tf- 是伪统一，文档说明即可 |
| P3-2 | recon-probe.sh 并入 `ssf recon` CLI | 🔲 待实施 | v1.0.0+ | 来源：v0.8 §18.4.2 |
| P3-3 | ce-brainstorm 无头模式兼容：headless 检测 + 自动选推荐 | 🔲 待实施 | v1.0.0+ | 来源：v0.16.0 无头测试 |
| P3-4 | S3 ce-plan grounding 性能：增量 grounding | 🔲 待实施 | v1.0.0+ | 来源：v0.16.0 无头测试 |
