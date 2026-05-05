# Phase 6 GDS 输出交付件报告

**生成时间**: 2026-05-05 08:26:00
**运行目录**: RUN_2026.05.04_17.02.01

## 输出文件

### 主交付件

| 文件 | 大小 | 用途 |
|------|------|------|
| pwm_ctrl.gds | 408K | 流片主文件 (GDSII 格式) |
| pwm_ctrl.lef | 8.0K | IP 集成接口 (Library Exchange Format) |
| pwm_ctrl.lib | 12K | 时序模型 (Liberty 格式) |

### 辅助交付件

| 文件 | 说明 |
|------|------|
| pwm_ctrl.def | 设计交换格式，含物理布局信息 |
| pwm_ctrl.v (gl) | 门级 Verilog 网表 |
| pwm_ctrl.spice | LVS 用 SPICE 网表 |
| pwm_ctrl.sdf (9个) | 多 corner 标准延时格式 |
| pwm_ctrl.spef (3个) | 多 corner 寄生参数提取 |

## 质量指标 (来自 metrics.csv)

| 指标 | 值 |
|------|-----|
| 流程状态 | flow completed |
| DRC 违例 | 0 |
| LVS 错误 | 0 |
| Antenna 违例 | 0 |
| 总单元数 | 5 |
| 版图面积 | 60705.880995046464 mm^2 |

## 查看版图

```bash
# 使用 KLayout 打开 GDS 版图
klayout /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow/openlane/pwm_ctrl/runs/RUN_2026.05.04_17.02.01/results/final/gds/pwm_ctrl.gds

# 使用 Magic 打开版图
magic /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow/openlane/pwm_ctrl/runs/RUN_2026.05.04_17.02.01/results/final/mag/pwm_ctrl.mag
```

## 交付完整性检查

| 交付件 | 状态 |
|--------|------|
| GDS 版图文件 | ✅ |
| LEF 库视图 | ✅ |
| LIB 时序库 | ✅ |
| DEF 设计交换 | ✅ |
| 门级网表 | ✅ |
| SPICE 网表 | ✅ |
| SDF (多 corner) | ✅ |
| SPEF (多 corner) | ✅ |
| DRC clean | ✅ |
| LVS clean | ✅ |

## 签核结论

**✅ GDS 交付件完整，可以进入流片准备**

---

*此报告由 run_gds.sh 自动生成*
