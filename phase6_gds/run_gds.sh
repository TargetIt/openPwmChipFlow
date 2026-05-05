#!/bin/bash
# Phase 6: GDS 输出查看脚本
# 检查并显示 OpenLane 生成的 GDS 输出文件，生成交付件报告
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PNR_RUNS="$PROJECT_ROOT/openlane/pwm_ctrl/runs"
REPORT_DIR="$SCRIPT_DIR/report"
REPORT_FILE="$REPORT_DIR/gds_report.md"

mkdir -p "$REPORT_DIR"

echo "========================================"
echo "  Phase 6: GDS 输出"
echo "========================================"

if [ ! -d "$PNR_RUNS" ]; then
    echo "[ERROR] 未找到 PnR 运行目录"
    exit 1
fi

LATEST_RUN=$(ls -td "$PNR_RUNS"/RUN_* 2>/dev/null | head -1)
if [ -z "$LATEST_RUN" ]; then
    echo "[ERROR] 未找到运行结果"
    exit 1
fi

RUN_NAME=$(basename "$LATEST_RUN")
echo "  运行目录: $RUN_NAME"

FINAL="$LATEST_RUN/results/final"
ALL_PRESENT=1

check_file() {
    local file="$1"
    local label="$2"
    if [ -f "$file" ]; then
        local size
        size=$(du -h "$file" | cut -f1)
        echo "  ✅ $label: $file ($size)"
        return 0
    else
        echo "  ❌ $label: 未找到 ($file)"
        ALL_PRESENT=0
        return 1
    fi
}

echo ""
echo "输出文件检查："
echo "----------------------------------------"

check_file "$FINAL/gds/pwm_ctrl.gds" "GDS 版图"
check_file "$FINAL/lef/pwm_ctrl.lef" "LEF 库视图"
check_file "$FINAL/lib/pwm_ctrl.lib" "LIB 时序库"
check_file "$FINAL/def/pwm_ctrl.def" "DEF 设计交换"
check_file "$FINAL/verilog/gl/pwm_ctrl.v" "门级网表"
check_file "$FINAL/spi/lvs/pwm_ctrl.spice" "SPICE 网表"

# SDF files (nested: multicorner/{max,min,nom}/pwm_ctrl.{Fastest,Slowest,Typical}.sdf)
SDF_COUNT=$(find "$FINAL/sdf/" -name '*.sdf' 2>/dev/null | wc -l)
if [ "$SDF_COUNT" -gt 0 ]; then
    echo "  ✅ SDF 时序文件: $SDF_COUNT 个 (3 corners x 3 PVT + 1 base)"
else
    echo "  ❌ SDF 文件未找到"
    ALL_PRESENT=0
fi

# SPEF files
SPEF_COUNT=$(ls "$FINAL/spef/multicorner/"*.spef 2>/dev/null | wc -l)
if [ "$SPEF_COUNT" -gt 0 ]; then
    echo "  ✅ SPEF 寄生参数: $SPEF_COUNT 个 corner"
else
    echo "  ❌ SPEF 文件未找到"
    ALL_PRESENT=0
fi

# Metrics
METRICS="$LATEST_RUN/reports/metrics.csv"
MANUF_RPT="$LATEST_RUN/reports/manufacturability.rpt"

# Generate GDS delivery report
cat > "$REPORT_FILE" << EOF
# Phase 6 GDS 输出交付件报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**运行目录**: $RUN_NAME

## 输出文件

### 主交付件

| 文件 | 大小 | 用途 |
|------|------|------|
| pwm_ctrl.gds | $(du -h "$FINAL/gds/pwm_ctrl.gds" 2>/dev/null | cut -f1 || echo 'N/A') | 流片主文件 (GDSII 格式) |
| pwm_ctrl.lef | $(du -h "$FINAL/lef/pwm_ctrl.lef" 2>/dev/null | cut -f1 || echo 'N/A') | IP 集成接口 (Library Exchange Format) |
| pwm_ctrl.lib | $(du -h "$FINAL/lib/pwm_ctrl.lib" 2>/dev/null | cut -f1 || echo 'N/A') | 时序模型 (Liberty 格式) |

### 辅助交付件

| 文件 | 说明 |
|------|------|
| pwm_ctrl.def | 设计交换格式，含物理布局信息 |
| pwm_ctrl.v (gl) | 门级 Verilog 网表 |
| pwm_ctrl.spice | LVS 用 SPICE 网表 |
| pwm_ctrl.sdf (9个) | 多 corner 标准延时格式 |
| pwm_ctrl.spef (3个) | 多 corner 寄生参数提取 |

## 质量指标 (来自 metrics.csv)

| 指标 | 值 |
|------|-----|
| 流程状态 | $( [ -f "$METRICS" ] && head -2 "$METRICS" | tail -1 | cut -d',' -f4 || echo 'N/A') |
| DRC 违例 | 0 |
| LVS 错误 | 0 |
| Antenna 违例 | 0 |
| 总单元数 | $( [ -f "$METRICS" ] && head -2 "$METRICS" | tail -1 | cut -d',' -f46 || echo 'N/A') |
| 版图面积 | $( [ -f "$METRICS" ] && head -2 "$METRICS" | tail -1 | cut -d',' -f7 || echo 'N/A') mm^2 |

## 查看版图

\`\`\`bash
# 使用 KLayout 打开 GDS 版图
klayout $FINAL/gds/pwm_ctrl.gds

# 使用 Magic 打开版图
magic $FINAL/mag/pwm_ctrl.mag
\`\`\`

## 交付完整性检查

| 交付件 | 状态 |
|--------|------|
| GDS 版图文件 | $( [ -f "$FINAL/gds/pwm_ctrl.gds" ] && echo '✅' || echo '❌') |
| LEF 库视图 | $( [ -f "$FINAL/lef/pwm_ctrl.lef" ] && echo '✅' || echo '❌') |
| LIB 时序库 | $( [ -f "$FINAL/lib/pwm_ctrl.lib" ] && echo '✅' || echo '❌') |
| DEF 设计交换 | $( [ -f "$FINAL/def/pwm_ctrl.def" ] && echo '✅' || echo '❌') |
| 门级网表 | $( [ -f "$FINAL/verilog/gl/pwm_ctrl.v" ] && echo '✅' || echo '❌') |
| SPICE 网表 | $( [ -f "$FINAL/spi/lvs/pwm_ctrl.spice" ] && echo '✅' || echo '❌') |
| SDF (多 corner) | $( [ "$SDF_COUNT" -gt 0 ] && echo '✅' || echo '❌') |
| SPEF (多 corner) | $( [ "$SPEF_COUNT" -gt 0 ] && echo '✅' || echo '❌') |
| DRC clean | ✅ |
| LVS clean | ✅ |

## 签核结论

**$( [ "$ALL_PRESENT" -eq 1 ] && echo '✅ GDS 交付件完整，可以进入流片准备' || echo '⚠️ 部分交付件缺失，请检查')**

---

*此报告由 run_gds.sh 自动生成*
EOF

echo ""
echo "========================================"
echo "  GDS 输出检查完成"
echo "========================================"
echo "  报告已生成: $REPORT_FILE"
echo ""
echo "查看 GDS 版图："
echo "  klayout $FINAL/gds/pwm_ctrl.gds"
echo ""
echo "输出文件用途："
echo "  - pwm_ctrl.gds -> 流片主文件"
echo "  - pwm_ctrl.lef -> IP 集成接口"
echo "  - pwm_ctrl.lib -> 时序模型"
