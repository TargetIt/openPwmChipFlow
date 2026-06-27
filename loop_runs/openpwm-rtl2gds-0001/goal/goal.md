# Goal

Run the `openPwmChipFlow` project through the chip-development flow using a Harness-style loop:

1. Probe the repository and local tool capability.
2. Execute all stages that the local machine can run.
3. Mark blocked or skipped stages explicitly.
4. Fix evidence-generation defects found during the run.
5. Produce a reviewable record that separates real evidence from assumptions.

## Exit Standard

The run can only be called a full RTL-to-GDS success if every required stage has direct evidence:

| Stage | Required Evidence |
|------|-------------------|
| RTL | Source exists and matches the public interface spec |
| Simulation | Compiled simulator, raw log, generated wave, all tests pass |
| Synthesis | OpenLane/Yosys run log and synthesis report |
| PnR | OpenROAD/OpenLane run log and layout report |
| Physical verification | DRC/LVS reports with zero blocking violations |
| GDS | Generated GDS path and viewer/export evidence |

This run is allowed to end as partial success if missing tools prevent later stages. That state must be recorded as `needs_tooling`, not `passed`.
