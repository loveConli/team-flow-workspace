# Skill 质量自检清单

> 配套 lt-skill-forge 的 Phase 2 质量自查。标注「*」者为 ima 内部 skill 可选（公开发布到 Skill 市场才强制）。来源：Anthropic 官方《Skill authoring best practices》+ 社区《Claude Code Skill Quality Checklist》+ 《Skill 高质量编写与使用指南》。

---

## 创建前识别（Phase 0）
- [ ] 频次/复用滤镜通过（解决"一类问题"，非一次性任务）
- [ ] 价值滤镜通过（补知识差 or 补执行差，非重复 LLM 能力）
- [ ] SOP 已萃取（回溯 / 异常萃取 / 抽象到一类）
- [ ] 三问自检全过（触发边界 / 可执行性 / 反向排除）

---

## Frontmatter (10)
- [ ] `name`：kebab-case，≤64 字符（社区建议 ≤40）
- [ ] `description` 第一句说做什么
- [ ] `description` 列触发条件（具体短语 / 意图关键词）
- [ ] `description` 含不适用边界
- [ ] `description` 控制在 ~200 字符（过长移入正文）
- [ ] `tags`*：3–8 项，混合维度（如 `lang:typescript`, `type:code-review`）
- [ ] `allowed-tools`*：收窄到实际使用的范围
- [ ] `license`*：注明（公开分发才需）
- [ ] `version`*：已发布则设置（如 1.2.0）
- [ ] frontmatter 无拼写错误（注意 `tags` 非 `tag`，YAML 忽略未知键）

---

## Body (12)
- [ ] `## 概述`：1–2 句说明做什么
- [ ] 流程清晰：只读步骤标题能串成操作链
- [ ] `## 示例`：≥2 个真实输入→输出对
- [ ] `## 不适用场景（When NOT to use）`：独立反触发章节（单一最大质量信号）
- [ ] `## Gotchas / 常见坑`：高语境坑点沉淀（信息密度最高部分）
- [ ] 无内联密钥 / PII
- [ ] 单一职责（无 "and…and…and"）
- [ ] 不与 LLM 默认冲突
- [ ] 外部命令 safe-by-default
- [ ] 代码块带语言标签（如 ```typescript）
- [ ] 明确命名真实工具 / 文件
- [ ] 渐进式披露（细节拆 references/，SKILL.md ≤400 行）

---

## Discovery (3)
- [ ] 新会话下 2/3 触发语能选中本 skill
- [ ] 读者 10 秒读懂意图
- [ ] 与已有 skill 无碰撞

---

## Distribution (5) * 仅公开分发需
- [ ] LICENSE 文件置于仓库根
- [ ] 注明 source-of-truth URL（frontmatter / README）
- [ ] 可找到联系方式
- [ ] 版本已 tag（哪怕 v0.1.0）
- [ ] 可能被误用则加 SECURITY.md
