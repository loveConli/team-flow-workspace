---
name: ima-knowledge
description: 知识库管理与元信息操作：内容导入/导出/移动/重命名、文件夹层级浏览与组织、按名称/标签/类型定位文件与文件夹、标签管理（给文件打/移除标签、列出/重命名/删除标签）、知识库定位（包括根据知识库名称/类别获取知识库id，即kb_id）与创建、设置、权限管理。当用户提到知识库/资料库，并且同时涉及上述管理操作，或需要获取kb_id时，触发此 skill。按内容搜索知识库或阅读文件内容应使用 Search / Fetch 工具，不触发此 skill。
---

# 知识库管理

## 规则

1. **调用任何 API 前，先用 Read 工具读取对应的 reference 文件** —— API 参数有严格校验，凭记忆容易传错字段名或遗漏必填参数，导致调用失败。reference 文件中有准确的参数定义和返回值结构，读一次就能避免反复试错。
2. **不知道该查看哪个知识库时先搜索（search_knowledge_base）** —— 通过 search_knowledge_base 可以找到用户需要的知识库对应 knowledge_base_id, 并拥有用户在此知识库中的角色信息，当用户为普通成员时， 请拒绝用户对于该知识库的写操作(references/knowledge_base_write.md)
3. **当前 API 不支持任何实体删除操作** —— 仅支持标签管理（删除），无法删除知识库、文件夹、文件或任何已上传的内容。如果用户要求删除，直接告知需要在 IMA 客户端中手动操作，**不要尝试寻找或构造删除接口，不要重试**。
4. **所有写入操作不可逆** —— 由于没有删除 API，一旦创建（知识库、文件夹、上传文件、导入链接），就无法通过 API 撤回。因此：当写入操作不是由用户显式/隐式要求时，必须先向用户确认再执行。**特别注意 `tag_delete` 和 `tag_rename`**：前者会一次性解除所有文件上的该标签关联，后者在新名称已存在时会自动合并两组标签——这两类操作影响范围远大于单次写入，调用前必须用 `tag_list` 或 `get_knowledge_list(tags=[...])` 让用户预览受影响的文件数量并显式确认。
5. **所有 API 返回的 ID 必须原样使用** —— 传入其他接口时必须原样保留，禁止比如去掉前缀/截取数字部分/做任何格式修改。
6. **内容搜索和阅读由 search/fetch 完成，不由此 skill 完成** —— Search 提供关键词+向量融合搜索，Fetch 可直接通过 media_id 读取文件内容，两者在内容检索和阅读场景下效果更优。此 skill 聚焦于：知识库元信息查询、文件夹浏览、按名称/标签定位、文件导入/导出、知识库创建与管理。**混合场景下（如需要先定位知识库/获取知识库元信息，再搜索/阅读内容），通过此 skill 获取 kb_id 后，应切回 search(source="kb", kb_id=xxx) + fetch(type="media_id") 完成内容检索**，而非继续使用 export_media → 下载 → 本地处理。
7. **任何操作前，必须确认当前使用的 kb_id 与目标知识库一致** ，一定要仔细check —— 错误的读取会导致后续所有操作偏离目标，错误的写入更是不可逆的。

## API 调用方式

所有 `/openapi/wiki/v1/*` 接口统一使用

```bash
curl -s -X POST "https://ima.qq.com/$endpoint" \
    -H "ima-openapi-clientid: $IMA_OPENAPI_CLIENTID" \
    -H "ima-openapi-apikey: $IMA_OPENAPI_APIKEY" \
    -H "Content-Type: application/json" \
    -d "$body"
```

- `$endpoint`：完整 API 路径，如 `openapi/wiki/v1/get_knowledge_base`
- `$body`：有效的 JSON 字符串请求体

## 关键概念

| 概念 | 说明 | 获取方式                                  |
|------|------|---------------------------------------|
| knowledge_base_id | 知识库唯一 ID | search_knowledge_base                 |
| folder_id | 文件夹 ID，不传时默认为根目录 | get_knowledge_list 或 search_knowledge |
| media_id | 文件/文件夹条目 ID | get_knowledge_list 或 search_knowledge |

## 决策表

### 上传与导入 → references/knowledge_base_upload.md

| 用户意图 | 操作流程 |
|---------|---------|
| 上传文件到知识库 | upload_file.py |
| 添加网页链接 | import_urls |
| 添加笔记到知识库 | add_knowledge |

### 查询与浏览 → references/knowledge_base_read.md

