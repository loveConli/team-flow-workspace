---
name: ima-docx
description: "创建和编辑 Word 文档。当用户需要创建、编辑、套模板或转换 Word/docx/doc/docm/dotx 文件时使用此 skill。不适用于：仅读取/查看文档内容（用 fetch 工具）、PDF、电子表格或与文档生成无关的任务。"
---

# DOCX Skill

## 环境契约（IMA 沙箱保证）

研发已确认以下资源在沙箱内可用：

- Python 包：python-docx 已预装最新版
- LibreOffice headless：用于 .doc→.docx 和 .docx→pdf 转换
- 中文字体：fontconfig 已注册 `"Noto Sans SC"`（来自 NotoSansSC TTF）

注意：fontconfig 里**没有**"宋体"/"黑体"。docx 文档在 IMA 沙箱内用 LibreOffice 转 PDF 时，找不到"宋体"会 fallback 到默认字体。如果交付物是 PDF，建议创建 docx 时直接用 `'Noto Sans SC'`。

---

## 路由

根据用户意图，选择对应路由并严格按照该路由的步骤执行。

| 用户想要... | 路由 |
|---|---|
| 从零创建文档（"做一个/写一个/生成一个"） | → 创建 |
| 读取 / 分析文档（"看一下/提取/分析"） | → 读取 |
| 编辑现有文档（"改一下/替换/更新"） | → 编辑 |
| 套模板 / 统一样式（"按这个模板/统一风格"） | → 模板 |
| .doc → .docx 或 → PDF（"转成/导出"） | → 转换 |

---

## 创建

**标准流程：**

1. 确定文档类型 → 选择排版参数（见下方排版规范）
2. 写 Python 脚本创建文档
3. 保存并告知用户输出路径

**基础模板（中文文档）：**

```python
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

doc = Document()

# ── 页面设置 ──
section = doc.sections[0]
section.page_width = Cm(21)
section.page_height = Cm(29.7)
section.top_margin = Cm(2.54)
section.bottom_margin = Cm(2.54)
section.left_margin = Cm(3.18)
section.right_margin = Cm(3.18)

# ── 设置中文字体的辅助函数 ──
def set_style_cjk_font(style, cn_font, en_font):
    """为样式设置中西文字体（含容错）"""
    style.font.name = en_font
    rPr = style.element.get_or_add_rPr()
    rFonts = rPr.find(qn('w:rFonts'))
    if rFonts is None:
        rFonts = OxmlElement('w:rFonts')
        rPr.insert(0, rFonts)
    rFonts.set(qn('w:eastAsia'), cn_font)
    rFonts.set(qn('w:ascii'), en_font)
    rFonts.set(qn('w:hAnsi'), en_font)

# ── 正文样式 ──
normal = doc.styles['Normal']
normal.font.size = Pt(12)
set_style_cjk_font(normal, '宋体', 'Times New Roman')
normal.paragraph_format.line_spacing = 1.5

# ── 标题样式（去掉默认的蓝色、主题引用和底部横线）──
def clean_heading_style(style):
    """清除标题样式的主题色和边框线"""
    style.font.color.rgb = RGBColor(0, 0, 0)
    rPr = style.element.get_or_add_rPr()
    rFonts = rPr.find(qn('w:rFonts'))
    if rFonts is not None:
        for attr in ['w:asciiTheme', 'w:hAnsiTheme', 'w:eastAsiaTheme', 'w:cstheme']:
            if rFonts.get(qn(attr)):
                del rFonts.attrib[qn(attr)]
    # 去掉段落边框（Title 样式的底部横线）
    pPr = style.element.find(qn('w:pPr'))
    if pPr is not None:
        pBdr = pPr.find(qn('w:pBdr'))
        if pBdr is not None:
            pPr.remove(pBdr)

# Title 样式
title_style = doc.styles['Title']
set_style_cjk_font(title_style, '黑体', 'Arial')
clean_heading_style(title_style)

# Heading 1-3
for i in range(1, 4):
    h_style = doc.styles[f'Heading {i}']
    set_style_cjk_font(h_style, '黑体', 'Arial')
    clean_heading_style(h_style)

# ── 标题 ──
heading = doc.add_heading('文档标题', level=0)
heading.alignment = WD_ALIGN_PARAGRAPH.CENTER

# ── 正文 ──
doc.add_paragraph('正文内容')

# ── 保存 ──
os.makedirs(os.path.dirname(output_path), exist_ok=True)
doc.save(output_path)
```

**常用元素：**

