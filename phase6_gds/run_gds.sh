#!/bin/bash
# Phase 6: GDS 输出查看脚本
# 检查并显示 OpenLane2 生成的 GDS 输出文件信息
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PNR_RUNS="$PROJECT_ROOT/phase4_pnr/runs"

echo "========================================"
echo "  Phase 6: GDS 输出"
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

# 检查各输出文件
echo "输出文件检查："
echo "----------------------------------------"

# GDS 文件
GDS_FILE="$LATEST_RUN/results/final/gds/pwm_ctrl.gds"
if [ -f "$GDS_FILE" ]; then
    GDS_SIZE=$(du -h "$GDS_FILE" | cut -f1)
    echo "  ✅ GDS 文件: $GDS_FILE ($GDS_SIZE)"
else
    echo "  ❌ GDS 文件未找到"
fi

# LEF 文件
LEF_FILE="$LATEST_RUN/results/final/lef/pwm_ctrl.lef"
if [ -f "$LEF_FILE" ]; then
    echo "  ✅ LEF 文件: $LEF_FILE"
else
    echo "  ❌ LEF 文件未找到"
fi

# LIB 文件
LIB_FILE="$LATEST_RUN/results/final/lib/pwm_ctrl.lib"
if [ -f "$LIB_FILE" ]; then
    echo "  ✅ LIB 文件: $LIB_FILE"
else
    echo "  ❌ LIB 文件未找到"
fi

# Summary 报告
SUMMARY="$LATEST_RUN/final_summary.html"
if [ -f "$SUMMARY" ]; then
    echo "  ✅ 流程报告: $SUMMARY"
else
    echo "  ❌ 流程报告未找到"
fi

echo ""
echo "========================================"
echo "  GDS 输出检查完成"
echo "========================================"
echo ""
echo "查看 GDS 版图："
echo "  klayout $GDS_FILE"
echo ""
echo "输出文件用途："
echo "  - pwm_ctrl.gds → 流片主文件"
echo "  - pwm_ctrl.lef → IP 集成接口"
echo "  - pwm_ctrl.lib → 时序模型"
