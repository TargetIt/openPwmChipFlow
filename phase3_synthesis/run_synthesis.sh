#!/bin/bash
# Phase 3: PWM 综合脚本
# 使用 OpenLane (Docker) 运行 Yosys 综合到 GDS 全流程
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESIGN_DIR="$PROJECT_ROOT/openlane/pwm_ctrl"
VOLARE_DIR="$HOME/.volare"

echo "========================================"
echo "  Phase 3: PWM 综合 (Yosys via OpenLane)"
echo "========================================"

if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker 未安装。请先安装 Docker。"
    exit 1
fi

if ! docker image inspect efabless/openlane:latest &> /dev/null; then
    echo "[INFO] OpenLane Docker 镜像不存在，正在拉取..."
    docker pull efabless/openlane:latest
fi

if [ ! -f "$DESIGN_DIR/config.tcl" ]; then
    echo "[ERROR] 配置文件不存在: $DESIGN_DIR/config.tcl"
    exit 1
fi

echo "[1/2] 启动 OpenLane 全流程 (RTL -> GDS)..."
docker run --rm \
    -v "$PROJECT_ROOT":/work \
    -v "$VOLARE_DIR":/root/.volare \
    -e PDK_ROOT=/root/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b \
    -w /work/openlane/pwm_ctrl \
    efabless/openlane:latest \
    flow.tcl

echo ""
echo "========================================"
echo "  综合完成！"
echo "  报告位于: openlane/pwm_ctrl/runs/ 目录下"
echo "========================================"
echo ""
echo "检查要点："
echo "  - 标准单元数: 预期 20-50 个"
echo "  - 关键路径: 预期 < 2 ns"
echo "  - 面积: 预期 < 200 um^2"
echo "  - 时序违例: 必须为 0"
