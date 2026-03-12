#!/bin/bash
# PWM 芯片全流程开发 - 一键运行脚本
# 按阶段顺序运行完整的 RTL → GDS 流程
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "╔══════════════════════════════════════════╗"
echo "║  PWM 数字芯片全流程开发                    ║"
echo "║  PWM Controller + Sky130 + OpenLane2      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ======== Phase 1: RTL ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 1: RTL 编写"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "$PROJECT_ROOT/phase1_rtl/src/pwm_ctrl.v" ]; then
    LINES=$(wc -l < "$PROJECT_ROOT/phase1_rtl/src/pwm_ctrl.v")
    echo "  ✅ pwm_ctrl.v 已就绪 ($LINES 行)"
else
    echo "  ❌ pwm_ctrl.v 不存在"
    exit 1
fi
echo ""

# ======== Phase 2: 仿真 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 2: 仿真验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v iverilog &> /dev/null; then
    bash "$PROJECT_ROOT/phase2_sim/run_sim.sh"
else
    echo "  [SKIP] iverilog 未安装，跳过仿真"
    echo "  运行 ./setup_env.sh 安装依赖"
fi
echo ""

# ======== Phase 3: 综合 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 3: 综合"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v docker &> /dev/null; then
    bash "$PROJECT_ROOT/phase3_synthesis/run_synthesis.sh"
else
    echo "  [SKIP] Docker 未安装，跳过综合"
    echo "  运行 ./setup_env.sh 安装依赖"
fi
echo ""

# ======== Phase 4: 布局布线 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 4: 布局布线"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v docker &> /dev/null; then
    bash "$PROJECT_ROOT/phase4_pnr/run_pnr.sh"
else
    echo "  [SKIP] Docker 未安装，跳过布局布线"
fi
echo ""

# ======== Phase 5: 物理验证 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 5: 物理验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_ROOT/phase4_pnr/runs" ]; then
    bash "$PROJECT_ROOT/phase5_verification/run_verify.sh"
else
    echo "  [SKIP] Phase 4 未完成，跳过物理验证"
fi
echo ""

# ======== Phase 6: GDS 输出 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 6: GDS 输出"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_ROOT/phase4_pnr/runs" ]; then
    bash "$PROJECT_ROOT/phase6_gds/run_gds.sh"
else
    echo "  [SKIP] Phase 4 未完成，跳过 GDS 输出"
fi
echo ""

# ======== 完成 ========
echo "╔══════════════════════════════════════════╗"
echo "║  全流程执行完毕 🎉                        ║"
echo "╚══════════════════════════════════════════╝"