```python
# 无序列表
doc.add_paragraph('条目', style='List Bullet')

# 有序列表
doc.add_paragraph('步骤', style='List Number')

# 表格
table = doc.add_table(rows=3, cols=4, style='Table Grid')

# 图片（居中）
doc.add_picture('image.png', width=Cm(15))
doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER

# 分页
from docx.enum.text import WD_BREAK
doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
```

**页眉页脚 + 页码：**

```python
from docx.oxml.ns import nsdecls
from docx.oxml import parse_xml

section = doc.sections[0]

# 页眉
header = section.header
header.is_linked_to_previous = False
header.paragraphs[0].text = "页眉文本"
header.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER

# 页脚页码
footer = section.footer
footer.is_linked_to_previous = False
footer_para = footer.paragraphs[0]
footer_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="begin"/>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:instrText {nsdecls("w")} xml:space="preserve"> PAGE </w:instrText>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="end"/>'))
```

---

## 读取

**首选方案：IMA 文档解析 API**

通过 IMA 解析服务将 docx 转为 Markdown，支持复杂排版、表格、图片等场景。

**标准流程：**

1. 获取文件的 COS URL
2. 调用解析 API，获取 download_url
3. 下载 zip 并解压，得到 Markdown 结果

```bash
# ── 1. 获取文件可访问 URL ──
cos_key=$(ima_cos_util -f input.docx)
cos_url=$(ima_cos_url -c "$cos_key")

# ── 2. 调用解析 API ──
body=$(printf '{"url": "%s", "file_name": "%s"}' "$cos_url" "input.docx")
response=$(curl -sS -X POST 'https://ima.qq.com/openapi/mcp_cloud_agent/parse_file' \
    -H "ima-openapi-clientid: $IMA_OPENAPI_CLIENTID" \
    -H "ima-openapi-apikey: $IMA_OPENAPI_APIKEY" \
    -H "Content-Type: application/json" \
    -d "$body")
download_url=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['download_url'])")

# ── 3. 下载并解压 ──
curl -sS -o /tmp/parsed_result.zip "$download_url"
unzip -o /tmp/parsed_result.zip -d /tmp/parsed_result

# ── 4. 读取解析后的 Markdown ──
cat /tmp/parsed_result/*.md
```

备注：
- ima_cos_util、ima_cos_url的使用约束：1）是平台内置的虚拟命令，直接使用即可，无需检查是否存在；2）各自独立 shell 调用 —— 每个虚拟命令必须作为单独的 shell() 工具调用发出。禁止：在同一 shell 调用中用 $() 捕获其输出、用 &&/;/| 组合、或在 Python 脚本中 subprocess 调用
- $IMA_OPENAPI_CLIENTID 和 $IMA_OPENAPI_APIKEY 为 IMA 平台自动注入的环境变量，无需手动配置

**备选方案：python-docx 直接读取（降级）**

当解析 API 不可用时（网络异常、服务故障），降级使用 python-docx。注意：python-docx 直接读取无法完美还原复杂排版。

```python
from docx import Document

doc = Document("input.docx")

# 1. 输出基本信息
print(f"段落数: {len(doc.paragraphs)}")
print(f"表格数: {len(doc.tables)}")
print(f"节数: {len(doc.sections)}")

# 2. 输出段落结构（索引 + 样式 + 内容摘要）
for i, para in enumerate(doc.paragraphs):
    if para.text.strip():
        print(f"[{i}] style={para.style.name} | {para.text[:80]}")

# 3. 输出表格内容
for t, table in enumerate(doc.tables):
    print(f"\n--- 表格 {t} ({len(table.rows)}x{len(table.columns)}) ---")
    for row in table.rows:
        print([cell.text[:30] for cell in row.cells])
```

读取后根据用户意图决定下一步：用自然语言向用户总结文档内容，或作为编辑操作的前置步骤。

---

## 编辑

**标准流程：**

1. 用 python-docx 打开文档，输出段落索引和样式（代码同上方"读取"路由的备选方案）
2. 执行编辑操作
3. 保存到新路径（不覆盖原文件）

> 注意：编辑前的结构探查不用 IMA API。编辑需要段落索引和样式名来精确定位。

**文本替换（处理 run 边界）：**

```python
def replace_text_in_paragraph(paragraph, old_text, new_text):
    """安全替换，处理跨 run 文本。"""
    full_text = paragraph.text
    if old_text not in full_text:
        return False
    for run in paragraph.runs:
        if old_text in run.text:
            run.text = run.text.replace(old_text, new_text)
            return True
    # 跨 run：合并到第一个 run
    new_full = full_text.replace(old_text, new_text)
    for run in paragraph.runs:
        run.text = ""
    paragraph.runs[0].text = new_full
    return True

# 替换所有位置（段落 + 表格）
for para in doc.paragraphs:
    replace_text_in_paragraph(para, old, new)
for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            for para in cell.paragraphs:
                replace_text_in_paragraph(para, old, new)
```