| 用户意图 | 操作流程 |
|---------|---------|
| 按名称定位知识库、查看知识库详情、列出可写知识库、获取知识库id | search_knowledge_base |
| 逐级浏览知识库文件夹结构，支持按标签筛选 | get_knowledge_list |
| 按名称定位文件/文件夹（获取位置和类型信息） | search_knowledge |
| 导出媒体到 workspace（获取下载链接），也用于 Fetch 工具返回生成内容而非原文时的 fallback：先 export 落盘再做格式转换 | export_media_for_ima_sandbox |
| 发现公开广场知识库 | search_knowledge_base_in_square |

### 知识库与文件管理 → references/knowledge_base_write.md

| 用户意图 | 操作流程 |
|---------|---------|
| 创建知识库 | create_knowledge_base |
| 修改知识库信息 | update_knowledge_base_basic_info |
| 创建文件夹 | create_folder |
| 重命名文件/文件夹 | rename_knowledge |
| 置顶/取消置顶 | set_knowledge_top |
| 移动文件到其他知识库/文件夹（不支持文件夹的移动） | move_knowledge |

### 标签管理 → references/knowledge_base_tag.md

| 用户意图 | 操作流程 |
|---------|---------|
| 给文件打标签 | tag_add |
| 从文件移除某个标签 | tag_remove |
| 列出 / 搜索知识库中的所有标签 | tag_list |
| 重命名标签（所有打了该标签的文件自动迁移） | tag_rename |
| 删除标签（所有文件上的关联自动解除） | tag_delete |
| 查看某个文件有哪些标签 | get_knowledge_list 返回的 `tags` 字段 |
| 按标签筛选文件 | get_knowledge_list 请求参数 `tags` |
| 替换文件的标签 | tag_remove + tag_add 组合 |

### 权限管理 → references/knowledge_base_permission.md

| 用户意图 | 操作流程 |
|---------|---------|
| 修改知识库权限 | update_knowledge_base_permission |
| 加入知识库 | join_knowledge |
| 修改文件访问状态 | update_knowledge_access_status |

## media_type 速查表

| 值 | 类型 | 值 | 类型 |
|----|------|----|------|
| 1 | PDF 文件 | 11 | 笔记 |
| 2 | 网页 | 12 | QA 对话 |
| 3 | Word 文件 | 13 | TXT 文本 |
| 4 | PPT 文件 | 14 | Xmind |
| 5 | Excel 文件 | 15 | 录音 |
| 6 | 公众号文章 | 16 | 网页视频 |
| 7 | Markdown | 17 | 对话 |
| 9 | 图片 | 18 | 视频 |
| | | 19 | 播客 |
| | | 20 | HTML |
| | | 99 | 文件夹 |

## 分页策略

多个 API 使用 cursor 分页（如 search_knowledge_base、get_knowledge_list 等），统一遵循以下原则：

- 首次请求：cursor 传空字符串，limit 建议设为 20
- 翻页判断：检查返回的 `is_end` 字段，为 `false` 时使用 `next_cursor` 继续请求
- 自动翻页获取结果，但设置上限：最多翻页 5 次（即最多约 100 条结果），避免在大知识库中无限循环

## 典型工作流示例

### 示例 1：上传文件到知识库

```
用户: "把 report.pdf 上传到知识库"

步骤 1: 读取 references/knowledge_base_read.md，调用 search_knowledge_base(query="", query_user=true)
       获取用户有写权限的知识库列表
步骤 2: 向用户展示知识库名称列表，让用户选择目标知识库
步骤 3: 读取 references/knowledge_base_upload.md，调用 upload_file 上传文件
步骤 4: 告诉用户上传成功
```

### 示例 2：整理知识库文件到新文件夹

```
用户: "在'产品资料'知识库里建一个'项目文档'文件夹，把那几个 PPT 移进去"

步骤 1: 读取 references/knowledge_base_read.md，调用 search_knowledge_base(query="产品资料") 获取知识库 ID
步骤 2: 确认获取到的 知识库 ID 对应的知识库名称/类型与用户意图一致
步骤 3: 读取 references/knowledge_base_write.md，调用 create_folder 创建"项目文档"文件夹
步骤 4: 调用 get_knowledge_list 浏览知识库内容，找到 PPT 文件（media_type=4）
步骤 5: 调用 move_knowledge 将 PPT 文件移动到新文件夹
步骤 6: 告诉用户整理完成
```

### 示例 3：导入网页链接到知识库

```
用户: "把这个网页存到知识库 https://example.com/article"

步骤 1: 读取 references/knowledge_base_read.md，调用 search_knowledge_base(query="", query_user=true)
       获取可写知识库列表
步骤 2: 向用户展示知识库名称列表，让用户选择
步骤 3: 读取 references/knowledge_base_upload.md，调用 import_urls 导入链接
步骤 4: 告诉用户导入成功
```