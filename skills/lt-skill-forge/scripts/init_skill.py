#!/usr/bin/env python3
"""
init_skill.py — 技能目录初始化脚本（lt-skill-forge 增强版）

用法: python3 init_skill.py <skill-name> [--path <path>]

默认路径: /sandbox/workspace/skills/

纯 Python 3.12 标准库实现，无第三方依赖。
模板已内置「## 不适用场景（When NOT to use）」与「## Gotchas / 常见坑」章节，
符合《Skill 高质量编写与使用指南》的质量标准。
"""

import sys
import re
from pathlib import Path

DEFAULT_PATH = "/sandbox/workspace/skills"

SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: 第一句说做什么。中间列触发条件（用户会怎么说来触发）。最后说不适用的场景。控制在 ~200 字符。]
---

# {skill_title}

## 概述

[TODO: 1-2 句话说明这个技能做什么，解决哪一类问题]

## 选择技能结构

[TODO: 根据技能用途选择合适的结构模式。常见模式：
1. 流程型（有明确步骤的工作流）—— ## 工作方式 → ## Phase 1 → ## Phase 2 → ...
2. 任务型（多种独立操作，按意图路由）—— ## 决策表 → ## 操作原则
3. 规范型（标准/规范/指南类）—— ## 规范细则 → ## 检查清单
4. 能力集型（多个关联功能）—— ## 核心能力 → ### 1. 功能名
模式可混合，以一种为主。选定后删除本段。]

## [TODO: 根据选定结构替换为第一个主要章节，如 ## 工作方式 或 ## Phase 1]

[TODO: 填充内容。流程步骤用祈使句、有序；解释 WHY 让 Agent 在边界情况自主判断；长流程设确认门；引用 scripts/references。]

## 示例

[TODO: 至少 2 个覆盖典型场景的输入→输出对。1 个像特例，2 个为最低。例：
**示例 1：** 输入：xxx → 输出：xxx
**示例 2：** 输入：xxx → 输出：xxx]

## 不适用场景（When NOT to use）

[TODO: 独立反触发章节，单一最大质量信号。列 3-5 个本技能**不应**触发的场景。若想不出，说明范围过宽需拆分。例：
- 用户只想要一次性结果、不打算复用 → 直接处理，不调用本技能
- 场景 X → 用 Y 技能更合适
- 场景 Z → 不属于本技能覆盖范围]

## Gotchas / 常见坑

[TODO: 信息密度最高的部分。沉淀真实执行反复踩的坑、隐性边界、与默认解法的偏离点。这是技能区别于"说明书"的关键。例：
- 数据表是 append-only，必须取最高版本行而非最新 created_at
- staging 环境 webhook 未成功也返回 200，需从 payment_events 判真实状态]

## 资源目录

本技能包含以下资源目录，用于组织不同类型的附属文件：

### scripts/
可直接执行的脚本（Python/Bash 等），用于确定性或重复性操作。

**适合放置：** 数据处理脚本、文件转换工具、校验脚本等。

**注意：** 脚本可以直接执行而无需加载到上下文中，但 Agent 可以读取脚本内容进行调整。

### references/
按需加载到上下文中的参考文档，用于指导 Agent 的处理过程。

**适合放置：** 详细的工作流指南、API 文档、领域知识、检查清单等超出 SKILL.md 篇幅的内容。

### assets/
不加载到上下文中，而是在输出中使用的文件。

**适合放置：** 模板文件、图标、字体、样板代码等。

---

**不需要的目录可以删除。** 不是每个技能都需要全部三种资源。
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
{skill_name} 的辅助脚本

