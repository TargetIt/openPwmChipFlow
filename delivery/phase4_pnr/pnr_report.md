# Phase 4 布局布线交付件报告

**生成时间**: 2026-05-05 08:23:57
**运行目录**: RUN_2026.05.04_17.02.01
**流程状态**: flow completed

## PnR 结果摘要

### 面积与利用率

| 指标 | 实测值 | 目标 | 判定 |
|------|--------|------|------|
| Die Area | 60705.880995046464mm^2 | - | - |
| Core Area | 19um^2 | - | - |
| Final Utilization | 61.758% | < 70% | ✅ |
| 综合单元数 | 0 | - | - |
| 总单元数 (含 filler) | 5 | - | - |

### 时序收敛

| 指标 | 实测值 | 约束 | 判定 |
|------|--------|------|------|
| 时钟周期 | 5ns | 20.0ns | ✅ |
| 关键路径 | 17ns | < 20ns | ✅ (裕量 3.0ns) |
| WNS | 0.0ns | >= 0 | ✅ |
| TNS | 0.0ns | 0 | ✅ |

### 布线质量

| 指标 | 实测值 | 目标 | 判定 |
|------|--------|------|------|
| 布线违例总数 | 0 | 0 | ✅ |
| Short 违例 | 0 | 0 | ✅ |
| MetSpc 违例 | 0 | 0 | ✅ |
| 总走线长度 | 0um | - | - |
| 过孔数 | 1190 | - | - |

### 物理验证

| 指标 | 实测值 | 目标 | 判定 |
|------|--------|------|------|
| Magic DRC | 1190 | 0 | ❌ |
| KLayout DRC | 0.0 | 0 | ❌ |
| Pin Antenna | 498 | 0 | ❌ |
| LVS 错误 | 0.0 | 0 | ❌ |

### 功耗估算

| 指标 | 实测值 |
|------|--------|
| 内部功耗 (typical) | 0uW |
| 开关功耗 (typical) | 2uW |

### 资源消耗

| 指标 | 实测值 |
|------|--------|
| 运行时间 (routed) | 0h0m44s0ms |
| 峰值内存 | 494.01MB |

## PnR 流程步骤 (共 44 步)

| 阶段 | 步骤 | 关键操作 |
|------|------|----------|
| 综合 | 1-2 | Yosys 综合 + STA |
| 布图规划 | 3-6 | Initial FP, IO Place, Tap, PDN |
| 布局 | 7-14 | Global/Detailed Placement + STA + Resizer |
| 时钟树 | 15-17 | CTS + STA + Timing Opt |
| 布线 | 18-27 | Global Routing, Detailed Routing, Fill, Wire Check |
| Signoff | 28-44 | 3-Corner STA, IR Drop, GDS/LEF/MAG, XOR, LVS, DRC, Antenna |

## 警告评审

共 4 条警告:
```
[WARNING]: PNR_SDC_FILE is not set. It is recommended to write a custom SDC file for the design. Defaulting to BASE_SDC_FILE
[WARNING]: SIGNOFF_SDC_FILE is not set. It is recommended to write a custom SDC file for the design. Defaulting to BASE_SDC_FILE
[WARNING]: Current core area is too small for the power grid settings chosen. The power grid was scaled down to an offset of 1/8 the core width and height and a pitch of 1/4 the core width and height.
[WARNING]: VSRC_LOC_FILES was not given a value, which may make the results of IR drop analysis inaccurate. If you are not integrating a top-level chip for manufacture, you may ignore this warning, otherwise, see the documentation for VSRC_LOC_FILES.
```

## 交付件清单

| 文件 | 说明 | 路径 |
|------|------|------|
| GDS | 流片版图 | results/final/gds/pwm_ctrl.gds |
| LEF | 库交换格式 | results/final/lef/pwm_ctrl.lef |
| LIB | 时序库 | results/final/lib/pwm_ctrl.lib |
| DEF | 设计交换格式 | results/final/def/pwm_ctrl.def |
| SDF (9 corners) | 标准延时格式 | results/final/sdf/multicorner/ |
| SPEF (3 corners) | 寄生参数提取 | results/final/spef/multicorner/ |
| Gate-Level Verilog | 门级网表 | results/final/verilog/gl/pwm_ctrl.v |
| SPICE Netlist | LVS 用 SPICE | results/final/spi/lvs/pwm_ctrl.spice |

## PnR 评审签核

| 检查项 | 状态 |
|--------|------|
| 全流程 44 步完成 | ✅ |
| 布线无违例 | ✅ |
| DRC clean | ✅ |
| LVS clean | ✅ |
| 无 Antenna 违例 | ✅ |
| 时序收敛 (setup/hold) | ✅ |
| 功耗在预期范围 | ✅ |
| 警告已评审 | ✅ |
| 全部交付件已生成 | ✅ |

**PnR 评审结论**: ❌ **需整改**

---

*此报告由 gen_report.sh 自动生成，基于 OpenLane 运行数据*
