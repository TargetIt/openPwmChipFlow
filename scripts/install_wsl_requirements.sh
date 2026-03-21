#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS_FILE="${1:-$SCRIPT_DIR/wsl_requirements.txt}"

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
  echo "[ERROR] Requirements file not found: $REQUIREMENTS_FILE"
  exit 1
fi

if [[ ! -f /etc/os-release ]]; then
  echo "[ERROR] This script supports Linux environments only."
  exit 1
fi

. /etc/os-release
OS_ID="${ID:-unknown}"

if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
  echo "[ERROR] Unsupported distro: $OS_ID"
  echo "        Please install packages in $REQUIREMENTS_FILE manually."
  exit 1
fi

need_sudo() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "sudo"
  else
    echo ""
  fi
}

SUDO="$(need_sudo)"

apt_update_done=0
install_pkg_if_missing() {
  local cmd="$1"
  local pkg="$2"
  local purpose="$3"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd already installed"
    return
  fi

  if [[ "$apt_update_done" -eq 0 ]]; then
    echo "[INFO] Running apt-get update..."
    $SUDO apt-get update
    apt_update_done=1
  fi

  echo "[INSTALL] $pkg ($purpose)"
  $SUDO apt-get install -y "$pkg"
}

echo "========================================"
echo "  WSL Tool Installer"
echo "========================================"
echo "Distro: $PRETTY_NAME"
echo "Requirements: $REQUIREMENTS_FILE"
echo ""

while IFS='|' read -r cmd pkg purpose; do
  [[ -z "${cmd// }" ]] && continue
  [[ "$cmd" =~ ^# ]] && continue

  if [[ -z "${pkg// }" ]]; then
    echo "[WARN] Skip malformed line: $cmd|$pkg|$purpose"
    continue
  fi

  install_pkg_if_missing "$cmd" "$pkg" "${purpose:-no description}"
done < "$REQUIREMENTS_FILE"

echo ""
echo "[POST] Docker daemon checks..."
if command -v docker >/dev/null 2>&1; then
  if id -nG "$USER" | grep -qw docker; then
    echo "[OK] User $USER is already in docker group"
  else
    echo "[INFO] Adding $USER to docker group"
    $SUDO usermod -aG docker "$USER" || true
  fi

  if command -v systemctl >/dev/null 2>&1 && [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
    $SUDO systemctl enable --now docker || true
  else
    $SUDO service docker start || true
  fi

  if docker info >/dev/null 2>&1; then
    echo "[OK] Docker daemon is reachable"
  elif $SUDO docker info >/dev/null 2>&1; then
    echo "[OK] Docker daemon is reachable (via sudo)"
  else
    echo "[WARN] Docker daemon is not reachable yet."
    echo "       If group was just updated, restart WSL/session and retry."
  fi

  echo "[POST] Pulling OpenLane2 image..."
  if docker pull efabless/openlane2:latest >/dev/null 2>&1; then
    echo "[OK] OpenLane2 image pulled"
  elif $SUDO docker pull efabless/openlane2:latest >/dev/null 2>&1; then
    echo "[OK] OpenLane2 image pulled (via sudo)"
  else
    echo "[WARN] Failed to pull efabless/openlane2:latest"
  fi
fi

echo ""
echo "========================================"
echo "  Final Status"
echo "========================================"
for c in iverilog gtkwave klayout docker; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  [OK] $c"
  else
    echo "  [MISS] $c"
  fi
done

echo ""
echo "Done."
