# python-docx 进阶参考

当 SKILL.md 的标准流程不够用时，查阅本文档。只收录 python-docx API 不直接支持、需要 XML 操作或容易写错的场景。

---

## 1. 表格进阶

### 合并单元格

```python
# 水平合并
table.cell(0, 0).merge(table.cell(0, 2))  # 第一行前 3 格合并

# 垂直合并
table.cell(0, 0).merge(table.cell(2, 0))  # 第一列前 3 行合并
```

### 单元格边框

```python
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def set_cell_border(cell, **kwargs):
    """
    用法: set_cell_border(cell, top={"sz": 12, "val": "single", "color": "000000"})
    可选边: top, bottom, left, right
    """
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = tcPr.find(qn('w:tcBorders'))
    if tcBorders is None:
        tcBorders = OxmlElement('w:tcBorders')
        tcPr.append(tcBorders)
    for edge, attrs in kwargs.items():
        elem = OxmlElement(f'w:{edge}')
        for attr_name, attr_val in attrs.items():
            elem.set(qn(f'w:{attr_name}'), str(attr_val))
        tcBorders.append(elem)
```

### 垂直居中

```python
from docx.enum.table import WD_ALIGN_VERTICAL

for row in table.rows:
    for cell in row.cells:
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
```

---

## 2. 页眉页脚进阶

### 不同节使用不同页眉

```python
new_section = doc.add_section()
new_section.header.is_linked_to_previous = False
new_section.footer.is_linked_to_previous = False

doc.sections[0].header.paragraphs[0].text = "第一章"
doc.sections[1].header.paragraphs[0].text = "第二章"
```

### 首页不同页眉

```python
section = doc.sections[0]
section.different_first_page_header_footer = True
section.first_page_header.paragraphs[0].text = "首页专用页眉"
section.header.paragraphs[0].text = "正文页眉"
```

### "第 X 页 / 共 Y 页" 格式

```python
from docx.oxml.ns import nsdecls
from docx.oxml import parse_xml

footer_para = section.footer.paragraphs[0]
footer_para.alignment = WD_ALIGN_PARAGRAPH.CENTER

footer_para.add_run("第 ")
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="begin"/>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:instrText {nsdecls("w")} xml:space="preserve"> PAGE </w:instrText>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="end"/>'))
footer_para.add_run(" 页 / 共 ")
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="begin"/>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:instrText {nsdecls("w")} xml:space="preserve"> NUMPAGES </w:instrText>'))
run = footer_para.add_run()
run._r.append(parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="end"/>'))
footer_para.add_run(" 页")
```

---

## 3. 超链接

python-docx 没有超链接 API，需要 XML：

```python
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def add_hyperlink(paragraph, text, url):
    part = paragraph.part
    r_id = part.relate_to(
        url,
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
        is_external=True,
    )
    hyperlink = OxmlElement('w:hyperlink')
    hyperlink.set(qn('r:id'), r_id)
    new_run = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    color = OxmlElement('w:color')
    color.set(qn('w:val'), '0563C1')
    rPr.append(color)
    u = OxmlElement('w:u')
    u.set(qn('w:val'), 'single')
    rPr.append(u)
    new_run.append(rPr)
    new_run.text = text
    hyperlink.append(new_run)
    paragraph._p.append(hyperlink)
    return hyperlink
```

---

## 4. 做不到的事（建议替代方案）

| 需求 | python-docx 支持度 | 替代方案 |
|------|:---:|------|
| 浮动图片（文字环绕） | ❌ | 用表格布局实现图文混排，或在模板中预设 |
| 水印 | ❌ | 在模板文档中预设水印，用代码填充内容 |
| 真正的目录内容 | ❌ | 只能插 TOC 域代码占位，告知用户打开后刷新 |
| 修订标记 (Track Changes) | 只读 | 不支持写入修订 |
