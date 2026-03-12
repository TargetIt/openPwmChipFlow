# openPwmChipFlow

**PWM 数字芯片全流程开发项目**

> PWM Controller + Sky130 (130nm) + OpenLane2 + AI 辅助  
> 用最简单的设计，跑通 RTL → GDS 完整流程

---

## 项目简介

本项目以一个极简的 PWM（脉宽调制）控制器为载体，完整演示数字芯片从 RTL 设计到 GDS 输出的全流程。PWM 控制器仅 ~25 行 Verilog 代码，由计数器 + 比较器组成，逻辑清晰，适合将精力集中在学习工具链上。

## 项目结构

```
openPwmChipFlow/
├── or.md                         ← 全流程开发策略文档
├── setup_env.sh                  ← 环境安装脚本
├── run_all.sh                    ← 一键全流程运行脚本
│
├── phase0_spec/                  ← Phase 0: 规格与需求定义
│   ├── requirements.md           ← 需求文档
│   ├── design_spec.md            ← 设计规格文档
│   └── README.md
│
├── phase1_rtl/                   ← Phase 1: RTL 编写
│   ├── src/pwm_ctrl.v            ← PWM 控制器主设计文件
│   └── README.md
│
├── phase2_sim/                   ← Phase 2: 仿真验证
│   ├── tb/tb_pwm.v               ← Testbench
│   ├── run_sim.sh                ← 仿真自动化脚本
│   └── README.md
│
├── phase3_synthesis/             ← Phase 3: 综合
│   ├── openlane/config.json      ← OpenLane2 综合配置
│   ├── run_synthesis.sh          ← 综合自动化脚本
│   └── README.md
│
├── phase4_pnr/                   ← Phase 4: 布局布线
│   ├── openlane/config.json      ← OpenLane2 完整流程配置
│   ├── run_pnr.sh                ← PnR 自动化脚本
│   └── README.md
│
├── phase5_verification/          ← Phase 5: 物理验证
│   ├── run_verify.sh             ← DRC/LVS 检查脚本
│   └── README.md
│
└── phase6_gds/                   ← Phase 6: GDS 输出
    ├── run_gds.sh                ← GDS 输出检查脚本
    └── README.md
```

## 快速开始

### 1. 安装环境

```bash
chmod +x setup_env.sh
./setup_env.sh
```

此脚本将自动安装：
- **iverilog** — Verilog 仿真编译器
- **GTKWave** — 波形查看器
- **Docker** — OpenLane2 运行环境（需手动安装）

### 2. 一键运行全流程

```bash
chmod +x run_all.sh
./run_all.sh
```

此脚本将按顺序执行 6 个阶段：
1. ✅ 检查 RTL 文件
2. 🔄 运行仿真验证（需要 iverilog）
3. 🔄 运行综合（需要 Docker + OpenLane2）
4. 🔄 运行布局布线（需要 Docker + OpenLane2）
5. 🔄 检查物理验证报告
6. 🔄 检查 GDS 输出文件

### 3. 分阶段运行

也可以单独运行各阶段：

```bash
# Phase 2: 仿真验证（仅需 iverilog，无需 Docker）
./phase2_sim/run_sim.sh

# Phase 3: 综合（需要 Docker + OpenLane2）
./phase3_synthesis/run_synthesis.sh

# Phase 4: 布局布线（需要 Docker + OpenLane2）
./phase4_pnr/run_pnr.sh

# Phase 5: 物理验证
./phase5_verification/run_verify.sh

# Phase 6: GDS 输出
./phase6_gds/run_gds.sh
```

## 工具链

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| iverilog | RTL 仿真 | `sudo apt install iverilog` |
| GTKWave | 波形查看 | `sudo apt install gtkwave` |
| OpenLane2 | 全流程框架 | `docker pull efabless/openlane2:latest` |
| KLayout | GDS 查看 | `sudo apt install klayout` |

## 全流程时间线

| 阶段 | 内容 | 工具 | 预计时间 |
|------|------|------|----------|
| Phase 0 | 规格与需求定义 | Markdown | 0.5 天 |
| Phase 1 | RTL 编写 | VS Code + AI | 0.5 天 |
| Phase 2 | 仿真验证 | iverilog + GTKWave | 1 天 |
| Phase 3 | 综合 | Yosys (via OpenLane2) | 0.5 天 |
| Phase 4 | 布局布线 | OpenROAD (via OpenLane2) | 1–2 天 |
| Phase 5 | 物理验证 | Magic + Netgen | 0.5 天 |
| Phase 6 | GDS 输出 | KLayout | 0.5 天 |

**总计：约 4–5 天**

## 里程碑检查表

- [ ] RTL 完成 — `pwm_ctrl.v` 不超过 30 行，端口清晰
- [ ] 仿真通过 — GTKWave 波形占空比与 duty 值一致
- [ ] 综合干净 — Yosys 报告无时序违例
- [ ] PnR 完成 — OpenLane2 流程无 ERROR 结束
- [ ] DRC clean — violation = 0
- [ ] LVS clean — net/device match
- [ ] GDS 生成 — KLayout 可正常打开版图

---

*从 25 行代码出发，走完芯片设计的完整旅程。*