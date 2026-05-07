# openPwmChipFlow 交付件清单

**项目**: PWM 数字芯片 (Sky130A, OpenLane v1.1.1)
**交付日期**: 2026-05-05
**流程状态**: ✅ 全流程通过 (DRC=0, LVS=0, Timing Clean)

---

## 目录结构

```
delivery/
├── README.md                          ← 本文件
├── phase1_rtl/                        ← RTL 源码
├── phase2_sim/                        ← 仿真验证
├── phase3_synthesis/                  ← 逻辑综合
├── phase4_pnr/                        ← 布局布线
├── phase5_verification/               ← 物理验证
└── phase6_gds/                        ← GDS 输出
```

---

## Phase 1 — RTL 设计

| 文件 | 说明 | 大小 |
|------|------|------|
| `pwm_ctrl.v` | PWM 控制器 Verilog RTL (18 行) | 331B |

**设计要点**:
- 8-bit 计数器 + 比较器架构
- 同步复位 (高有效)
- 端口: clk, rst, duty[7:0], pwm_out
- 无状态机，无复杂时序路径

---

## Phase 2 — 仿真验证

| 文件 | 说明 | 大小 |
|------|------|------|
| `test_report.md` | 测试评审报告 (6/6 PASS) | ~2K |
| `test_results.log` | 仿真原始输出日志 | ~1K |
| `wave.vcd` | VCD 波形文件 | ~67K |

**测试结果**:

| 用例 | 描述 | 结果 |
|------|------|------|
| TEST 1 | Reset behavior | ✅ |
| TEST 2 | 50% duty (duty=128) | ✅ 50.00% |
| TEST 3 | 25% duty (duty=64) | ✅ 25.00% |
| TEST 4 | 0% duty (duty=0) | ✅ 0.00% |
| TEST 5 | ~100% duty (duty=255) | ✅ 99.61% |
| TEST 6 | Reset during operation | ✅ |

---

## Phase 3 — 逻辑综合

| 文件 | 说明 | 大小 |
|------|------|------|
| `pwm_ctrl_synth.v` | Yosys 综合后门级网表 | ~28K |
| `pwm_ctrl_synth.sdf` | 综合后标准延时格式 | ~4K |
| `1-synthesis.log` | Yosys 综合完整日志 | ~15K |
| `2-sta.log` | 综合后 STA 日志 | ~1K |
| `2-sta.rpt` | 综合后 STA 详细报告 | ~6K |
| `linter.log` | Verilator Lint 检查日志 | ~1K |
| `metrics.csv` | 全流程量化指标 (86 字段) | ~3K |
| `synthesis_report.md` | 综合签核评审报告 | ~3K |

**关键指标**:
- 标准单元数: 53
- 关键路径: 0.86ns (时钟约束 20ns)
- Die Area: 0.0025mm²
- WNS/TNS: 0 (无时序违例)
- Lint: 0 errors, 0 warnings

---

## Phase 4 — 布局布线

| 文件 | 说明 | 大小 |
|------|------|------|
| `pwm_ctrl.def` | 最终设计交换格式 (含物理信息) | 92K |
| `pwm_ctrl.sdc` | SDC 时序约束文件 | 4K |
| `pwm_ctrl_pnr.v` | 后 PnR 门级网表 | 28K |
| `sdf/` | 多 corner SDF (3 corners × 3 PVT) | ~340K |
| `spef/` | 多 corner 寄生参数 (3 corners) | ~176K |
| `pnr_report.md` | PnR 签核评审报告 | ~4K |

**关键指标**:
- Final Utilization: 61.76%
- 布线违例: 0 (shorts=0, MetSpc=0)
- 总走线长度: 1190um, Vias: 498
- 全流程 44 步完成, 耗时 1min

---

## Phase 5 — 物理验证

| 文件 | 说明 | 大小 |
|------|------|------|
| `drc.rpt` | Magic DRC 报告 (COUNT=0) | <1K |
| `lvs.rpt` | LVS 报告 (total errors=0) | <1K |
| `antenna.rpt` | Antenna 违例报告 | <1K |
| `xor.rpt` | Magic/KLayout GDS XOR 对比 | <1K |
| `manufacturability.rpt` | 可制造性综合报告 | ~2K |
| `verify_report.md` | 物理验证签核报告 | ~3K |

**验证结果**:
- Magic DRC: 0 violations
- KLayout DRC: 0 violations (violations.json total=0)
- LVS: net/device match, total errors=0
- Antenna: 0 pin, 0 net violations
- XOR: No differences between Magic and KLayout GDS

