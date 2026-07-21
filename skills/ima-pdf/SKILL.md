---
name: ima-pdf
description: "当用户需要创建、操作或填写 PDF 时使用此 skill。包括从零创建 PDF、合并、拆分、旋转、加密解密、水印、表单填写。不适用于：仅读取/查看 PDF 内容（用 fetch 工具）、Word 文档、电子表格或图片处理。"
---

# PDF Skill

## 环境契约（IMA 沙箱保证）

研发已确认以下资源在沙箱内可用，**直接使用主路径**：

- Python 包：pypdf, reportlab 已预装最新版
- 中文字体（TTF）：
  - `/usr/local/share/fonts/custom/NotoSansSC-Regular.ttf`
  - `/usr/local/share/fonts/custom/NotoSansSC-Bold.ttf`

如果主路径不可用，按 try/except 兜底走 STSong-Light（CID 字体，有缺字风险，仅供应急）。

---

## 路由

| 用户想要... | 路由 |
|---|---|
| 从零创建 PDF（"做一个/生成/创建 PDF"） | → 创建 |
| 读取/分析 PDF 内容（"看看/提取/分析"） | → 读取 |
| 操作已有 PDF（"合并/拆分/旋转/加密/水印"） | → 操作 |
| 填写 PDF 表单（"帮我填/填写/写入"） | → 填表 |

---

## 创建

**标准流程：**

1. 确定内容结构和布局需求
2. 写 reportlab 代码生成 PDF
3. 保存并告知用户输出路径

**基础模板（Platypus 流式布局）：**

```python
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm, mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# ── 注册中文字体 ──
# 首选：IMA 沙箱预装的 NotoSansSC TTF（字形完整、嵌入字体、跨设备稳定）
try:
    pdfmetrics.registerFont(TTFont('Chinese', '/usr/local/share/fonts/custom/NotoSansSC-Regular.ttf'))
    pdfmetrics.registerFont(TTFont('Chinese-Bold', '/usr/local/share/fonts/custom/NotoSansSC-Bold.ttf'))
    CN_FONT = 'Chinese'
    CN_FONT_BOLD = 'Chinese-Bold'
except:
    # 兜底：CID 字体（部分字符可能缺失，仅应急用）
    from reportlab.pdfbase.cidfonts import UnicodeCIDFont
    pdfmetrics.registerFont(UnicodeCIDFont('STSong-Light'))
    CN_FONT = 'STSong-Light'
    CN_FONT_BOLD = 'STSong-Light'

output_path = "output.pdf"
os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

doc = SimpleDocTemplate(
    output_path,
    pagesize=A4,
    leftMargin=2.5*cm,
    rightMargin=2.5*cm,
    topMargin=2.5*cm,
    bottomMargin=2.5*cm,
)

# ── 样式 ──
styles = getSampleStyleSheet()
cn_style = ParagraphStyle('Chinese', parent=styles['Normal'], fontName=CN_FONT, fontSize=10.5)
cn_title = ParagraphStyle('CNTitle', parent=styles['Title'], fontName=CN_FONT, fontSize=18)
cn_heading = ParagraphStyle('CNHeading', parent=styles['Heading1'], fontName=CN_FONT, fontSize=14)

story = []
story.append(Paragraph("报告标题", cn_title))
story.append(Spacer(1, 12))
story.append(Paragraph("正文内容。" * 20, cn_style))

# 表格
data = [["列1", "列2", "列3"], ["数据1", "数据2", "数据3"]]
table = Table(data)
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4472C4')),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, -1), CN_FONT),
    ('FONTSIZE', (0, 0), (-1, -1), 9),
    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
]))
story.append(table)

doc.build(story)
```

**页眉页脚（带页码）：**

```python
def add_header_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFont(CN_FONT, 9)
    canvas.drawString(2.5*cm, height - 1.5*cm, "文档标题")
    canvas.line(2.5*cm, height - 1.6*cm, width - 2.5*cm, height - 1.6*cm)
    canvas.drawCentredString(width / 2, 1.5*cm, f"- {doc.page} -")
    canvas.restoreState()

doc.build(story, onFirstPage=add_header_footer, onLaterPages=add_header_footer)
```

