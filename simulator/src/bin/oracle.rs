use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use simulator::core::Core;
use simulator::memory::Memory;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: oracle <hex_file>");
        return;
    }

    let hex_path = &args[1];
    let mut core = Core::new(0); // ID 0
    let mut mem = Memory::new(65536, 0);

    // 1. Load Hex
    let path = Path::new(hex_path);
    let file = File::open(&path).expect("Failed to open hex file");
    let reader = BufReader::new(file);

    let mut addr = 0;
    for line in reader.lines() {
        let line = line.expect("Failed read line");
        let parts: Vec<&str> = line.split("//").collect(); // Remove comments
        let hex_str = parts[0].trim();
        if hex_str.is_empty() { continue; }
        
        let instr = u32::from_str_radix(hex_str, 16).expect("Invalid hex");
        mem.write_word(addr, instr).unwrap();
        addr += 4;
    }

    // 2. Run for Fixed Cycles (e.g. 20)
    // Enough to execute the small vector
    for _ in 0..20 {
        core.step(&mut mem);
        if core.halted { break; }
    }

    // 3. Output State (Oracle)
    println!("x1:{}", core.regs[1]);
    println!("x3:{}", core.regs[3]);
}
