#!/bin/bash
set -e

echo "--- Hansen Accelerator Benchmark Suite ---"
echo "Date: $(date)"
echo "----------------------------------------"

# 1. Build Simulator (Release)
echo "[1/3] Building Simulator..."
cd simulator
cargo build --release --quiet
cd ..

# 2. Run Overhead Benchmark (Driver vs Native)
echo "[2/3] Running Driver Overhead Benchmark..."
./simulator/target/release/bench_overhead > bench_driver_overhead.txt
cat bench_driver_overhead.txt

# 3. Run Micro-Benchmark (Python Interop)
# Checks the latency of the Python -> C -> Rust stack
echo "[3/3] Running Python Interop Latency Test..."
if [ -f "demo/benchmark.py" ]; then
    python3 demo/benchmark.py > bench_python_stack.txt
    head -n 5 bench_python_stack.txt
else
    echo "Skipping Python bench (file not found)."
fi

echo "----------------------------------------"
echo "Benchmarks Complete. Results saved to *.txt"
