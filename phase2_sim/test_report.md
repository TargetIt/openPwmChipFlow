# Phase 2 仿真验证报告

**生成时间**: 2026-06-27 22:06:26

## 测试环境

| 项目 | 值 |
|------|-----|
| 仿真工具 | iverilog Icarus Verilog version 13.0 (stable) (v13_0) |
| RTL 文件 | /Users/jiuri/data/targetIt/openPwmChipFlow/phase1_rtl/src/pwm_ctrl.v |
| Testbench | /Users/jiuri/data/targetIt/openPwmChipFlow/phase2_sim/tb/tb_pwm.v |
| 波形文件 | /Users/jiuri/data/targetIt/openPwmChipFlow/phase2_sim/wave.vcd (128K) |

## 测试用例

| 用例 | 描述 | 预期结果 | 结果 |
|------|------|----------|------|
| TEST 1 | Reset 行为 | pwm_out=0 在 reset 期间 | ✅ PASS |
| TEST 2 | 50% 占空比 (duty=128) | high=128/256, 误差<0.5% | ✅ PASS |
| TEST 3 | 25% 占空比 (duty=64) | high=64/256, 误差<0.5% | ✅ PASS |
| TEST 4 | 0% 占空比 (duty=0) | high=0/256 | ✅ PASS |
| TEST 5 | ~100% 占空比 (duty=255) | high=255/256, 误差<0.5% | ✅ PASS |
| TEST 6 | 运行中 Reset | counter 复位, pwm_out=0 | ✅ PASS |

## 测试统计

| 指标 | 值 |
|------|-----|
| 总测试数 | 6 |
| 通过用例数 | 6 |
| 失败/未观测用例数 | 0 |
| 原始 PASS 断言数 | 7 |
| 原始 FAIL 断言数 | 0 |

## 总体结果

**✅ ALL TESTS PASSED**

## 交付件清单

| 文件 | 说明 | 状态 |
|------|------|------|
| wave.vcd | 波形文件 | ✅ |
| test_results.log | 仿真原始日志 | ✅ |
| test_report.md | 本测试报告 | ✅ |
| sim | 编译后可执行文件 | ✅ |
