# Phase 4 — 布局布线

## 概述

本阶段使用 OpenROAD（通过 OpenLane2）完成 PWM 控制器的布局布线（Place & Route），生成物理版图。

## 工具要求

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| Docker | 容器运行环境 | [安装指南](https://docs.docker.com/get-docker/) |
| OpenLane2 | EDA 全流程框架 | `docker pull efabless/openlane2:latest` |

## 一键运行

```bash
chmod +x phase4_pnr/run_pnr.sh
./phase4_pnr/run_pnr.sh
```

## 配置参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| `CLOCK_PERIOD` | 20.0 ns | 50 MHz，PWM 完全够用 |
| `FP_CORE_UTIL` | 30 | 设计极小，低利用率更稳定 |
| `PL_TARGET_DENSITY` | 0.3 | 留足余量，避免拥塞 |

> PWM 设计极小，整个 PnR 流程通常 **5 分钟内**完成。

## 文件说明

```
phase4_pnr/
  ├── openlane/
  │   └── config.json    ← OpenLane2 完整流程配置
  ├── run_pnr.sh         ← 一键布局布线脚本
  └── README.md          ← 本文档
```

## 验证通过标准

- [ ] OpenLane2 流程无 ERROR 退出
- [ ] 时序满足约束（无 setup/hold 违例）
- [ ] 布线无拥塞错误
