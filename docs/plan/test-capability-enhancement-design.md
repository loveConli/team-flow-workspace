# team-flow 测试能力增强设计方案（v1.0）

> 设计时间：2026-08-04
> 状态：**P0/P1/P2 已实施完成**
> 优先级：P0/P1/P2
> 测试状态：571/571 通过（含 15 个新增测试）

---

## 一、背景和目标

### 1.1 背景

team-flow 当前的测试能力：
- ✅ 测试设计方法论（test-strategy，10+1 种方法）
- ✅ TDD 铁律（build-executor Law 2，RED→GREEN→REFACTOR）
- ✅ 测试矩阵机制（test-matrix.md 生成→执行→归档闭环）
- ✅ 测试门禁（3 个 guard 维度：ready/passing/complete）
- ✅ 测试归档（test-merge → test-ledger 跨 change 复利）

glaf4-test 的能力：
- ✅ 测试设计（8 个覆盖维度、复杂度分级、组合覆盖声明）
- ✅ 测试代码生成（write-unit-worker、write-integration-worker）
- ✅ 测试验证（validate-worker、Maven/JUnit 运行、Surefire 分析）
- ✅ 质量门禁（design_gate、scanner、compile、validate）

**关键发现**：
- 两个系统在测试方法论层面已高度对齐（design_method、复杂度分级、work_mode 完全一致）
- glaf4-test 的 TDD 实现存在架构级差距（RED 是声明式的、REFACTOR 缺失、多 Worker 架构割裂）
- team-flow 的通用性架构允许吸收部分能力，但 Java 专用部分不应吸收

### 1.2 目标

1. **吸收 glaf4-test 的通用能力**：组合覆盖声明、测试质量规则、failure 分类法
2. **保持 team-flow 的通用性**：不硬编码 Java 专用规则
3. **建立 conventions 机制**：plugin 内置默认 conventions，支持版本化管理和自动更新
4. **支持全新项目初始化**：workflow-bootstrap 增加交互式引导

---

## 二、核心设计决策

### 2.1 职责划分

| 能力 | 负责方 | 理由 |
|------|--------|------|
| **TDD 执行（RED→GREEN→REFACTOR）** | team-flow build-executor | 必须保持紧凑循环，不能割裂 |
| **测试设计（test-matrix 生成）** | team-flow contract-builder | 通用方法论，已对齐 |
| **测试代码生成** | team-flow implementer 子代理 | 保持通用性，通过 conventions 注入技术栈规范 |
| **测试验证** | team-flow tf test record | 通用 runner 支持（maven-surefire/jest/pytest） |
| **TDD 证据链** | team-flow build-executor | 必须记录 RED/GREEN 日志 |
| **门禁校验** | team-flow guard | 统一门禁机制 |

### 2.2 能力吸收策略

#### 可吸收（P0/P1/P2）

| 优先级 | 能力 | 来源 | 工作量 | 收益 |
|--------|------|------|--------|------|
| **P0** | 组合覆盖声明 + 对账 | glaf4-test design-worker | 小（SKILL.md 增强） | 填补 test-strategy 的覆盖盲区 |
| **P1** | 测试质量规则（通用部分） | glaf4-test scan-generated-tests.py | 中（references/ 文档） | 提升 code-reviewer 的测试审查质量 |
| **P1** | failure analysis 分类法 | glaf4-test analyze-surefire-failures.py | 小（bug-investigator 增强） | 结构化测试失败诊断 |
| **P2** | 社交测试契约声明 | glaf4-test social-test-contracts.md | 小（test-strategy 增加章节） | 集成测试的组织方法论 |
| **P2** | 测试隔离分级 | glaf4-test h2-rabbitmq-redis.md | 小（references/ 文档） | 集成测试的分层策略 |

#### 不可吸收（Java 专用）

| 能力 | 理由 | 接入方式 |
|------|------|---------|
| test_kind 12 枚举 | Java/Spring 专用 | 通过 test-matrix-export.mjs 桥接 |
| MockMvc/H2/Redis/RabbitMQ 测试模式 | Java/Spring 专用 | 通过 conventions 注入 |
| Spring 合同检查 | Spring 专用 | 通过 glaf4-test 外部管线路由 |
| GLAF4 框架契约 | GTMC 内部框架专用 | 通过 glaf4-test 外部管线路由 |

---

## 三、conventions 机制设计

### 3.1 核心原则

1. **plugin 内置默认 conventions**：符合 glaf4-test 要求的 Java 技术栈规范
2. **版本化管理**：conventions 带版本号，支持更新检查
3. **分层设计**：默认层（plugin 内置）+ 项目层（用户自定义）
4. **更新通知**：team-flow 更新时检查 conventions 版本，提示用户