---

## 读取

**首选方案：IMA 文档解析 API**

通过 IMA 解析服务将 PDF 转为 Markdown，支持表格、扫描件 OCR 等复杂场景。

**标准流程：**

1. 获取文件的 COS URL
2. 调用解析 API，获取 download_url
3. 下载 zip 并解压，得到 Markdown 结果

```bash
# ── 1. 获取文件可访问 URL ──
cos_key=$(ima_cos_util -f input.pdf)
cos_url=$(ima_cos_url -c "$cos_key")

# ── 2. 调用解析 API ──
body=$(printf '{"url": "%s", "file_name": "%s"}' "$cos_url" "input.pdf")
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

**备选方案：pypdf 直接读取（降级）**

当解析 API 不可用时（网络异常、服务故障），降级使用 pypdf。注意：pypdf 的文本提取质量有限（无法还原表格结构、扫描件无文字）。

---

## 操作

所有操作基于 pypdf（`PdfReader` + `PdfWriter`）。支持的操作：

| 操作 | 关键 API |
|------|---------|
| 合并 | 遍历多个 PDF，`writer.add_page(page)` |
| 拆分/提取页面 | `reader.pages[i]`，按索引选页（0-indexed） |
| 旋转 | `page.rotate(90)` 顺时针 |
| 加密 | `writer.encrypt(user_password, owner_password)` |
| 解密 | `reader.decrypt("密码")` |
| 水印 | `page.merge_page(watermark_page)` |
| 压缩 | `qpdf --optimize-images input.pdf output.pdf`（需 qpdf） |

**中文文字水印**需要先用 reportlab 生成水印 PDF（字体注册逻辑同创建路由），再用 `merge_page` 叠加。

---

## 填表

**标准流程：**

1. **探测表单字段** — `reader.get_fields()` 获取字段 ID、类型、可选值
2. **理解字段含义** — 结合文档内容或页面图片理解每个字段
3. **确定填写内容** — 结合用户提供的信息
4. **写入值** — `writer.update_page_form_field_values(page, {field: value})`
5. **验证** — 确认填写正确

**注意事项：**
- 先探测再填写，不要猜字段名
- Radio/Checkbox 的值通常是 `/Yes`、`/Off`、`/male` 等格式
- pypdf 的 flatten 支持有限，复杂表单可能不完全扁平化

---

## 防坑规则

### 1. 绝不使用 Unicode 上下标字符

reportlab 内置字体不包含 ₀₁₂₃₄₅₆₇₈₉ / ⁰¹²³⁴⁵⁶⁷⁸⁹，会渲染为黑色方块。

```python
# ❌ 错误
Paragraph("H₂O", styles['Normal'])

# ✅ 正确
Paragraph("H<sub>2</sub>O", styles['Normal'])
```

### 2. 中文需要注册字体

reportlab 内置字体不含中文。使用创建模板中的 try/except 字体注册逻辑。

**图表标签也需要单独设置字体：**

```python
pie.slices.label_fontName = CN_FONT
chart.categoryAxis.labels.fontName = CN_FONT
chart.valueAxis.labels.fontName = CN_FONT
```

### 3. 填表前必须先探测字段

不要猜字段名。用 `reader.get_fields()` 获取实际的字段 ID 和可选值，再填写。

### 4. 水印叠加方向

`page.merge_page(watermark_page)` 把水印叠在内容下方。如需叠在上方，交换调用顺序。

### 5. reportlab Paragraph 的 mini-HTML 标签严格

Paragraph 富文本只支持 XML 风格的自闭合或成对标签，写错会触发 paraparser 内部 AttributeError，报错信息不直观。

```python
# ✅ 正确
Paragraph("第一行<br/>第二行", style)
Paragraph("H<sub>2</sub>O", style)

# ❌ 错误（会炸）
Paragraph("第一行<br>第二行", style)      # 缺斜杠
Paragraph("第一行</br>第二行", style)     # 结束标签写法
Paragraph("第一行<br />第二行", style)    # 带空格
```

---

## 参考资料

按需读取：
- `references/reportlab_guide.md` — reportlab 进阶用法（复杂表格、图文混排、自定义页面模板、多栏布局等）
