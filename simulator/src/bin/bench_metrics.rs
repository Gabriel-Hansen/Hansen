use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use simulator::core::Core;
use simulator::memory::Memory;
use simulator::isa::Instruction;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: bench_metrics <hex_file>");
        return;
    }

    let hex_path = &args[1];
    
    // Load
    let path = Path::new(hex_path);
    let file = File::open(&path).expect("Failed to open hex file");
    let reader = BufReader::new(file);

    let mut program: Vec<Instruction> = Vec::new();
    for line in reader.lines() {
        let line = line.expect("Failed read line");
        let parts: Vec<&str> = line.split("//").collect(); 
        let hex_str = parts[0].trim();
        if hex_str.is_empty() { continue; }
        let word = u32::from_str_radix(hex_str, 16).expect("Invalid hex");
        program.push(Instruction::decode(word));
    }

    let mut core = Core::new(0);
    let mut mem = Memory::new(65536, 0);

    // Run until HALT or Max Cycles
    let max_cycles = 1_000_000;
    let mut instr_retired = 0;
    
    while core.cycle_count < max_cycles as u64 {
        if core.halted { break; }
        if let Err(_) = core.step(&program, &mut mem) {
            break;
        }
        instr_retired += 1;
    }

    // Metrics
    let cycles = core.cycle_count;
    let ipc = if cycles > 0 { instr_retired as f64 / cycles as f64 } else { 0.0 };
    // Power Model: 5 mW static + 1 mW/MHz dynamic? 
    // Let's assume normalized "Energy Units": 1 unit per cycle.
    
    println!("{{");
    println!("  \"instructions\": {},", instr_retired);
    println!("  \"cycles\": {},", cycles);
    println!("  \"ipc\": {:.2},", ipc);
    println!("  \"status\": \"{}\"", if core.halted { "SUCCESS" } else { "TIMEOUT" });
    println!("}}");
}
