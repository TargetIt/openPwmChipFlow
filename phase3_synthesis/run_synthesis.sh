#!/bin/bash
# Phase 3: PWM 综合脚本
# 使用 OpenLane2 本地工具链运行到 Yosys 综合阶段
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESIGN_DIR="$PROJECT_ROOT/openlane/pwm_ctrl"
CONFIG_FILE="$DESIGN_DIR/config.json"
RUN_TAG="${OPENLANE_RUN_TAG:-RUN_phase3_synthesis}"

source "$PROJECT_ROOT/scripts/toolchain_env.sh"

echo "========================================"
echo "  Phase 3: PWM 综合 (Yosys via OpenLane2)"
echo "========================================"

require_tool openlane "Install OpenLane2 or set OPENLANE_VENV to the venv containing openlane."
require_tool yosys "Install OSS CAD Suite or set OSS_CAD_SUITE to its extracted directory."
require_tool verilator "Verilator lint is the first OpenLane2 Classic step."
require_pdk

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "  openlane : $(command -v openlane)"
echo "  yosys    : $(command -v yosys)"
echo "  PDK_ROOT : $PDK_ROOT"
echo "  run tag  : $RUN_TAG"

echo "[1/2] 启动 OpenLane2 Classic flow，到 Yosys.Synthesis 停止..."
openlane \
    --manual-pdk \
    --pdk-root "$PDK_ROOT" \
    --pdk sky130A \
    --scl sky130_fd_sc_hd \
    --flow Classic \
    --design-dir "$DESIGN_DIR" \
    --run-tag "$RUN_TAG" \
    --overwrite \
    --to Yosys.Synthesis \
    "$CONFIG_FILE"

echo "[2/2] 生成综合报告..."
bash "$SCRIPT_DIR/gen_report.sh"

echo ""
echo "========================================"
echo "  综合完成！"
echo "  报告位于: phase3_synthesis/report/synthesis_report.md"
echo "========================================"
echo ""
echo "检查要点："
echo "  - 标准单元数: 预期 20-50 个"
echo "  - 关键路径: 预期 < 2 ns"
echo "  - 面积: 预期 < 200 um^2"
echo "  - 时序违例: 必须为 0"
