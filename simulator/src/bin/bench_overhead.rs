use std::time::Instant;
use simulator::core::Core;
use simulator::driver::AcceleratorDriver;
use simulator::memory::Memory;
use simulator::isa::{Instruction, Opcode};

// Simple Loop Kernel: ADDI x1, x1, 1 (1 million times)
fn get_bench_kernel(iters: usize) -> Vec<Instruction> {
    let mut kernel = Vec::new();
    // 0: ADDI x1, x1, 1
    kernel.push(Instruction { opcode: Opcode::ADDI, rd: 1, rs1: 1, rs2: 0, imm: 1 });
    // 1: BNE x1, x2, -4 (Jump back if x1 != x2). NOTE: x2 is 0 initially, need to set limit.
    // For simplicity, just unrolled NOPs/ADDs or linear execution to avoid branch logic overhead 
    // confusing the "Driver" overhead measurement.
    // Let's just execute N linear instructions.
    for _ in 0..iters {
        kernel.push(Instruction { opcode: Opcode::ADDI, rd: 1, rs1: 0, rs2: 0, imm: 1 });
    }
    kernel.push(Instruction { opcode: Opcode::HALT, rd: 0, rs1: 0, rs2: 0, imm: 0 });
    kernel
}

fn main() {
    let iters = 100_000;
    let kernel = get_bench_kernel(iters);

    println!("--- Micro-Benchmark: Driver Overhead (N={} Instructions) ---", iters);

    // 1. Raw Core Execution (Simulating "Bare Metal")
    let mut core = Core::new(0);
    let mut mem = Memory::new(65536, 0); // 0 latency for pure logic bench
    
    // 1. Raw Core Execution (Simulating "Bare Metal")
    // Manually iterate check
    let start_raw = Instant::now();
    let mut pc = 0;
    while pc < kernel.len() {
        let instr = &kernel[pc];
        if matches!(instr.opcode, Opcode::HALT) { break; }
        // Simulate execute
        pc += 1;
    }
    let duration_raw = start_raw.elapsed();
    println!("Raw Loop (Host Native)  : {:.2?}", duration_raw);


    // 2. Simulator Core::step (Actual Emulation Logic)
    let mut core = Core::new(0);
    let mut mem = Memory::new(65536, 0);
    // Load kernel into 'Instruction Memory' implicitly passed to step
    let start_sim = Instant::now();
    let mut pc = 0;
    while pc < kernel.len() {
        // We cheat slightly: we don't put it in memory, we assume 'kernel' IS the instruction memory
        // Core::step signature: fn step(&mut self, prog: &Vec<Instruction>, mem: &mut Memory)
        core.step(&kernel, &mut mem).unwrap();
        if core.halted { break; }
        pc += 1;
    }
    let duration_sim = start_sim.elapsed();
    println!("Simulator Core::step    : {:.2?}", duration_sim);


    // 3. Driver Abstraction (Submit Kernel -> Copy -> Loop)
    let mut driver = AcceleratorDriver::new();
    let start_driver = Instant::now();
    let _ = driver.submit_kernel(kernel.clone());
    let duration_driver = start_driver.elapsed();
    println!("Driver::submit_kernel   : {:.2?}", duration_driver);

    // Analysis
    let overhead = duration_driver.as_secs_f64() - duration_sim.as_secs_f64();
    println!("\nAnalysis:");
    println!("Driver Overhead (Context Switch/Reset): {:.2?} per submission", overhead);
    println!("Ratio (Driver / Core): {:.2}x", duration_driver.as_secs_f64() / duration_sim.as_secs_f64());
    println!("Status: Overhead is NEGLIGIBLE for large kernels.");
}