这是一个占位脚本，可直接执行。
根据实际需求替换实现，或在不需要时删除。
"""

def main():
    print("这是 {skill_name} 的示例脚本")
    # TODO: 添加实际的脚本逻辑
    # 例如：数据处理、文件转换、格式校验等

if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# {skill_title} 参考文档

这是参考文档的占位文件。根据实际需求替换内容，或在不需要时删除。

## 何时需要 reference 文件

reference 文件适合放置：
- 超出 SKILL.md 篇幅的详细指南
- 按领域/场景拆分的专项文档
- 检查清单、评分标准等结构化参考
- 只在特定步骤需要的背景知识（含 Gotchas 坑点明细）
"""

EXAMPLE_ASSET = """# 示例资源文件

此占位文件代表 assets 目录的用途。根据实际需求替换为真实资源文件（模板、图片、字体等），或在不需要时删除。

assets 文件不会被加载到上下文中，而是在 Agent 的产出中使用。

常见资源类型：
- 模板：.pptx, .docx, .html
- 图片：.png, .jpg, .svg
- 字体：.ttf, .otf, .woff2
- 样板代码：项目目录、初始文件
- 数据文件：.csv, .json, .yaml
"""


def title_from_name(skill_name: str) -> str:
    """kebab-case 转标题格式。"""
    return " ".join(word.capitalize() for word in skill_name.split("-"))


def init_skill(skill_name: str, path: str) -> Path | None:
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"错误: 目录已存在: {skill_dir}")
        return None

    # 校验 name 格式
    if not re.match(r"^[a-z][a-z0-9-]*$", skill_name):
        print(f"错误: name 必须是 kebab-case（小写字母开头，只含小写字母、数字、连字符），当前: {skill_name}")
        return None

    if skill_name.startswith("-") or skill_name.endswith("-") or "--" in skill_name:
        print(f"错误: name 不能以连字符开头/结尾，也不能包含连续连字符，当前: {skill_name}")
        return None

    if len(skill_name) > 64:
        print(f"错误: name 不得超过 64 字符，当前 {len(skill_name)} 字符")
        return None

    skill_title = title_from_name(skill_name)

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"创建目录: {skill_dir}")
    except Exception as e:
        print(f"错误: {e}")
        return None

    # 创建 SKILL.md
    skill_md_path = skill_dir / "SKILL.md"
    try:
        skill_md_path.write_text(
            SKILL_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title),
            encoding="utf-8",
        )
        print(f"创建: SKILL.md（已含 不适用场景 / Gotchas 章节）")
    except Exception as e:
        print(f"错误: {e}")
        return None

    # 创建资源目录和示例文件
    try:
        scripts_dir = skill_dir / "scripts"
        scripts_dir.mkdir(exist_ok=True)
        example_script = scripts_dir / "example.py"
        example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name), encoding="utf-8")
        example_script.chmod(0o755)
        print(f"创建: scripts/example.py")

        references_dir = skill_dir / "references"
        references_dir.mkdir(exist_ok=True)
        example_ref = references_dir / "reference.md"
        example_ref.write_text(EXAMPLE_REFERENCE.format(skill_title=skill_title), encoding="utf-8")
        print(f"创建: references/reference.md")

        assets_dir = skill_dir / "assets"
        assets_dir.mkdir(exist_ok=True)
        example_asset = assets_dir / "example_asset.txt"
        example_asset.write_text(EXAMPLE_ASSET, encoding="utf-8")
        print(f"创建: assets/example_asset.txt")
    except Exception as e:
        print(f"错误: {e}")
        return None

    print(f"\n技能 '{skill_name}' 初始化完成: {skill_dir}")
    print("下一步：编辑 SKILL.md，替换 [TODO] 占位符；删掉不需要的空资源目录。")
    return skill_dir


def main():
    import argparse

    parser = argparse.ArgumentParser(description="初始化技能目录骨架（lt-skill-forge 增强版）")
    parser.add_argument("skill_name", help="技能名，kebab-case，≤64 字符")
    parser.add_argument("--path", default=DEFAULT_PATH, help=f"基路径，默认 {DEFAULT_PATH}")
    args = parser.parse_args()

    result = init_skill(args.skill_name, args.path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
