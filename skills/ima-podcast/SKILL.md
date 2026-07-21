---
name: ima-podcast
description: 将笔记、网页内容、文件资料、知识库内容或开放主题生成为 AI 播客音频。当用户提到"帮我做一个播客""把这篇文章做成播客""生成播客""改一下上次的播客"等意图时，使用此 skill。
---

# AI 播客生成

将用户提供的主题、笔记、网页、文件或知识库内容整理为适合播客生成的素材，调用混元 AI 播客能力生成播客。

## 使用时机

当用户表达以下类似意图时触发此技能：

- "帮我做一个播客""生成一期播客"
- "把这篇文章/笔记/网页/文件做成播客"
- "基于这个主题/这份资料生成播客"

## 工作流程

### Step 1：意图澄清与参数确认

#### 参数说明

| 参数 | 可选值       | 默认值                                          |
| ---- | ------------ | ----------------------------------------------- |
| 人数 | 单人 / 双人 | 双人                                            |

> 当前仅支持**单人**和**双人**播客，不支持三人及以上。
| 音色 | 见下方音色表 | 单人默认：明快·元气满满；双人默认：明快·元气满满 + 醇厚·稳重低沉        |

> 确认音色时**只输出风格描述**（如"明快·元气满满"），**不输出人名**（如"小棠"）。

#### 音色对照表

