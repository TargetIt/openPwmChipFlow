#!/bin/bash
# Phase 3: PWM 综合脚本
# 使用 OpenLane2 (Docker) 运行 Yosys 综合
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$SCRIPT_DIR/openlane/config.json"

echo "========================================"
echo "  Phase 3: PWM 综合 (Yosys via OpenLane2)"
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

# 运行综合
echo "[1/2] 启动 OpenLane2 综合..."
docker run --rm \
    -v "$PROJECT_ROOT":/work \
    -w /work/phase3_synthesis \
    efabless/openlane2:latest \
    openlane /work/phase3_synthesis/openlane/config.json --to synthesis

echo "[2/2] 检查综合报告..."
echo ""
echo "========================================"
echo "  综合完成！"
echo "  报告位于: phase3_synthesis/runs/ 目录下"
echo "========================================"
echo ""
echo "检查要点："
echo "  - 标准单元数: 预期 20–50 个"
echo "  - 关键路径: 预期 < 2 ns"
echo "  - 面积: 预期 < 200 μm²"
echo "  - 时序违例: 必须为 0"
