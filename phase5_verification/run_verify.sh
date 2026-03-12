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

# 检查 DRC 报告
DRC_RPT="$LATEST_RUN/reports/signoff/drc.rpt"
echo "[1/2] 检查 DRC 报告..."
if [ -f "$DRC_RPT" ]; then
    DRC_VIOLATIONS=$(grep -c "violation" "$DRC_RPT" 2>/dev/null || echo "0")
    echo "  DRC 报告: $DRC_RPT"
    echo "  违例数量: $DRC_VIOLATIONS"
    if [ "$DRC_VIOLATIONS" = "0" ]; then
        echo "  ✅ DRC Clean!"
    else
        echo "  ⚠️  发现 DRC 违例，请检查报告"
        cat "$DRC_RPT"
    fi
else
    echo "  [WARN] DRC 报告未找到: $DRC_RPT"
    echo "  请确认 Phase 4 已成功完成"
fi

echo ""

# 检查 LVS 报告
LVS_RPT="$LATEST_RUN/reports/signoff/lvs.rpt"
echo "[2/2] 检查 LVS 报告..."
if [ -f "$LVS_RPT" ]; then
    echo "  LVS 报告: $LVS_RPT"
    if grep -qi "clean\|match\|passed" "$LVS_RPT" 2>/dev/null; then
        echo "  ✅ LVS Clean!"
    else
        echo "  ⚠️  请人工检查 LVS 报告"
        cat "$LVS_RPT"
    fi
else
    echo "  [WARN] LVS 报告未找到: $LVS_RPT"
    echo "  请确认 Phase 4 已成功完成"
fi

echo ""
echo "========================================"
echo "  物理验证检查完成"
echo "========================================"
echo ""
echo "常见违例及处理方法："
echo "  - Antenna violation → OpenLane2 默认自动插入 antenna diode"
echo "  - Metal spacing     → 降低 PL_TARGET_DENSITY 重跑"
echo "  - LVS mismatch      → 检查 pwm_ctrl.v 端口声明"
