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
        eprintln!("Usage: oracle <hex_file>");
        return;
    }

    let hex_path = &args[1];
    
    // 1. Load Program (Instruction Memory)
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

    // 2. Init Core
    let mut core = Core::new(0);
    let mut mem = Memory::new(65536, 0);

    // 3. Run
    for _ in 0..20 {
        if let Err(e) = core.step(&program, &mut mem) {
            // Handle PC out of bounds or other errors gracefully for Oracle
             break;
        }
        if core.halted { break; }
    }

    // 4. Output State
    println!("x1:{}", core.regs[1]);
    println!("x3:{}", core.regs[3]);
}
