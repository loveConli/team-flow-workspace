# 成本监控（L3 Harness · 03D）

> 报告引用: §5  Harness 工程（六组件中的「成本监控与错误处理」）/ §11 后续段落提及「结合 Anthropic SDK 的成本监控元数据和 Harness 工程的确定性评分，构建三层度量框架」
> 定位: 监控 Agent 运行成本（token、API 调用、时间），防止失控消费；构建三层度量框架。
> 标签: 【来源已核验✅·落地待验证⚠️】（需 Anthropic SDK / cost API）

## 三层度量框架（报告提及，骨架定义）

| 层级 | 度量对象 | 采集方式 | 阈值/告警 | 行动 |
|------|----------|----------|-----------|------|
| **L1 成本层** | Token 消耗、API 调用次数 | Anthropic SDK metadata / HTTP header | 单会话 ≥ 50K tokens 告警 | 自动 compact / 人工审查 |
| **L2 效率层** | 每需求 token 效率、每任务时间 | 计算: tokens/需求, 时间/phase | 效率比基线下降 ≥ 20% 告警 | 审查策展策略、skill 调度 |
| **L3 确定性层** | 确定性评分（Harness 六组件覆盖率） | 评分卡: Hook 激活率 / 门禁通过率 / 审计闭合率 | 评分 < 60% 告警 | 审查 Harness 零件叠加进度 |

## 成本监控指标定义

| 指标 | 计算公式 | 告警阈值 | 归属 |
|------|----------|----------|------|
| 单次会话 token 数 | `total_tokens_used` (Anthropic API) | ≥ 50K tokens/会话 | L1 |
| 单次 API 调用成本 | `$0.003/1K input + $0.015/1K output` (Claude 3.5 Sonnet) | ≥ $5/会话 | L1 |
| 需求级累计成本 | Σ(各 phase token 数) × 单价 | ≥ $50/需求 | L2 |
| 每需求 token 效率 | tokens / (spec.md 行数 + plan.md 行数 + 代码行数) | 单位产出 token 数 ≥ 基线 1.5 倍 | L2 |
| 门禁激活率 | 激活门禁数 / 应激活门禁总数 | < 80% | L3 |
| 审计闭合率 | 闭合审计数 / 总审计数 | < 95% | L3 |
| 确定性评分 | 加权: 门禁激活率×0.4 + 审计闭合率×0.3 + 错误恢复率×0.2 + 成本合规率×0.1 | < 60% | L3 |

## Anthropic SDK 成本监控采集

```python
# 伪代码骨架（待实现）
import anthropic

def track_cost(response, phase, task_id):
    metadata = {
        "input_tokens": response.usage.input_tokens,
        "output_tokens": response.usage.output_tokens,
        "total_tokens": response.usage.input_tokens + response.usage.output_tokens,
        "cost_usd": calculate_cost(response.usage),  # 按模型单价计算
        "phase": phase,  # DRAFT/CLARIFYING/...
        "task_id": task_id,
        "timestamp": iso8601_now(),
        "session_id": SESSION_ID,
    }
    # 写入成本监控日志
    append_to("memory/cost-log.jsonl", metadata)
    # 检查阈值
    if metadata["total_tokens"] > TOKEN_THRESHOLD:
        alert("单次会话 token 超标", metadata)
    if metadata["cost_usd"] > COST_THRESHOLD:
        alert("单次会话成本超标", metadata)
```

## 成本告警与阻断

| 告警级别 | 条件 | 自动行动 | 人工行动 |
|----------|------|----------|----------|
| 信息 | 单次会话 token > 20K | 记录日志 | 无 |
| 警告 | 单次会话 token > 50K 或成本 > $5 | 自动触发 `/compact` | 审查会话内容 |
| 严重 | 单次会话 token > 100K 或成本 > $20 | 强制停止会话 + BLOCKED | 紧急审查，可能需要调整策展策略 |
| 紧急 | 需求级累计成本 > $50 | 暂停该需求所有新会话 | 项目复盘，审查 skill 调度或需求拆分粒度 |

## 成本与错误处理联动

> 报告 §5 将「成本监控与错误处理」作为 Harness 六组件之一。

| 错误类型 | 成本影响 | 错误处理 | 成本行动 |
|----------|----------|----------|----------|
| API 调用失败 | 浪费 tokens（重试） | 指数退避重试（max 3次） | 记录重试成本，超阈值告警 |
| 上下文溢出 | 需要 compact（额外 token） | 自动 compact | 记录 compact 成本，审查策展策略 |
| 无限循环（Agent 反复修改同一文件） | 持续消耗 tokens | max_turns 限制（Harness 终止原语） | 强制停止，BLOCKED，审查 task 拆分粒度 |
| Hook 被绕过 | 无直接成本，但有合规风险 | CI backstop | 记录 bypass 事件，审计闭环 |

## 错误处理骨架

```python
# 伪代码（待实现）
def error_handler(error, phase, cost_so_far):
    log_error({
        "error_type": type(error).__name__,
        "phase": phase,
        "cost_so_far": cost_so_far,
        "timestamp": iso8601_now(),
    })
    
    if cost_so_far > EMERGENCY_COST_THRESHOLD:
        block_session("成本超标，进入 WAITING_USER")
        alert_human("需求 {} 成本超标，需紧急审查".format(REQ_ID))
        return "BLOCKED"
    
    if error.is_retryable() and retry_count < MAX_RETRIES:
        exponential_backoff(retry_count)
        return "RETRY"
    
    if error.is_fatal():
        block_session("致命错误，进入 BLOCKED")
        return "BLOCKED"
    
    return "CONTINUE"
```

---
> 此文件为**监控骨架**。真实项目需按实际 Anthropic SDK 版本、成本单价、阈值配置填充。
> 落地待验证⚠️：Anthropic SDK 集成、成本单价更新（模型价格变动）、告警通道配置。
