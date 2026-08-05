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
| v0.28.0    | Agent 补全 + 架构自动审查 + 项目级规范被动沉淀（设计增强方案 v0.11）：① architecture-design agent 创建（P1-18）② architecture-reviewer agent 创建（6 维度审查 + ≤3 轮循环修正，P1-20/21）③ conventions 配置段 schema + 4 个 skill 上下文注入 + 4 个模板 + 阶段转换前规范建议协议（P2-18~21）④ routing-rules.md 审查增强；agents 8→10；来源：workflow-feedback 2026-07-31 + LT 需求 | ✅ 2026-07-31 |
| v0.28.1    | Agent/Skill 职责分离修正 + 主干补强 auto-review + 横展三 agent 精简（设计增强方案 v0.11 §35/§36/§37）：① architecture-design agent 精简（WHO/WHAT only，229→~100 行）+ `skills:` 字段预加载 Skill 完整知识库（P1-22）② workflow-start SKILL.md 主干补强三步协议摘要（dispatch→auto-review→reasonableness check）+ Guardrails/State Writes 同步（P1-23）③ 横展修复 bug-investigator（180→~85 行）+ code-reviewer（171→~100 行）+ prototype-builder（230→~95 行）三个 Category A2 agent，HOW 内容迁移至对应 Skill（P1-25/26/27）；来源：workflow-feedback 2026-07-31（P1-1 agent-quality + P1-2 sop-flow）+ LT 横展需求 | ✅ 2026-07-31 |
| v0.29.0    | §37 DP-A 确认门 + 产物权限规则 + A4 PRD 交叉验证 + change 命名版本前缀（7 个 workflow-feedback 根因修复）：① workflow-start 三步→四步协议，Step 4 DP-A 用户确认门（AskUserQuestion + SendMessage 复用 + 项目规范变更提示）② Artifact Ownership guardrail（workflow-start/orchestrator 双 skill + architecture-design agent 唯一负责人声明）③ architecture-reviewer A4 双对照源（brief + PRD 功能清单）+ 子实体 CRUD 完整性检查 ④ architecture-design api.md PRD 功能→API 端点映射表 ⑤ change-split-auditor Dim 1 子实体操作完整性检查 ⑥ s4-split-validate change 目录命名 `v{N}-C{n}-{kebab-name}` + change_dag prd_version ⑦ 代码层补齐 arch_review_* + dp_a_* 字段（修复 v0.28.1 死命令）；来源：workflow-feedback 2026-07-31 × 7（#1~#7）；457/457 测试全过 | ✅ 2026-07-31 |
| v0.30.0    | workflow 健壮性增强（设计增强方案 v0.11 §38/§39，9 个 workflow-feedback 四根因修复）：① RC-A 行为规范补齐（跨 change 隔离 guardrail + 实事求是原则 + 修复→审查串行 + state 禁写横展 + 统一结果协议 + workflow-start DP 编号错位修正）② RC-B 子代理投递（注册 spec-writer/contract-builder/build-executor/release-archivist/need-explorer 5 个 agent + skills 预加载 + 路由下沉 + 返回即验证门）③ RC-C CLI（tf state transition 相对路径 bug 修复 + VALID_STATES 抽共享 + writeState 校验 + doctor 非法 state 巡检）④ RC-D tf isolate 多仓库工作区重构（.worktrees/<change>/<repo>，Case A/B 布局识别）；agents 10→15（含 cross-change-consistency-checker 颜色 orange→red，关闭 P2-22）；B4 WHEN/THEN 校验降级 v0.31.0（P2-26）；来源：workflow-feedback 2026-08-01 ×9（#100000~#100009）；459/459 测试全过 | ✅ 2026-08-01 |

## 规划中里程碑

