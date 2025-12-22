
# OpenLane Configuration for Hansen SoC
# Target Process: SkyWater 130nm (sky130A)

# Design
set ::env(DESIGN_NAME) "hansen_soc"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/../hardware/*.v]

# Timing Configuration
set ::env(CLOCK_PORT) "clk"
# Target frequency: 50MHz for 130nm is conservative and safe
set ::env(CLOCK_PERIOD) "20.0"

# Synthesis
set ::env(SYNTH_STRATEGY) "AREA 0" ;# Optimize for area (low cost)
set ::env(SYNTH_MAX_FANOUT) 10

# Floorplanning
set ::env(FP_SIZING) "absolute"
# 2.9mm x 2.9mm user area (standard Caravel harness slot)
set ::env(DIE_AREA) "0 0 2920 3520"

set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

# Routing
# Use standard density
set ::env(PL_TARGET_DENSITY) 0.55

# Magic & LVS
# Ensure we check against SkyWater PDK
set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

# Report Generation
set ::env(RUN_KLAYOUT) 1
set ::env(RUN_CVC) 1
