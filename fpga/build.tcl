# Vivado Build Script for Hansen SoC
# Usage: vivado -mode batch -source fpga/build.tcl

# 1. Configuration
set project_name "hansen_fpga"
set output_dir "fpga/build"
set part_name "xc7a35ticsg324-1L" ; # Default for Arty A7-35T. Change to xc7a100tcsg324-1 for A7-100T.

# 2. Create Project
file mkdir $output_dir
create_project -force $project_name $output_dir -part $part_name

# 3. Add Sources
add_files -norecurse [list \
    "hardware/hansen_core.v" \
    "hardware/control_unit.v" \
    "fpga/hansen_top.v" \
    "fpga/firmware.hex" \
]

# 4. Add Constraints
add_files -fileset constrs_1 -norecurse "fpga/arty_a7.xdc"

# Set Top Level
set_property top hansen_top [current_fileset]

# 5. Synthesis
puts "--- Running Synthesis ---"
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { error "Synthesis failed" }

# 6. Implementation
puts "--- Running Implementation ---"
launch_runs impl_1 -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} { error "Implementation failed" }

# 7. Generate Bitstream
puts "--- Generating Bitstream ---"
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

puts "--- SUCCESS: Bitstream generated at $output_dir/$project_name.runs/impl_1/hansen_top.bit ---"
