# Phase 5 — 物理验证

## 概述

本阶段检查 OpenLane2 生成的 DRC（设计规则检查）和 LVS（布局与原理图一致性检查）报告，确保物理版图符合工艺要求。

## 工具说明

物理验证由 OpenLane2 在 Phase 4 流程结束后自动运行（使用 Magic + Netgen），本阶段主要是**读取和分析报告**。

## 一键运行

```bash
chmod +x phase5_verification/run_verify.sh
./phase5_verification/run_verify.sh
```

> 注意：需先完成 Phase 4（布局布线），报告从 `phase4_pnr/runs/` 目录读取。

## 报告位置

```
phase4_pnr/runs/RUN_xxx/reports/signoff/
  ├── drc.rpt    ← DRC 报告
  └── lvs.rpt    ← LVS 报告
```

## PWM 常见违例

| 违例类型 | 原因 | 处理方法 |
|----------|------|----------|
| Antenna violation | 金属线过长 | OpenLane2 默认自动插入 antenna diode |
| Metal spacing | 绕线密度过高 | 降低 `PL_TARGET_DENSITY` 重跑 |
| LVS mismatch | 端口连接错误 | 检查 `pwm_ctrl.v` 端口声明 |

## 文件说明

```
phase5_verification/
  ├── run_verify.sh    ← 一键验证脚本
  └── README.md        ← 本文档
```

## 验证通过标准

- [ ] DRC violation = 0
- [ ] LVS clean（net/device match）
