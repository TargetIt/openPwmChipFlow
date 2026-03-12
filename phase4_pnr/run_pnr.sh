#!/bin/bash
# Phase 4: PWM 布局布线脚本
# 使用 OpenLane2 (Docker) 运行完整 RTL → GDS 流程
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$SCRIPT_DIR/openlane/config.json"

echo "========================================"
echo "  Phase 4: PWM 布局布线 (OpenROAD via OpenLane2)"
echo "========================================"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker 未安装。请先安装 Docker。"
    echo "  参考: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 OpenLane2 镜像
if ! docker image inspect efabless/openlane2:latest &> /dev/null; then
    echo "[INFO] OpenLane2 Docker 镜像不存在，正在拉取..."
    docker pull efabless/openlane2:latest
fi

# 检查配置文件
if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] 配置文件不存在: $CONFIG"
    exit 1
fi

# 运行完整 PnR 流程
echo "[1/2] 启动 OpenLane2 完整流程 (RTL → GDS)..."
docker run --rm \
    -v "$PROJECT_ROOT":/work \
    -w /work/phase4_pnr \
    efabless/openlane2:latest \
    openlane /work/phase4_pnr/openlane/config.json

echo "[2/2] 检查 PnR 报告..."
echo ""
echo "========================================"
echo "  布局布线完成！"
echo "  报告位于: phase4_pnr/runs/ 目录下"
echo "========================================"
echo ""
echo "配置参数："
echo "  - CLOCK_PERIOD: 20.0 ns (50 MHz)"
echo "  - FP_CORE_UTIL: 30"
echo "  - PL_TARGET_DENSITY: 0.3"
