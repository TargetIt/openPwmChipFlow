#!/bin/bash
# Phase 5: PWM 物理验证脚本
# 检查 OpenLane2 生成的 DRC 和 LVS 报告
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PNR_RUNS="$PROJECT_ROOT/phase4_pnr/runs"

echo "========================================"
echo "  Phase 5: PWM 物理验证 (DRC + LVS)"
echo "========================================"

# 查找最新的运行目录
if [ ! -d "$PNR_RUNS" ]; then
    echo "[ERROR] 未找到 PnR 运行目录。请先运行 Phase 4 (run_pnr.sh)"
    exit 1
fi

LATEST_RUN=$(ls -td "$PNR_RUNS"/RUN_* 2>/dev/null | head -1)
if [ -z "$LATEST_RUN" ]; then
    echo "[ERROR] 未找到运行结果。请先运行 Phase 4 (run_pnr.sh)"
    exit 1
fi

echo "  使用运行目录: $(basename "$LATEST_RUN")"
echo ""

overall_pass=1

# Helper: read first integer from report line that matches a pattern.
extract_first_int_by_pattern() {
    local report_file="$1"
    local pattern="$2"
    local value=""
    value=$(grep -Ei "$pattern" "$report_file" 2>/dev/null | grep -Eo '[0-9]+' | head -1 || true)
    if [ -n "$value" ]; then
        echo "$value"
    else
        echo ""
    fi
}

# 检查 DRC 报告
DRC_RPT="$LATEST_RUN/reports/signoff/drc.rpt"
echo "[1/2] 检查 DRC 报告..."
if [ -f "$DRC_RPT" ]; then
    echo "  DRC 报告: $DRC_RPT"
    DRC_TOTAL=$(extract_first_int_by_pattern "$DRC_RPT" 'total[^0-9]*violations?|violations?[^0-9]*total')
    if [ -n "$DRC_TOTAL" ]; then
        echo "  解析结果: total violations = $DRC_TOTAL"
        if [ "$DRC_TOTAL" -eq 0 ]; then
            echo "  ✅ DRC Clean!"
        else
            echo "  ❌ DRC 失败: total violations = $DRC_TOTAL"
            overall_pass=0
        fi
    else
        # Fallback: if no total field can be parsed, provide a conservative hint.
        echo "  [WARN] 未解析到明确的 DRC 总违例数，请人工检查报告"
        if grep -Eqi 'violation|error|fail' "$DRC_RPT" 2>/dev/null; then
            echo "  [WARN] 报告中存在关键字 violation/error/fail"
        fi
    fi
else
    echo "  [WARN] DRC 报告未找到: $DRC_RPT"
    echo "  请确认 Phase 4 已成功完成"
    overall_pass=0
fi

echo ""

# 检查 LVS 报告
LVS_RPT="$LATEST_RUN/reports/signoff/lvs.rpt"
echo "[2/2] 检查 LVS 报告..."
if [ -f "$LVS_RPT" ]; then
    echo "  LVS 报告: $LVS_RPT"
    if grep -Eqi 'LVS.*clean|netlists?.*match|devices?.*match|result.*pass|passed' "$LVS_RPT" 2>/dev/null; then
        echo "  ✅ LVS Clean!"
    elif grep -Eqi 'mismatch|not match|fail|error' "$LVS_RPT" 2>/dev/null; then
        echo "  ❌ LVS 失败: 报告中检测到 mismatch/fail/error"
        overall_pass=0
    else
        echo "  ⚠️  请人工检查 LVS 报告"
    fi
else
    echo "  [WARN] LVS 报告未找到: $LVS_RPT"
    echo "  请确认 Phase 4 已成功完成"
    overall_pass=0
fi

echo ""
echo "========================================"
echo "  物理验证检查完成"
echo "========================================"
if [ "$overall_pass" -eq 1 ]; then
    echo "  结果: PASS"
else
    echo "  结果: FAIL"
fi
echo ""
echo "常见违例及处理方法："
echo "  - Antenna violation → OpenLane2 默认自动插入 antenna diode"
echo "  - Metal spacing     → 降低 PL_TARGET_DENSITY 重跑"
echo "  - LVS mismatch      → 检查 pwm_ctrl.v 端口声明"

if [ "$overall_pass" -ne 1 ]; then
    exit 1
fi
