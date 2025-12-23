# Hansen Accelerator Makefile

.PHONY: all sim hw-test bench clean driver-build

# Default target
all: sim hw-test

# --- Hardware Simulation (Verilog) ---
# Compiles and runs the Robust Testbench
hw-test:
	@echo "[HW] Compiling Verilog Testbench..."
	@iverilog -g2012 -o robust_sim hardware/tb_hansen_core_robust.v hardware/hansen_core.v hardware/control_unit.v
	@echo "[HW] Running Robust Simulation..."
	@vvp robust_sim
	@echo "[HW] Running Granular Verification Suite..."
	@make verify-alu verify-control verify-mem

verify-alu:
	@iverilog -g2012 -o alu_sim hardware/verification/tb_alu.v hardware/hansen_core.v hardware/control_unit.v
	@vvp alu_sim

verify-control:
	@iverilog -g2012 -o control_sim hardware/verification/tb_control.v hardware/hansen_core.v hardware/control_unit.v
	@vvp control_sim

verify-mem:
	@iverilog -g2012 -o mem_sim hardware/verification/tb_memory.v hardware/hansen_core.v hardware/control_unit.v
	@vvp mem_sim

# --- Software Simulator (Rust) ---
# Runs the Rust-based functional simulator
sim:
	@echo "[SW] Building Simulator..."
	@cd simulator && cargo build --release --quiet
	@echo "[SW] Simulator Ready."

# --- Benchmarks ---
# Runs the automated performance suite
bench:
	@echo "[BENCH] Running Benchmark Suite..."
	@chmod +x run_benchmarks.sh
	@./run_benchmarks.sh

# --- Utilities ---
clean:
	@echo "Cleaning up..."
	@rm -f robust_sim *.vcd *.log *.txt
	@cd simulator && cargo clean
	@rm -rf docs/PROJECT_WALKTHROUGH.md # Example cleanup
	@echo "Clean complete."

# --- Kernel Driver (Linux) ---
driver-build:
	@echo "[DRIVER] Building Kernel Module..."
	@cd kernel_driver && make
