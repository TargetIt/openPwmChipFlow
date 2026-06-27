#!/bin/bash
# Phase 4: PWM 布局布线脚本
# 使用 OpenLane2 本地工具链运行完整 RTL -> GDS 流程
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESIGN_DIR="$PROJECT_ROOT/openlane/pwm_ctrl"
CONFIG_FILE="$DESIGN_DIR/config.json"
RUN_TAG="${OPENLANE_RUN_TAG:-RUN_phase4_pnr}"

source "$PROJECT_ROOT/scripts/toolchain_env.sh"

echo "========================================"
echo "  Phase 4: PWM 布局布线 (OpenROAD via OpenLane2)"
echo "========================================"

require_tool openlane "Install OpenLane2 or set OPENLANE_VENV to the venv containing openlane."
require_tool yosys "Install OSS CAD Suite or set OSS_CAD_SUITE to its extracted directory."
require_tool openroad "OpenROAD is required for floorplan/place/route."
require_tool magic "Magic is required for GDS/DRC extraction."
require_tool netgen "Netgen is required for LVS."
require_pdk

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "  openlane : $(command -v openlane)"
echo "  openroad : $(command -v openroad)"
echo "  magic    : $(command -v magic)"
echo "  netgen   : $(command -v netgen)"
echo "  PDK_ROOT : $PDK_ROOT"
echo "  run tag  : $RUN_TAG"

echo "[1/2] 启动 OpenLane2 Classic 完整流程 (RTL -> GDS)..."
openlane \
    --manual-pdk \
    --pdk-root "$PDK_ROOT" \
    --pdk sky130A \
    --scl sky130_fd_sc_hd \
    --flow Classic \
    --design-dir "$DESIGN_DIR" \
    --run-tag "$RUN_TAG" \
    --overwrite \
    "$CONFIG_FILE"

echo "[2/2] 生成 PnR 报告..."
bash "$SCRIPT_DIR/gen_report.sh"

echo ""
echo "========================================"
echo "  布局布线完成！"
echo "  报告位于: phase4_pnr/report/pnr_report.md"
echo "========================================"
echo ""
echo "配置参数："
echo "  - CLOCK_PERIOD: 20.0 ns (50 MHz)"
echo "  - FP_CORE_UTIL: 30"
echo "  - PL_TARGET_DENSITY: 0.3"