| voice_name | 风格描述       | 样音链接                                                              |
| ---------- | -------------- | --------------------------------------------------------------------- |
| 小棠       | 明快·元气满满（女声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/db2ryZMM.wav)    |
| 小昊       | 醇厚·稳重低沉（男声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/P5TxmC6d.wav)    |
| 思思       | 温柔·娓娓道来（女声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/dxyQK0sD.wav)    |
| 明宇       | 清朗·温润悦耳（男声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/CZI2wXRJ.wav)    |
| 小雨       | 知性·沉稳清晰（女声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/yHmC397e.wav)    |
| 子言       | 深沉·磁性入耳（男声） | [试听](https://static.ima.qq.com/wupload/xy/ima_tool/6ifjDSRi.wav)    |

#### 参数确认策略（用户未明确人数或音色时）

- **显性引导**：以自然对话的方式逐步确认参数，向用户灵活告知人数、音色的可选值，并告知不选择时的默认配置（双人对谈 + 明快·元气满满 + 醇厚·稳重低沉）。
- **兜底处理**：用户回复"默认""你决定""直接生成""按默认来"或表达强执行意图（如"别问了，直接生成"）时，**立即使用默认配置，不再追问**。
- **部分明确**：用户只明确了部分参数，则仅补问缺失的关键参数，并提示可使用默认值。
- **样音试听**：用户要求试听音色时，直接给出样音链接供用户试听。


### Step 2：整理播客生成素材

根据用户的query及要求，整理播客生成的素材，并将整理后的结果以文件形式保存。
整理素材的目标是形成一份能支撑对话型播客的内容：有明确主题、有核心论点、有可展开细节、有可延展角度。**不要只堆关键词，也不要把没有依据的内容写成事实。**
**优先使用用户指定的素材**：当用户指定根据特定笔记或上传的特定附件生成播客时，需首先获取该特定素材的完整内容，优先将该特定内容作为素材上传到 COS 并获取 cosKey。如判断该素材内容量不足，再主动向用户确认是否补充其他材料。

#### 素材质量自检

- 主题是否明确
- 是否有足够信息支撑播客内容
- 是否包含可展开的事实、观点、例子、背景或争议点
- 是否能区分素材事实和基于素材的合理推断
- 是否存在明显敏感、无法解析或不可访问的素材风险

若素材不足，**优先主动补搜**；仍不足时，向用户说明缺口并请求补充。

#### 将素材上传到 COS 获取 cosKey

- 将整理好的播客素材写入文件并执行以下命令，将素材上传到 cos，将输出的 cosKey 记录下来，作为 Step 3 调用 generate 接口时 report_content 参数的值。（将 `<文件路径>` 替换为实际路径）：
   ```bash
   ima_cos_util -f <文件路径>
   ```

备注：ima_cos_util是平台内置的虚拟命令，直接使用即可，无需检查是否存在。

### Step 3：调用 API

```bash
# 鉴权（环境变量已预配，直接引用即可，禁止自行 export 或填入硬编码值）
# $IMA_OPENAPI_CLIENTID / $IMA_OPENAPI_APIKEY

# 发起生成
curl -sS -X POST "https://ima.qq.com/openapi/agent_podcast/v1/generate" \
    -H "ima-openapi-clientid: $IMA_OPENAPI_CLIENTID" \
    -H "ima-openapi-apikey: $IMA_OPENAPI_APIKEY" \
    -H "Content-Type: application/json" \
    --max-time 1800 \
    -d "$(cat <<JSON
{
  "question": "基于这份素材生成一期 2 人对话播客",
  "report_content": "$COSKEY",
  "people_num": 2,
  "voice_name": ["小棠", "小昊"]
}
JSON
)" \
    -w "\n--- http_code=%{http_code} ---\n"
```

`report_content` 每次调用都必须传，取值取决于素材是否需要变化：

- **素材无变化**（改风格/音色/人数、删减段落、同素材换版本）→ 复用上一轮的 `report_content`
- **素材有变化**（追加/替换内容）→ 重走 Step 2，传新 cosKey

### Step 4：向用户回复

#### 生成成功


1. 从 API 响应 JSON 中提取 `preview_url` 和 `media_id` 和`title` 字段。
2. 使用以下 Python 脚本下载音频并写入 `.metadata` 文件：

```python
#!/usr/bin/env python3
"""Download podcast audio and write .metadata file from API response."""
import json, os, sys, urllib.request
from urllib.parse import urlparse

def download_podcast(api_response: dict, output_dir: str = ".") -> str:
    preview_url = api_response["preview_url"]
    media_id = api_response["media_id"]

    parsed = urlparse(preview_url)
    filename = parsed.path.rstrip('/').rsplit('/', 1)[-1] or "podcast_output"
    if not filename.endswith(('.mp3', '.wav', '.m4a', '.ogg', '.aac')):
        filename += '.mp3'
    output_path = os.path.join(output_dir, filename)

    req = urllib.request.Request(preview_url)
    req.add_header('User-Agent', 'Mozilla/5.0')
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
            with open(output_path, 'wb') as f:
                f.write(data)
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return ""

    # 写入 .metadata 文件（供 provide_file 读取 media_id 等信息传给 event）
    metadata_path = os.path.join(output_dir, f".{filename}.metadata")
    with open(metadata_path, 'w') as f:
        json.dump({"media_id": media_id, "media_type": 19}, f)

    print(f"✅ Downloaded: {output_path} ({len(data)} bytes)")
    print(f"✅ Metadata: {metadata_path}")
    return output_path

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python download_podcast.py '<json_response>'")
        sys.exit(1)
    resp = json.loads(sys.argv[1])
    result = download_podcast(resp, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(0 if result else 1)
```

> ⚠️ **下载目录强制约束（必须严格遵守）**：
> - 脚本会将音频下载到**脚本所在目录**（/sandbox/workspace/outputs/）.
> - **禁止**给脚本传第二个参数指定其他输出路径。
> - **禁止**修改脚本里的 `output_dir` 默认值。
下载完成后，通过 mv 命令将音频文件和对应的 .metadata 文件原地重命名为「`title` .mp3」和「.`title` .mp3.metadata」，不要移动到其他目录。

3. 使用 `provide_file` 工具将下载好的本地文件提供给用户,。**【注意：一定要用 provide_file 工具】**
4. 生成简短回复告知用户播客已生成完毕。
> ⚠️ 无需在向用户的最终回复中输出任何链接，也不要提示"下方/下面有链接"。（包括但不限于 cos 链接、preview_url 、下载链接等），因为`provide_file` 工具会自动在本轮回复上方生成可点击链接，用户点击后可查看播客详情并收听。

#### 生成失败

失败时说明可行动原因，不输出笼统失败话术：

| 失败类型     | 用户话术                                                       |
| ------------ | -------------------------------------------------------------- |
| 素材解析失败 | 说明失败素材，建议换链接、上传文件或粘贴正文                   |
| 内容不适合   | 说明该素材无法用于播客生成，建议更换或调整素材                 |
| API 调用失败 | 说明当前生成服务异常，建议稍后重试                             |
| 上下文丢失   | 说明无法基于上次播客继续修改，需要重新提供素材或确认要修改的播客 |

## 注意事项

- `question` 上限 4 KiB，`report_content` 上限 2 MiB，超过需精简素材
- 当前接口**不支持用户指定播客时长**，时长由素材量和模型决定，无法通过参数控制
- **禁止编造播客时长**：如需在回复中提及播客时长，必须通过读取下载好的音频文件获取真实时长，不要凭印象或素材量猜测

## 错误处理

常见错误码及处理方式：

| 错误码 | 含义           | 建议处理                       |
| ------ | -------------- | ------------------------------ |
| 100001 | 参数错误       | 检查必填字段和参数范围         |
| 100002 | 携带无效的 ID  | 检查 ID 是否合法               |
| 100003 | 服务器内部错误 | 等待后重试                     |
| 100004 | 内容超限       | 检查 question/report_content 大小 |
| 100005 | 无权限         | 检查凭证配置                   |
| 100006 | 上下文已失效   | 提示用户重新提供素材生成       |
| 100009 | 单次内容超最大限制 | 精简素材后重试              |
| 20002  | apiKey 超限频  | 降低调用频率                   |
| 20004  | apikey 鉴权失败 | 检查 clientid / apikey 配置    |

> 除 trpc 错误码外，HTTP 200 但 `file_content.status == TOOL_TYPE_ERROR` 也视为生成失败，按"API 调用失败"提示用户重试。
