# Harness Run Report

## Summary

This run completed the full RTL-to-GDS flow through the backend. Phase 3 through Phase 6 were not skipped.

| Stage | Status | Evidence |
| --- | --- | --- |
| RTL simulation | passed | GitHub Actions run `28294071129` |
| Synthesis | passed | Phase 3 report generated |
| PnR | passed | Phase 4 report generated |
| Physical verification | passed | Magic DRC 0, KLayout DRC 0, LVS clean, Antenna 0 |
| GDS delivery | passed | GDS/LEF/LIB/DEF/netlist/SPICE/SDF/SPEF produced |

## Product Lesson For Harness

The main lesson is that backend completion requires a real backend execution target. The local macOS environment was sufficient for project probe and RTL simulation, but not for OpenROAD/Magic/Netgen closure.

The Harness should therefore treat `needs_backend_execution_target` as a first-class non-pass state. Once a Linux/container backend is available, the same goal can be completed and verified by current-run artifacts.

## Environment Contamination Lesson

The failed backend run exposed a stale hard-coded PDK path in OpenLane Tcl config. PDK_ROOT and tool install paths are execution-environment data, not design intent.

Future Harness checks should reject design configs that hard-code stale PDK/tool paths, especially when CI or containers inject the canonical PDK version.
