#!/bin/bash
# PWM 芯片全流程开发 - 一键运行脚本
# 按阶段顺序运行完整的 RTL → GDS 流程
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKIPPED_PHASES=0

source "$PROJECT_ROOT/scripts/toolchain_env.sh"

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
    SKIPPED_PHASES=$((SKIPPED_PHASES + 1))
fi
echo ""

# ======== Phase 3: 综合 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 3: 综合"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v openlane >/dev/null 2>&1 && command -v yosys >/dev/null 2>&1; then
    bash "$PROJECT_ROOT/phase3_synthesis/run_synthesis.sh"
else
    echo "  [SKIP] openlane/yosys 未安装，跳过综合"
    echo "  设置 OPENLANE_VENV/OSS_CAD_SUITE/PDK_ROOT 后重跑"
    SKIPPED_PHASES=$((SKIPPED_PHASES + 1))
fi
echo ""

# ======== Phase 4: 布局布线 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 4: 布局布线"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v openlane >/dev/null 2>&1 && command -v openroad >/dev/null 2>&1 && command -v magic >/dev/null 2>&1 && command -v netgen >/dev/null 2>&1; then
    bash "$PROJECT_ROOT/phase4_pnr/run_pnr.sh"
else
    echo "  [SKIP] openlane/openroad/magic/netgen 未安装，跳过布局布线"
    echo "  设置 OPENLANE_VENV/OSS_CAD_SUITE/PDK_ROOT 后重跑"
    SKIPPED_PHASES=$((SKIPPED_PHASES + 1))
fi
echo ""

# ======== Phase 5: 物理验证 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 5: 物理验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_ROOT/openlane/pwm_ctrl/runs" ]; then
    bash "$PROJECT_ROOT/phase5_verification/run_verify.sh"
else
    echo "  [SKIP] Phase 3/4 未完成，跳过物理验证"
    SKIPPED_PHASES=$((SKIPPED_PHASES + 1))
fi
echo ""

# ======== Phase 6: GDS 输出 ========
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 6: GDS 输出"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$PROJECT_ROOT/openlane/pwm_ctrl/runs" ]; then
    bash "$PROJECT_ROOT/phase6_gds/run_gds.sh"
else
    echo "  [SKIP] Phase 3/4 未完成，跳过 GDS 输出"
    SKIPPED_PHASES=$((SKIPPED_PHASES + 1))
fi
echo ""

# ======== 完成 ========
if [ "$SKIPPED_PHASES" -eq 0 ]; then
    echo "╔══════════════════════════════════════════╗"
    echo "║  全流程执行完毕                           ║"
    echo "╚══════════════════════════════════════════╝"
else
    echo "╔══════════════════════════════════════════╗"
    echo "║  部分流程完成：存在 $SKIPPED_PHASES 个跳过阶段          ║"
    echo "╚══════════════════════════════════════════╝"
    echo "请补齐缺失工具后重跑，跳过阶段不能视为流片出口证据。"
    exit 2
fi