### 3.2 目录结构

#### plugin 内置模板

```
team-flow/
├── templates/
│   └── conventions/
│       ├── _manifest.json              # 模板清单（版本、描述、适用技术栈）
│       ├── java-testing.md             # Java 测试规范（JUnit 5 + Mockito）
│       ├── spring-patterns.md          # Spring Boot 测试规范
│       ├── js-testing.md               # JavaScript 测试规范（Jest/Vitest）
│       ├── python-testing.md           # Python 测试规范（Pytest）
│       └── glaf4-compliant/            # 符合 glaf4-test 要求的规范
│           ├── java-testing.md
│           └── spring-patterns.md
```

#### 项目 conventions

```
项目根目录/
├── .team-flow/
│   ├── conventions/
│   │   ├── java-testing.md             # 从 plugin 复制，可自定义
│   │   ├── spring-patterns.md
│   │   └── .versions.json              # 版本信息
│   └── team-flow.config.json           # conventions 路径映射
```

### 3.3 conventions 文件格式

**文件头部**：
```markdown
---
name: java-testing
version: 1.0.0
updated_at: 2026-08-04
source: team-flow plugin (glaf4-test compliant)
description: Java 测试规范（JUnit 5 + Mockito）
tech_stack: [java, junit5, mockito]
glaf4_compliant: true
---

# Java 测试规范（glaf4-test 兼容）

...
```

### 3.4 版本管理

**.versions.json 格式**：
```json
{
  "conventions": {
    "java-testing.md": {
      "source_version": "1.0.0",
      "installed_at": "2026-08-04",
      "customized": false,
      "last_checked": "2026-08-04"
    }
  }
}
```

### 3.5 更新检查机制

**触发时机**：
- `workflow-start` 的 S1 阶段（路径路由器）
- `tf version upgrade` 时
- 用户手动执行 `/team-flow conventions check`

**检查逻辑**：
1. 读取项目 `.versions.json`
2. 读取 plugin `_manifest.json`
3. 比较版本号
4. 检测用户是否自定义
5. 提示用户更新

**更新提示**：
```
检测到 conventions 有新版本：
  - java-testing.md: 1.0.0 → 1.1.0
  - 自定义状态：未自定义

? 选择处理方式：
  → [Y] 更新到最新版本（推荐）
    [N] 保持当前版本
    [D] 查看差异
```

---

## 四、workflow-bootstrap 增强

### 4.1 两条路径设计

| 路径 | 触发条件 | 行为 |
|------|---------|------|
| **存量项目路径** | 检测到 pom.xml/package.json 等 | 自动识别技术栈，生成 conventions |
| **全新项目路径** | 未检测到任何技术栈特征 | 交互式引导用户选择技术栈，生成 conventions + 项目骨架 |

### 4.2 存量项目路径

```
workflow-bootstrap B1
  ├── recon-probe.sh 检测到 pom.xml
  ├── codebase-recon-analyst 识别：Java 17 + Spring Boot 3 + JUnit 5 + Mockito
  ├── conventions-generator
  │   ├── 读取 plugin 内置模板
  │   ├── 复制到项目 .team-flow/conventions/
  │   ├── 更新 .versions.json
  │   └── 更新 team-flow.config.json
  └── 产出 baseline.md
```

### 4.3 全新项目路径

```
workflow-bootstrap B1
  ├── recon-probe.sh：未检测到技术栈特征
  └── interactive-setup（新增）
      ├── 询问：编程语言（Java/JavaScript/Python）
      ├── 询问：构建工具（Maven/Gradle/npm/yarn/pip/poetry）
      ├── 询问：测试框架（JUnit 5/Jest/Pytest）
      ├── 询问：应用框架（Spring Boot/Express/Django）
      ├── conventions-generator 生成 conventions
      ├── project-scaffolder（可选）生成项目骨架
      └── 产出 baseline.md
```

---

## 五、实际使用流程

### 5.1 首次接入（workflow-bootstrap）

```
用户：/workflow-start bootstrap "初始化 Java 项目"

workflow-bootstrap B1
  ├── 识别技术栈：Java + Spring Boot + JUnit 5 + Mockito
  ├── conventions-generator
  │   ├── 读取 plugin 内置模板
  │   ├── 复制到项目 .team-flow/conventions/
  │   ├── 更新 .versions.json
  │   └── 更新 config
  └── 产出 baseline.md
```

### 5.2 后续变更（workflow-start）