| 版本      | 里程碑                 | 核心内容                                                                                                                                                          | 状态                    |
| ------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| v0.31.0 | **测试矩阵驱动开发**        | 测试矩阵驱动开发流程 + 测试复利闭环（设计增强方案 v0.12）：① test-strategy skill（10+1 种 design_method + 分层策略 + 对抗验证 + 复杂度分级）② test-matrix.md 产物（12 列字段 + 候选覆盖台账 + 对抗验证段）③ docs/test-ledger/ 全局测试台账 + tf test-merge 复利回写 ④ build-executor/code-reviewer/release-archivist 改造 ⑤ guard test-matrix-complete + 豁免策略 ⑥ glaf4-tests 对接方案；来源：LT 审查（2026-08-01）+ glaf4-tests 插件 + S03 单元测试课程 + 三方评审 | ✅ 2026-08-01（发布当日 C1-domain-policy 事件暴露门禁三重绕过 → v0.32.1 硬化，见 v0.13） |
| v0.32.1 | **测试门禁硬化**          | C1-domain-policy 事件修复（设计增强方案 v0.13 §47-§53）：① 豁免键修正 schema_version（init 打戳，删除内容型豁免 + hash null 短路）② 门禁前移 test-matrix-ready（approved-for-build→executing）③ tests-passing 程序化（tf test record + 证据落盘 + 关闭手工通道 + dp_6 去证据化）④ review 硬化（禁 base==head + receipt 测试统计）⑤ SOP 批次（contract-builder 矩阵 MUST + release-archivist 零测试条款 + 路由归位）⑥ doctor/validate 巡检扩展；来源：C1 事件四方证据验证 + LT 四项决策（2026-08-03） | ✅ 2026-08-03（0.32.0 打包事故撤回，版本号不可复用，以 0.32.1 重发） |
| v0.32.2 | **工作流写入门禁修复 patch** | C1 死锁链修复三件套：① pre-tool-use-guard 路径化（change 目录内产物写入放行，目录外维持状态门禁——修复 exploring/specifying/bridging 阶段产物写入被误伤、被迫 Bash 绕过的问题）② exploring→specifying 移除 artifacts-exist（P3-10，产物齐全性由 specifying→bridging 独家负责）③ hooks/session-start PLUGIN_VERSION 纳入 team-flow.mjs version 自动同步（消除每次发版手工修 hook 的中断）；来源：C1 事件死锁链复盘 + LT 决策（2026-08-03） | ✅ 2026-08-03 |
| v0.33.0 | **skills 注入恢复（frontmatter YAML 修复）** | frontmatter YAML 非法导致 skills: 预加载静默失效的修复（设计增强方案 v0.13 §54）：① 15 个 agent description 单句化（删除顶格 `<example>` 块——YAML 块标量断裂根因）→ 恢复 `skills:` 预加载与 `tools:` 限制 ② e2e/test-strategy 两个 SKILL.md frontmatter 裸冒号修复 ③ frontmatter-lint 长效门禁（js-yaml 严格解析全部 agents/skills/commands frontmatter + 必填字段 + skills 引用解析，进 npm test）；来源：C1 补救流程实证发现注入=0 + glaf4 对照组实证 + LT 决策（2026-08-03） | ✅ 2026-08-03 |
| v0.34.1 | **工作空间支持** | conventions-generator 支持多子项目扫描（v0.34.1 新增） | ✅ 2026-08-04 |
| v0.35.0 | **C1 workflow-feedback 根因修复** | 6 条 feedback 4 根因聚类（设计增强方案 §55）：① test-merge.mjs 自调用 bug 修复 ② revise 保留 reviews/ 目录（receipt 不随 hash 丢失）③ 新增 tf execution refresh-hash ④ 新增 tf deisolate（worktree 生命周期管理）⑤ build-executor BLOCKED 证据链 ⑥ 原子代理上下文水位例外条款 ⑦ release-archivist closing deisolate advisory；来源：vrm4teamflow workflow-feedback 2026-08-05 + 4 专家交叉验证 | ✅ 2026-08-05 |
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
| P0-6 | 产品级架构设计增强（v0.14 §57-§66，v0.36.0）：architecture 阶段编排 + 产品级文档模板（6 产物）+ 变更级输入联动（路由分流）+ arch-merge 重构（当前态 upsert/生成式/冲突预检/并发安全 4 硬门禁）+ 旧项目逆向重建（arch-reverse-analyst）+ guard 门禁（arch-readiness/arch-snapshot + arch_baseline 豁免） | ✅ v0.36.0（2026-08-05） | v0.36.0 | 来源：LT 三诉求 2026-08-03 + 四专家评审 + 复利/change 级评估；设计增强方案 v0.14 |

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
| P1-15 | 架构设计显式编排与产物独立化（v0.9 §26）：① workflow-start 路由表增加 architecture-design 子代理调用（exploring→specifying 之间） ② architecture-design 判断+执行一体化 SOP + 结构化输出契约 ③ 产出目录从 `specs/<cap>/` 提升为独立 `architecture/` ④ spec-writer Required Inputs 增加 `architecture/` 读取 ⑤ workflow-start 合理性确认机制 + yaml 字段 + 硬阻断 ⑥ hotfix/tweak 不豁免 | ✅ v0.23.0（2026-08-05 补登：CLAUDE.md 记载 v0.22.5+/v0.23.0 已贯通，roadmap 状态此前未同步） | v0.23.0 | 来源：LT+CC 讨论（2026-07-27） |
| P1-16 | ce-brainstorm Phase 0.0 增加 tf CLI 可用性检查和显式降级逻辑：① 先检查 `which tf` ② 不可用时走 fallback（询问用户：默认模板 or 自定义路径）③ 在工作区创建模板（`.team-flow/templates/`）④ 维护配置文件到 `.team-flow/team-flow.config.json` | 🔲 待实施 | v0.26.0 | 来源：workflow-feedback 2026-07-29（P1） |
| P1-17 | ce-brainstorm SKILL.md 增加 guardrail：禁止写入 skill 目录（显式声明项目级制品只在项目工作区创建/修改） | 🔲 待实施 | v0.26.0 | 来源：workflow-feedback 2026-07-29（P1） |
| P1-22 | architecture-design agent 精简（WHO/WHAT only，229→~100 行）+ `skills:` 字段预加载 Skill 完整知识库 | ✅ 2026-07-31 | v0.28.1 | 来源：workflow-feedback 2026-07-31（P1-1 agent-quality）+ 设计增强方案 v0.11 §35 |
| P1-23 | workflow-start SKILL.md 主干补强三步协议摘要（dispatch→auto-review→reasonableness check）+ Guardrails/State Writes 同步 | ✅ 2026-07-31 | v0.28.1 | 来源：workflow-feedback 2026-07-31（P1-2 sop-flow）+ 设计增强方案 v0.11 §36 |
| P1-24 | 横展验证：扫描 10 个 agent 是否存在同样的"Agent 堆 HOW"反模式 | ✅ 2026-07-31 | v0.28.1 | 来源：LT 横展需求 + 设计增强方案 v0.11 §35.4；结果：3 个 Category A2（bug-investigator/code-reviewer/prototype-builder）需修复，5 个 Category B 无对应 Skill 暂不修复，1 个 Category C 轻量级无需修复 |
| P1-25 | bug-investigator agent 精简（180→~85 行）+ `skills:` 字段预加载 + HOW 内容迁移至 SKILL.md（Report Format / Quality Standards / Edge Cases） | ✅ 2026-07-31 | v0.28.1 | 来源：P1-24 横展验证 + 设计增强方案 v0.11 §37 |
| P1-26 | code-reviewer agent 精简（171→~100 行）+ `skills:` 字段预加载 + HOW 内容迁移至 SKILL.md（6 步 Review Process / Severity Levels / Calibration Rules） | ✅ 2026-07-31 | v0.28.1 | 来源：P1-24 横展验证 + 设计增强方案 v0.11 §37 |
| P1-27 | prototype-builder agent 精简（230→~95 行）+ `skills:` 字段预加载 + HOW 内容迁移至 references/builder-methodology.md（Build Process Steps 0-4 / Hard Constraints / Seed Composition / P0-P2 自检 / Deliverable Hard Gate / Decision-Point Interaction） | ✅ 2026-07-31 | v0.28.1 | 来源：P1-24 横展验证 + 设计增强方案 v0.11 §37 |
| P1-28 | workflow-start 增加「跨 change 隔离」Guardrail + 接入 cross-change-consistency-checker | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100000） |
| P1-29 | 注册 spec-writer/contract-builder/build-executor/release-archivist/need-explorer 为 agent（skills 预加载）+ 路由下沉 + 返回即验证门 | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100001 #100006） |
| P1-30 | 子代理实事求是原则：reviewer 建议先查代码验证，存疑据实反馈主代理 | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100002） |
| P1-31 | workflow-start 四步协议修复→审查严格串行 + 并行白名单 + 三步/四步表述修正 | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100003） |
| P1-32 | tf isolate 重构为多仓库工作区 .worktrees/<change>/<repo>（Case A/B 布局识别） | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100009） |
| P1-33 | 新增 `skills/test-strategy/SKILL.md` + references/（10+1 种 design_method + 分层策略 + 对抗验证 + 复杂度分级） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §41 |
| P1-34 | spec-writer SKILL.md 增加 Unit/Integration 可选标签（测试矩阵上游输入） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §44.1 |
| P1-35 | build-executor implementer-prompt.md 增强：按矩阵 TDD + 五步闭环 + 两不原则 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §44.2 |
| P1-36 | code-reviewer SKILL.md + prompt 增强：Test Matrix Compliance 审查维度 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §44.3 |
| P1-37 | release-archivist SKILL.md 增加 Step 2b Test Matrix Reconciliation（条件触发） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §44.4 |
| P1-38 | build-executor agents 声明 `skills: [build-executor, test-strategy]` 预加载 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §41.3 |
| P1-39 | 豁免键修正：state init 打戳 `schema_version`（仅 change 创建时；rebuild/set 禁追加、不进 SETTABLE_FIELDS）+ `test_matrix_skip_reason`/`test_evidence_path` 字段 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §48.1；LT 决策 2026-08-03 |
| P1-40 | test-matrix-complete 重构：legacy/skip 双豁免 + 删除内容型豁免 + 删除 hash null 短路 + skip 必附理由 + 共享豁免模块 test-gate-exemptions.mjs | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §48.2-48.4 |
| P1-41 | test-matrix-ready 新增：full approved-for-build→executing 门禁前移（矩阵存在非空 OR 显式 skip；hotfix/tweak 豁免） | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §49；LT 决策 2026-08-03 |
| P1-42 | 新增 `tf test record` 命令：maven-surefire（含 XML 目录）/jest/pytest 解析器 + auto 识别 + 证据落盘 `.superpowers/test-evidence/` + 无手工通道 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §50.1；LT 决策"一步到位程序化" |
| P1-43 | tests-passing 重构：结构化 test_result 解析（recorded-by=tf-test-record）+ dp_6_result 去证据化（BUG-A 通道仅存量保留）+ total=0 空真拒绝 + 证据文件存在性校验 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §50.2 |
| P1-44 | pre-tool-use-guard 路径化改造：写入目标在 change 目录内（产物区：architecture/、specs/、proposal/design/tasks/contract/matrix 等）→ 放行；change 目录外（代码区）→ 维持状态门禁（仅 approved-for-build/executing/debugging 放行）。修复 exploring/specifying/bridging 阶段产物写入被一刀切拦截、LLM 被迫 Bash 绕过（写入彻底脱管）的死锁；与 P3-10 联动解除 C1 死锁链 | ✅ v0.32.2（2026-08-03） | v0.32.2 | 来源：C1 死锁链复盘（hook L105-116 状态一刀切误伤产物写入）+ LT 决策（2026-08-03） |
| P1-45 | §54 frontmatter YAML 合法性事件设计写回：四轮实证证据链（诊断探针/行为探针/glaf4 对照/PyYAML 解析）+ 根因（非法 YAML → Claude Code 静默降级丢弃 skills:/tools: 元数据）+ 修复决策 + 教训（机制断言必须实证、静默降级是最危险失效模式、行为探针优于字符串内省） | ✅ v0.33.0（2026-08-03） | v0.33.0 | 来源：C1 补救流程发现 skills 注入=0；LT 决策（2026-08-03） |
| P1-48 | 产品级架构事件建模深度：事件风暴模板 + 事件来源矩阵 + 聚合不变量反推启发式（v0.14 §64.2） | 🔲 待实施 | v0.36.0+ | 来源：v0.14 §64.2；DDD 评审 |
| P1-49 | BC 依赖环检测工具化：domains/ 与 ARCHITECTURE.md §1 图论校验 | 🔲 待实施 | v0.36.0+ | 来源：v0.14 §64.2 |

