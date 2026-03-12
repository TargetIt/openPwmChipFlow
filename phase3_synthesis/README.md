# Phase 3 — 综合

## 概述

本阶段使用 Yosys（通过 OpenLane2）将 PWM 控制器的 RTL 代码综合为门级网表。

## 工具要求

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| Docker | 容器运行环境 | [安装指南](https://docs.docker.com/get-docker/) |
| OpenLane2 | EDA 全流程框架 | `docker pull efabless/openlane2:latest` |

## 一键运行

```bash
chmod +x phase3_synthesis/run_synthesis.sh
./phase3_synthesis/run_synthesis.sh
```

## OpenLane2 配置说明

| 参数 | 值 | 说明 |
|------|-----|------|
| `DESIGN_NAME` | `pwm_ctrl` | 顶层模块名 |
| `CLOCK_PORT` | `clk` | 时钟端口 |
| `CLOCK_PERIOD` | 20.0 ns | 50 MHz 时钟约束 |
| `pdk` | `sky130A` | 使用 Sky130 工艺库 |
| `STD_CELL_LIBRARY` | `sky130_fd_sc_hd` | 高密度标准单元库 |

## 预期综合结果

| 指标 | PWM 预期值 | 说明 |
|------|-----------|------|
| 标准单元数 | 20–50 个 | 极少 |
| 关键路径 | < 2 ns | 远优于 20ns 约束 |
| 面积 | < 200 μm² | 极小 |
| 时序违例 | 0 | 必须干净 |

## 文件说明

```
phase3_synthesis/
  ├── openlane/
  │   └── config.json      ← OpenLane2 综合配置
  ├── run_synthesis.sh      ← 一键综合脚本
  └── README.md             ← 本文档
```

## 验证通过标准

- [ ] Yosys 综合无错误退出
- [ ] 时序违例为 0
- [ ] 标准单元数在预期范围内
