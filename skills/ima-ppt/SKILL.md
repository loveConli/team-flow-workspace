---
name: ima-ppt
description: PPT演示文稿的创建与多轮编辑。支持创建PPT、对已有PPT进行修改（新增/编辑/删除/移动页面）、全局风格调整。当用户提到PPT、演示文稿，或涉及创建、编辑、美化PPT时，使用此skill。
---

# PPT 演示文稿

通过 HTML 生成 PPT 演示文稿。每页是一个独立的 1280×720 HTML 文件，存放在同一目录下，最终通过 API 转换为 PPTX。支持多轮编辑。

交付物：**output.pptx** — 通过 API 逐页转换的最终 PPT 文件

---

## 创建流程

```
用户意图
  → Step 1: 内容大纲（输出供用户确认）
  → Step 2: 视觉规划
  → Step 3: 生成每页 slide HTML
  → Step 4: 转换 output.pptx（调用 API）
```

### Step 1：内容大纲

分析用户需求，规划 PPT 的结构骨架。用户自己的逻辑优先，没有明确结构时再辅助构建。

如果用户连主题都不明确，先追问主题和用途再动手。用户提供了附件或资料时，先提取关键内容作为素材。用户没给结构时，可参考常见模型（如 SCQA）辅助梳理。

几个要点：
- 标题要有信息量——"背景介绍"是空洞的类别名，标题应传达这页的核心观点
- 未指定页数时 8-15 页，默认包含封面页和结尾页，默认不生成目录页
- 自检：只读每页标题，连起来应该是一条通顺的逻辑线

⛔ **确认门**：输出大纲后，必须停止当前回复，等待用户确认或调整。禁止在输出大纲的同一回复中执行 Step 2 或调用 file_write 生成 HTML。
例外：用户在需求中明确说了"不用确认""直接做""不用给我看大纲"等类似表述时，可以跳过确认门，但仍需在回复中输出大纲（供用户事后查看），并继续执行 Step 2。

### Step 2：视觉规划

根据大纲的内容主题和受众，确定整套 PPT 的视觉设计语言。

从以下风格中选 1 个作为 Visual Anchor（也可根据内容提出其他风格）：Retro、Memphis、Luxury/Refined、Playful/Toy-like、Editorial/Magazine、Swiss/International、Organic/Natural、Zen/Minimalist

读取 `references/design-guide.md` 了解设计理念和约束，然后**必须按以下模板输出设计规格**（禁止在未输出设计规格的情况下调用 file_write 生成 HTML）：

```
Visual Anchor: [风格名称]
Design Rationale: [一句话，为什么选这个风格]

配色（60-30-10 法则，Tailwind 类名，不用 HEX）:
  60% 背景: bg-[xxx]
  30% 正文: text-[xxx]
  10% 强调: text-[xxx] / bg-[xxx]

字体:
  字体族: [具体字体名]
  标题: [text-size font-weight 等 Tailwind 类名]
  正文: [text-size text-color 等 Tailwind 类名]
```

输出设计规格后无需等待用户确认，直接进入 Step 3。

### Step 3：生成 slide HTML

读取 `references/html-skeleton.md` 获取每页 HTML 的技术骨架，以此为起点生成独立的 HTML 文件（`slide_01.html`、`slide_02.html`...），所有文件存放在同一个 slides 目录下。各页之间无依赖，可并发生成。

⛔ **文件命名必须是 `slide_XX.html`（下划线+两位数字）**。转换服务按文件名中下划线后的数字升序组装 PPT 页面顺序。用其他格式会导致页面顺序错误。

读取 `references/design-guide.md` 了解设计原则，确保每页的设计达成两个目标：观众能在 10 秒内抓住核心观点（Clarity），视觉上协调专业（Aesthetics）。

相邻两页的布局应交替变化，避免视觉单调。

每页自查：
- 所有内容在 1280×720 画布内
- HTML 标签正确闭合
- 只输出代码，禁止输出代码解释、设计说明等额外内容
- ⛔ 所有数据和事实必须可追溯至前序步骤搜集的资料，禁止编造资料中不存在的数字、日期、比例等。资料不足时留空或标注"待补充"，不要用看似合理的数字填充

### Step 4：转换 PPTX

将 slides 目录转换为 output.pptx：

```bash
ima_html_to_ppt -d <slides目录路径>
```

⛔ **硬性规则：此命令必须单独执行。禁止在同一条命令中拼接其他命令（不能用 `&&`、`;`、`|` 等连接其他操作）。一次只执行这一个命令。**

命令会返回生成的 pptx 文件路径。

---

## 编辑流程

用户在首次创建后通常会进行多轮修改。读取 `references/edit-operations.md` 了解各类编辑操作（单页修改、删除、移动、全局风格调整）的详细规则。

核心原则：只改用户要求的部分，其余保持原样。新增或修改的页面必须与整套 PPT 的设计规范一致——修改前先读取 2-3 个已有 slide 的完整 HTML 源码，提取当前设计规范。

### 新增页面（高频操作，必须严格遵守）

新增页面涉及文件重编号，操作不当会导致已有文件被覆盖丢失。必须按以下步骤执行：

**优先使用脚本**（推荐）：

新增页面分两步：

1. 调用脚本，在插入位置腾出空位：
   `bash scripts/reorder_slides.sh insert <slides目录路径> <插入位置页码>`

2. 用 file_write 将新页面内容写入腾出的位置

其中"插入位置页码"是新页面要占据的编号。如用户说"在第 6 页后面加一页"，则插入位置页码 = 7。

**手动操作时的硬性规则**（脚本不可用时）：
```
① 用临时文件名写入新页面（如 slide_new.html）
   ⛔ 禁止直接用目标文件名写入——会覆盖已有文件

② 倒序重编号：从最后一个文件开始往前改名
   for i in $(seq <最大页码> -1 <插入位置页码>); do
     mv slide_$(printf "%02d" $i).html slide_$(printf "%02d" $((i+1))).html
   done
   ⛔ 禁止正序重编号——会导致连锁覆盖

③ 将临时文件改名到空出来的位置
   mv slide_new.html slide_$(printf "%02d" <插入位置页码>).html
```

删除和移动页面同理：
- 删除：`bash scripts/reorder_slides.sh delete <slides目录路径> <要删除的页码>`
- 移动：`bash scripts/reorder_slides.sh move <slides目录路径> <原页码> <目标页码>`

### 编辑后同步

每次编辑完成后，重新执行转换命令（`ima_html_to_ppt -d <slides目录路径>`，同样必须单独执行），然后向用户确认修改内容和当前页面序列。

---

## 参考文件

这些文件包含执行各步骤时需要的详细规范，按需读取：

- `references/html-skeleton.md` — HTML 技术骨架、约束与原因（Step 3 时读取）
- `references/design-guide.md` — 设计理念、配色排版规范、素材策略（Step 2/3 时读取）
- `references/edit-operations.md` — 编辑操作补充规则（编辑时读取）
- `scripts/reorder_slides.sh` — slide 文件重编号工具（新增/删除/移动页面时调用）
