set ::env(DESIGN_NAME) pwm_ctrl
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 20.0
set ::env(PDK) sky130A
set ::env(PDK_ROOT) /root/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
set ::env(FP_CORE_UTIL) 30
set ::env(PL_TARGET_DENSITY) 0.3
