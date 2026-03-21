#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
INSTALLER="$PROJECT_ROOT/scripts/install_wsl_requirements.sh"
REQUIREMENTS="$PROJECT_ROOT/scripts/wsl_requirements.txt"

echo "========================================"
echo "  openPwmChipFlow Environment Setup"
echo "========================================"

if [[ ! -f /etc/os-release ]]; then
  echo "[ERROR] setup_env.sh must run on Linux/WSL."
  exit 1
fi

if [[ ! -f "$INSTALLER" ]]; then
  echo "[ERROR] Missing installer script: $INSTALLER"
  exit 1
fi

chmod +x "$INSTALLER"
"$INSTALLER" "$REQUIREMENTS"

echo ""
echo "[NEXT] You can run: ./run_all.sh"