### P2（改善，按节奏推进）

| ID   | 待办                                                                                           | 状态                | 目标版本    | 备注                                                       |
| ---- | -------------------------------------------------------------------------------------------- | ----------------- | ------- | -------------------------------------------------------- |
| P2-16 | config-loader.mjs 增加 `.team-flow/` 目录查找优先级（查找顺序：① .team-flow/ → ② 根目录 → ③ git 根 → ④ home） | 🔲 待实施 | v0.26.0 | 来源：workflow-feedback 2026-07-29（P2） |
| P2-17 | 项目配置文件迁移至 `.team-flow/` 目录（team-flow.config.json → .team-flow/team-flow.config.json） | 🔲 待实施 | v0.26.0 | 来源：workflow-feedback 2026-07-29（P2） |
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
| P2-22 | Agent color 无效值修复：`cross-change-consistency-checker` 和 `prototype-builder` 使用了 `orange`（不在有效颜色列表 blue/cyan/green/yellow/magenta/red 中），改为 `yellow` 或 `red` | ✅ 2026-08-01 | v0.30.0 | cross-change-consistency-checker orange→red（prototype-builder 已是 green，横展确认 agents/ 仅此一处）；来源：v0.28.0 plugin-validator |
| P2-23 | 子代理 state 禁写红线横展 5 skill + 5 agent + CLI 纵深防御（writeState 校验 + doctor 巡检） | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100004） |
| P2-24 | tf state transition 错误提示升级 + 绝对路径一致性（path.resolve）+ VALID_STATES 抽共享 | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100005） |
| P2-26 | validator 补 WHEN/THEN 结构校验（B4 降级：需专项夹具防回归） | 🔲 待实施 | v0.32.0+ | 来源：v0.30.0 §39.2 降级项（v0.31.0 未实施，顺延） |
| P2-27 | 定义 test-matrix.md 格式规范（12 列 + schema 强制覆盖 + 对抗验证段） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §42 |
| P2-28 | contract-builder SKILL.md 改造：生成 test-matrix.md 附属产物 + 注入 test-ledger baselines | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §42 + §43.5 |
| P2-29 | hash.mjs 新增 computeTestMatrixHash + state-loader 新增 test_matrix_hash / test_matrix_skipped 字段 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §42.5 + §45.4 |
| P2-30 | scripts/guard/checks/test-matrix-complete.mjs 新增 + guard.mjs 矩阵更新 + 豁免策略（tweak/hotfix/显式跳过/存量兼容） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §45 |
| P2-31 | scripts/lib/test-merge.mjs 新增（6 步流程 + 三方合并 + INDEX 重写） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §43.3 |
| P2-32 | docs/test-ledger/ 目录结构定义 + INDEX.md / baselines/ / patterns/ / changelog/ 格式规范 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §43.1-43.2 |
| P2-33 | test-ledger 注入机制：contract-builder + S1 路由 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §43.5 |
| P2-34 | execution review 硬化：base≠head（禁空 diff review）+ receipt tests 统计字段（--tests-total/passed/failed） | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §51 |
| P2-35 | 矩阵 hash 接线：contract-builder SOP 生成后必跑 tf state rebuild + tf validate 矩阵 hash 漂移警告 + 双向互锁（段↔文件） | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §51.3 + §52 B1 |
| P2-36 | contract-builder：agent 补 test-strategy 预加载（修复预加载断点）+ 矩阵生成 MUST 化 + skip 必附理由 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §52 B1 |
| P2-37 | release-archivist：零测试条款（0 tests ≠ PASS）+ tf test record 对接 + Step 2b 非 legacy FAIL + dp_6 去证据化说明 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §52 B2 |
| P2-38 | workflow-start：glaf4-tests 路由归位（触发主体=contract-builder）+ 入口门禁前移引导 + build-executor 返回验证补测试文件检查 | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §52 B3 |
| P2-39 | doctor 巡检扩展：skip_reason 配对 + 产物引用完整性（arch_review_report/test_evidence_path）；checkChangeTestGates | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §52 B4 |
| P2-40 | hooks/session-start 的 PLUGIN_VERSION 纳入 `team-flow.mjs version` 自动同步范围（或 check-version-consistency --fix 支持）：消除每次发版 npm version 脚本链必中断、手工 sed 修 hook 的重复踩坑（v0.27.1/v0.27.2/v0.32.0/v0.32.1 四次实证） | ✅ v0.32.2（2026-08-03） | v0.32.2 | 来源：v0.32.0/v0.32.1 升版事故复盘 + LT 决策（2026-08-03）；附带修复 major 硬编码为 0 缺陷 |
| P2-41 | frontmatter YAML 修复：15 个 agent description 单句化（删除顶格 `<example>` 块——块标量断裂根因，学 glaf4 写法）+ e2e/test-strategy 两个 SKILL.md description 裸冒号修复 → 恢复 skills: 预加载与 tools: 限制。**行为变更**：子代理工具集从全量（含全部 MCP）收紧为声明集 | ✅ v0.33.0（2026-08-03） | v0.33.0 | 来源：v0.13 §54.5；LT 决策"精简单句 + 删除示例"（2026-08-03） |
| P2-46 | ER/时序图自动渲染 + 提交图与生成图漂移检测（pretty-mermaid/archify） | 🔲 待实施 | v0.36.0+ | 来源：v0.14 §64.2 |
| P2-47 | arch-merge 语义冲突增强：聚合不变量级冲突检测（两 delta 改同一不变量语义相反） | 🔲 待实施 | v0.36.0+ | 来源：v0.14 §64.2 |

