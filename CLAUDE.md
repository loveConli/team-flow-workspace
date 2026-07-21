# Team Flow 聚合工作空间

Claude 聚合工作空间根目录，由 parent 级独立 Git 仓库维护。存放跨项目规范、设计文档、工作计划，不托管子工程源码。

## 工作区结构

- `docs/` - 设计文档目录
  - `external-references/` - 外部参考资料（架构参考、最佳实践等）
  - `plan/` - 实现计划与方案
- `team-flow/` - 核心工具库（独立 Git 仓库，已被 .gitignore 忽略）
- `skills/` - GLAF4 技能定义
- `architecture-design-source/` - 架构设计源文件

## 规范要求

### 子工程管理
- `team-flow/` 为独立 Git 仓库，parent 级不跟踪其变更
- 子工程变更需进入子目录单独提交

### 文档管理
- 设计文档统一存放在 `docs/` 目录
- 外部参考文档存放在 `docs/external-references/`
- 实现计划存放在 `docs/plan/`
- 根目录下的散落文档应逐步迁移到 docs 目录

### 代码规范
- 遵循 GLAF4 技能规范
- 优先参考既有实现方案
- 核心代码需增加说明注释
