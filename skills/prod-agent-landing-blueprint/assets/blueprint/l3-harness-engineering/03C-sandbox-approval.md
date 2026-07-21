# 沙箱与审批流程（L3 Harness · 03C）

> 报告引用: §5.5 沙箱与审批 / §10.4 硬门禁边界 / §5.11 设计原则（质量门 = 确定性验证阻断）
> 定位: 建立沙箱与审批机制，确保高风险操作在受控环境中执行并通过人工审批。
> 标签: 【来源已核验✅·落地待验证⚠️】（需 sandbox 环境配置）

## 沙箱定义

> 沙箱 = 安全隔离执行环境。Agent 的所有副作用（写文件、执行 Bash、调用 MCP）在沙箱内执行，不影响生产环境。

| 沙箱类型 | 用途 | 隔离级别 | 生命周期 |
|----------|------|----------|----------|
| **文件系统沙箱** | 限制 Agent 可访问的目录 | 目录级 chroot/jail | 会话级 |
| **网络沙箱** | 限制 Agent 可访问的网络资源 | 防火墙/代理规则 | 会话级 |
| **执行沙箱** | 限制 Agent 可执行的命令 | 白名单/容器/Docker | 会话级 |
| **合并沙箱** | 合并代理在独立 worktree 中验证 | Git worktree 隔离 | 合并阶段 |

## 沙箱配置要点

### 文件系统沙箱
```
允许访问: {PROJECT_ROOT}/src/, {PROJECT_ROOT}/tests/, {PROJECT_ROOT}/requirement/
禁止访问: {PROJECT_ROOT}/.git/hooks/*（防止篡改 hook）,
         {PROJECT_ROOT}/.env（防止泄露密钥）,
         /etc/*, /var/*（系统目录）
只读访问: {PROJECT_ROOT}/CLAUDE.md, {PROJECT_ROOT}/AGENTS.md
```

### 网络沙箱
```
允许: [AONE_API_ENDPOINT], [DINGTALK_API_ENDPOINT], [WIKI_SEARCH_ENDPOINT], [CI_API_ENDPOINT]
禁止: 所有其他外网访问（防止数据外泄）
代理: 所有外网请求须经企业代理（可审计）
```

### 执行沙箱
```
允许命令: git status, git diff, git log, mvn test, npm test, pmd, eslint
禁止命令: git push（须过 eco-gate）, rm -rf /, curl 外部 API（须审批）
容器化: 高风险操作在 Docker 容器中执行，容器结束后销毁
```

## 审批流程

> 报告原则：质量门 = "不通过就阻断"，不是 "建议检查"。

| 操作 | 审批级别 | 审批人 | 审批方式 | 是否可自动化 |
|------|----------|--------|----------|--------------|
| 修改聚合根 / 限界上下文 | 高（CCB/ARB） | 架构师 | WAITING_USER + 会议 | 否 |
| 跨域接口变更 | 高（CCB/ARB） | 技术负责人 | WAITING_USER + 签名 | 否 |
| 配置变更（生产环境） | 中（运维审批） | SRE/运维 | WAITING_USER + CI 校验 | 部分（schema 校验可自动） |
| 代码变更（feature 分支） | 低（CR 确认） | 代码审查员 | CR resolve | 是（pre-push gate + CI） |
| 日常实现（task 级） | 极低（TDD 自验证） | 无（Agent 自验证） | pre-push gate | 是（全自动） |

## 审批状态机

```
操作请求
  │
  ├─ 低风险（日常实现）──► pre-push gate 自动通过 ──► 执行
  │
  ├─ 中风险（配置/CR）──► CI green + CR resolve ──► 执行
  │
  └─ 高风险（聚合根/跨域）──► WAITING_USER ──► 人工审查 ──► 批准/拒绝
       │
       └─ 若拒绝 ──► BLOCKED（记录 blocked_reason）
```

## 沙箱与 eco-gate 协同

- 沙箱内执行的操作也需经过 eco-gate 校验（沙箱 ≠ 绕过门禁）
- 沙箱内操作同样记入 `audit-log.jsonl`
- 沙箱结束后，审批状态回写到 `status-tracker.md`

---
> 此文件为**流程骨架**。真实项目需按实际 sandbox 环境（Docker/K8s/VM）、审批人列表、操作风险分级填充。
> 落地待验证⚠️：sandbox 环境配置、审批系统集成、容器化执行。
