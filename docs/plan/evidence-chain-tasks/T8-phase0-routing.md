# T8: phase0-routing.md

## 基本信息

| 属性 | 值 |
|------|-----|
| Task | T8 |
| 类型 | 修改 |
| 文件 | `team-flow/skills/ce-brainstorm/references/phase0-routing.md` |
| 依赖 | T4（Batch 2） |
| 批次 | Batch 3 |
| 预估行数 | +15 |

## 设计规划依据

- §3.1 目录结构（requirement/vN/）
- §8.2 文件变更清单

## 输入

- 设计规划 §3.1 目录结构
- 当前 phase0-routing.md

## 具体修改点

1. Phase 0.1 Resume：扫描 `requirement/` 目录 + 读取 `requirement/ledger.md`
2. Phase 0.5 Iteration Version：扫描 `requirement/` 检测已有迭代版本

## 验收标准

- [ ] Phase 0.1 扫描 requirement/ + 读取 ledger.md
- [ ] Phase 0.5 扫描 requirement/ 检测迭代版本
- [ ] 存量 prd/ 兼容说明
- [ ] 现有内容（0.1b/0.1c/0.2/0.3/0.4）未修改
- [ ] +15 行

## 关键约束

- 存量兼容：已有 prd/ 目录平滑过渡
- ledger.md 只在 0.1 读取，不在 0.5 写入