---

## Phase 6 — GDS 输出

| 文件 | 说明 | 大小 |
|------|------|------|
| `pwm_ctrl.gds` | **GDSII 流片版图** | 408K |
| `pwm_ctrl.lef` | LEF 库交换格式 (IP 集成) | 8K |
| `pwm_ctrl.lib` | Liberty 时序库模型 | 12K |
| `pwm_ctrl.spice` | SPICE 晶体管级网表 (LVS 用) | 20K |
| `gds_report.md` | GDS 交付签核报告 | ~3K |

---

## 版图截图 (`images/`)

> 由 KLayout batch mode + Yosys 自动生成，共 21 张图片

### 逐层版图（11 层金属 + 接触孔）

| 图片 | GDS 层 | 说明 | 大小 |
|------|--------|------|------|
| `02_li1.png` | 67/20 | Local Interconnect (本地互联) | 99K |
| `03_licon1.png` | 67/44 | LI Contact (金属接触) | 100K |
| `04_met1.png` | 68/20 | Metal 1 (第一层金属, 最密) | 130K |
| `05_via1.png` | 68/44 | Via1 (M1→M2 通孔) | 101K |
| `06_met2.png` | 69/20 | Metal 2 (第二层金属) | 141K |
| `07_via2.png` | 69/44 | Via2 (M2→M3 通孔) | 94K |
| `08_met3.png` | 70/20 | Metal 3 (第三层金属) | 101K |
| `09_via3.png` | 70/44 | Via3 (M3→M4 通孔) | 93K |
| `10_met4.png` | 71/20 | Metal 4 (第四层金属) | 147K |
| `11_via4.png` | 71/44 | Via4 (M4→M5 通孔) | 96K |
| `12_met5.png` | 72/20 | Metal 5 (顶层金属) | 113K |

### 组合视图与细节

| 图片 | 说明 | 大小 |
|------|------|------|
| `01_full_chip.png` | 完整芯片版图 (全部层) | 327K |
| `13_all_labels_outline.png` | 全部标签 + 引脚 + 边界 | 262K |
| `14_met1_to_met2.png` | M1 → M2 堆叠 (晶体管级连接) | 188K |
| `15_met2_to_met3.png` | M2 → M3 堆叠 | 152K |
| `16_met3_to_met5.png` | M3 → M5 堆叠 (上层走线) | 192K |
| `17_detail_top.png` | 芯片顶部区域放大 | 43K |
| `18_detail_center.png` | 芯片中心区域放大 | 40K |
| `19_detail_transistor.png` | 晶体管级细节 (li1+licon1+met1) | 60K |

### 综合原理图

| 图片 | 说明 | 大小 |
|------|------|------|
| `synthesis_hierarchy.png` | Yosys 综合后模块层次图 | 69K |
| `synthesis_hierarchy.dot` | DOT 源文件 | 2.2K |

**综合统计**: 4 cells ($add, $dff, $lt, $mux), 1 DFF

### 物理设计指标

| 指标 | 值 |
|------|-----|
| 工艺 | SkyWater 130nm (sky130A) |
| 芯片面积 | 45.0µm × 55.7µm = 0.003 mm² |
| 金属层 | li1 + met1–met5 (5 层金属 + 本地互联) |
| 标准单元数 | 35 种 |
| 总形状数 | 3,210 (21 层) |

---

## 质量门禁汇总

| 门禁项 | 目标 | 实测 | 状态 |
|--------|------|------|------|
| 仿真覆盖率 | 100% 用例通过 | 6/6 | ✅ |
| 时序收敛 (setup) | WNS >= 0 | 0.0 | ✅ |
| 时序收敛 (hold) | WHS >= 0 | 0.0 | ✅ |
| 布线违例 | 0 | 0 | ✅ |
| DRC violations | 0 | 0 | ✅ |
| LVS errors | 0 | 0 | ✅ |
| Antenna violations | 0 | 0 | ✅ |
| GDS 生成 | 文件存在 | 408K | ✅ |
| LEF 生成 | 文件存在 | 8K | ✅ |
| LIB 生成 | 文件存在 | 12K | ✅ |

**结论: ✅ 全流程交付件完整，所有质量门禁通过，可进入流片准备阶段。**

---

*交付件由各 phase 的 gen_report.sh / run_*.sh 自动生成并汇总*