```
用户：/workflow-start full "为 UserService 添加分页查询功能"

workflow-start S1
  └── conventions 更新检查

workflow-start S3（计划阶段）
  └── contract-builder
      ├── 读取 conventions
      ├── 生成 test-matrix.md（含组合覆盖声明）
      └── 生成 execution-contract.md

workflow-start S5（执行阶段）
  └── build-executor
      ├── 读取 conventions
      ├── 注入到 implementer 子代理
      └── implementer 按 TDD 铁律执行

tf test record → guard 门禁 → test-merge
```

---

## 六、能力吸收实施计划

### 6.1 P0：组合覆盖声明（立即可做）

**吸收位置**：`team-flow/skills/test-strategy/SKILL.md`

**增加内容**：
```markdown
## §8 组合覆盖声明

当目标方法满足以下条件之一时，矩阵中必须声明组合覆盖策略：

1. **多参数方法**（param_count > 1）：声明 `pairwise`，要求至少一个 equivalence/boundary 用例覆盖参数组合
2. **有分支逻辑**（if/case/switch）：声明 `branch`，要求至少一个 state/path 用例覆盖各分支

声明格式（在 test-matrix.md 的 description 列中）：
- `[pairwise] 已覆盖参数组合 A×B, A×C`
- `[branch] 已覆盖 true/false 分支`
- `[not_applicable] 单参数无分支，无需组合覆盖`
```

### 6.2 P1：测试质量规则

**吸收位置**：`team-flow/skills/test-strategy/references/test-quality-rules.md`

**可抽取的 15 条通用规则**：
1. `missing-meaningful-assertion`：测试没有有效断言
2. `weak-assertion-only`：只有 assertNotNull/isNotNull
3. `verify-only-without-assertion`：只有 mock verify 没有状态断言
4. `system-out`/`print-stack-trace`：调试代码残留
5. `disabled-test`/`unfinished-test-todo`：禁用/未完成的测试
6. `hardcoded-sample-like-value`：检测到样本数据
7. `real-external-url`：测试中包含真实外部 URL
8. `large-test-class`：测试类过大
9. `generic-test-class-name`：类名过于泛化
10. 矩阵对账规则：case-method-not-found、case-test-file-mismatch、evidence-not-in-method、extra-test-methods

### 6.3 P1：failure analysis 分类法

**吸收位置**：`team-flow/scripts/lib/test-record.mjs`

**增加内容**：在测试失败时，按以下 6 类分类：
1. `assertion_failure`：断言不符
2. `runtime_error`：运行时异常（NPE/IAE 等）
3. `framework_error`：框架错误（上下文加载失败等）
4. `compile_error`：编译错误
5. `dependency_blocker`：依赖解析/网络问题
6. `unknown`：未知

### 6.4 P2：社交测试契约

**吸收位置**：`team-flow/skills/test-strategy/references/integration-test-contracts.md`

**可抽取的通用模式**：
- 入口契约：系统边界入口声明
- 协作者契约：依赖分级（真实/mock/stub）
- 数据契约：测试数据规格声明
- 清理契约：测试隔离清理声明

### 6.5 P2：conventions 机制建设

**实施内容**：
1. plugin 内置 conventions 模板（templates/conventions/）
2. conventions-generator（workflow-bootstrap B1 阶段）
3. 版本管理机制（.versions.json + 更新检查）
4. 全新项目交互式引导

---

## 七、风险和缓解措施

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| conventions 更新冲突 | 用户自定义被覆盖 | 提供合并/覆盖/保持三种选项 |
| 全新项目引导过于复杂 | 用户体验差 | 提供合理默认值，减少交互步骤 |
| glaf4-test 规范变更 | conventions 过时 | 版本化管理 + 自动更新检查 |
| 通用性被破坏 | Java 专用规则污染通用框架 | 通过 conventions 注入，不硬编码 |

---

## 八、总结

### 核心设计要点

1. **职责划分清晰**：TDD 执行由 team-flow build-executor 保障，不委托给 glaf4-test
2. **能力吸收有界**：只吸收通用能力，Java 专用部分通过 conventions 注入
3. **conventions 机制完善**：plugin 内置默认规范、版本化管理、自动更新检查
4. **支持全新项目**：workflow-bootstrap 增加交互式引导

### 预期效果

- ✅ Java 项目自动接入 glaf4-test 兼容的测试规范
- ✅ 测试质量规则统一（15 条通用规则）
- ✅ 组合覆盖声明填补盲区
- ✅ failure analysis 分类法提升诊断能力
- ✅ conventions 版本化管理，支持自动更新
- ✅ 全新项目零门槛接入

---

## 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|---------|
| 2026-08-04 | v1.0 | 初始设计完成 |
| 2026-08-04 | v1.0-impl | P0/P1/P2 实施完成（571/571 测试通过） |
