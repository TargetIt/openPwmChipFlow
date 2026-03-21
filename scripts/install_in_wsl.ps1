$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$wslPath = & wsl wslpath -a $projectRoot

if (-not $wslPath) {
    throw 'Failed to convert project path to WSL path.'
}

Write-Host "Running setup in WSL: $wslPath"
& wsl -e bash -lc "cd '$wslPath' && chmod +x setup_env.sh scripts/install_wsl_requirements.sh && ./setup_env.sh"
