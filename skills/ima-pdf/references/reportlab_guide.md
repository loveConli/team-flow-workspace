# reportlab 进阶参考

当 SKILL.md 的基础模板不够用时，查阅本文档。

---

## 1. 复杂表格

### 合并单元格

```python
from reportlab.platypus import Table, TableStyle
from reportlab.lib import colors

data = [
    ["合并标题", "", "", ""],
    ["A", "B", "C", "D"],
    ["1", "2", "3", "4"],
]

table = Table(data, colWidths=[4*cm, 4*cm, 4*cm, 4*cm])
table.setStyle(TableStyle([
    ('SPAN', (0, 0), (3, 0)),  # 第一行全部合并
    ('ALIGN', (0, 0), (3, 0), 'CENTER'),
    ('BACKGROUND', (0, 0), (3, 0), colors.HexColor('#4472C4')),
    ('TEXTCOLOR', (0, 0), (3, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
]))
```

### 表格内换行

```python
from reportlab.platypus import Table, Paragraph
from reportlab.lib.styles import getSampleStyleSheet

styles = getSampleStyleSheet()

# 单元格内容用 Paragraph 包裹才能自动换行
data = [
    [Paragraph("很长的标题文本会自动换行", styles['Normal']), "短"],
    [Paragraph("另一段长文本内容", styles['Normal']), "短"],
]

# 设置列宽，Paragraph 才知道何时换行
table = Table(data, colWidths=[10*cm, 4*cm])
```

### 交替行底色

```python
style_commands = [
    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4472C4')),  # 表头
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
]

# 奇数数据行上色
for i in range(1, len(data)):
    if i % 2 == 1:
        style_commands.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor('#F2F2F2')))

table.setStyle(TableStyle(style_commands))
```

---

## 2. 自定义页面模板

### 不同页面用不同页眉/页脚

```python
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate, NextPageTemplate

def cover_template(canvas, doc):
    """封面页：无页眉页脚"""
    pass

def body_template(canvas, doc):
    """正文页：有页眉页脚"""
    canvas.saveState()
    width, height = A4
    canvas.setFont('Helvetica', 9)
    canvas.drawString(2.5*cm, height - 1.5*cm, "正文页眉")
    canvas.drawCentredString(width/2, 1.5*cm, f"第 {doc.page} 页")
    canvas.restoreState()

# 定义两个模板
frame = Frame(2.5*cm, 2.5*cm, A4[0]-5*cm, A4[1]-5*cm)

doc = BaseDocTemplate("output.pdf")
doc.addPageTemplates([
    PageTemplate(id='cover', frames=[frame], onPage=cover_template),
    PageTemplate(id='body', frames=[frame], onPage=body_template),
])

# story 中切换模板
story = [
    Paragraph("封面", styles['Title']),
    NextPageTemplate('body'),
    PageBreak(),
    Paragraph("正文开始", styles['Heading1']),
]

doc.build(story)
```

---

## 3. 图文混排

### 图片插入

```python
from reportlab.platypus import Image
from reportlab.lib.units import cm

# 指定宽度，高度自动按比例
img = Image("photo.png", width=8*cm, height=6*cm)
story.append(img)
```

### 图片居中

```python
from reportlab.platypus import Image, Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER

img = Image("photo.png", width=10*cm, height=7*cm)
img.hAlign = 'CENTER'
story.append(img)
```

### 图片加标题

```python
caption_style = ParagraphStyle('Caption', parent=styles['Normal'],
                                fontSize=9, alignment=TA_CENTER, textColor=colors.grey)

story.append(img)
story.append(Paragraph("图 1: 系统架构图", caption_style))
```

---

## 4. 多栏布局

```python
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm

width, height = A4
margin = 2*cm
gutter = 0.5*cm
col_width = (width - 2*margin - gutter) / 2

frame1 = Frame(margin, margin, col_width, height - 2*margin)
frame2 = Frame(margin + col_width + gutter, margin, col_width, height - 2*margin)

doc = BaseDocTemplate("two_column.pdf")
doc.addPageTemplates([
    PageTemplate(id='twocol', frames=[frame1, frame2])
])
```

---

## 5. 做不到的事

| 需求 | reportlab 支持度 | 替代方案 |
|------|:---:|------|
| 编辑已有 PDF 的文本 | ❌ | pypdf 只能做页面级操作（合并/旋转等），不能改文字 |
| 真正的"编辑 PDF" | ❌ | PDF 是终态格式，不像 docx 能改内容。建议从源头重新生成 |
| 复杂数学公式 | 有限 | 简单的用 `<super>`/`<sub>`；复杂的考虑先用 LaTeX 渲染为图片再插入 |
| 交互式表单创建 | 有限 | reportlab 的 AcroForm 支持有限，复杂表单建议用专业工具设计 |
