# Evidence Register

## Run Identity

```text
commit: 2e6f479 Remove hard-coded OpenLane PDK path
GitHub Actions run: 28294071129
job: 83830873514
OpenLane run: RUN_2026.06.27_15.52.49
artifact: openpwm-rtl2gds-28294071129
artifact id: 7925921115
artifact size: 18,731,201 bytes
artifact file count: 454
```

## Execution Target

```text
frontend: local macOS arm64 for probe/simulation smoke checks
backend: GitHub Actions ubuntu-24.04 with efabless/openlane:latest
PDK: sky130A
PDK version: 0fe599b2afb6708d281543108caf8310912f54af
```

## Stage Evidence

| Stage | Status | Evidence |
| --- | --- | --- |
| Phase 2 simulation | passed | Workflow simulation step passed |
| Phase 3 synthesis | passed | `phase3_synthesis/report/synthesis_report.md` generated |
| Phase 4 PnR | passed | `phase4_pnr/report/pnr_report.md` generated |
| Magic DRC | passed | 0 violations |
| KLayout DRC | passed | 0 violations |
| LVS | passed | no mismatches |
| Antenna | passed | 0 violations |
| Phase 6 GDS | passed | GDS generated and readable by KLayout Python |

## Final Backend Artifacts

```text
pwm_ctrl.gds    416K
pwm_ctrl.lef    8.0K
pwm_ctrl.lib    12K
pwm_ctrl.def    88K
gate netlist    24K
pwm_ctrl.spice  20K
SDF files       10
SPEF corners    3
```

## Repaired Failure

Previous run `28293936383` failed during Magic GDS stream-out because the active OpenLane Tcl config hard-coded an old `PDK_ROOT`.

Repair:

- removed hard-coded `PDK_ROOT` from `openlane/pwm_ctrl/config.tcl`;
- removed hard-coded `PDK_ROOT` from `openlane/pwm_ctrl/config_pnr.tcl`;
- added CI checks for expected Magic tech file and stale PDK hash contamination.
