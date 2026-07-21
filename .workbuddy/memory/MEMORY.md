# team-flow-workspace 项目记忆

## 工作空间定位
大哥的「AI Agent 工程化工作流」研发工作区。核心产物是 **team-flow 统一插件**（v0.10.0）：把四套能力合成一个 AI 编程工作流插件，一次安装、四套协同。

## 四套能力（共 17 skills）
1. **spec-superflow**（spec 驱动开发，9 skills）— 上游 MageByte-Zero；8 态变更机 exploring→specifying→bridging→approved-for-build→executing→closing；TDD+SDD+Review Gate 纪律。
2. **compound-engineering 核心子集**（全局复利，6 skills：ce-brainstorm/ce-plan/ce-compound/ce-strategy/ce-ideate/ce-proof）— 上游 EveryInc。
3. **architecture-design**（4A+DDD 增量架构设计，1 skill）— 蒸馏自 LT 知识库 4A/DDD 培训材料（F1–F8 框架）。
4. **prototype**（零外部依赖、可离线本地 HTML 原型，1 skill）。

## 目录结构
- `team-flow/` —— 自研统一插件本体（合并上述四套；TS 底座 `src/`，`npm run build/test/validate`；支持 9 安装面）。
- `compound-engineering/` == `compound-engineering-plugin-main/` —— 上游 Compound Engineering 插件（EveryInc），**两份精确重复副本（diff 无差异）**。
- `spec-superflow/` == `spec-superflow-main/` —— 上游 spec-superflow 插件（MageByte-Zero），**两份精确重复副本（diff 无差异）**。
- `skills/` —— 独立自定义/个人 skill 集合（ima-* 腾讯 ima 集成、lt-* 个人技能、architecture-design、book-to-skill、prod-agent-landing-blueprint、lixiaolai-thinking-truth）。
- `architecture-design-source/4a-ddd-architecture.md` —— architecture-design skill 的源材料。
- 根 md：`architecture-api-db-design-enhancement` v0.1→v0.2→v0.3（架构/API/DB 设计增强方案演进笔记）、`prototype-design-research.md`。

## 关键事实
- 所有目录均无 `.git`（手动 clone/拷贝的快照，非 git 仓库）。
- 两对 `*-main` 与非 `-main` 目录内容完全一致，属冗余副本。
- 设计方法论：F1–F8（4A 分叉依赖 BA→(IA∥AA)→TA、跨域一致性、变更级联、DDD 聚合四要素、限界上下文/Context Map、CQRS、三维判定、增量+复利回写闭环）。
- SOP：模糊需求 → ce-brainstorm/ce-plan → prd/vN（git 分支隔离）→ 拆 change → spec-superflow 8 态 → arch-merge / prototype-sync 顺序提交复利回写全局（docs/architecture/、prototype/、design-system.md）。

## 注意事项
- 复数 vendor 插件当作只读上游；功能改动应在 `team-flow/` 内进行。
- 不要随意删除 `*-main` 副本（可能是上游 main 分支参考快照）；清理前先与大哥确认。
- `prototype/` 全局一份、与 PRD 同级、git 分支隔离；change 引用全局 prototype 作 UI 契约，design.md 不可变。
