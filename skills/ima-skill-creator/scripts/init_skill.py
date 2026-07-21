#!/usr/bin/env python3
"""
init_skill.py — 技能目录初始化脚本

用法: python3 init_skill.py <skill-name> [--path <path>]

默认路径: /sandbox/workspace/skills/

纯 Python 3.12 标准库实现，无第三方依赖。
"""

import sys
import re
from pathlib import Path

DEFAULT_PATH = "/sandbox/workspace/skills"

SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: 第一句说做什么。中间列触发条件（用户会怎么说来触发）。最后说不适用的场景。]
---

# {skill_title}

## 概述

[TODO: 1-2 句话说明这个技能做什么]

## 选择技能结构

[TODO: 根据技能用途选择合适的结构模式。常见模式：

**1. 流程型**（适用于有明确步骤的工作流）
- 适合有清晰阶段的顺序任务
- 示例：报告生成技能——"你的工作方式" → "需求理解" → "信息收集" → "大纲规划" → "分章节撰写" → "整合交付"
- 结构：## 你的工作方式 → ## Phase 1：步骤名 → ## Phase 2：步骤名 → ... → ## 多轮修改

**2. 任务型**（适用于提供多种独立操作的技能）
- 适合没有固定顺序、根据用户意图路由到对应操作的任务
- 示例：知识库管理技能——"快速开始" → "创建文件夹" → "移动文件" → "删除文件"
- 结构：## 你的工作方式 → ## 决策表 → ## 操作原则

**3. 规范型**（适用于标准、规范或指南类技能）
- 适合品牌指南、编码规范、合规要求等需要在执行中遵守的规则
- 示例：品牌写作规范技能——"写作风格" → "用词规范" → "格式要求" → "审查清单"
- 结构：## 概述 → ## 规范细则 → ## 检查清单

**4. 能力集型**（适用于多个相互关联功能的集成系统）
- 适合提供多个有关联的功能模块的技能
- 示例：客服工作台技能——"核心能力" → "1. 查询订单" → "2. 处理退款" → "3. 升级工单"
- 结构：## 概述 → ## 核心能力 → ### 1. 功能名 → ### 2. 功能名

模式可以混合使用。大多数技能以一种为主，按需组合其他模式。

选定后删除本段——这只是指引。]

## [TODO: 根据选定结构替换为第一个主要章节]

[TODO: 填充内容。参考已有技能中的做法：
- 流程型技能的阶段划分和确认门设计
- 决策表驱动的意图路由
- 覆盖典型场景的工作流示例
- 对 scripts/references 的引用]

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
- 只在特定步骤需要的背景知识
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
        print(f"创建: SKILL.md")
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
    print("\n后续步骤:")
    print("1. 编辑 SKILL.md，完成所有 [TODO] 项并删除选型指引段落")
    print("2. 根据需要替换或删除 scripts/、references/、assets/ 中的示例文件")
    return skill_dir


def main():
    if len(sys.argv) < 2:
        print("用法: python3 init_skill.py <skill-name> [--path <path>]")
        print(f"\n默认路径: {DEFAULT_PATH}")
        print("\nname 要求:")
        print("  - kebab-case（小写字母、数字、连字符）")
        print("  - 小写字母开头，不能以连字符开头或结尾")
        print("  - 最长 64 字符")
        print("\n示例:")
        print("  python3 init_skill.py contract-review")
        print("  python3 init_skill.py weekly-report --path /tmp/skills")
        sys.exit(1)

    skill_name = sys.argv[1]

    path = DEFAULT_PATH
    if len(sys.argv) >= 4 and sys.argv[2] == "--path":
        path = sys.argv[3]

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
