#!/bin/bash
# PWM 芯片全流程开发 - 环境安装脚本
# 安装仿真验证所需的本地工具
set -e

echo "========================================"
echo "  PWM 芯片全流程 - 环境安装"
echo "========================================"

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "[ERROR] 无法检测操作系统"
    exit 1
fi

echo "  检测到操作系统: $OS"
echo ""

# 安装本地仿真工具
echo "[1/3] 安装 iverilog (Verilog 仿真器)..."
if command -v iverilog &> /dev/null; then
    echo "  iverilog 已安装: $(iverilog -V 2>&1 | head -1)"
else
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt-get update && sudo apt-get install -y iverilog
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y iverilog
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm iverilog
    else
        echo "  [WARN] 请手动安装 iverilog"
    fi
fi

echo ""
echo "[2/3] 安装 GTKWave (波形查看器)..."
if command -v gtkwave &> /dev/null; then
    echo "  GTKWave 已安装"
else
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt-get install -y gtkwave
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y gtkwave
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm gtkwave
    else
        echo "  [WARN] 请手动安装 gtkwave"
    fi
fi

echo ""
echo "[3/3] 检查 Docker (OpenLane2 运行环境)..."
if command -v docker &> /dev/null; then
    echo "  Docker 已安装: $(docker --version)"
    echo "  拉取 OpenLane2 镜像..."
    docker pull efabless/openlane2:latest || echo "  [WARN] Docker 镜像拉取失败，请检查 Docker 配置"
else
    echo "  [WARN] Docker 未安装"
    echo "  OpenLane2 需要 Docker 运行，请安装 Docker："
    echo "  https://docs.docker.com/get-docker/"
fi

echo ""
echo "========================================"
echo "  环境安装完成！"
echo "========================================"
echo ""
echo "已安装工具："
command -v iverilog &> /dev/null && echo "  ✅ iverilog" || echo "  ❌ iverilog"
command -v gtkwave &> /dev/null && echo "  ✅ GTKWave" || echo "  ❌ GTKWave"
command -v docker &> /dev/null && echo "  ✅ Docker" || echo "  ❌ Docker"
echo ""
echo "下一步: 运行 ./run_all.sh 执行完整流程"
