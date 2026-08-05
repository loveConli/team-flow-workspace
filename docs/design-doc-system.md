# 设计文档体系

> 本文件从 CLAUDE.md 抽取（2026-07-25），按需加载。

## 文档层级与定位

```
设计增强方案（唯一真相源，定义 WHY + WHAT + 决策记录）
  → AGENTS.md（插件运行时参考，定义 HOW，必须与真相源同步）
  → 各 SKILL.md（执行指令，必须与 AGENTS.md 一致）
  → CLAUDE.md（工作区级指令摘要，必须与 AGENTS.md 一致）
```

## 核心设计文档

| 文档                   | 路径                                                    | 定位                                                                         | 版本规则                                                                   |
| -------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **架构/API/DB 设计增强方案** | `docs/architecture-api-db-design-enhancement-v{X}.md` | team-flow 插件的**唯一权威设计文档**。定义设计目标、方法论底座（F1-F8）、SOP 闭环、产物结构、复利机制、集成规则、决策落实状态 | 文件名带版本号；每次重大设计变更**新增版本文件**，旧版保留不删；文件内部标题版本可超前于文件名 |
| **插件设计总纲**           | `team-flow/AGENTS.md`                                 | 面向 LLM 和贡献者的运行时参考：能力概览、Skills 索引（必须与实际 `skills/` 目录一致）、SOP、产物结构、配置、约束      | 必须与最新设计增强方案和实际 skills/ 目录保持同步                                          |
| 原型设计调研               | `docs/prototype-design-research.md`                   | 原型方案选型调研（五方案对比），结论已吸收进设计增强方案第十五章                                           | 仅作历史参考，不再独立维护                                                          |
| 产品级架构设计文档（v0.36.0） | `docs/architecture/iterations/vN/architecture.md`     | 产品级详细架构（6 产物：BC/聚合注册表/指令事件/状态机/概念 ER/时序），architecture 阶段产出，预测态快照，三层数据面 L3 层 | 随迭代 vN 新建，迭代收尾标 archived；全局当前态由 arch-merge 从 change 增量维护 |

## 辅助文档（team-flow/ 子仓库内）

| 文档        | 路径                                    | 定位                                |
| --------- | ------------------------------------- | --------------------------------- |
| README    | `team-flow/README.md`                 | 安装指南 + 快速上手（面向用户），skill 计数必须与实际一致 |
| CHANGELOG | `team-flow/CHANGELOG.md`              | 版本变更记录                            |
| 状态机       | `team-flow/docs/state-machine.md`     | 8 态状态机详细定义                        |
| 决策点       | `team-flow/docs/decision-points.md`   | DP-0 到 DP-7 决策门定义                 |
| 平台矩阵      | `team-flow/docs/platform-matrix.md`   | 9 安装面兼容性矩阵                        |
| 制品契约      | `team-flow/docs/artifact-contract.md` | 制品格式与校验规则                         |

## 设计增强方案版本规则

- **文件命名**：`docs/architecture-api-db-design-enhancement-v{X}.md`，X 为版本号
- **新增 vs 修订**：重大设计变更（新章节、SOP 重画、方法论变更）→ 新增版本文件；小幅修订（措辞修正、决策状态更新）→ 在当前版本文件内修订
- **旧版保留**：历史版本文件**保留不删**，仅供追溯
- **修订摘要**：每个版本文件开头必须有修订摘要，说明相较上一版的关键变更点
- **决策落实状态**：设计增强方案末尾的"决策落实状态"章节是决策追踪的唯一真相源，每次决策确认后必须更新

## 工作区 docs/ 目录管理

- `architecture-api-db-design-enhancement*.md`：设计增强方案版本系列（唯一权威设计文档）
- `prototype-design-research.md`：原型方案选型调研（已吸收，仅作历史参考）
- `external-references/`：外部参考资料，新增时维护 README.md 索引
- `plan/`：实现计划
- 新增设计文档时，必须在本文件和 CLAUDE.md 工作区结构中登记
