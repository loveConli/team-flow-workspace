---
name: lt-second-brain-pipeline
description: LT 第二大脑 · 新资料思考框架管线。当「LT的知识库」每进来一份新资料（文章/书/灵感/链接），想用李笑来《思考的真相》六要素框架（定义→分类→比较→因果→决策→流程）过一遍、产出结构化分析卡并整合进第二大脑时触发；也适用于运行 Express 周/双周闭环与连接密度报表。不适用于知识库日常管理（建文件夹/打标签/移动文件等，请用 ima-knowledge）。
---

# LT 第二大脑 · 新资料思考框架管线 (Skill)

> 把"新资料进 LT的知识库"变成一条固定管线：用李笑来《思考的真相》六要素框架（定义→分类→比较→因果→决策→流程）结合知识库已有内容做分析，以"三张表"（概念/关系/流程）为草稿，落库为**原子概念笔记 + 连接**，并持续迭代为第二大脑。
> 状态：v1.0 · 全功能 MVP（含 cron 自动化、Express 闭环、月度连接密度报表）

---

## 0. 一句话定位
**进资料 → 脚本取料+喂上下文 → LLM 用六要素框架思考并结合第二大脑上下文 → 产出三张表草稿+分析卡 → 你逐笔记审阅 → 脚本落库(原子笔记+连接+MOC) → 周期 Express 闭环。**

---

## 1. 何时触发
- **入站处理**：你往 `00-灵感库` 存入一份新资料（文章 / 书 / 灵感笔记 / 网页链接）后，想用它过一遍思考框架并整合进第二大脑。
- **Express 闭环**：周期（周 / 双周）想让 AI 汇总近期落库、产出"可组合洞察 / 可决策议题"。

---

## 2. 环境参数（实测）
| 项 | 值 |
|---|---|
| KB 名称 | LT的知识库 |
| kb_id | `EXJh01CG7_y2QAeuFrtCQcIeMRdb3byUSzoJMIzDfs8=` |
| 00-灵感库 (inbox) | `folder_7480821992675662` |
| 01-P-Projects | `folder_7480822030424655` |
| 02-A-Assets (原子概念) | `folder_7480829454342475` |
| 03-R-Resources (原始/参考原件) | `folder_7480829588560901` |
| 04-A-Archive | `folder_7480829655666977` |
| 05-Skill | `folder_7480829726968580` |
| 依赖 Skill | `lixiaolai-thinking-truth`（六要素 + 三张表） |

### 文件夹语义（厘清后）
- `03-R-Resources` = **外部输入 / 参考原件**（如第三方原文、参考资料；管线不挪动它，保留原样）
- `02-A-Assets` = **你提炼的原子概念笔记**（自有知识，最小可复用单元）
- `05-Skill` = 可复用 SOP / 流程
- `01-P-Projects` = 进行中的行动项
- `04-A-Archive` = 已完成 / 陈旧归档（**处理后源文件移此 + 打 status/processed**）
- 分析卡 / MOC 索引 → 放 `02-A-Assets`（挂 `type/index`）

---

## 3. 标签状态机（幂等 + 防膨胀）
单值 `status/` 标签，**每笔记至多一个**；其余标签作为属性叠加。
```
[入口·无 status/processed = 待处理·位于 00-灵感库]
       │ 取料（脚本加锁 analyzing，防重复处理）
       ▼
status/analyzing ──(分析完成)──▶ status/pending_review
                                       │
        status/processed ◀──(人确认·执行落库·源移 04-A-Archive)──┤
        status/rejected  ◀──(人拒绝)─────────────────────────────┤
        status/deferred  ◀──(人延迟)─────────────────────────────┘
```
辅助标签：
- `type/concept` `type/flow` `type/reference` `type/index`
- `src/<来源>`（如 `src/wechat` `src/book`）
- `status/review`（长期未连接 / 需回炉）

**幂等规则**：cron 扫 `00-灵感库` 全部，客户端过滤「无 `status/processed`」（即待处理）的项；取料即 `tag_add(analyzing)` 加锁 → 下一轮即便未打 processed 也不会重复选中。全库活跃标签目标 ≤ 50–75，季度 prune。

---

## 4. 七阶段管线（脚本 / LLM 拆分）

