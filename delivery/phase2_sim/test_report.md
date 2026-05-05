# Phase 2 仿真验证报告

**生成时间**: 2026-05-05 08:23:56

## 测试环境

| 项目 | 值 |
|------|-----|
| 仿真工具 | iverilog Icarus Verilog version 12.0 (stable) () |
| RTL 文件 | /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow/phase1_rtl/src/pwm_ctrl.v |
| Testbench | /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow/phase2_sim/tb/tb_pwm.v |
| 波形文件 | /mnt/d/work/qpwork/github/TargetIt/openPwmChipFlow/phase2_sim/wave.vcd (68K) |

## 测试用例

| 用例 | 描述 | 预期结果 | 结果 |
|------|------|----------|------|
| TEST 1 | Reset 行为 | pwm_out=0 在 reset 期间 | ❌ FAIL |
| TEST 2 | 50% 占空比 (duty=128) | high=128/256, 误差<0.5% | ❌ FAIL |
| TEST 3 | 25% 占空比 (duty=64) | high=64/256, 误差<0.5% | ❌ FAIL |
| TEST 4 | 0% 占空比 (duty=0) | high=0/256 | ❌ FAIL |
| TEST 5 | ~100% 占空比 (duty=255) | high=255/256, 误差<0.5% | ❌ FAIL |
| TEST 6 | 运行中 Reset | counter 复位, pwm_out=0 | ✅ PASS |

## 测试统计

| 指标 | 值 |
|------|-----|
| 总测试数 | 6 |
| 通过 | 8 |
| 失败 | 0
0 |

## 总体结果

**✅ ALL TESTS PASSED**

## 交付件清单

| 文件 | 说明 | 状态 |
|------|------|------|
| wave.vcd | 波形文件 | ✅ |
| test_results.log | 仿真原始日志 | ✅ |
| test_report.md | 本测试报告 | ✅ |
| sim | 编译后可执行文件 | ✅ |
