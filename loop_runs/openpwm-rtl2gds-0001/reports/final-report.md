# Harness Run Report

## Summary

This run reached a verified RTL simulation state, but did not complete the full RTL-to-GDS flow because Docker/OpenLane and physical-design tools are not available on the local machine.

The correct status is partial success:

| Stage | Status | Evidence |
|------|--------|----------|
| Probe | passed | Project structure and tool capability recorded |
| Spec | needs_review | Requirement now aligns with implemented `duty/256` behavior |
| RTL | passed | `phase1_rtl/src/pwm_ctrl.v` exists and is used by simulation |
| Simulation | passed | 6/6 test cases passed, raw log and VCD generated |
| Synthesis | needs_tooling | Docker/OpenLane/Yosys unavailable |
| PnR | needs_tooling | Docker/OpenLane/OpenROAD unavailable |
| Physical verification | needs_tooling | No Phase 3/4 run evidence; Magic/Netgen path unavailable |
| GDS | needs_tooling | No completed backend run |

## Fixes Made During The Run

1. Installed a local minimal Icarus Verilog toolchain for this machine.
2. Fixed `phase2_sim/run_sim.sh` so per-test status is parsed from the raw log instead of fragile grep patterns.
3. Fixed the Phase 2 summary counters so test-case pass count is not confused with raw assertion count.
4. Updated the requirement document to state the implemented duty-cycle range accurately: `0/256` to `255/256`.
5. Updated `run_all.sh` so skipped required stages no longer print as full-flow success.

## Product Lesson For Harness

The important failure was not that the design failed. The design passed RTL simulation.

The important failure was that the original flow could make a reader believe the full chip flow succeeded even when synthesis, PnR, physical verification, and GDS were skipped. A chip Agent Harness must therefore treat evidence consistency as a first-class gate:

1. A passing summary cannot override failing or missing stage evidence.
2. A skipped required stage must be visible as `needs_tooling` or `not_run`.
3. Generated reports must be tied to raw logs and current-run artifacts.
4. The Agent is useful only if it turns uncertain output into auditable engineering state.

## Next Required Work

To complete the full flow, install a Docker/OpenLane-capable backend environment, then rerun Phase 3 through Phase 6 and replace the `needs_tooling` statuses with direct run evidence.