### [0] 触发
- **手动一键**：你主动发起（MVP 最稳、零浪费、天然幂等）。
- **cron 批处理**：定时扫 `00-灵感库` 中无 `status/processed` 的项，适合"自动沉淀"。
- ⚠️ ima **无 webhook / 无实时事件**，所谓"自动"=轮询式 cron，目标措辞应为"定时批处理 inbox"。

### [1] 取料（脚本）
```bash
# 列 00-灵感库 全部，客户端过滤「无 status/processed」= 待处理
curl .../get_knowledge_list -d '{"knowledge_base_id":"EXJh...=","folder_id":"folder_7480821992675662"}'
# 逐份加锁（入口无标签，直接加 analyzing 防重复）
curl .../tag_add -d '{"media_id":"<id>","tags":["status/analyzing"]}'
# 取正文（超长检测→分块 map-reduce / 降级摘要 + status/needs_human_review）
curl .../export_media_for_ima_sandbox -d '{"media_id":"<id>"}'
```

### [2] 取上下文（脚本）
- 对全文件夹（**含 02/01/03/05**）做**定向 query** `search(source="kb", kb_id, query=<主题词>)`，非全库 dump。
- reranker + 相似度阈值 + top-K 预算，避免过召回与上下文溢出。

### [3] 思考分析（LLM · 加载 thinking-truth）
- 套六要素：**定义(概念=描述)→分类(合理且完整/MECE)→比较(同一范畴同一属性)→因果(因果四问，区分相关)→决策→流程**。
- 产出**三张表草稿**（strict JSON，每条带 `evidence`+`confidence`，见 §5）。
- **偏见检查操作化**（必须输出）：
  1. 本资料缺失的 ≥1 个对立 / 替代视角；
  2. 知识库是否存在支持本观点的"回音室"聚类；
  3. 若某主题旧知 < 阈值，标注"样本不足 / 低置信"。
- AI 只出**草稿 + 建议连接 / 标签 / 对立视角候选**，**不做最终判断**。

### [4] 出草稿卡（LLM → 脚本落库为 note）
- 写"分析草稿卡"入 `05-Skill`（审阅区），`tag=status/pending_review`。
- 源文件**仅加锁标签** `analyzing→pending_review`（**零不可逆写**；入口无标签，不预打 inbox）。
- 严格结构化 JSON → schema 校验 → 失败重试 ≤3 → 仍失败**死信**（`tag=status/needs_manual_analysis`，写极简 note，不写任何不可逆内容）。

### [5] 人审阅（你 · note 级）
- 打开草稿卡，**逐笔记"留 / 并 / 弃 + 我的立场一句话"**（粒度 = note，非 file）。
- **两步确认 + diff 预览**：点"执行落库"先弹预览——"将创建 N 概念笔记@02；链接 M 关系；移动源文件至 04-A-Archive；其中 K 项置信度<阈值需你确认"，再点"确认"才执行。
- 审计日志：`{ts, decision, items}`（写不可逆，日志是唯一追溯手段）。

### [6] 执行落库（脚本 · 确认后）
**顺序硬规则：人确认 → 去重闸门 → 创建概念笔记 → 创建流程 → 最后移动源文件 00→04-A-Archive 打 processed。**
1. **去重闸门**：搜 `02-A-Assets` 规范词 + 别名，命中则**链接并更新**，未命中才建。
2. 原子概念笔记落 `02-A-Assets`（`type/concept`，frontmatter：`aliases/definition/source_ids/related/status/created/version`）。
3. 源文件移 `04-A-Archive`（`folder_7480829655666977`），打 `status/processed`；`03-R-Resources` 保留作外部输入，管线不挪动。
4. 流程 SOP → `05-Skill`（`type/flow`）；行动项 → `01-P-Projects`。
5. **更新主题 MOC 索引笔记**（`type/index`，把本次概念/流程/参考以链接串起）。
6. 写**运行摘要**（计数：新增概念 / 链接 / 移出 / 拒绝），存 `05-Skill` 日志区。

### [7] Express 闭环（cron / 手动 · 周 / 双周）
- AI 基于近期落库（`status/processed` 近 N 天）生成"可组合洞察 / 可决策议题"，供你审阅。
- 度量：连接密度、笔记复用率；长期孤立笔记打 `status/review` 或回炉。
- **无 Express 则第二大脑退化为"数字坟墓"**——本步为最高优先级闭环。

---

