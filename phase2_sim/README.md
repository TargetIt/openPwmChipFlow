# Phase 2 — 仿真验证

## 概述

本阶段使用 iverilog 对 PWM 控制器进行功能仿真，验证 RTL 设计的正确性。

## 工具要求

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| iverilog | RTL 仿真编译器 | `sudo apt install iverilog` |
| GTKWave | 波形查看器 | `sudo apt install gtkwave` |

## 一键运行

```bash
chmod +x phase2_sim/run_sim.sh
./phase2_sim/run_sim.sh
```

## 手动运行

```bash
cd phase2_sim
iverilog -o sim tb/tb_pwm.v ../phase1_rtl/src/pwm_ctrl.v
./sim
gtkwave wave.vcd
```

## 测试用例

| 测试项 | 设置 | 预期结果 |
|--------|------|----------|
| 复位行为 | rst=1 | counter=0，pwm_out=0 |
| 50% 占空比 | duty=128 | pwm_out 高电平占 50% |
| 25% 占空比 | duty=64 | pwm_out 高电平占 25% |
| 0% 占空比 | duty=0 | 全低电平 |
| ~100% 占空比 | duty=255 | 接近全高电平 |
| 运行中复位 | rst=1 during operation | counter 清零，pwm_out=0 |

## 文件说明

```
phase2_sim/
  ├── tb/
  │   └── tb_pwm.v     ← Testbench 文件
  ├── run_sim.sh        ← 一键仿真脚本
  └── README.md         ← 本文档
```

## 验证通过标准

- [ ] 所有测试用例通过（终端输出 `ALL TESTS PASSED`）
- [ ] 波形文件 `wave.vcd` 正确生成
- [ ] GTKWave 中波形占空比与 duty 值一致