### P3（低优先级，时机成熟再做）

| ID   | 待办                                           | 状态           | 目标版本   | 备注                                               |
| ---- | -------------------------------------------- | ------------ | ------ | ------------------------------------------------ |
| P3-1 | "ce-" 前缀正名：保留 ce- + README 命名约定文档化（方案C） | ✅ 2026-07-24 | v1.0.0 | 改 tf- 是伪统一，文档说明即可 |
| P3-2 | recon-probe.sh 并入 `ssf recon` CLI | 🔲 待实施 | v1.0.0+ | 来源：v0.8 §18.4.2 |
| P3-3 | ce-brainstorm 无头模式兼容：headless 检测 + 自动选推荐 | 🔲 待实施 | v1.0.0+ | 来源：v0.16.0 无头测试 |
| P3-4 | S3 ce-plan grounding 性能：增量 grounding | 🔲 待实施 | v1.0.0+ | 来源：v0.16.0 无头测试 |
| P3-5 | 统一子代理结果传递协议（FINAL VERDICT + SendMessage 权威结果） | ✅ 2026-08-01 | v0.30.0 | 来源：workflow-feedback 2026-08-01（#100008） |
| P3-6 | scripts/lib/test-matrix-export.mjs（glaf4 格式转换） | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §46.1 |
| P3-7 | routing-rules.md 新增 glaf4-tests 路由段 | ✅ v0.31.0（2026-08-01） | v0.31.0 | 来源：v0.12 §46.2 |
| P3-9 | 报告生成纪律：LLM 重构报告必须现场核对（session-handoff Guardrail #6） | ✅ v0.32.1（2026-08-03） | v0.32.0 | 来源：v0.13 §52 B5；C1 报告 10+ 处失真教训 |
| P3-10 | exploring→specifying 门禁时序修复：`exploring:specifying` 移除 `artifacts-exist` 维度（产物齐全性由 `specifying:bridging` 独家负责，该维度本就挂着）——消除"先转换被拦、先产物没转换"的鸡生蛋；与 P1-44 联动解除 C1 死锁链（环2） | ✅ v0.32.2（2026-08-03） | v0.32.2 | 来源：v0.13 待办表；C1 报告问题 #5 + 死锁链复盘；LT 确认方案 A（2026-08-03） |
| P3-11 | ~~存量超限 SKILL.md 渐进式披露收敛~~ | 🗑️ 不执行 | — | LT 决策 2026-08-03：不需要执行（存量超限非功能问题，接受现状） |
| P3-12 | frontmatter-lint 长效门禁：js-yaml 严格解析全部 agents/skills/commands frontmatter + name/description 必填断言 + agent name 与文件名一致 + skills: 引用必须解析到真实 skills/<name>/SKILL.md；进 npm test（58 例），杜绝非法 frontmatter 静默降级复发 | ✅ v0.33.0（2026-08-03） | v0.33.0 | 来源：v0.13 §54.5；教训"门禁要校验产物有效性，不能只校验存在性" |
| P3-13 | 全局 API 消费者影响扫描（变更端点时提示受影响消费方） | 🔲 待实施 | — | 来源：v0.14 §64.2 |