**在指定位置插入段落：**

```python
from docx.oxml.ns import nsdecls
from docx.oxml import parse_xml

def insert_paragraph_after(paragraph, text, style=None):
    new_p = parse_xml(f'<w:p {nsdecls("w")}/>')
    paragraph._p.addnext(new_p)
    new_para = type(paragraph)(new_p, paragraph._parent)
    new_para.text = text
    if style:
        new_para.style = style
    return new_para
```

**删除段落：**

```python
def delete_paragraph(paragraph):
    paragraph._element.getparent().remove(paragraph._element)
```

**关键原则：**
- 文本替换用 `replace_text_in_paragraph`，不要直接赋值 `paragraph.text`（会丢格式）
- 插入/删除用 XML 操作，`add_paragraph()` 只能追加到末尾
- 别忘了表格内的文本
- 保留原有样式，不要主动修改

---

## 模板

基本思路：
1. 打开模板文档，提取样式定义
2. 确定源文档样式 → 模板样式的映射关系
3. 遍历段落/表格，应用映射后的样式
4. 保存

进阶用法（复制样式 XML、处理不同样式名映射等）参见 `references/python_docx_guide.md`。

---

## 转换

**标准命令：**

```bash
# .doc → .docx
libreoffice --headless --convert-to docx input.doc

# .docx → PDF
libreoffice --headless --convert-to pdf input.docx

# 批量转换
libreoffice --headless --convert-to docx --outdir ./output/ *.doc
```

执行前先检查 LibreOffice 是否可用：
```bash
which libreoffice || which soffice
```

---

## 排版规范

创建文档时，**优先按用户指定的格式**。用户没指定时，使用以下通用默认值：

| 属性 | 中文默认值 | 英文默认值 |
|------|-----------|-----------|
| 页面 | A4, 上下 2.54cm 左右 3.18cm | Letter, 1 inch |
| 正文 | 宋体 + Times New Roman, 12pt, 1.5 倍行距 | Calibri, 11pt, 1.15 |
| 标题 | 黑体 + Arial | Calibri |
| 首行缩进 | 2 字符 (Pt(24)，基于 12pt 字号) | 无 |

### 标题层级

- **文档大标题**：`doc.add_heading('...', level=0)` — "Title" 样式，居中
- **一级标题（章）**：`level=1`（Heading 1）
- **二级标题（节）**：`level=2`（Heading 2）

不要跳级（比如从 Heading 1 直接到 Heading 3）。

---

## 防坑规则

### 1. 中文字体必须双设

`font.name` 只管西文。中文需要 XML 层设 `w:eastAsia`，否则中文显示为 Calibri/等线。

```python
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

# 容错写法（处理 rFonts 不存在的情况）
rPr = style.element.get_or_add_rPr()
rFonts = rPr.find(qn('w:rFonts'))
if rFonts is None:
    rFonts = OxmlElement('w:rFonts')
    rPr.insert(0, rFonts)
rFonts.set(qn('w:eastAsia'), '宋体')
```

> 或直接使用创建模板中的 `set_style_cjk_font` 辅助函数。

### 2. 标题样式自带蓝色和底部横线

python-docx 默认模板的 Title/Heading 样式带有蓝色主题色和底部边框。不处理的话标题会是蓝色的，Title 下面会多一条线。

→ 使用创建模板中的 `clean_heading_style` 函数清除。

### 3. 单元格底色必须用 XML

python-docx 没有设置单元格背景色的 API：

```python
from docx.oxml.ns import nsdecls
from docx.oxml import parse_xml
shading = parse_xml(f'<w:shd {nsdecls("w")} w:fill="4472C4"/>')
cell._tc.get_or_add_tcPr().append(shading)
```

### 4. 列表样式名必须精确

正确：`'List Bullet'`、`'List Number'`、`'List Bullet 2'`
错误：`'Bullet List'`、`'bullet'`、`'list-bullet'`（会 KeyError）

### 5. 目录只是占位符

python-docx 插入的 TOC 域代码不会自动生成内容。必须告知用户：打开文档后按 Ctrl+A → F9 刷新目录。

### 6. 保存前确保目录存在

```python
import os
os.makedirs(os.path.dirname(output_path), exist_ok=True)
doc.save(output_path)
```

---

## 参考资料

按需读取，不要一次全读：
- `references/python_docx_guide.md` — python-docx 进阶用法（XML 层操作、复杂表格、合并单元格、不同节不同页眉、浮动图片、超链接等）
