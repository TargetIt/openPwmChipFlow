# Project Probe

## Repository

| Item | Value |
|------|-------|
| Repository | `TargetIt/openPwmChipFlow` |
| Branch | `main` |
| Flow shape | Phase 0 spec, Phase 1 RTL, Phase 2 simulation, Phase 3 synthesis, Phase 4 PnR, Phase 5 physical verification, Phase 6 GDS |

## Tool Capability

| Tool | Status | Evidence |
|------|--------|----------|
| `iverilog` | available | Built locally at `/Users/jiuri/tools/iverilog/bin/iverilog`, version 13.0 |
| `vvp` | available | Built locally at `/Users/jiuri/tools/iverilog/bin/vvp`, version 13.0 |
| `docker` | missing | `command -v docker` returned no path |
| `yosys` | missing | `command -v yosys` returned no path |
| `openroad` | missing | `command -v openroad` returned no path |
| `klayout` | missing | `command -v klayout` returned no path |
| `verilator` | missing | `command -v verilator` returned no path |

## Important Probe Findings

The old Phase 2 report generator could claim overall success while marking individual test rows as failed. This was an evidence-generation bug, not an RTL bug.

The requirement document said `duty=255` maps to 100% duty cycle. The design spec and simulation show the implemented behavior is `255/256`, about 99.6%. The requirement was updated to match the actual RTL contract.
