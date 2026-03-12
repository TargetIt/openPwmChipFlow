#!/bin/bash
# Phase 2: PWM 仿真验证脚本
# 使用 iverilog 编译并运行仿真，生成 VCD 波形文件
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RTL_SRC="$PROJECT_ROOT/phase1_rtl/src/pwm_ctrl.v"
TB_SRC="$SCRIPT_DIR/tb/tb_pwm.v"
SIM_OUT="$SCRIPT_DIR/sim"
WAVE_FILE="$SCRIPT_DIR/wave.vcd"

echo "========================================"
echo "  Phase 2: PWM 仿真验证"
echo "========================================"

# 检查 iverilog 是否安装
if ! command -v iverilog &> /dev/null; then
    echo "[ERROR] iverilog 未安装。请运行: sudo apt install iverilog"
    exit 1
fi

# 检查源文件
if [ ! -f "$RTL_SRC" ]; then
    echo "[ERROR] RTL 源文件不存在: $RTL_SRC"
    exit 1
fi

if [ ! -f "$TB_SRC" ]; then
    echo "[ERROR] Testbench 文件不存在: $TB_SRC"
    exit 1
fi

# 编译
echo "[1/3] 编译 RTL 和 Testbench..."
iverilog -o "$SIM_OUT" "$TB_SRC" "$RTL_SRC"
echo "  编译成功"

# 运行仿真
echo "[2/3] 运行仿真..."
cd "$SCRIPT_DIR"
./sim
echo "  仿真完成"

# 检查波形文件
echo "[3/3] 检查输出..."
if [ -f "$WAVE_FILE" ]; then
    echo "  波形文件已生成: $WAVE_FILE"
    echo ""
    echo "========================================"
    echo "  仿真完成！"
    echo "  查看波形: gtkwave $WAVE_FILE"
    echo "========================================"
else
    echo "[ERROR] 波形文件未生成"
    exit 1
fi
