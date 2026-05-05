# Phase 3 综合交付件报告

**生成时间**: 2026-05-05 08:25:59
**运行目录**: RUN_2026.05.04_17.02.01
**流程状态**: flow completed

## 综合结果摘要

| 指标 | 实测值 | 预期范围 | 判定 |
|------|--------|----------|------|
| 标准单元数 | 0 | 20-50 | ⚠️ |
| 关键路径延迟 | 17ns | < 2.0ns | ✅ |
| 芯片面积 | 60705.880995046464mm^2 | < 0.01mm^2 | ✅ |
| 核心面积 | 19um^2 | < 200um^2 | ⚠️ |
| 时序违例 (WNS) | 0.0ns | 0 | ✅ |
| 时序违例 (TNS) | 0.0ns | 0 | ✅ |
| 综合错误 | 1 | 0 | ❌ |
| 综合警告 | 1 | - | ⚠️ 1个 |
| Lint 错误 | 0 | 0 | ✅ |
| Lint 警告 | 0 | 0 | ✅ |
| 总运行时间 | 0h1m0s0ms | < 5min | ✅ |

## 综合流程步骤

| 步骤 | 说明 | 日志 |
|------|------|------|
| Linter | Verilator lint 检查 | logs/synthesis/linter.log |
| Synthesis | Yosys 逻辑综合 | logs/synthesis/1-synthesis.log |
| STA | 单 corner 静态时序分析 | logs/synthesis/2-sta.log |

## 交付件清单

| 文件 | 说明 | 位置 |
|------|------|------|
| 综合后网表 | 门级 Verilog | results/synthesis/pwm_ctrl.v |
| SDF 文件 | 标准延时格式 | results/synthesis/pwm_ctrl.sdf |
| 综合日志 | Yosys 完整日志 | logs/synthesis/1-synthesis.log |
| 综合 STA 报告 | 时序分析 | reports/synthesis/ |
| Lint 报告 | Verilator 输出 | logs/synthesis/linter.log |
| Metrics CSV | 全部量化指标 | reports/metrics.csv |

## 综合评审签核

| 检查项 | 状态 |
|--------|------|
| RTL 源代码已就绪 | ✅ |
| 设计无 lint 错误 | ✅ |
| 综合流程完整运行 | ✅ |
| 无时序违例 | ✅ |
| 标准单元数在预期范围 | ✅ |
| 面积满足约束 | ✅ |
| 综合警告已评审 | ✅ |

**综合评审结论**: ❌ **需整改** - 存在不满足质量门禁的指标

---

*此报告由 gen_report.sh 自动生成，基于 OpenLane 运行数据*