## 5. LLM 输出 Schema（strict function-calling + 校验）
```json
{
  "metadata": {"schema_version":"1.0","source_media_id":"","source_title":"","generated_at":"ISO8601","analyzer_model":"","overall_confidence":0.0},
  "concept_table": [
    {"concept_id":"slug","name":"","definition":"","tags":[""],"target_folder_id":"02-A-Assets",
     "evidence":[{"type":"source|kb","ref":"media_id/chunk_id","quote":"","confidence":0.0}]}
  ],
  "relation_table": [
    {"relation_id":"uuid","from":"concept_id|existing","to":"concept_id|existing",
     "relation_type":"supports|contradicts|extends|example_of|part_of","description":"","evidence":[{"ref":"","quote":"","confidence":0.0}]}
  ],
  "process_table": [
    {"process_id":"uuid","name":"","steps":[""],"applies_to":["concept_id"],"target_folder_id":"05-Skill|01-P-Projects"}
  ],
  "analysis_card": {"summary":"","six_elements":{"概念":"","关联":"","结构":"","例子":"","反例":"","应用":""},"key_connections":[""],"bias_reflection":""},
  "improvement_suggestions":[{"priority":1,"suggestion":"","rationale":""}],
  "quality_flags":{"empty_tables":false,"low_confidence_items":[""],"needs_human_review":true}
}
```
**业务校验**：① `target_folder_id` ∈ 白名单；② `concept_id` 唯一；③ 每个 relation/claim 至少 1 条 evidence（无证据即丢弃）；④ 检测 safety refusal → 死信。
**采样**：temp=0.1 / top_p=0.2 / top_k=5 / 紧 max_tokens，压低编造。

---

## 6. 原子笔记标准（最小可用单元四测试）
把"概念=描述"升级为"**可独立成立的观点（claim + 为何重要 + 一条证据/含义）**"。四测试：
1. **标题测试**：能用一句陈述性标题？（"客户留存取决于 onboarding 速度"✅ / "关于增长的一些想法"❌）
2. **链接测试**：连入本笔记的链接是否都指向"整篇"？否则该拆。
3. **挑战测试**：别人能否就"整篇"反驳？含 3 主张只同意 2 个 → 该拆。
4. **复用测试**：能否用在完全不同项目？不能 = 绑死在某上下文，需抽象。
过碎判定：一句话且无法独立成立 → 合并进分析卡而非单建笔记。

---

## 7. 三张表 → 目录映射（全功能）
| 思考产物 | 落库位置 | 标签 |
|---|---|---|
| 概念（定义） | `02-A-Assets` 原子概念笔记 | `type/concept` |
| 关系（分类/比较/因果） | 以**链接 + 标签**体现在原子笔记正文（"参见[[X]]""反驳[[Y]]"） | — |
| 流程（决策/流程） | 可复用 → `05-Skill`；仅服务项目 → `01-P-Projects` | `type/flow` |
| 原始资料 | `03-R-Resources` | `type/reference` `src/<>` |
| 分析卡 + MOC 索引 | `02-A-Assets`（入口，串起三表产物） | `type/index` |

> ima **无 Obsidian 式自动双向链接**："连接" = 标签 + 笔记正文引用(media_id/标题) + MOC 索引笔记三者组合，索引层由脚本 / 你维护。

---

## 8. 鲁棒性 & 成本
- **截断**：长度异常检测 → 分块 map-reduce / 长上下文护栏；超限降级为摘要并标 `needs_human_review`。
- **过召回**：reranker + 相似度阈值 + top-K。
- **空表 / 幻觉连接**："每条 claim 需 evidence" + 低温度 + 置信度门控 HITL 升级。
- **成本**：定向 query 非全库；同批次多份新资料共享一次检索；模型路由（小模型抽取）；MVP 用手动，cron 仅作增强。

---

## 9. ima 关键约束（设计前提）
- 无 webhook（触发 = 手动 / cron）。
- 写入不可逆、无删除 API → **人决策必须在脚本写操作之前**。
- 文件夹不可移动（只能移动文件）。
- 标签可增删、可编码状态（被本方案用作状态机）。

---

## 10. 月度连接密度报表（全功能）
cron 月度执行：统计 `02-A-Assets` 中孤立笔记占比、最大聚类主题、新增概念/链接/复用率，产出报表 note 供你评估"第二大脑是否在持续迭代"。
