#!/bin/bash
# Project quick health check:
# - Required files and directories exist
# - Key OpenLane config fields exist
# - Local simulation can run (if iverilog is installed)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass_count=0
fail_count=0

check_path_exists() {
    local p="$1"
    local label="$2"
    if [ -e "$p" ]; then
        echo "  [PASS] $label"
        pass_count=$((pass_count + 1))
    else
        echo "  [FAIL] $label"
        fail_count=$((fail_count + 1))
    fi
}

check_config_field() {
    local file="$1"
    local field="$2"
    if grep -q "\"$field\"" "$file"; then
        echo "  [PASS] $(basename "$file") has field '$field'"
        pass_count=$((pass_count + 1))
    else
        echo "  [FAIL] $(basename "$file") missing field '$field'"
        fail_count=$((fail_count + 1))
    fi
}

echo "========================================"
echo "  openPwmChipFlow Health Check"
echo "========================================"

echo "[1/4] Checking required structure..."
check_path_exists "$PROJECT_ROOT/phase0_spec" "phase0_spec directory exists"
check_path_exists "$PROJECT_ROOT/phase1_rtl/src/pwm_ctrl.v" "RTL source exists"
check_path_exists "$PROJECT_ROOT/phase2_sim/tb/tb_pwm.v" "testbench exists"
check_path_exists "$PROJECT_ROOT/phase3_synthesis/openlane/config.json" "phase3 OpenLane config exists"
check_path_exists "$PROJECT_ROOT/phase4_pnr/openlane/config.json" "phase4 OpenLane config exists"
check_path_exists "$PROJECT_ROOT/run_all.sh" "top-level run_all.sh exists"

echo ""
echo "[2/4] Checking OpenLane config keys..."
check_config_field "$PROJECT_ROOT/phase3_synthesis/openlane/config.json" "DESIGN_NAME"
check_config_field "$PROJECT_ROOT/phase3_synthesis/openlane/config.json" "PDK"
check_config_field "$PROJECT_ROOT/phase3_synthesis/openlane/config.json" "CLOCK_PORT"
check_config_field "$PROJECT_ROOT/phase4_pnr/openlane/config.json" "DESIGN_NAME"
check_config_field "$PROJECT_ROOT/phase4_pnr/openlane/config.json" "PDK"
check_config_field "$PROJECT_ROOT/phase4_pnr/openlane/config.json" "CLOCK_PORT"

echo ""
echo "[3/4] Checking shell scripts..."
for script in \
    "$PROJECT_ROOT/setup_env.sh" \
    "$PROJECT_ROOT/run_all.sh" \
    "$PROJECT_ROOT/phase2_sim/run_sim.sh" \
    "$PROJECT_ROOT/phase3_synthesis/run_synthesis.sh" \
    "$PROJECT_ROOT/phase4_pnr/run_pnr.sh" \
    "$PROJECT_ROOT/phase5_verification/run_verify.sh" \
    "$PROJECT_ROOT/phase6_gds/run_gds.sh"
do
    check_path_exists "$script" "$(basename "$script") exists"
done

echo ""
echo "[4/4] Running simulation smoke test (if available)..."
if command -v iverilog >/dev/null 2>&1; then
    if bash "$PROJECT_ROOT/phase2_sim/run_sim.sh" >/dev/null 2>&1; then
        echo "  [PASS] simulation smoke test passed"
        pass_count=$((pass_count + 1))
    else
        echo "  [FAIL] simulation smoke test failed"
        fail_count=$((fail_count + 1))
    fi
else
    echo "  [WARN] iverilog not installed, skipping simulation smoke test"
fi

echo ""
echo "========================================"
echo "  Summary: PASS=$pass_count FAIL=$fail_count"
echo "========================================"

if [ "$fail_count" -ne 0 ]; then
    exit 1
fi
