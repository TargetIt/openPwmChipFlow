#!/bin/bash
# Shared local toolchain discovery for the RTL-to-GDS scripts.
#
# Defaults point to the user-local tools used by the Harness run, but every
# path can be overridden by the caller.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TOOLS_ROOT="${TOOLS_ROOT:-$HOME/tools}"
OPENLANE_VENV="${OPENLANE_VENV:-$TOOLS_ROOT/openlane2-venv}"
OSS_CAD_SUITE="${OSS_CAD_SUITE:-$TOOLS_ROOT/oss-cad-suite}"
OPENLANE_PDK_ROOT="${OPENLANE_PDK_ROOT:-$TOOLS_ROOT/pdks}"

if [ -d "$OPENLANE_VENV/bin" ]; then
    export PATH="$OPENLANE_VENV/bin:$PATH"
fi

if [ -d "$OSS_CAD_SUITE/bin" ]; then
    export PATH="$OSS_CAD_SUITE/bin:$PATH"
fi

if [ -d "$TOOLS_ROOT/iverilog/bin" ]; then
    export PATH="$TOOLS_ROOT/iverilog/bin:$PATH"
fi

export PDK_ROOT="${PDK_ROOT:-$OPENLANE_PDK_ROOT}"

require_tool() {
    local tool="$1"
    local hint="$2"
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[ERROR] Missing required tool: $tool"
        if [ -n "$hint" ]; then
            echo "        $hint"
        fi
        exit 1
    fi
}

require_pdk() {
    if [ ! -d "$PDK_ROOT" ]; then
        echo "[ERROR] PDK_ROOT does not exist: $PDK_ROOT"
        echo "        Set OPENLANE_PDK_ROOT or PDK_ROOT to a prepared Sky130 PDK."
        exit 1
    fi
}
