#!/bin/bash
# Phase 2: PWM 仿真验证脚本
# 使用 iverilog 编译并运行仿真，生成 VCD 波形文件及测试报告
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RTL_SRC="$PROJECT_ROOT/phase1_rtl/src/pwm_ctrl.v"
TB_SRC="$SCRIPT_DIR/tb/tb_pwm.v"
SIM_OUT="$SCRIPT_DIR/sim"
WAVE_FILE="$SCRIPT_DIR/wave.vcd"
TEST_LOG="$SCRIPT_DIR/test_results.log"
TEST_REPORT="$SCRIPT_DIR/test_report.md"

echo "========================================"
echo "  Phase 2: PWM 仿真验证"
echo "========================================"

if ! command -v iverilog &> /dev/null; then
    echo "[ERROR] iverilog 未安装。请运行: sudo apt install iverilog"
    exit 1
fi

if [ ! -f "$RTL_SRC" ]; then
    echo "[ERROR] RTL 源文件不存在: $RTL_SRC"
    exit 1
fi

if [ ! -f "$TB_SRC" ]; then
    echo "[ERROR] Testbench 文件不存在: $TB_SRC"
    exit 1
fi

# 编译
echo "[1/4] 编译 RTL 和 Testbench..."
iverilog -o "$SIM_OUT" "$TB_SRC" "$RTL_SRC"
echo "  编译成功"

# 运行仿真，输出同时保存到日志
echo "[2/4] 运行仿真..."
cd "$SCRIPT_DIR"
./sim 2>&1 | tee "$TEST_LOG"
SIM_EXIT=${PIPESTATUS[0]}
echo "  仿真完成"

# 检查波形文件
echo "[3/4] 检查输出..."
if [ ! -f "$WAVE_FILE" ]; then
    echo "[ERROR] 波形文件未生成"
    exit 1
fi
echo "  波形文件已生成: $WAVE_FILE"

# 生成测试报告
echo "[4/4] 生成测试报告..."
test_result() {
    local test_id="$1"
    awk -v test_id="$test_id" '
        $0 ~ "^\\[TEST " test_id "\\]" { seen=1; in_test=1; pass=0; fail=0; next }
        /^\[TEST [0-9]+\]/ && in_test { in_test=0; exit }
        in_test && /^[[:space:]]+PASS:/ { pass=1 }
        in_test && /^[[:space:]]+FAIL:/ { fail=1 }
        END {
            if (seen && fail) print "❌ FAIL";
            else if (seen && pass) print "✅ PASS";
            else print "❌ NOT OBSERVED";
        }
    ' "$TEST_LOG"
}

ASSERTION_PASS_COUNT=$(awk '/^[[:space:]]+PASS:/ { count++ } END { print count+0 }' "$TEST_LOG")
ASSERTION_FAIL_COUNT=$(awk '/^[[:space:]]+FAIL:/ { count++ } END { print count+0 }' "$TEST_LOG")
ALL_PASSED=$(awk '/^=== ALL TESTS PASSED ===/ { count++ } END { print count+0 }' "$TEST_LOG")
TEST_PASS_COUNT=0
TEST_FAIL_COUNT=0
for TEST_ID in 1 2 3 4 5 6; do
    case "$(test_result "$TEST_ID")" in
        *"PASS"*) TEST_PASS_COUNT=$((TEST_PASS_COUNT + 1)) ;;
        *) TEST_FAIL_COUNT=$((TEST_FAIL_COUNT + 1)) ;;
    esac
done

cat > "$TEST_REPORT" << EOF
# Phase 2 仿真验证报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 测试环境

| 项目 | 值 |
|------|-----|
| 仿真工具 | iverilog $(iverilog -V 2>&1 | head -1) |
| RTL 文件 | $RTL_SRC |
| Testbench | $TB_SRC |
| 波形文件 | $WAVE_FILE ($(du -h "$WAVE_FILE" | cut -f1)) |

## 测试用例

| 用例 | 描述 | 预期结果 | 结果 |
|------|------|----------|------|
| TEST 1 | Reset 行为 | pwm_out=0 在 reset 期间 | $(test_result 1) |
| TEST 2 | 50% 占空比 (duty=128) | high=128/256, 误差<0.5% | $(test_result 2) |
| TEST 3 | 25% 占空比 (duty=64) | high=64/256, 误差<0.5% | $(test_result 3) |
| TEST 4 | 0% 占空比 (duty=0) | high=0/256 | $(test_result 4) |
| TEST 5 | ~100% 占空比 (duty=255) | high=255/256, 误差<0.5% | $(test_result 5) |
| TEST 6 | 运行中 Reset | counter 复位, pwm_out=0 | $(test_result 6) |

## 测试统计

| 指标 | 值 |
|------|-----|
| 总测试数 | 6 |
| 通过用例数 | $TEST_PASS_COUNT |
| 失败/未观测用例数 | $TEST_FAIL_COUNT |
| 原始 PASS 断言数 | $ASSERTION_PASS_COUNT |
| 原始 FAIL 断言数 | $ASSERTION_FAIL_COUNT |

## 总体结果

**$(if [ "$ALL_PASSED" -gt 0 ]; then echo '✅ ALL TESTS PASSED'; else echo '❌ SOME TESTS FAILED'; fi)**

## 交付件清单

| 文件 | 说明 | 状态 |
|------|------|------|
| wave.vcd | 波形文件 | ✅ |
| test_results.log | 仿真原始日志 | ✅ |
| test_report.md | 本测试报告 | ✅ |
| sim | 编译后可执行文件 | ✅ |
EOF

echo "  测试报告已生成: $TEST_REPORT"
echo ""
echo "========================================"
echo "  仿真完成！"
echo "  测试报告: $TEST_REPORT"
echo "  查看波形: gtkwave $WAVE_FILE"
echo "========================================"

if [ "$ALL_PASSED" -eq 0 ]; then
    exit 1
fi
