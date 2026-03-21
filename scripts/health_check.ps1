$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")

$passCount = 0
$failCount = 0

function Check-PathExists {
    param(
        [string]$PathToCheck,
        [string]$Label
    )
    if (Test-Path $PathToCheck) {
        Write-Host "  [PASS] $Label"
        $script:passCount++
    }
    else {
        Write-Host "  [FAIL] $Label"
        $script:failCount++
    }
}

function Check-JsonField {
    param(
        [string]$JsonPath,
        [string]$FieldName
    )
    $json = Get-Content -Raw -Encoding UTF8 $JsonPath | ConvertFrom-Json
    if ($null -ne $json.$FieldName) {
        Write-Host "  [PASS] $(Split-Path -Leaf $JsonPath) has field '$FieldName'"
        $script:passCount++
    }
    else {
        Write-Host "  [FAIL] $(Split-Path -Leaf $JsonPath) missing field '$FieldName'"
        $script:failCount++
    }
}

Write-Host "========================================"
Write-Host "  openPwmChipFlow Health Check (Windows)"
Write-Host "========================================"

Write-Host "[1/3] Checking required structure..."
Check-PathExists (Join-Path $projectRoot "phase0_spec") "phase0_spec directory exists"
Check-PathExists (Join-Path $projectRoot "phase1_rtl/src/pwm_ctrl.v") "RTL source exists"
Check-PathExists (Join-Path $projectRoot "phase2_sim/tb/tb_pwm.v") "testbench exists"
Check-PathExists (Join-Path $projectRoot "phase3_synthesis/openlane/config.json") "phase3 OpenLane config exists"
Check-PathExists (Join-Path $projectRoot "phase4_pnr/openlane/config.json") "phase4 OpenLane config exists"
Check-PathExists (Join-Path $projectRoot "run_all.sh") "top-level run_all.sh exists"

Write-Host ""
Write-Host "[2/3] Checking OpenLane config keys..."
Check-JsonField (Join-Path $projectRoot "phase3_synthesis/openlane/config.json") "DESIGN_NAME"
Check-JsonField (Join-Path $projectRoot "phase3_synthesis/openlane/config.json") "PDK"
Check-JsonField (Join-Path $projectRoot "phase3_synthesis/openlane/config.json") "CLOCK_PORT"
Check-JsonField (Join-Path $projectRoot "phase4_pnr/openlane/config.json") "DESIGN_NAME"
Check-JsonField (Join-Path $projectRoot "phase4_pnr/openlane/config.json") "PDK"
Check-JsonField (Join-Path $projectRoot "phase4_pnr/openlane/config.json") "CLOCK_PORT"

Write-Host ""
Write-Host "[3/3] Checking shell scripts..."
$shellScripts = @(
    "setup_env.sh",
    "run_all.sh",
    "phase2_sim/run_sim.sh",
    "phase3_synthesis/run_synthesis.sh",
    "phase4_pnr/run_pnr.sh",
    "phase5_verification/run_verify.sh",
    "phase6_gds/run_gds.sh"
)

foreach ($script in $shellScripts) {
    Check-PathExists (Join-Path $projectRoot $script) "$script exists"
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Summary: PASS=$passCount FAIL=$failCount"
Write-Host "========================================"

if ($failCount -ne 0) {
    exit 1
}
