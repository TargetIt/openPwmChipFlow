set ::env(DESIGN_NAME) pwm_ctrl
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 20.0
set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
