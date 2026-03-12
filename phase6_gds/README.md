# Phase 6 — GDS 输出

## 概述

本阶段查看和验证 OpenLane2 生成的最终 GDS 文件及相关输出。GDS（Graphic Data System）是芯片流片所需的版图数据格式。

## 工具要求

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| KLayout | GDS 版图查看器 | `sudo apt install klayout` |

## 一键运行

```bash
chmod +x phase6_gds/run_gds.sh
./phase6_gds/run_gds.sh
```

> 注意：需先完成 Phase 4（布局布线），输出文件从 `phase4_pnr/runs/` 目录读取。

## 输出文件说明

| 文件 | 路径 | 用途 |
|------|------|------|
| `pwm_ctrl.gds` | `results/final/gds/` | 流片主文件 |
| `pwm_ctrl.lef` | `results/final/lef/` | IP 集成接口 |
| `pwm_ctrl.lib` | `results/final/lib/` | 时序模型 |
| `final_summary.html` | `runs/RUN_xxx/` | 完整流程报告 |

## 查看 GDS 版图

```bash
klayout phase4_pnr/runs/RUN_xxx/results/final/gds/pwm_ctrl.gds
```

看到真实的芯片版图，全流程完成 🎉

## 文件说明

```
phase6_gds/
  ├── run_gds.sh     ← 一键输出检查脚本
  └── README.md      ← 本文档
```

## 验证通过标准

- [ ] GDS 文件成功生成
- [ ] KLayout 可正常打开版图
- [ ] LEF/LIB 文件完整
