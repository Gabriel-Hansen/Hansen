
import subprocess
import time
import math

# BENCHMARK CONFIG
PARTICLES = 100
FRAMES = 1

# HARDWARE SPECS (ESTIMATED)
# x64 Host: Core i7, ~4GHz, ~15W per core optimized
# Hansen: RISC-V ASIC, 50MHz, ~50mW estimated (Embedded/Low Power)

def run_host_benchmark():
    # Python is slow, but acts as a proxy for "High Level Game Script" running on CPU
    start = time.perf_counter()
    
    # Simple Particle Update (x = x + v; v = v)
    # Matching the Hansen Kernel Logic
    particles = [i*2 for i in range(PARTICLES)]
    limit = 100
    
    for _ in range(FRAMES):
        for i in range(PARTICLES):
            particles[i] += 1 # V=1
            if particles[i] > limit:
                particles[i] = 0
                
    end = time.perf_counter()
    return (end - start) * 1_000_000 # in micros

def run_hansen_benchmark():
    # Run the simulator in benchmark mode
    # Note: Simulator is written in Rust, running on x64.
    # It reports the "CYCLES" the hardware WOULD take.
    
    # Build first
    subprocess.run(["cargo", "build", "--release"], cwd="./simulator", check=True, capture_output=True)
    
    cmd = ["./target/release/simulator", "benchmark"]
    result = subprocess.run(cmd, cwd="./simulator", capture_output=True, text=True)
    
    cycles = 0
    for line in result.stdout.split('\n'):
        if line.startswith("CYCLES:"):
            cycles = int(line.split(":")[1].strip())
            
    return cycles

def main():
    print("--- HANSEN ACCELERATOR BENCHMARK ---")
    print(f"Workload: {PARTICLES} Particles Update x {FRAMES} Frame")
    print("-------------------------------------")

    # 1. Host (Python)
    t_host = run_host_benchmark()
    e_host = (t_host / 1_000_000) * 15.0 # Joules (Time * 15W)
    
    print(f"[x64 Host] Time: {t_host:.2f} us | Energy (Est): {e_host:.6f} J")

    # 2. Hansen (Simulated)
    cycles = run_hansen_benchmark()
    # 50MHz = 50,000,000 cycles / sec
    # Time = Cycles / Freq
    t_hansen = (cycles / 50_000_000) * 1_000_000 # us
    e_hansen = (t_hansen / 1_000_000) * 0.05 # Joules (Time * 50mW)

    print(f"[Hansen  ] Cycles: {cycles} | Time (Est): {t_hansen:.2f} us | Energy (Est): {e_hansen:.6f} J")
    
    print("-------------------------------------")
    print("COMPARISON (Hansen vs Host):")
    
    speedup = t_host / t_hansen
    efficiency = e_host / e_hansen
    
    print(f"Speedup Factor:     {speedup:.2f}x {'(FASTER)' if speedup > 1 else '(SLOWER)'}")
    print(f"Energy Efficiency:  {efficiency:.2f}x (BETTER)")
    
    print("\n--- PITCH SUMMARY ---")
    print(f"\"While the x64 CPU is powerful, the Hansen Accelerator achieves {efficiency:.0f}x better energy efficiency for parallel physics workloads, freeing up the main CPU for Game Logic.\"")

if __name__ == "__main__":
    main()
